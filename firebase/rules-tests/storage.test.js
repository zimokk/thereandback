// Security Rules tests for storage.rules (CLAUDE.md §8, §14 — quest content
// downloads on demand instead of shipping in every build). Runs against the
// Storage emulator via `firebase emulators:exec --only firestore,storage
// "npm test"` (see .github/workflows/ci.yaml's `firestore-rules` job) — no
// real Firebase project or credentials needed.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

let testEnv;

// Resolved from this file's own location, not `process.cwd()` — same
// reasoning `firestore.test.js` already documents for its own rules path.
const rulesPath = path.join(import.meta.dirname, '../../storage.rules');

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-thereandback',
    storage: {
      rules: readFileSync(rulesPath, 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearStorage();
});

/** Writes via a context with rules disabled — arranging state under test,
 * not itself under test. */
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(fn);
}

describe('journeys/{journeyId}/**', () => {
  it('a signed-in user can read a quest\'s downloadable content', async () => {
    await seed((ctx) =>
      ctx.storage().ref('journeys/some-quest/map.webp').putString('fake-map-bytes'),
    );
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.storage().ref('journeys/some-quest/map.webp').getDownloadURL(),
    );
  });

  it('an unauthenticated read is denied', async () => {
    await seed((ctx) =>
      ctx.storage().ref('journeys/some-quest/map.webp').putString('fake-map-bytes'),
    );
    const anon = testEnv.unauthenticatedContext();
    await assertFails(
      anon.storage().ref('journeys/some-quest/map.webp').getDownloadURL(),
    );
  });

  it('a client can never write quest content, signed in or not — only the '
    + 'content pipeline uploads it', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.storage().ref('journeys/some-quest/map.webp').putString('evil-bytes'),
    );
  });
});
