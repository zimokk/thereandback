import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/design/components/app_snackbar.dart';

void main() {
  group(
    'SnackBarDebouncer (§7 — "the same notification 20 times in a row")',
    () {
      test('the first ever message is always shown', () {
        final debouncer = SnackBarDebouncer();
        expect(debouncer.shouldShow('hello', DateTime(2026)), isTrue);
      });

      test(
        'an exact repeat within the window is suppressed — a burst of '
        'identical calls (a double-tap, a retry loop) collapses to one',
        () {
          final debouncer = SnackBarDebouncer(
            window: const Duration(seconds: 3),
          );
          final now = DateTime(2026, 1, 1, 12);

          expect(debouncer.shouldShow('hello', now), isTrue);
          // 20 more identical calls, one right after another — every one
          // of them must be suppressed, not just the second.
          for (var i = 0; i < 20; i++) {
            expect(
              debouncer.shouldShow(
                'hello',
                now.add(Duration(milliseconds: i + 1)),
              ),
              isFalse,
            );
          }
        },
      );

      test('a different message is never suppressed by an unrelated one', () {
        final debouncer = SnackBarDebouncer();
        final now = DateTime(2026, 1, 1, 12);

        expect(debouncer.shouldShow('hello', now), isTrue);
        expect(debouncer.shouldShow('goodbye', now), isTrue);
      });

      test('the same message shows again once the window has elapsed', () {
        final debouncer = SnackBarDebouncer(
          window: const Duration(seconds: 3),
        );
        final now = DateTime(2026, 1, 1, 12);

        expect(debouncer.shouldShow('hello', now), isTrue);
        expect(
          debouncer.shouldShow(
            'hello',
            now.add(const Duration(seconds: 3)),
          ),
          isTrue,
        );
      });

      test(
        'right at the window boundary (not yet elapsed) still suppresses',
        () {
          final debouncer = SnackBarDebouncer(
            window: const Duration(seconds: 3),
          );
          final now = DateTime(2026, 1, 1, 12);

          expect(debouncer.shouldShow('hello', now), isTrue);
          expect(
            debouncer.shouldShow(
              'hello',
              now.add(const Duration(milliseconds: 2999)),
            ),
            isFalse,
          );
        },
      );
    },
  );

  testWidgets(
    'showAppSnackBar short-circuits an exact repeat before ever touching '
    'ScaffoldMessenger',
    (tester) async {
      // A message unique to this test — the debouncer behind showAppSnackBar
      // is process-wide (module-level state, by design — see its own doc
      // comment), so a message reused across test files could otherwise
      // read as "already shown" because of an unrelated test's own call.
      const message = 'app_snackbar_test unique wiring message';

      late BuildContext scaffoldContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                scaffoldContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      showAppSnackBar(scaffoldContext, message);
      await tester.pump();
      expect(find.text(message), findsOneWidget);

      // A bare context with no Scaffold/ScaffoldMessenger ancestor at all
      // — `ScaffoldMessenger.of(context)` asserts and throws on this one.
      // Calling showAppSnackBar with the *same* message here proves the
      // repeat was suppressed before ever reaching that call: if it
      // weren't, this would fail with that exception instead of passing
      // quietly — a deterministic proof of the short-circuit that doesn't
      // depend on SnackBar's own display-duration/animation timing.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              showAppSnackBar(context, message);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );
}
