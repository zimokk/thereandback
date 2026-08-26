// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get navJourney => 'Путь';

  @override
  String get navQuestStats => 'Карта';

  @override
  String get navAchievements => 'Трофеи';

  @override
  String get navSettings => 'Настройки';

  @override
  String unitMeters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'метра',
      many: 'метров',
      few: 'метра',
      one: 'метр',
    );
    return '$_temp0';
  }

  @override
  String unitKilometers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'километра',
      many: 'километров',
      few: 'километра',
      one: 'километр',
    );
    return '$_temp0';
  }

  @override
  String get journeyCatalogTitle => 'Выберите поход';

  @override
  String get journeyCatalogStartButton => 'Начать поход';

  @override
  String journeyDayCounter(int day) {
    return 'День $day';
  }

  @override
  String get journeyNarrativeComingSoon =>
      'Рассказ об этом участке пути ещё пишется.';

  @override
  String get stepsPermissionExplainTitle => 'Пусть шаги двигают вас';

  @override
  String get stepsPermissionExplainBody =>
      'There and Back читает данные о шагах и пройденном расстоянии, чтобы двигать вашего путника по маршруту. Эти данные не покидают устройство — кроме итогового прогресса по квесту.';

  @override
  String get stepsPermissionAllow => 'Разрешить доступ';

  @override
  String get stepsPermissionDeniedTitle => 'Пока нет данных о шагах';

  @override
  String get stepsPermissionDeniedBody =>
      'В доступе было отказано, поэтому путник пока не двигается. Вы можете разрешить доступ снова в любой момент.';

  @override
  String get stepsPermissionRetry => 'Повторить';

  @override
  String get stepsPermissionPermanentlyDeniedTitle =>
      'Нужно включить разрешение в настройках';

  @override
  String get stepsPermissionPermanentlyDeniedBody =>
      'После пары отказов Android больше не показывает запрос сам — откройте настройки приложения и разрешите «Физическая активность», чтобы путник снова двигался.';

  @override
  String get stepsPermissionOpenSettings => 'Открыть настройки';

  @override
  String get stepsHealthConnectMissingTitle => 'Нужен Health Connect';

  @override
  String get stepsHealthConnectMissingBody =>
      'Установите Health Connect, чтобы шаги двигали вашего путника.';

  @override
  String get stepsHealthConnectInstall => 'Установить Health Connect';

  @override
  String get stepsFlaggedPaceNotice =>
      'В последней синхронизации был необычно быстрый отрезок — он всё равно засчитан, просто помечен для проверки.';

  @override
  String questStatsToLabel(String pointB) {
    return 'До $pointB';
  }

  @override
  String get questStatsStartedLabel => 'Поход начат';

  @override
  String get questStatsEtaLabel => 'Ожидаемое прибытие';

  @override
  String get questStatsMapComingSoonTitle => 'Карта маршрута';

  @override
  String get questStatsMapComingSoonBody =>
      'Иллюстрированная карта этого квеста готовится — загляните позже.';

  @override
  String get questStatsEmptyTitle => 'Квест ещё не выбран';

  @override
  String get questStatsEmptyBody =>
      'Начните поход на вкладке «Путь», чтобы увидеть здесь статистику.';

  @override
  String get questStatsEmptyCta => 'К вкладке «Путь»';

  @override
  String get achievementFirstStepsTitle => 'Первые шаги';

  @override
  String get achievementHalfDayMarchTitle => 'Полдня в пути';

  @override
  String get achievementSeasonedWandererTitle => 'Бывалый путник';

  @override
  String get achievementJourneysEndTitle => 'Конец пути';

  @override
  String get achievementUnlockedLabel => 'Получено';

  @override
  String achievementRemainingLabel(String amount) {
    return 'осталось $amount';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAccountSectionTitle => 'Аккаунт';

  @override
  String get settingsSignInButton => 'Войти';

  @override
  String get settingsSignInSubtitle =>
      'Не обязательно — прогресс работает и без аккаунта.';

  @override
  String get settingsSignInStubTitle => 'Скоро';

  @override
  String get settingsSignInStubBody =>
      'Вход в аккаунт пока не подключён — прогресс по квесту уже работает и без него.';

  @override
  String get settingsSignInStubClose => 'Закрыть';

  @override
  String get settingsLanguageSectionTitle => 'Язык';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLockScreenSectionTitle => 'Экран блокировки';

  @override
  String get settingsLockScreenToggleTitle =>
      'Показывать прогресс на экране блокировки';

  @override
  String get settingsLockScreenToggleSubtitle =>
      'Тихое постоянное уведомление с прогрессом похода — видно в шторке уведомлений и на экране блокировки.';

  @override
  String get lockScreenPermissionExplainTitle => 'Прогресс всегда на виду';

  @override
  String get lockScreenPermissionExplainBody =>
      'Чтобы показывать прогресс на экране блокировки, There and Back нужно разрешение показывать уведомление и читать шаги в фоне — примерно раз в 15 минут. Там показывается только прогресс похода — никогда не сырые данные о здоровье.';

  @override
  String get lockScreenPermissionAllow => 'Разрешить';

  @override
  String get lockScreenPermissionDeniedBody =>
      'Разрешение не получено, отображение на экране блокировки выключено. Его можно включить снова в любой момент.';

  @override
  String get lockScreenPermissionMissingNotifications =>
      'Не хватает разрешения на показ уведомлений.';

  @override
  String get lockScreenPermissionMissingBackgroundHealth =>
      'Не хватает разрешения читать шаги в фоне. Оно выдаётся на экране разрешений Health Connect.';

  @override
  String get lockScreenChannelName => 'Прогресс похода';

  @override
  String get lockScreenChannelDescription =>
      'Показывает текущий прогресс похода в шторке уведомлений и на экране блокировки.';

  @override
  String lockScreenBody(String day, String distance) {
    return '$day · $distance';
  }
}
