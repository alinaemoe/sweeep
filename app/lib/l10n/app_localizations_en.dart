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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String photosCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String groupsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n groups',
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
    return 'Duplicate group, $count photos, saves $size';
  }

  @override
  String semGroupSim(int count, String size) {
    return 'Similar group, $count photos, saves $size';
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
    return '$i of $n';
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
    return '$n selected · $size · recoverable until you empty';
  }

  @override
  String restoreN(int n) {
    return 'Restore $n';
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
    return '${n}d';
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
    return '$n selected · $size · recoverable from the trash';
  }

  @override
  String moveNToTrash(int n) {
    return 'Move $n to trash';
  }

  @override
  String groupsSummary(String groups, String size) {
    return '$groups · $size to free';
  }

  @override
  String groupsInTrash(int count, String size) {
    return ' · $count in trash ($size)';
  }

  @override
  String get sortSaving => 'Biggest saving';

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
    return '$kind group, $count files, $state';
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
    return 'Group $i of $n';
  }

  @override
  String get pagerNothing => 'Nothing to review.';

  @override
  String get tipAllGroups => 'All groups';

  @override
  String get pagerKeepAll => 'Keep all · next';

  @override
  String pagerTrashN(int n, String size) {
    return 'Trash $n · save $size';
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
  String get pagerTip => 'Tap a copy to flip it · swipe for the next group';

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
