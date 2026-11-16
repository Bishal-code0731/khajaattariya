import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaja_attariya/core/errors/user_message.dart';
import 'package:khaja_attariya/core/l10n/app_language.dart';
import 'package:khaja_attariya/core/l10n/s.dart';
import 'package:khaja_attariya/core/theme/app_palette.dart';
import 'package:khaja_attariya/core/theme/app_theme.dart';
import 'package:khaja_attariya/core/utils/formatters.dart';
import 'package:khaja_attariya/core/utils/validators.dart';
import 'package:khaja_attariya/shared/widgets/app_button.dart';
import 'package:khaja_attariya/shared/widgets/busy_overlay.dart';
import 'package:khaja_attariya/shared/widgets/language_toggle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppValidators', () {
    final v = AppValidators(S.en.common);

    test('email accepts real addresses, rejects broken ones', () {
      expect(v.email('name@example.com'), isNull);
      expect(v.email('a.b+food@mail.co.uk'), isNull); // B-12
      expect(v.email(''), isNotNull);
      expect(v.email('name@'), isNotNull);
      expect(v.email('name example.com'), isNotNull);
    });

    test('Nepali mobile numbers', () {
      expect(v.phone('9812345678'), isNull);
      expect(v.phone('+977 9801234567'), isNull);
      expect(v.phone('98-1234-5678'), isNull);
      expect(v.phone('1234567890'), isNotNull);
      expect(v.phone('981234567'), isNotNull);
      expect(v.optionalPhone(''), isNull);
    });

    test('password needs 8+ chars with a letter and a number', () {
      expect(v.password('abc12345'), isNull);
      expect(v.password('abcdefgh'), isNotNull);
      expect(v.password('1234567'), isNotNull);
      expect(v.confirmPassword(() => 'abc12345')('abc12345'), isNull);
      expect(v.confirmPassword(() => 'abc12345')('abc12346'), isNotNull);
    });

    test('price and numbers', () {
      expect(v.price('250'), isNull);
      expect(v.price('0'), isNotNull);
      expect(v.price('abc'), isNotNull);
      expect(v.nonNegative('Fee')('0'), isNull);
      expect(v.nonNegative('Fee')('-1'), isNotNull);
      expect(v.integerRange('Minutes', 5, 240)('30'), isNull);
      expect(v.integerRange('Minutes', 5, 240)('300'), isNotNull);
      expect(v.time24('09:30'), isNull);
      expect(v.time24('25:00'), isNotNull);
    });

    test('messages are translated', () {
      final ne = AppValidators(S.ne.common);
      expect(ne.email(''), contains('इमेल'));
    });
  });

  group('AppFormat', () {
    test('money uses Nepali grouping and hides .00', () {
      expect(AppFormat.moneyWith(S.en, 1250), 'Rs 1,250');
      expect(AppFormat.moneyWith(S.en, 125000), 'Rs 1,25,000');
      expect(AppFormat.moneyWith(S.en, 99.5), 'Rs 99.50');
      expect(AppFormat.moneyWith(S.ne, 30), 'रु 30');
    });

    test('order code and phone', () {
      expect(AppFormat.orderCode('a1b2c3d4-e5f6-0000-0000-000000000000'),
          '#A1B2C3D4');
      expect(AppFormat.phone('+9779812345678'), '981-234-5678');
    });
  });

  group('userMessageFor', () {
    final c = S.en.common;

    test('never shows raw exception text', () {
      expect(userMessageFor(c, StateError('boom at line 42')), c.errGeneric);
      expect(userMessageFor(c, TimeoutException('x')), c.errTimeout);
      expect(userMessageFor(c, const UserFacingException('Shop is closed.')),
          'Shop is closed.');
    });

    test('maps Supabase errors to friendly text', () {
      expect(
          userMessageFor(c, const AuthException('Invalid login credentials')),
          c.errInvalidLogin);
      expect(
        userMessageFor(
            c,
            const PostgrestException(
                message: 'new row violates row-level security policy',
                code: '42501')),
        c.errPermission,
      );
      // Our own database functions raise ready-to-show sentences.
      expect(
        userMessageFor(
            c,
            const PostgrestException(
                message: 'Your cart is empty.', code: 'P0001')),
        'Your cart is empty.',
      );
      expect(
          userMessageFor(
              c, const PostgrestException(message: 'dup', code: '23505')),
          c.errDuplicate);
    });
  });

  group('Themes', () {
    test('light and dark both carry the palette and Mukta', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(theme.extension<AppPalette>(), isNotNull);
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Mukta');
      }
      expect(AppTheme.darkTheme.extension<AppPalette>()!.textPrimary,
          isNot(AppTheme.lightTheme.extension<AppPalette>()!.textPrimary));
    });
  });

  group('Widgets', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget host(Widget child, {Locale locale = const Locale('en')}) =>
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              locale: ref.watch(languageNotifierProvider).locale,
              supportedLocales: const [Locale('en'), Locale('ne')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(body: Center(child: child)),
            ),
          ),
        );

    testWidgets('LanguageToggle switches the app to Nepali', (tester) async {
      String? label;
      await tester.pumpWidget(host(Column(children: [
        const LanguageToggle(),
        Builder(builder: (context) {
          label = context.s.common.save;
          return Text(label!);
        }),
      ])));
      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('ने'));
      await tester.pumpAndSettle();
      expect(find.text('सेभ गर्नुहोस्'), findsOneWidget);
    });

    testWidgets('BusyOverlay blocks taps only while busy', (tester) async {
      var taps = 0;
      Widget screen(bool busy) => host(BusyOverlay(
            busy: busy,
            child: TextButton(
                onPressed: () => taps++, child: const Text('Tap me')),
          ));
      await tester.pumpWidget(screen(true));
      await tester.tap(find.text('Tap me'), warnIfMissed: false);
      expect(taps, 0);
      await tester.pumpWidget(screen(false));
      await tester.tap(find.text('Tap me'));
      expect(taps, 1);
    });

    testWidgets('AppButton ignores taps while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(
          AppButton(label: 'Pay', isLoading: true, onPressed: () => taps++)));
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
