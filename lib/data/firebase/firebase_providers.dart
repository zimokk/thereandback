import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// The Firebase Auth instance (§8). Overridden in tests with
/// `firebase_auth_mocks`' `MockFirebaseAuth` (`testing` skill: never the
/// real Firebase SDK in a test) — same `keepAlive` shape as
/// `app/database_provider.dart`'s `appDatabaseProvider`.
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

/// The Firestore instance — a sync layer, never the source of truth (drift
/// on-device is, §8). Overridden in tests with `fake_cloud_firestore`.
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;
