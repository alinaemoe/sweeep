// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navClean => 'Clean';

  @override
  String get navSwipe => 'Swipe';

  @override
  String get navTools => 'Tools';

  @override
  String get navTrash => 'Trash';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get undo => 'Undo';

  @override
  String get selectAll => 'Select all';

  @override
  String get clear => 'Clear';

  @override
  String get seeAll => 'See all';

  @override
  String get actionSwipe => 'Swipe';

  @override
  String get skip => 'Skip';

  @override
  String filesCount(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString files',
      one: '1 file',
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
      other: '$nString photos',
      one: '1 photo',
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
      other: '$nString groups',
      one: '1 group',
    );
    return '$_temp0';
  }

  @override
  String get byteUnits => 'B,KB,MB,GB,TB';

  @override
  String hz(String n) {
    return '$n Hz';
  }

  @override
  String get unitHz => 'Hz';

  @override
  String khz(String n) {
    return '$n kHz';
  }

  @override
  String get onbTitle => 'Your photos\nnever leave\nyour phone.';

  @override
  String get onbPoint1 => 'Everything is analyzed on this device.';

  @override
  String get onbPoint2 => 'No uploads, no accounts, no ads.';

  @override
  String get onbPoint3 => 'Nothing is deleted until you confirm.';

  @override
  String get onbDenied =>
      'Access is off. Allow photos and videos for Sweeep in Settings › Apps › Sweeep › Permissions, then come back.';

  @override
  String get onbCheckAgain => 'Check again';

  @override
  String get onbAllow => 'Allow photo access';

  @override
  String get secDuplicates => 'Duplicates';

  @override
  String get secSimilar => 'Similar photos';

  @override
  String get secScreenshots => 'Screenshots';

  @override
  String get secVideos => 'Videos';

  @override
  String get secChat => 'Chat media';

  @override
  String get secBlurry => 'Blurry & dark';

  @override
  String get srcAll => 'All photos';

  @override
  String get tagBlurry => 'blurry';

  @override
  String get tagDark => 'dark';

  @override
  String get scanReading => 'READING LIBRARY';

  @override
  String scanAnalyzing(String done, String total) {
    return 'ANALYZING $done OF $total';
  }

  @override
  String get scanComparing => 'COMPARING FILES';

  @override
  String get homeNothing =>
      'Nothing to clean yet. Pull in more photos or re-scan later.';

  @override
  String ovalReclaimableOf(String size) {
    return 'RECLAIMABLE OF $size';
  }

  @override
  String get ovalScanning => 'SCANNING';

  @override
  String get ovalReclaimable => 'RECLAIMABLE';

  @override
  String get ctaScanning => 'Scanning…';

  @override
  String get ctaAllClean => 'All clean';

  @override
  String ctaFreeUp(String size) {
    return 'Free up $size';
  }

  @override
  String get tipLibraryDetails => 'Library details';

  @override
  String semGroupDup(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Duplicate group, $countString photos, saves $size';
  }

  @override
  String semGroupSim(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Similar group, $countString photos, saves $size';
  }

  @override
  String semVideo(String size) {
    return 'Video, $size';
  }

  @override
  String semVideoLen(String length, String size) {
    return 'Video, $length, $size';
  }

  @override
  String semPhoto(String size) {
    return 'Photo, $size';
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

    return '$iString of $nString';
  }

  @override
  String get tipTrash => 'Move to trash';

  @override
  String get tipKeep => 'Keep';

  @override
  String get stampLater => 'LATER';

  @override
  String get stampTrash => 'TO TRASH';

  @override
  String get stampKeep => 'KEEP';

  @override
  String swipeInTrash(String files) {
    return 'In trash: $files ';
  }

  @override
  String get swipeDoneNothing => 'Nothing to review';

  @override
  String get swipeDoneAll => 'All reviewed';

  @override
  String get swipeDoneHint => 'You can restore anything from the trash.';

  @override
  String get hintTitle => 'Swipe to sort';

  @override
  String get hintTrash => 'Trash';

  @override
  String get hintKeep => 'Keep';

  @override
  String get hintLater => 'Later';

  @override
  String get hintTap => 'Tap anywhere to start';

  @override
  String get tlNewestFirst => 'Newest first';

  @override
  String get tlOldestFirst => 'Oldest first';

  @override
  String get tlHeadline => 'Swipe through\nevery month';

  @override
  String tlSummary(String photos, String swept) {
    return '$photos · $swept swept so far';
  }

  @override
  String get tlNoPhotos => 'No photos yet.';

  @override
  String tlContinueMonth(String month) {
    return 'Continue · $month';
  }

  @override
  String tlMonthLine(String photos, String status) {
    return '$photos · $status';
  }

  @override
  String get tlAllSwept => 'all swept';

  @override
  String tlNSwept(String n) {
    return '$n swept';
  }

  @override
  String get tlNotStarted => 'not started';

  @override
  String get tlDone => 'Done';

  @override
  String get tlContinue => 'Continue';

  @override
  String get tlMore => 'more';

  @override
  String tlSemMore(String n) {
    return '$n more photos';
  }

  @override
  String tlSemPhotoFrom(String date) {
    return 'Photo from $date';
  }

  @override
  String tlSemReview(String month) {
    return 'Review again $month';
  }

  @override
  String tlSemContinue(String month) {
    return 'Continue $month';
  }

  @override
  String tlSemSwipe(String month) {
    return 'Swipe $month';
  }

  @override
  String get tlSemSort => 'Newest first. Tap to show oldest first';

  @override
  String get tlSemSortOld => 'Oldest first. Tap to show newest first';

  @override
  String get trashNothingDeleted => 'Nothing was deleted.';

  @override
  String get trashDeleteTitle => 'Delete everything?';

  @override
  String trashDeleteBody(String files, String size) {
    return '$files ($size) will be deleted from your phone. Android may ask once more.';
  }

  @override
  String get deleteAll => 'Delete all';

  @override
  String get emptyAll => 'Empty all';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String trashWillFree(String files, String size) {
    return '$files · $size will be freed';
  }

  @override
  String get trashLandHere => 'Swiped-away photos land here.';

  @override
  String trashSelected(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$nString selected · $size · recoverable until you empty';
  }

  @override
  String restoreN(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Restore $nString';
  }

  @override
  String get deleteForever => 'Delete forever';

  @override
  String freedTitle(String size) {
    return '$size freed';
  }

  @override
  String freedSub(String files) {
    return '$files deleted';
  }

  @override
  String get daysToday => 'today';

  @override
  String daysLeft(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '${nString}d';
  }

  @override
  String movedToTrash(String files) {
    return '$files moved to trash';
  }

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortLargest => 'Largest';

  @override
  String get allApps => 'All apps';

  @override
  String get nothingHere => 'Nothing here.';

  @override
  String catSelected(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$nString selected · $size · recoverable from the trash';
  }

  @override
  String moveNToTrash(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Move $nString to trash';
  }

  @override
  String groupsSummary(String groups, String size) {
    return '$groups · $size to free';
  }

  @override
  String groupsInTrash(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return ' · $countString in trash ($size)';
  }

  @override
  String get sortSaving => 'Biggest';

  @override
  String get sortCopies => 'Copies';

  @override
  String get nothingLeft => 'Nothing left here.';

  @override
  String groupsSelectedBar(String groups) {
    return '$groups selected · best photo of each is kept';
  }

  @override
  String cleanGroups(String groups, String size) {
    return 'Clean $groups · save $size';
  }

  @override
  String groupSemantics(String kind, int count, String state) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$kind group, $countString files, $state';
  }

  @override
  String get stateSelected => 'selected';

  @override
  String get stateNotSelected => 'not selected';

  @override
  String semSort(String label) {
    return 'Sort: $label';
  }

  @override
  String groupSave(String size) {
    return 'save $size';
  }

  @override
  String pagerGroupOf(int i, int n) {
    final intl.NumberFormat iNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String iString = iNumberFormat.format(i);
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Group $iString of $nString';
  }

  @override
  String get pagerNothing => 'Nothing to review.';

  @override
  String get tipAllGroups => 'All groups';

  @override
  String get pagerKeepAll => 'Keep all · next';

  @override
  String pagerTrashN(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Trash $nString · save $size';
  }

  @override
  String get whyOldest => 'Oldest copy';

  @override
  String get whySharpest => 'Sharpest';

  @override
  String get pillBestPick => 'BEST PICK';

  @override
  String get pillBest => 'BEST';

  @override
  String get pillKeep => 'KEEP';

  @override
  String get pillTrash => 'TRASH';

  @override
  String get semKeptCopy => 'Keep this copy. Tap to trash it';

  @override
  String get semTrashCopy => 'Trash this copy. Tap to keep it';

  @override
  String get pagerTip =>
      'Tap to compare · hold to flip KEEP/TRASH · pull down to trash all';

  @override
  String pagerTrashAllN(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Trash all $nString · save $size';
  }

  @override
  String get stampTrashAll => 'TRASH ALL';

  @override
  String get secScreenRecordings => 'Screen recordings';

  @override
  String get notifTitle => 'Sweeep is scanning';

  @override
  String get notifChannel => 'Library scan';

  @override
  String get notifStart => 'Scanning your library';

  @override
  String notifHashing(String done, String total) {
    return 'Hashing photos · $done of $total';
  }

  @override
  String notifChecking(String done, String total) {
    return 'Checking duplicates · $done of $total';
  }

  @override
  String scanOfFiles(String done, String total) {
    return '$done OF $total FILES';
  }

  @override
  String get scanStepRead => 'Reading library';

  @override
  String get scanStepFinger => 'Fingerprinting photos';

  @override
  String get scanStepCompare => 'Comparing similar shots';

  @override
  String get scanStepGroup => 'Grouping & ranking';

  @override
  String get scanStatusDone => 'done';

  @override
  String get scanStatusNext => 'next';

  @override
  String get scanCountGroups => 'groups';

  @override
  String get scanCountShots => 'screenshots';

  @override
  String get scanCountFound => 'found so far';

  @override
  String get scanPrivacy => 'Analyzed on this device. Nothing is uploaded.';

  @override
  String get scanPausedNote => 'Paused. Progress is saved.';

  @override
  String get scanPause => 'Pause scan';

  @override
  String get scanResume => 'Resume scan';

  @override
  String get scanLater => 'Later';

  @override
  String get modeGrid => 'Grid';

  @override
  String get modeSwipe => 'Swipe';

  @override
  String get modeMonths => 'Months';

  @override
  String groupsMonthLine(String groups, String size) {
    return '$groups · save $size';
  }

  @override
  String get videoPlay => 'Play video';

  @override
  String get videoPause => 'Pause video';

  @override
  String get videoFailed => 'Can\'t play this video';

  @override
  String get storUpdated => 'Updated just now';

  @override
  String get storSafeLabel => 'YOU CAN SAFELY FREE';

  @override
  String storOfTotal(String size) {
    return 'of $size your photos and videos take up';
  }

  @override
  String get storCutMonths => 'Months';

  @override
  String get storCutTypes => 'Types';

  @override
  String get storCutSources => 'Sources';

  @override
  String get storLegend => 'the part you can clear in this block';

  @override
  String storClear(String size) {
    return 'clear $size';
  }

  @override
  String get storReview => 'Review this block';

  @override
  String get storQuickTitle => 'Quick wins';

  @override
  String get storQuickSub => 'Safe to clear, one tap each';

  @override
  String storQuickTotal(String size) {
    return '$size total';
  }

  @override
  String get storSafe => 'SAFE';

  @override
  String get storClean => 'Clean';

  @override
  String get storEarlier => 'Earlier';

  @override
  String storEarlierSub(String month, String n) {
    return 'before $month · $n files';
  }

  @override
  String storMonthSub(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString photos and videos',
      one: '1 photo or video',
    );
    return '$_temp0';
  }

  @override
  String get storTypeVideos => 'Videos';

  @override
  String get storTypePhotos => 'Photos';

  @override
  String get storTypeChat => 'Chat media';

  @override
  String get storTypeShots => 'Screenshots';

  @override
  String get storTypeRecs => 'Screen rec.';

  @override
  String storSubVideos(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString clips',
      one: '1 clip',
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
      other: '$nString photos',
      one: '1 photo',
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
      other: '$nString files from messengers',
      one: '1 file from messengers',
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
      other: '$nString screenshots',
      one: '1 screenshot',
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
      other: '$nString recordings',
      one: '1 recording',
    );
    return '$_temp0';
  }

  @override
  String get storSrcCamera => 'Camera';

  @override
  String get storSrcDownloads => 'Downloads';

  @override
  String get storSrcOther => 'Other';

  @override
  String get storSubCamera => 'taken on this phone';

  @override
  String get storSubChatSrc => 'received and sent media';

  @override
  String get storSubShotsSrc => 'screen captures';

  @override
  String get storSubDownloads => 'saved from the browser';

  @override
  String get storSubInstagram => 'saved posts and stories';

  @override
  String get storSubOther => 'everything else';

  @override
  String get qwOldShots => 'Old screenshots';

  @override
  String get qwOldShotsSub => 'Older than 90 days, never opened since';

  @override
  String get qwBlurry => 'Blurry and dark';

  @override
  String get qwBlurrySub => 'Out of focus or nearly black frames';

  @override
  String get qwChat => 'Chat leftovers';

  @override
  String get qwChatSub => 'Memes and forwards you already have in a chat';

  @override
  String get qwRecs => 'Long screen recordings';

  @override
  String get qwRecsSub => 'Over a minute, saved months ago';

  @override
  String get qwDups => 'Exact duplicates';

  @override
  String get qwDupsSub => 'Identical files, the oldest copy stays';

  @override
  String get toolsWater => 'Water';

  @override
  String get toolsDust => 'Dust';

  @override
  String get toolsSound => 'Sound test';

  @override
  String get toolsSweepStatus => 'Sweep · 20 Hz to 20 kHz';

  @override
  String get toolsLeftOnly => 'Left speaker only';

  @override
  String get toolsRightOnly => 'Right speaker only';

  @override
  String get toolsSteady => 'Steady tone';

  @override
  String toolsPulsing(String tail) {
    return 'Pulsing tone · $tail';
  }

  @override
  String toolsTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get toolsFrequency => 'Frequency';

  @override
  String get toolsEject => 'Eject water';

  @override
  String get toolsShake => 'Shake out dust';

  @override
  String get toolsPlay => 'Play tone';

  @override
  String get toolsStop => 'Stop';

  @override
  String get toolsBoth => 'Both';

  @override
  String get toolsLeft => 'Left';

  @override
  String get toolsRight => 'Right';

  @override
  String get toolsBass => 'Bass 60 Hz';

  @override
  String get toolsTreble => 'Treble 8 kHz';

  @override
  String get toolsSweep => 'Sweep';

  @override
  String get toolsWarning =>
      'Start at low volume and keep the phone away from your ear. Results aren\'t guaranteed.';
}
