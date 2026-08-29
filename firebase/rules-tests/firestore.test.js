// Security Rules tests for firestore.rules (CLAUDE.md §8, §6.4; Phase 8
// plan). Runs against the Firestore emulator via
// `firebase emulators:exec --only firestore "npm test"` (see
// .github/workflows/ci.yaml's `firestore-rules` job) — no real Firebase
// project or credentials needed. Every allow/deny pair the plan enumerates
// gets a case here.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

let testEnv;

// Resolved from this file's own location, not `process.cwd()` — the rules
// path must stay correct no matter which directory `node --test` is
// actually invoked from (`npm test` here, or `npm --prefix
// firebase/rules-tests test` from the repo root, as CI does).
const rulesPath = path.join(import.meta.dirname, '../../firestore.rules');

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-thereandback',
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

/** Writes via a context with rules disabled — arranging state under test,
 * not itself under test. */
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(fn);
}

describe('users/{uid}', () => {
  it('any signed-in user can read another user\'s profile', async () => {
    await seed((ctx) =>
      ctx.firestore().collection('users').doc('alice').set({ nickname: 'Alice' }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertSucceeds(bob.firestore().collection('users').doc('alice').get());
  });

  it('an unauthenticated read is denied', async () => {
    await seed((ctx) =>
      ctx.firestore().collection('users').doc('alice').set({ nickname: 'Alice' }),
    );
    const anon = testEnv.unauthenticatedContext();
    await assertFails(anon.firestore().collection('users').doc('alice').get());
  });

  it('a user can create their own doc', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('users').doc('alice').set({ nickname: 'Alice' }),
    );
  });

  it('a user can update their own doc', async () => {
    await seed((ctx) =>
      ctx.firestore().collection('users').doc('alice').set({ nickname: 'Alice' }),
    );
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('users').doc('alice').update({ nickname: 'Alicia' }),
    );
  });

  it('a user cannot write another user\'s doc', async () => {
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      bob.firestore().collection('users').doc('alice').set({ nickname: 'Hacked' }),
    );
  });
});

describe('users/{uid}/progress/{journeyId}', () => {
  async function seedProgress() {
    await seed(async (ctx) => {
      await ctx
        .firestore()
        .collection('users')
        .doc('alice')
        .collection('progress')
        .doc('odyssey-ithaca')
        .set({ meters: 5000, isCurrent: true });
    });
  }

  it('self can read their own progress', async () => {
    await seedProgress();
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice
        .firestore()
        .collection('users')
        .doc('alice')
        .collection('progress')
        .doc('odyssey-ithaca')
        .get(),
    );
  });

  it('an accepted, not-hidden friend can read it', async () => {
    await seedProgress();
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertSucceeds(
      bob
        .firestore()
        .collection('users')
        .doc('alice')
        .collection('progress')
        .doc('odyssey-ithaca')
        .get(),
    );
  });

  it('a pending (not yet accepted) friend cannot read it', async () => {
    await seedProgress();
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'pending',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      bob
        .firestore()
        .collection('users')
        .doc('alice')
        .collection('progress')
        .doc('odyssey-ithaca')
        .get(),
    );
  });

  it('a friend the owner has hidden from cannot read it', async () => {
    await seedProgress();
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: { alice: true },
        }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      bob
        .firestore()
        .collection('users')
        .doc('alice')
        .collection('progress')
        .doc('odyssey-ithaca')
        .get(),
    );
  });

  it('someone with no friendship at all cannot read it', async () => {
    await seedProgress();
    const carol = testEnv.authenticatedContext('carol');
    await assertFails(
      carol
        .firestore()
        .collection('users')
        .doc('alice')
        .collection('progress')
        .doc('odyssey-ithaca')
        .get(),
    );
  });

  it('self can write their own progress', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice
        .firestore()
        .collection('users')
        .doc('alice')
        .collection('progress')
        .doc('odyssey-ithaca')
        .set({ meters: 100, isCurrent: true }),
    );
  });

  it('a friend cannot write the owner\'s progress', async () => {
    await seedProgress();
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      bob
        .firestore()
        .collection('users')
        .doc('alice')
        .collection('progress')
        .doc('odyssey-ithaca')
        .set({ meters: 999999, isCurrent: true }),
    );
  });
});

describe('usernames/{nicknameLower}', () => {
  it('any signed-in user can get one', async () => {
    await seed((ctx) =>
      ctx.firestore().collection('usernames').doc('alice').set({ uid: 'alice-uid' }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertSucceeds(bob.firestore().collection('usernames').doc('alice').get());
  });

  it('listing the whole collection is always denied', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(alice.firestore().collection('usernames').get());
  });

  it('a user can claim a nickname naming themself', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('usernames').doc('alice').set({ uid: 'alice' }),
    );
  });

  it('a user cannot claim a nickname naming a different uid', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('usernames').doc('alice').set({ uid: 'bob' }),
    );
  });

  it('a user cannot overwrite an existing claim', async () => {
    await seed((ctx) =>
      ctx.firestore().collection('usernames').doc('alice').set({ uid: 'alice' }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      bob.firestore().collection('usernames').doc('alice').set({ uid: 'bob' }),
    );
  });

  it('the owner can update/delete their own claim', async () => {
    await seed((ctx) =>
      ctx.firestore().collection('usernames').doc('alice').set({ uid: 'alice' }),
    );
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('usernames').doc('alice').delete(),
    );
  });

  it('a non-owner cannot update/delete someone else\'s claim', async () => {
    await seed((ctx) =>
      ctx.firestore().collection('usernames').doc('alice').set({ uid: 'alice' }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      bob.firestore().collection('usernames').doc('alice').delete(),
    );
  });
});

describe('friendships/{pairId}', () => {
  it('creating a valid pending request succeeds', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'pending',
          initiatorUid: 'alice',
        }),
    );
  });

  it('creating with the wrong document id for the pair fails', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice
        .firestore()
        .collection('friendships')
        .doc('wrong-id')
        .set({
          uids: ['alice', 'bob'],
          status: 'pending',
          initiatorUid: 'alice',
        }),
    );
  });

  it('creating already-accepted fails', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
        }),
    );
  });

  it('creating a pair that doesn\'t include yourself fails', async () => {
    const carol = testEnv.authenticatedContext('carol');
    await assertFails(
      carol
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'pending',
          initiatorUid: 'alice',
        }),
    );
  });

  it('the non-initiator can accept a pending request', async () => {
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'pending',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertSucceeds(
      bob
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .update({ status: 'accepted' }),
    );
  });

  it('the initiator cannot accept their own request', async () => {
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'pending',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .update({ status: 'accepted' }),
    );
  });

  it('an accepted friendship cannot be moved back to pending', async () => {
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertFails(
      bob
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .update({ status: 'pending' }),
    );
  });

  it('a party can hide their own progress via hiddenBy', async () => {
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .update({ 'hiddenBy.alice': true }),
    );
  });

  it('a party cannot flip the other party\'s hiddenBy key', async () => {
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .update({ 'hiddenBy.bob': true }),
    );
  });

  it('either party can delete the friendship (remove/decline/cancel)', async () => {
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const bob = testEnv.authenticatedContext('bob');
    await assertSucceeds(
      bob.firestore().collection('friendships').doc('alice_bob').delete(),
    );
  });

  it('a third party cannot read or delete a friendship they are not in', async () => {
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    const carol = testEnv.authenticatedContext('carol');
    await assertFails(
      carol.firestore().collection('friendships').doc('alice_bob').get(),
    );
    await assertFails(
      carol.firestore().collection('friendships').doc('alice_bob').delete(),
    );
  });

  it('a fresh request can be created again after a delete', async () => {
    await seed((ctx) =>
      ctx
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'accepted',
          initiatorUid: 'alice',
          hiddenBy: {},
        }),
    );
    await seed((ctx) =>
      ctx.firestore().collection('friendships').doc('alice_bob').delete(),
    );
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice
        .firestore()
        .collection('friendships')
        .doc('alice_bob')
        .set({
          uids: ['alice', 'bob'],
          status: 'pending',
          initiatorUid: 'alice',
        }),
    );
  });
});

describe('journeys/{journeyId}', () => {
  it('any signed-in user can read the catalog', async () => {
    await seed((ctx) =>
      ctx.firestore().collection('journeys').doc('odyssey-ithaca').set({ name: 'The Odyssey' }),
    );
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('journeys').doc('odyssey-ithaca').get(),
    );
  });

  it('a client can never write the catalog', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('journeys').doc('odyssey-ithaca').set({ name: 'Hacked' }),
    );
  });
});
