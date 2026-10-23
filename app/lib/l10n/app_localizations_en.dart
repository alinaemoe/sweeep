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
  String get sessTitle => 'Cleanup Session';

  @override
  String get sessSub =>
      'A short run through your oldest photos.\nNo pressure, stop any time.';

  @override
  String sessDays(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String sessPhotosAbout(int m) {
    final intl.NumberFormat mNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String mString = mNumberFormat.format(m);

    return 'photos · about $mString min';
  }

  @override
  String get sessWeek => 'This week';

  @override
  String sessBest(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'best streak $nString days',
      one: 'best streak 1 day',
    );
    return '$_temp0';
  }

  @override
  String get sessFreeze => '1 freeze';

  @override
  String get sessFreezeSub =>
      'covers one missed day, so a busy week does not break the streak';

  @override
  String get sessFreezeUsed => 'This week\'s freeze is already used';

  @override
  String get sessMonths => 'Months swept';

  @override
  String get sessOldestFirst => 'oldest first';

  @override
  String sessStartsWith(String month) {
    return 'Starts with $month · lookalikes first, then the rest';
  }

  @override
  String sessStart(String photos) {
    return 'Start · $photos';
  }

  @override
  String get sessNothing => 'Everything is swept';

  @override
  String get sessEntryNoStreak => 'Start your streak';

  @override
  String get sessEntrySub => 'A short run through your oldest photos';

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
  String get remTitle => 'Daily reminder';

  @override
  String get remSub => 'A nudge on days you have not swept yet';

  @override
  String get remTime => 'Time';

  @override
  String get remNeedPerm => 'Allow notifications to get reminders';

  @override
  String get remAllow => 'Allow';

  @override
  String get remNotifTitle => 'Time for a quick sweep';

  @override
  String get remNotifBody => 'A minute for your photos? Keep the streak going.';

  @override
  String get remChannel => 'Reminders';

  @override
  String doneSwept(String photos, String time) {
    return '$photos swept in $time';
  }

  @override
  String doneTimeMS(int m, int s) {
    final intl.NumberFormat mNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String mString = mNumberFormat.format(m);
    final intl.NumberFormat sNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sString = sNumberFormat.format(s);

    return '$mString min $sString s';
  }

  @override
  String doneTimeS(int s) {
    final intl.NumberFormat sNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sString = sNumberFormat.format(s);

    return '$sString s';
  }

  @override
  String get doneInTrash => 'IN TRASH';

  @override
  String doneInTrashSub(String unit, String files) {
    return '$unit · $files';
  }

  @override
  String get doneKept => 'KEPT';

  @override
  String get donePhotosStay => 'photos stay';

  @override
  String doneStreak(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$nString day streak';
  }

  @override
  String doneStreakUp(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'one more than yesterday · best is $bestString';
  }

  @override
  String doneStreakNew(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'a fresh start · best is $bestString';
  }

  @override
  String doneStreakSame(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'already counted today · best is $bestString';
  }

  @override
  String doneMonthProgress(int from, int to) {
    final intl.NumberFormat fromNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String toString = toNumberFormat.format(to);

    return '$fromString% to $toString%';
  }

  @override
  String doneLeft(String photos, String month) {
    return '$photos left in $month. ';
  }

  @override
  String doneMoreSessions(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'About $nString more sessions and it is done',
      one: 'About 1 more session and it is done',
    );
    return '$_temp0';
  }

  @override
  String doneMonthDone(String month) {
    return '$month is fully swept!';
  }

  @override
  String get doneNote =>
      'Photos are in the Sweeep trash for 30 days. Nothing leaves your phone until you empty it.';

  @override
  String get doneDone => 'Done';

  @override
  String doneAnother(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Another $nString';
  }

  @override
  String get limTitle => 'Sweeep only sees the photos you picked';

  @override
  String get limSub => 'Allow all to clean your whole library.';

  @override
  String get limAllow => 'Allow all';

  @override
  String get wrapLabel => 'MONTH WRAP';

  @override
  String get wrapSwept => '100% SWEPT';

  @override
  String wrapLooked(String photos) {
    return '$photos looked through';
  }

  @override
  String wrapCleared(String unit) {
    return '$unit cleared';
  }

  @override
  String get wrapBest => 'YOUR BEST OF THE MONTH';

  @override
  String get wrapKept => 'kept';

  @override
  String get wrapTrashed => 'cleared';

  @override
  String wrapSessions(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'sessions',
      one: 'session',
    );
    return '$_temp0';
  }

  @override
  String get wrapStreak => 'streak';

  @override
  String get wrapNote =>
      'The image is made on your phone. Nothing is uploaded unless you choose to share it.';

  @override
  String get wrapSave => 'Save image';

  @override
  String wrapNext(String month) {
    return 'Next: $month';
  }

  @override
  String get wrapSaved => 'Saved to Pictures/Sweeep';

  @override
  String get wrapSaveFailed => 'Could not save the image';

  @override
  String get goalLabel => 'I NEED';

  @override
  String get goalSub =>
      'Sweeep picks the safest files first and stops when you have enough.';

  @override
  String goalPicked(String size) {
    return '$size picked';
  }

  @override
  String get goalReached => 'goal reached';

  @override
  String goalAllFound(String size) {
    return 'all we found, $size';
  }

  @override
  String get goalWhatFirst => 'What goes first';

  @override
  String get goalSafestTop => 'safest on top';

  @override
  String get goalNote =>
      'You confirm the list first. Files go to the Sweeep trash for 30 days.';

  @override
  String goalReview(String size) {
    return 'Review list · $size';
  }

  @override
  String get goalReviewTitle => 'Review the list';

  @override
  String get goalSubDup => 'Identical files';

  @override
  String get goalSubOldShots => 'Older than 90 days';

  @override
  String get goalSubBlurry => 'Check the first few';

  @override
  String get goalSubChat => 'Already in a chat';

  @override
  String get goalSubRecs => 'Over a minute, months old';

  @override
  String get goalSubSimilar => 'Best one stays, you decide';

  @override
  String get goalEntryTitle => 'I need space';

  @override
  String get goalEntrySub => 'Pick a goal, Sweeep finds the safest files';

  @override
  String get navSpace => 'Space';

  @override
  String get tipHub => 'Hub';

  @override
  String get hubTitle => 'Hub';

  @override
  String get hubVersion => 'Sweeep 1.0';

  @override
  String get proTag => 'SWEEEP PRO';

  @override
  String get proTitle => 'Every cleaner, no limits';

  @override
  String get proSub => 'Unlimited sessions, Quick wins and Shrink videos.';

  @override
  String get proButton => 'See plans';

  @override
  String get proSoon => 'Plans are coming soon';

  @override
  String get hubMore => 'MORE CLEANERS';

  @override
  String get cleanerEmail => 'Email';

  @override
  String get cleanerEmailSub => 'Newsletters and junk';

  @override
  String get cleanerApps => 'Apps';

  @override
  String get cleanerAppsSub => 'Unused and heavy';

  @override
  String get cleanerCache => 'Cache';

  @override
  String get cleanerCacheSub => 'Temporary files';

  @override
  String get soonBadge => 'SOON';

  @override
  String get soonWord => 'Soon';

  @override
  String get hubTools => 'TOOLS';

  @override
  String get hubWater => 'Eject water';

  @override
  String get hubWaterSub => 'Speaker tone, 165 to 200 Hz';

  @override
  String get hubDust => 'Clean dust';

  @override
  String get hubDustSub => 'Low pulsing tone for the grille';

  @override
  String get hubSound => 'Sound test';

  @override
  String get hubSoundSub => 'Left, right and sweep';

  @override
  String get hubInsights => 'INSIGHTS';

  @override
  String get hubWeek => 'Your week';

  @override
  String get hubWeekSub => 'Cleared space and streak';

  @override
  String get hubWidgets => 'Home screen widgets';

  @override
  String get hubWidgetsSub => 'Streak and daily goal';

  @override
  String get hubSettings => 'SETTINGS';

  @override
  String get hubLanguage => 'Language';

  @override
  String get langAuto => 'Auto';

  @override
  String hubRemindOn(String time) {
    return 'Every day at $time';
  }

  @override
  String get hubRemindOff => 'Off';

  @override
  String get hubAccess => 'Photo access';

  @override
  String get hubAccessAll => 'All photos and videos';

  @override
  String get hubAccessLimited => 'Selected photos only';

  @override
  String get hubAccessNone => 'No access';

  @override
  String get hubScan => 'Scan again';

  @override
  String hubScanSub(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString files indexed',
      one: '1 file indexed',
    );
    return '$_temp0';
  }

  @override
  String get hubFoot1 =>
      'Everything is analysed on this phone. Nothing is uploaded.';

  @override
  String get hubFoot2 => 'Hold the version number for the developer screen.';

  @override
  String get spaceTitle => 'Space';

  @override
  String spaceCanGo(String unit) {
    return '$unit can go';
  }

  @override
  String spaceFind(String size) {
    return 'Find $size of safest files';
  }

  @override
  String get spaceMap => 'Storage map';

  @override
  String get spaceOpen => 'Open';

  @override
  String get spaceShrink => 'Shrink videos';

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

  @override
  String get appsTitle => 'App cleaner';

  @override
  String appsHeader(String count, String size) {
    return '$count · $size';
  }

  @override
  String appsCount(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get appsUnusedLabel => 'NOT OPENED IN 60+ DAYS';

  @override
  String get appsAllLabel => 'ALL YOUR APPS';

  @override
  String appsUnusedIn(int n, String unit) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$unit in $nString apps',
      one: '$unit in 1 app',
    );
    return '$_temp0';
  }

  @override
  String appsOfTotal(String size) {
    return 'of $size all apps use. Sizes include app data.';
  }

  @override
  String appsOfTotalApk(String size) {
    return 'of $size all apps use. App files only, no data.';
  }

  @override
  String get appsSortSize => 'Biggest';

  @override
  String get appsSortUnused => 'Unused';

  @override
  String get appsSortRecent => 'Recent';

  @override
  String appsAgeDays(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Not opened for $nString days',
      one: 'Not opened for 1 day',
    );
    return '$_temp0';
  }

  @override
  String get appsOpenedToday => 'Opened today';

  @override
  String get appsNeverOpened => 'Not opened yet';

  @override
  String get appsOpenedYesterday => 'Opened yesterday';

  @override
  String get appsUninstallNote => 'Android asks you to confirm each uninstall.';

  @override
  String appsUninstall(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Uninstall $nString · free $size';
  }

  @override
  String get appsEmpty => 'No apps to show';

  @override
  String get appsNoAccess =>
      'Sizes only. Allow usage access to see which apps sit unused.';

  @override
  String get appsAllowAccess => 'Show unused apps';

  @override
  String appsUninstallFail(String name) {
    return 'Could not remove $name';
  }

  @override
  String get usageTitle => 'See which apps you forgot';

  @override
  String get usageSub =>
      'To tell used apps from forgotten ones, Android needs your OK once.';

  @override
  String get usageDoneTitle => 'All set';

  @override
  String get usageDoneSub =>
      'Sweeep can now tell which apps sit unused. Nothing leaves your phone.';

  @override
  String get usageReadLabel => 'WE READ';

  @override
  String get usageReadText =>
      'The date each app was last opened and how much space it uses.';

  @override
  String get usageNeverLabel => 'WE NEVER';

  @override
  String get usageNeverText =>
      'See what you do inside an app, send anything off the phone, or remove an app without your tap.';

  @override
  String get usageCanLabel => 'YOU CAN';

  @override
  String get usageCanText =>
      'Switch it off any time in Android settings. Sizes still work without it.';

  @override
  String get usageOpen => 'Open Android settings';

  @override
  String get usageSee => 'See my apps';

  @override
  String get usageSkip => 'Skip, show sizes only';

  @override
  String get weekLabelNow => 'YOUR WEEK';

  @override
  String get weekLabelPast => 'WEEK REVIEW';

  @override
  String get weekPrev => 'Previous week';

  @override
  String get weekNext => 'Next week';

  @override
  String weekRange(String a, String b) {
    return '$a – $b';
  }

  @override
  String weekCleared(String unit) {
    return '$unit cleared';
  }

  @override
  String weekMore(int pct) {
    final intl.NumberFormat pctNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pctString = pctNumberFormat.format(pct);

    return '$pctString% more than the week before';
  }

  @override
  String weekLess(int pct) {
    final intl.NumberFormat pctNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pctString = pctNumberFormat.format(pct);

    return '$pctString% less than the week before';
  }

  @override
  String get weekSame => 'Same as the week before';

  @override
  String get weekFirst => 'First week on record';

  @override
  String get weekNothingBefore => 'Nothing cleared the week before';

  @override
  String get weekChartTitle => 'Photos swept per day';

  @override
  String weekGoal(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'goal $nString';
  }

  @override
  String weekPhotosSwept(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString photos swept',
      one: '1 photo swept',
    );
    return '$_temp0';
  }

  @override
  String weekSessions(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String weekDaySub(String a, String b) {
    return '$a · $b';
  }

  @override
  String get weekNoSession => 'No session this day';

  @override
  String get weekClearedWord => 'cleared';

  @override
  String weekStreak(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String weekGoalsHit(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$nString of 7 days reached the goal';
  }

  @override
  String get weekSwept => 'SWEPT';

  @override
  String get weekKept => 'KEPT';

  @override
  String get weekClearedCaps => 'CLEARED';

  @override
  String get weekWhatWent => 'What went';

  @override
  String get catDuplicates => 'Duplicates';

  @override
  String get catSimilar => 'Similar photos';

  @override
  String get catScreenshots => 'Screenshots';

  @override
  String get catBlurry => 'Blurry and dark';

  @override
  String get catOther => 'Other';

  @override
  String get weekStorage => 'Phone storage';

  @override
  String weekStorageFromTo(int a, int b) {
    final intl.NumberFormat aNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String aString = aNumberFormat.format(a);
    final intl.NumberFormat bNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bString = bNumberFormat.format(b);

    return '$aString% to $bString%';
  }

  @override
  String weekStorageNow(int p) {
    final intl.NumberFormat pNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pString = pNumberFormat.format(p);

    return '$pString% used';
  }

  @override
  String weekStorageNote(String size) {
    return 'Space is only freed after you empty the Sweeep trash. $size is waiting there now.';
  }

  @override
  String weekHubSub(String size, String streak) {
    return '$size cleared, $streak';
  }

  @override
  String weekSpaceSub(String size) {
    return '$size cleared this week';
  }

  @override
  String weekSpaceSubMore(String size, int pct) {
    final intl.NumberFormat pctNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pctString = pctNumberFormat.format(pct);

    return '$size cleared, $pctString% more than last week';
  }

  @override
  String wOfToday(int goal) {
    final intl.NumberFormat goalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String goalString = goalNumberFormat.format(goal);

    return '/ $goalString today';
  }

  @override
  String wLeftStreak(int left, int n) {
    final intl.NumberFormat leftNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String leftString = leftNumberFormat.format(left);
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$leftString left for a $nString-day streak';
  }

  @override
  String get wGoalReached => 'Goal reached today';

  @override
  String get wStreakNone => 'No streak yet';

  @override
  String get wContinue => 'Continue';

  @override
  String wSwipeNow(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Swipe $nString now';
  }

  @override
  String wAbout(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'about $nString min';
  }

  @override
  String get wCanFree => 'CAN FREE';

  @override
  String get wTapMap => 'Tap to open the storage map';

  @override
  String get wEmpty => 'Open Sweeep to start';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsNote =>
      'Widgets read numbers from the on-device database and open the app on tap. They show only counts, never photos, so nothing private sits on the home screen.';

  @override
  String get widgetToday => 'WIDGET 4×2 · TODAY';

  @override
  String get widgetOneMin => 'WIDGET 2×2 · ONE MINUTE';

  @override
  String get widgetCanFree => 'WIDGET 2×2 · CAN FREE';

  @override
  String get widgetAdd => 'Add to home screen';

  @override
  String get widgetAdded => 'Added';

  @override
  String get widgetHowTo => 'Long-press the home screen, Widgets, Sweeep';

  @override
  String wLeftGoal(int left) {
    final intl.NumberFormat leftNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String leftString = leftNumberFormat.format(left);

    return '$leftString left for today\'s goal';
  }
}
