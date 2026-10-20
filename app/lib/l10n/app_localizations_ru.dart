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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n файла',
      many: '$n файлов',
      few: '$n файла',
      one: '$n файл',
    );
    return '$_temp0';
  }

  @override
  String photosCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n фото',
      many: '$n фото',
      few: '$n фото',
      one: '$n фото',
    );
    return '$_temp0';
  }

  @override
  String groupsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n группы',
      many: '$n групп',
      few: '$n группы',
      one: '$n группа',
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
    return 'Дубликаты: $count фото, экономия $size';
  }

  @override
  String semGroupSim(int count, String size) {
    return 'Похожие: $count фото, экономия $size';
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
    return '$i из $n';
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
    return 'Выбрано: $n · $size · можно вернуть, пока не очистишь';
  }

  @override
  String restoreN(int n) {
    return 'Вернуть: $n';
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
    return '$n дн.';
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
    return 'Выбрано: $n · $size · можно вернуть из корзины';
  }

  @override
  String moveNToTrash(int n) {
    return 'В корзину: $n';
  }

  @override
  String groupsSummary(String groups, String size) {
    return '$groups · можно убрать $size';
  }

  @override
  String groupsInTrash(int count, String size) {
    return ' · в корзине $count ($size)';
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
    return '$kind: $count файлов, $state';
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
    return 'Группа $i из $n';
  }

  @override
  String get pagerNothing => 'Нечего разбирать.';

  @override
  String get tipAllGroups => 'Все группы';

  @override
  String get pagerKeepAll => 'Оставить все · дальше';

  @override
  String pagerTrashN(int n, String size) {
    return 'В корзину: $n · $size';
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
    return 'Удалить все $n · $size';
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
