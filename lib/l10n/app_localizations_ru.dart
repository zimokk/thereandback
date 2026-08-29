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
  String get navFriends => 'Друзья';

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
  String get questMapSectionTitle => 'Карта маршрута';

  @override
  String get questMapYouAreHere => 'Ваша позиция на маршруте';

  @override
  String get questMapIllustrationMissing =>
      'Рисованная карта ещё не вошла в сборку — ниже сама линия маршрута и ваша позиция на ней.';

  @override
  String questMapNextLandmark(String name, String distance) {
    return 'Впереди: $name — осталось $distance';
  }

  @override
  String questMapLandmarkBehindCaption(String name, String distance) {
    return 'Позади: $name — $distance назад';
  }

  @override
  String get questMapAllLandmarksReached =>
      'Все ориентиры этого маршрута уже позади.';

  @override
  String get questMapLoadFailed => 'Не удалось загрузить карту этого квеста.';

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
  String get achievementFirstLeagueTitle => 'Первая лига';

  @override
  String get achievementHalfDayMarchTitle => 'Полдня в пути';

  @override
  String get achievementCenturyMarkTitle => 'Сто километров';

  @override
  String get achievementSeasonedWandererTitle => 'Бывалый путник';

  @override
  String get achievementReachedCirceTitle => 'Добрался до Цирцеи';

  @override
  String get achievementReachedLotusEatersTitle => 'Побывал у лотофагов';

  @override
  String get achievementHalfwayThereTitle => 'Половина пути';

  @override
  String get achievementReachedCalypsoTitle => 'Добрался до Калипсо';

  @override
  String get achievementLongHaulerTitle => 'Долгий путь';

  @override
  String get achievementPassedScyllaCharybdisTitle =>
      'Миновал Сциллу и Харибду';

  @override
  String get achievementPassedSirensTitle => 'Миновал сирен';

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
  String get settingsSignedInTitle => 'Вы вошли';

  @override
  String get settingsSignedInSubtitle =>
      'Аккаунт Google привязан — друзья могут найти вас по нику.';

  @override
  String get settingsSignInSuccessMessage => 'Вход через Google выполнен.';

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
  String get lockScreenHealthConnectMissingBody =>
      'Health Connect не установлен. Установите его, чтобы читать шаги в фоне и показывать прогресс на экране блокировки.';

  @override
  String get lockScreenPermissionPermanentlyDeniedBody =>
      'После пары отказов Android больше не показывает запрос сам — откройте настройки приложения, разрешите «Физическая активность» и включите тумблер снова.';

  @override
  String get lockScreenPermissionOpenSettings => 'Открыть настройки';

  @override
  String get lockScreenTroubleshootLink => 'Не видно на экране блокировки?';

  @override
  String get lockScreenTroubleshootTitle => 'Не видно на экране блокировки?';

  @override
  String get lockScreenTroubleshootBody =>
      'Приложение уже просит Android показывать его на экране блокировки — но некоторые производители (Xiaomi/MIUI и другие) добавляют поверх свою собственную настройку, которая может это блокировать, и приложение не может её ни проверить, ни запросить напрямую. Если в шторке уведомление видно, а на экране блокировки — нет, проверьте на телефоне:\n\n1. Общий (не только для этого приложения) переключатель «Уведомления на заблокированном экране» — обычно в Настройки → Экран блокировки или Настройки → Уведомления — должен быть выставлен на показ содержимого, а не «скрыть».\n2. Собственное разрешение приложения на показ на экране блокировки — в Настройки → Приложения → There and Back → Разрешения.\n3. Автозапуск и экономию батареи для приложения — должны быть без ограничений.\n4. После изменения любого из пунктов выше — выключите и включите тумблер выше, затем перезагрузите телефон.\n5. Убедитесь, что режим «Не беспокоить» выключен.';

  @override
  String get lockScreenTroubleshootClose => 'Закрыть';

  @override
  String get lockScreenChannelName => 'Прогресс похода';

  @override
  String get lockScreenChannelDescription =>
      'Показывает текущий прогресс похода в шторке уведомлений и на экране блокировки.';

  @override
  String lockScreenBody(String day, String distance) {
    return '$day · $distance';
  }

  @override
  String get friendsTitle => 'Друзья';

  @override
  String get friendsYouLabel => 'Вы';

  @override
  String get friendsAddButton => 'Добавить друга';

  @override
  String get friendsAddDialogTitle => 'Добавить друга';

  @override
  String get friendsAddNicknameLabel => 'Ник';

  @override
  String get friendsAddSubmit => 'Отправить заявку';

  @override
  String get friendsAddCancel => 'Отмена';

  @override
  String get friendsMyNicknameLabel => 'Ваш ник';

  @override
  String get friendsMyNicknameCopyTooltip => 'Скопировать ник';

  @override
  String get friendsMyNicknameCopied => 'Ник скопирован — поделитесь им с другом.';

  @override
  String get friendsPendingIncomingTitle => 'Заявки';

  @override
  String get friendsPendingOutgoingTitle => 'Отправлено';

  @override
  String friendsIncomingRequestLabel(String name) {
    return '$name хочет добавить вас в друзья';
  }

  @override
  String friendsOutgoingRequestLabel(String name) {
    return 'Заявка отправлена: $name';
  }

  @override
  String get friendsAcceptButton => 'Принять';

  @override
  String get friendsDeclineButton => 'Отклонить';

  @override
  String get friendsCancelRequestButton => 'Отменить';

  @override
  String get friendsRemoveButton => 'Удалить';

  @override
  String get friendsEmptyTitle => 'Пока нет друзей';

  @override
  String get friendsEmptyBody =>
      'Добавьте друга по нику, чтобы сравнить прогресс в квесте.';

  @override
  String get friendsOutcomeSent => 'Заявка в друзья отправлена.';

  @override
  String get friendsOutcomeNicknameNotFound =>
      'Пользователь с таким ником не найден.';

  @override
  String get friendsOutcomeCannotAddSelf => 'Это ваш собственный ник.';

  @override
  String get friendsOutcomeAlreadyExists =>
      'Вы уже связаны с этим пользователем.';

  @override
  String get friendsOutcomeNotSignedIn =>
      'Не удалось войти — попробуйте ещё раз через момент.';

  @override
  String get friendsOutcomeUpgradeCancelled =>
      'Чтобы добавлять друзей, нужен аккаунт Google — вход отменён.';

  @override
  String get friendsOutcomeUpgradeAlreadyLinked =>
      'Этот аккаунт Google уже привязан к другому профилю.';
}
