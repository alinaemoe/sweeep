// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get navClean => 'Чисто';

  @override
  String get navSwipe => 'Свайп';

  @override
  String get navTools => 'Утилиты';

  @override
  String get navTrash => 'Корзина';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get undo => 'Вернуть';

  @override
  String get selectAll => 'Выбрать всё';

  @override
  String get clear => 'Сбросить';

  @override
  String get seeAll => 'Все';

  @override
  String get actionSwipe => 'Свайп';

  @override
  String get skip => 'Пропустить';

  @override
  String filesCount(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString файла',
      many: '$nString файлов',
      few: '$nString файла',
      one: '$nString файл',
    );
    return '$_temp0';
  }

  @override
  String photosCount(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString фото',
      many: '$nString фото',
      few: '$nString фото',
      one: '$nString фото',
    );
    return '$_temp0';
  }

  @override
  String groupsCount(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString группы',
      many: '$nString групп',
      few: '$nString группы',
      one: '$nString группа',
    );
    return '$_temp0';
  }

  @override
  String get byteUnits => 'Б,КБ,МБ,ГБ,ТБ';

  @override
  String hz(String n) {
    return '$n Гц';
  }

  @override
  String get unitHz => 'Гц';

  @override
  String khz(String n) {
    return '$n кГц';
  }

  @override
  String get onbTitle => 'Фото не уходят\nс телефона.';

  @override
  String get onbPoint1 => 'Всё считается на самом телефоне.';

  @override
  String get onbPoint2 => 'Без загрузок, аккаунтов и рекламы.';

  @override
  String get onbPoint3 => 'Без твоего ОК ничего не удалим.';

  @override
  String get onbDenied =>
      'Доступ выключен. Разреши фото и видео для Sweeep: Настройки › Приложения › Sweeep › Разрешения. Потом вернись.';

  @override
  String get onbCheckAgain => 'Проверить ещё раз';

  @override
  String get onbAllow => 'Разрешить доступ к фото';

  @override
  String get secDuplicates => 'Дубликаты';

  @override
  String get secSimilar => 'Похожие фото';

  @override
  String get secScreenshots => 'Скриншоты';

  @override
  String get secVideos => 'Видео';

  @override
  String get secChat => 'Из чатов';

  @override
  String get secBlurry => 'Смазанные и тёмные';

  @override
  String get srcAll => 'Все фото';

  @override
  String get tagBlurry => 'смазано';

  @override
  String get tagDark => 'тёмное';

  @override
  String get scanReading => 'ЧИТАЮ ФОТО';

  @override
  String scanAnalyzing(String done, String total) {
    return 'СМОТРЮ $done ИЗ $total';
  }

  @override
  String get scanComparing => 'СРАВНИВАЮ ФАЙЛЫ';

  @override
  String get homeNothing =>
      'Пока нечего чистить. Добавь фото или проверь позже.';

  @override
  String ovalReclaimableOf(String size) {
    return 'МОЖНО УБРАТЬ ИЗ $size';
  }

  @override
  String get ovalScanning => 'СКАНИРУЮ';

  @override
  String get ovalReclaimable => 'МОЖНО УБРАТЬ';

  @override
  String get ctaScanning => 'Сканирую…';

  @override
  String get ctaAllClean => 'Всё чисто';

  @override
  String ctaFreeUp(String size) {
    return 'Освободить $size';
  }

  @override
  String get tipLibraryDetails => 'Детали';

  @override
  String semGroupDup(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Дубликаты: $countString фото, экономия $size';
  }

  @override
  String semGroupSim(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Похожие: $countString фото, экономия $size';
  }

  @override
  String semVideo(String size) {
    return 'Видео, $size';
  }

  @override
  String semVideoLen(String length, String size) {
    return 'Видео, $length, $size';
  }

  @override
  String semPhoto(String size) {
    return 'Фото, $size';
  }

  @override
  String semTagged(String tag, String size) {
    return '$tag, $size';
  }

  @override
  String swipeOf(int i, int n) {
    final intl.NumberFormat iNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String iString = iNumberFormat.format(i);
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$iString из $nString';
  }

  @override
  String get tipTrash => 'В корзину';

  @override
  String get tipKeep => 'Оставить';

  @override
  String get stampLater => 'ПОТОМ';

  @override
  String get stampTrash => 'В КОРЗИНУ';

  @override
  String get stampKeep => 'ОСТАВИТЬ';

  @override
  String swipeInTrash(String files) {
    return 'В корзине: $files ';
  }

  @override
  String get swipeDoneNothing => 'Тут пусто';

  @override
  String get swipeDoneAll => 'Всё разобрано';

  @override
  String get swipeDoneHint => 'Всё можно вернуть из корзины.';

  @override
  String get hintTitle => 'Свайпай, чтобы разобрать';

  @override
  String get hintTrash => 'Корзина';

  @override
  String get hintKeep => 'Оставить';

  @override
  String get hintLater => 'Потом';

  @override
  String get hintTap => 'Тапни, чтобы начать';

  @override
  String get tlNewestFirst => 'Сначала новые';

  @override
  String get tlOldestFirst => 'Сначала старые';

  @override
  String get tlHeadline => 'Пролистай\nкаждый месяц';

  @override
  String tlSummary(String photos, String swept) {
    return '$photos · разобрано $swept';
  }

  @override
  String get tlNoPhotos => 'Пока нет фото.';

  @override
  String tlContinueMonth(String month) {
    return 'Дальше · $month';
  }

  @override
  String tlMonthLine(String photos, String status) {
    return '$photos · $status';
  }

  @override
  String get tlAllSwept => 'всё разобрано';

  @override
  String tlNSwept(String n) {
    return 'разобрано $n';
  }

  @override
  String get tlNotStarted => 'не начато';

  @override
  String get tlDone => 'Готово';

  @override
  String get tlContinue => 'Дальше';

  @override
  String get tlMore => 'ещё';

  @override
  String tlSemMore(String n) {
    return 'Ещё $n фото';
  }

  @override
  String tlSemPhotoFrom(String date) {
    return 'Фото от $date';
  }

  @override
  String tlSemReview(String month) {
    return 'Разобрать ещё раз: $month';
  }

  @override
  String tlSemContinue(String month) {
    return 'Продолжить: $month';
  }

  @override
  String tlSemSwipe(String month) {
    return 'Свайпать: $month';
  }

  @override
  String get tlSemSort => 'Сначала новые. Тап — сначала старые';

  @override
  String get tlSemSortOld => 'Сначала старые. Тап — сначала новые';

  @override
  String get trashNothingDeleted => 'Ничего не удалилось.';

  @override
  String get trashDeleteTitle => 'Удалить всё?';

  @override
  String trashDeleteBody(String files, String size) {
    return 'Удалим с телефона: $files ($size). Android может спросить ещё раз.';
  }

  @override
  String get deleteAll => 'Удалить всё';

  @override
  String get emptyAll => 'Очистить';

  @override
  String get trashEmpty => 'Корзина пуста';

  @override
  String trashWillFree(String files, String size) {
    return '$files · освободим $size';
  }

  @override
  String get trashLandHere => 'Сюда падают смахнутые фото.';

  @override
  String trashSelected(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Выбрано: $nString · $size · можно вернуть, пока не очистишь';
  }

  @override
  String restoreN(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Вернуть: $nString';
  }

  @override
  String get deleteForever => 'Удалить навсегда';

  @override
  String freedTitle(String size) {
    return 'Освободили $size';
  }

  @override
  String freedSub(String files) {
    return 'Удалено: $files';
  }

  @override
  String get daysToday => 'сегодня';

  @override
  String daysLeft(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$nString дн.';
  }

  @override
  String movedToTrash(String files) {
    return 'В корзине: $files';
  }

  @override
  String get sortNewest => 'Новые';

  @override
  String get sortLargest => 'Крупные';

  @override
  String get allApps => 'Все приложения';

  @override
  String get nothingHere => 'Тут пусто.';

  @override
  String catSelected(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Выбрано: $nString · $size · можно вернуть из корзины';
  }

  @override
  String moveNToTrash(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'В корзину: $nString';
  }

  @override
  String groupsSummary(String groups, String size) {
    return '$groups · можно убрать $size';
  }

  @override
  String groupsInTrash(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return ' · в корзине $countString ($size)';
  }

  @override
  String get sortSaving => 'Больше места';

  @override
  String get sortCopies => 'Копии';

  @override
  String get nothingLeft => 'Тут больше ничего.';

  @override
  String groupsSelectedBar(String groups) {
    return 'Выбрано: $groups · лучшее фото останется';
  }

  @override
  String cleanGroups(String groups, String size) {
    return 'Почистить: $groups · $size';
  }

  @override
  String groupSemantics(String kind, int count, String state) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$kind: $countString файлов, $state';
  }

  @override
  String get stateSelected => 'выбрано';

  @override
  String get stateNotSelected => 'не выбрано';

  @override
  String semSort(String label) {
    return 'Сортировка: $label';
  }

  @override
  String groupSave(String size) {
    return 'минус $size';
  }

  @override
  String pagerGroupOf(int i, int n) {
    final intl.NumberFormat iNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String iString = iNumberFormat.format(i);
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Группа $iString из $nString';
  }

  @override
  String get pagerNothing => 'Нечего разбирать.';

  @override
  String get tipAllGroups => 'Все группы';

  @override
  String get pagerKeepAll => 'Оставить все · дальше';

  @override
  String pagerTrashN(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'В корзину: $nString · $size';
  }

  @override
  String get whyOldest => 'Самая старая';

  @override
  String get whySharpest => 'Самое резкое';

  @override
  String get pillBestPick => 'ЛУЧШЕЕ';

  @override
  String get pillBest => 'ЛУЧШЕЕ';

  @override
  String get pillKeep => 'ОСТАВИТЬ';

  @override
  String get pillTrash => 'КОРЗИНА';

  @override
  String get semKeptCopy => 'Оставляем. Тап — в корзину';

  @override
  String get semTrashCopy => 'В корзину. Тап — оставить';

  @override
  String get pagerTip =>
      'Тап — сравнить · удержать — оставить/удалить · вниз — удалить все';

  @override
  String pagerTrashAllN(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Удалить все $nString · $size';
  }

  @override
  String get stampTrashAll => 'УДАЛИТЬ ВСЕ';

  @override
  String get secScreenRecordings => 'Записи экрана';

  @override
  String get notifTitle => 'Sweeep сканирует';

  @override
  String get notifChannel => 'Скан библиотеки';

  @override
  String get notifStart => 'Сканирую библиотеку';

  @override
  String notifHashing(String done, String total) {
    return 'Смотрю фото · $done из $total';
  }

  @override
  String notifChecking(String done, String total) {
    return 'Ищу дубликаты · $done из $total';
  }

  @override
  String scanOfFiles(String done, String total) {
    return '$done ИЗ $total ФАЙЛОВ';
  }

  @override
  String get scanStepRead => 'Читаю библиотеку';

  @override
  String get scanStepFinger => 'Смотрю фото';

  @override
  String get scanStepCompare => 'Сравниваю похожие';

  @override
  String get scanStepGroup => 'Собираю группы';

  @override
  String get scanStatusDone => 'готово';

  @override
  String get scanStatusNext => 'дальше';

  @override
  String get scanCountGroups => 'групп';

  @override
  String get scanCountShots => 'скриншотов';

  @override
  String get scanCountFound => 'найдено пока';

  @override
  String get scanPrivacy =>
      'Всё считается на телефоне. Ничего не уходит в сеть.';

  @override
  String get scanPausedNote => 'Пауза. Прогресс сохранён.';

  @override
  String get scanPause => 'Пауза';

  @override
  String get scanResume => 'Продолжить';

  @override
  String get scanLater => 'Позже';

  @override
  String get modeGrid => 'Сетка';

  @override
  String get modeSwipe => 'Свайп';

  @override
  String get modeMonths => 'Месяцы';

  @override
  String groupsMonthLine(String groups, String size) {
    return '$groups · минус $size';
  }

  @override
  String get videoPlay => 'Включить видео';

  @override
  String get videoPause => 'Пауза';

  @override
  String get videoFailed => 'Не получилось включить';

  @override
  String get storUpdated => 'Только что обновлено';

  @override
  String get storSafeLabel => 'МОЖНО СМЕЛО ОСВОБОДИТЬ';

  @override
  String storOfTotal(String size) {
    return 'из $size, что занимают фото и видео';
  }

  @override
  String get storCutMonths => 'Месяцы';

  @override
  String get storCutTypes => 'Типы';

  @override
  String get storCutSources => 'Источники';

  @override
  String get storLegend => 'сколько тут можно убрать';

  @override
  String storClear(String size) {
    return 'убрать $size';
  }

  @override
  String get storReview => 'Разобрать блок';

  @override
  String get storQuickTitle => 'Быстрая уборка';

  @override
  String get storQuickSub => 'Безопасно, по одной кнопке';

  @override
  String storQuickTotal(String size) {
    return 'всего $size';
  }

  @override
  String get storSafe => 'БЕЗОПАСНО';

  @override
  String get storClean => 'Убрать';

  @override
  String get storEarlier => 'Раньше';

  @override
  String storEarlierSub(String month, String n) {
    return 'до $month · $n файлов';
  }

  @override
  String storMonthSub(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString фото и видео',
      many: '$nString фото и видео',
      few: '$nString фото и видео',
      one: '$nString фото или видео',
    );
    return '$_temp0';
  }

  @override
  String get storTypeVideos => 'Видео';

  @override
  String get storTypePhotos => 'Фото';

  @override
  String get storTypeChat => 'Чаты';

  @override
  String get storTypeShots => 'Скриншоты';

  @override
  String get storTypeRecs => 'Запись экрана';

  @override
  String storSubVideos(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString ролика',
      many: '$nString роликов',
      few: '$nString ролика',
      one: '$nString ролик',
    );
    return '$_temp0';
  }

  @override
  String storSubPhotos(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString фото',
      many: '$nString фото',
      few: '$nString фото',
      one: '$nString фото',
    );
    return '$_temp0';
  }

  @override
  String storSubChat(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString файла из мессенджеров',
      many: '$nString файлов из мессенджеров',
      few: '$nString файла из мессенджеров',
      one: '$nString файл из мессенджеров',
    );
    return '$_temp0';
  }

  @override
  String storSubShots(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString скриншота',
      many: '$nString скриншотов',
      few: '$nString скриншота',
      one: '$nString скриншот',
    );
    return '$_temp0';
  }

  @override
  String storSubRecs(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString записи',
      many: '$nString записей',
      few: '$nString записи',
      one: '$nString запись',
    );
    return '$_temp0';
  }

  @override
  String get storSrcCamera => 'Камера';

  @override
  String get storSrcDownloads => 'Загрузки';

  @override
  String get storSrcOther => 'Другое';

  @override
  String get storSubCamera => 'снято на этот телефон';

  @override
  String get storSubChatSrc => 'присланное и отправленное';

  @override
  String get storSubShotsSrc => 'снимки экрана';

  @override
  String get storSubDownloads => 'скачано из браузера';

  @override
  String get storSubInstagram => 'сохранённые посты и сторис';

  @override
  String get storSubOther => 'всё остальное';

  @override
  String get qwOldShots => 'Старые скриншоты';

  @override
  String get qwOldShotsSub => 'Старше 90 дней, потом не открывали';

  @override
  String get qwBlurry => 'Мутные и тёмные';

  @override
  String get qwBlurrySub => 'Не в фокусе или почти чёрные кадры';

  @override
  String get qwChat => 'Остатки из чатов';

  @override
  String get qwChatSub => 'Мемы и пересылки, они и так есть в чате';

  @override
  String get qwRecs => 'Длинные записи экрана';

  @override
  String get qwRecsSub => 'Дольше минуты, записаны давно';

  @override
  String get qwDups => 'Точные дубли';

  @override
  String get qwDupsSub => 'Одинаковые файлы, старая копия остаётся';

  @override
  String get sessTitle => 'Сессия уборки';

  @override
  String get sessSub =>
      'Короткий заход по старым фото.\nБез спешки, бросай когда хочешь.';

  @override
  String sessDays(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString дня',
      many: '$nString дней',
      few: '$nString дня',
      one: '$nString день',
    );
    return '$_temp0';
  }

  @override
  String sessPhotosAbout(int m) {
    final intl.NumberFormat mNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String mString = mNumberFormat.format(m);

    return 'фото · около $mString мин';
  }

  @override
  String get sessWeek => 'Эта неделя';

  @override
  String sessBest(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'рекорд $nString дня',
      many: 'рекорд $nString дней',
      few: 'рекорд $nString дня',
      one: 'рекорд $nString день',
    );
    return '$_temp0';
  }

  @override
  String get sessFreeze => '1 заморозка';

  @override
  String get sessFreezeSub =>
      'закроет один пропуск, так что занятая неделя серию не сломает';

  @override
  String get sessFreezeUsed => 'Заморозка этой недели уже потрачена';

  @override
  String get sessMonths => 'Разобранные месяцы';

  @override
  String get sessOldestFirst => 'сначала старые';

  @override
  String sessStartsWith(String month) {
    return 'Начнём с месяца $month: сначала похожие, потом остальные';
  }

  @override
  String sessStart(String photos) {
    return 'Поехали · $photos';
  }

  @override
  String get sessNothing => 'Всё разобрано';

  @override
  String get sessEntryNoStreak => 'Начни серию';

  @override
  String get sessEntrySub => 'Короткий заход по старым фото';

  @override
  String sessProgress(int done, int goal) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat goalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String goalString = goalNumberFormat.format(goal);

    return '$doneString / $goalString';
  }

  @override
  String get remTitle => 'Напоминание';

  @override
  String get remSub => 'Пинок в дни, когда ты ещё не разбирал';

  @override
  String get remTime => 'Время';

  @override
  String get remNeedPerm => 'Разреши уведомления, чтобы напоминания приходили';

  @override
  String get remAllow => 'Разрешить';

  @override
  String get remNotifTitle => 'Пора немного прибраться';

  @override
  String get remNotifBody => 'Минутка на фото? Не теряй серию.';

  @override
  String get remChannel => 'Напоминания';

  @override
  String doneSwept(String photos, String time) {
    return 'Разобрано: $photos, за $time';
  }

  @override
  String doneTimeMS(int m, int s) {
    final intl.NumberFormat mNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String mString = mNumberFormat.format(m);
    final intl.NumberFormat sNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sString = sNumberFormat.format(s);

    return '$mString мин $sString с';
  }

  @override
  String doneTimeS(int s) {
    final intl.NumberFormat sNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sString = sNumberFormat.format(s);

    return '$sString с';
  }

  @override
  String get doneInTrash => 'В КОРЗИНЕ';

  @override
  String doneInTrashSub(String unit, String files) {
    return '$unit · $files';
  }

  @override
  String get doneKept => 'ОСТАВЛЕНО';

  @override
  String get donePhotosStay => 'фото остаются';

  @override
  String doneStreak(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Серия $nString дн.';
  }

  @override
  String doneStreakUp(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'на день больше, чем вчера · рекорд $bestString';
  }

  @override
  String doneStreakNew(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'новое начало · рекорд $bestString';
  }

  @override
  String doneStreakSame(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'сегодня уже засчитано · рекорд $bestString';
  }

  @override
  String doneMonthProgress(int from, int to) {
    final intl.NumberFormat fromNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String toString = toNumberFormat.format(to);

    return 'с $fromString% до $toString%';
  }

  @override
  String doneLeft(String photos, String month) {
    return 'В месяце $month осталось: $photos. ';
  }

  @override
  String doneMoreSessions(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ещё примерно $nString таких захода, и месяц готов',
      many: 'Ещё примерно $nString таких заходов, и месяц готов',
      few: 'Ещё примерно $nString таких захода, и месяц готов',
      one: 'Ещё примерно $nString такой заход, и месяц готов',
    );
    return '$_temp0';
  }

  @override
  String doneMonthDone(String month) {
    return '$month разобран целиком!';
  }

  @override
  String get doneNote =>
      'Фото лежат в корзине Sweeep 30 дней. С телефона ничего не уйдёт, пока не очистишь корзину.';

  @override
  String get doneDone => 'Готово';

  @override
  String doneAnother(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Ещё $nString';
  }

  @override
  String get limTitle => 'Sweeep видит только выбранные фото';

  @override
  String get limSub => 'Разреши всё, чтобы чистить всю галерею.';

  @override
  String get limAllow => 'Разрешить всё';

  @override
  String get wrapLabel => 'ИТОГИ МЕСЯЦА';

  @override
  String get wrapSwept => '100% РАЗОБРАНО';

  @override
  String wrapLooked(String photos) {
    return 'просмотрено: $photos';
  }

  @override
  String wrapCleared(String unit) {
    return '$unit убрано';
  }

  @override
  String get wrapBest => 'ЛУЧШЕЕ ЗА МЕСЯЦ';

  @override
  String get wrapKept => 'оставлено';

  @override
  String get wrapTrashed => 'убрано';

  @override
  String wrapSessions(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'сессии',
      many: 'сессий',
      few: 'сессии',
      one: 'сессия',
    );
    return '$_temp0';
  }

  @override
  String get wrapStreak => 'серия';

  @override
  String get wrapNote =>
      'Картинка делается на телефоне. Ничего не уходит в сеть, пока ты сам не поделишься.';

  @override
  String get wrapSave => 'Сохранить';

  @override
  String wrapNext(String month) {
    return 'Дальше: $month';
  }

  @override
  String get wrapSaved => 'Сохранено в Pictures/Sweeep';

  @override
  String get wrapSaveFailed => 'Не получилось сохранить';

  @override
  String get goalLabel => 'МНЕ НУЖНО';

  @override
  String get goalSub =>
      'Sweeep берёт самое надёжное и останавливается, когда хватит.';

  @override
  String goalPicked(String size) {
    return 'выбрано: $size';
  }

  @override
  String get goalReached => 'цель набрана';

  @override
  String goalAllFound(String size) {
    return 'это всё, что нашли: $size';
  }

  @override
  String get goalWhatFirst => 'Что уйдёт первым';

  @override
  String get goalSafestTop => 'сверху самое надёжное';

  @override
  String get goalNote =>
      'Сначала ты проверишь список. Файлы уйдут в корзину Sweeep на 30 дней.';

  @override
  String goalReview(String size) {
    return 'Проверить список · $size';
  }

  @override
  String get goalReviewTitle => 'Проверь список';

  @override
  String get goalSubDup => 'Одинаковые файлы';

  @override
  String get goalSubOldShots => 'Старше 90 дней';

  @override
  String get goalSubBlurry => 'Глянь первые несколько';

  @override
  String get goalSubChat => 'Уже есть в чате';

  @override
  String get goalSubRecs => 'Дольше минуты, давно записаны';

  @override
  String get goalSubSimilar => 'Лучшая остаётся, решаешь ты';

  @override
  String get goalEntryTitle => 'Мне нужно место';

  @override
  String get goalEntrySub => 'Задай цель, Sweeep найдёт самое надёжное';

  @override
  String get toolsWater => 'Вода';

  @override
  String get toolsDust => 'Пыль';

  @override
  String get toolsSound => 'Звук';

  @override
  String get toolsSweepStatus => 'Свип · от 20 Гц до 20 кГц';

  @override
  String get toolsLeftOnly => 'Только левый динамик';

  @override
  String get toolsRightOnly => 'Только правый динамик';

  @override
  String get toolsSteady => 'Ровный тон';

  @override
  String toolsPulsing(String tail) {
    return 'Пульсирующий тон · $tail';
  }

  @override
  String toolsTimeLeft(String time) {
    return 'ещё $time';
  }

  @override
  String get toolsFrequency => 'Частота';

  @override
  String get toolsEject => 'Выгнать воду';

  @override
  String get toolsShake => 'Вытряхнуть пыль';

  @override
  String get toolsPlay => 'Включить тон';

  @override
  String get toolsStop => 'Стоп';

  @override
  String get toolsBoth => 'Оба';

  @override
  String get toolsLeft => 'Левый';

  @override
  String get toolsRight => 'Правый';

  @override
  String get toolsBass => 'Бас 60 Гц';

  @override
  String get toolsTreble => 'Верха 8 кГц';

  @override
  String get toolsSweep => 'Свип';

  @override
  String get toolsWarning =>
      'Начни с тихого звука и держи телефон подальше от уха. Результат не гарантируем.';
}
