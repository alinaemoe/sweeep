import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @navClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get navClean;

  /// No description provided for @navSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get navSwipe;

  /// No description provided for @navTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// No description provided for @navTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get navTrash;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @actionSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get actionSwipe;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 file} other{{n} files}}'**
  String filesCount(int n);

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 photo} other{{n} photos}}'**
  String photosCount(int n);

  /// No description provided for @groupsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 group} other{{n} groups}}'**
  String groupsCount(int n);

  /// No description provided for @byteUnits.
  ///
  /// In en, this message translates to:
  /// **'B,KB,MB,GB,TB'**
  String get byteUnits;

  /// No description provided for @hz.
  ///
  /// In en, this message translates to:
  /// **'{n} Hz'**
  String hz(String n);

  /// No description provided for @unitHz.
  ///
  /// In en, this message translates to:
  /// **'Hz'**
  String get unitHz;

  /// No description provided for @khz.
  ///
  /// In en, this message translates to:
  /// **'{n} kHz'**
  String khz(String n);

  /// No description provided for @onbTitle.
  ///
  /// In en, this message translates to:
  /// **'Your photos\nnever leave\nyour phone.'**
  String get onbTitle;

  /// No description provided for @onbPoint1.
  ///
  /// In en, this message translates to:
  /// **'Everything is analyzed on this device.'**
  String get onbPoint1;

  /// No description provided for @onbPoint2.
  ///
  /// In en, this message translates to:
  /// **'No uploads, no accounts, no ads.'**
  String get onbPoint2;

  /// No description provided for @onbPoint3.
  ///
  /// In en, this message translates to:
  /// **'Nothing is deleted until you confirm.'**
  String get onbPoint3;

  /// No description provided for @onbDenied.
  ///
  /// In en, this message translates to:
  /// **'Access is off. Allow photos and videos for Sweeep in Settings › Apps › Sweeep › Permissions, then come back.'**
  String get onbDenied;

  /// No description provided for @onbCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get onbCheckAgain;

  /// No description provided for @onbAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow photo access'**
  String get onbAllow;

  /// No description provided for @secDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get secDuplicates;

  /// No description provided for @secSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar photos'**
  String get secSimilar;

  /// No description provided for @secScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get secScreenshots;

  /// No description provided for @secVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get secVideos;

  /// No description provided for @secChat.
  ///
  /// In en, this message translates to:
  /// **'Chat media'**
  String get secChat;

  /// No description provided for @secBlurry.
  ///
  /// In en, this message translates to:
  /// **'Blurry & dark'**
  String get secBlurry;

  /// No description provided for @srcAll.
  ///
  /// In en, this message translates to:
  /// **'All photos'**
  String get srcAll;

  /// No description provided for @tagBlurry.
  ///
  /// In en, this message translates to:
  /// **'blurry'**
  String get tagBlurry;

  /// No description provided for @tagDark.
  ///
  /// In en, this message translates to:
  /// **'dark'**
  String get tagDark;

  /// No description provided for @scanReading.
  ///
  /// In en, this message translates to:
  /// **'READING LIBRARY'**
  String get scanReading;

  /// No description provided for @scanAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'ANALYZING {done} OF {total}'**
  String scanAnalyzing(String done, String total);

  /// No description provided for @scanComparing.
  ///
  /// In en, this message translates to:
  /// **'COMPARING FILES'**
  String get scanComparing;

  /// No description provided for @homeNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to clean yet. Pull in more photos or re-scan later.'**
  String get homeNothing;

  /// No description provided for @ovalReclaimableOf.
  ///
  /// In en, this message translates to:
  /// **'RECLAIMABLE OF {size}'**
  String ovalReclaimableOf(String size);

  /// No description provided for @ovalScanning.
  ///
  /// In en, this message translates to:
  /// **'SCANNING'**
  String get ovalScanning;

  /// No description provided for @ovalReclaimable.
  ///
  /// In en, this message translates to:
  /// **'RECLAIMABLE'**
  String get ovalReclaimable;

  /// No description provided for @ctaScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get ctaScanning;

  /// No description provided for @ctaAllClean.
  ///
  /// In en, this message translates to:
  /// **'All clean'**
  String get ctaAllClean;

  /// No description provided for @ctaFreeUp.
  ///
  /// In en, this message translates to:
  /// **'Free up {size}'**
  String ctaFreeUp(String size);

  /// No description provided for @tipLibraryDetails.
  ///
  /// In en, this message translates to:
  /// **'Library details'**
  String get tipLibraryDetails;

  /// No description provided for @semGroupDup.
  ///
  /// In en, this message translates to:
  /// **'Duplicate group, {count} photos, saves {size}'**
  String semGroupDup(int count, String size);

  /// No description provided for @semGroupSim.
  ///
  /// In en, this message translates to:
  /// **'Similar group, {count} photos, saves {size}'**
  String semGroupSim(int count, String size);

  /// No description provided for @semVideo.
  ///
  /// In en, this message translates to:
  /// **'Video, {size}'**
  String semVideo(String size);

  /// No description provided for @semVideoLen.
  ///
  /// In en, this message translates to:
  /// **'Video, {length}, {size}'**
  String semVideoLen(String length, String size);

  /// No description provided for @semPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo, {size}'**
  String semPhoto(String size);

  /// No description provided for @semTagged.
  ///
  /// In en, this message translates to:
  /// **'{tag}, {size}'**
  String semTagged(String tag, String size);

  /// No description provided for @swipeOf.
  ///
  /// In en, this message translates to:
  /// **'{i} of {n}'**
  String swipeOf(int i, int n);

  /// No description provided for @tipTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get tipTrash;

  /// No description provided for @tipKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get tipKeep;

  /// No description provided for @stampLater.
  ///
  /// In en, this message translates to:
  /// **'LATER'**
  String get stampLater;

  /// No description provided for @stampTrash.
  ///
  /// In en, this message translates to:
  /// **'TO TRASH'**
  String get stampTrash;

  /// No description provided for @stampKeep.
  ///
  /// In en, this message translates to:
  /// **'KEEP'**
  String get stampKeep;

  /// No description provided for @swipeInTrash.
  ///
  /// In en, this message translates to:
  /// **'In trash: {files} '**
  String swipeInTrash(String files);

  /// No description provided for @swipeDoneNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get swipeDoneNothing;

  /// No description provided for @swipeDoneAll.
  ///
  /// In en, this message translates to:
  /// **'All reviewed'**
  String get swipeDoneAll;

  /// No description provided for @swipeDoneHint.
  ///
  /// In en, this message translates to:
  /// **'You can restore anything from the trash.'**
  String get swipeDoneHint;

  /// No description provided for @hintTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to sort'**
  String get hintTitle;

  /// No description provided for @hintTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get hintTrash;

  /// No description provided for @hintKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get hintKeep;

  /// No description provided for @hintLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get hintLater;

  /// No description provided for @hintTap.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to start'**
  String get hintTap;

  /// No description provided for @tlNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get tlNewestFirst;

  /// No description provided for @tlOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get tlOldestFirst;

  /// No description provided for @tlHeadline.
  ///
  /// In en, this message translates to:
  /// **'Swipe through\nevery month'**
  String get tlHeadline;

  /// No description provided for @tlSummary.
  ///
  /// In en, this message translates to:
  /// **'{photos} · {swept} swept so far'**
  String tlSummary(String photos, String swept);

  /// No description provided for @tlNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get tlNoPhotos;

  /// No description provided for @tlContinueMonth.
  ///
  /// In en, this message translates to:
  /// **'Continue · {month}'**
  String tlContinueMonth(String month);

  /// No description provided for @tlMonthLine.
  ///
  /// In en, this message translates to:
  /// **'{photos} · {status}'**
  String tlMonthLine(String photos, String status);

  /// No description provided for @tlAllSwept.
  ///
  /// In en, this message translates to:
  /// **'all swept'**
  String get tlAllSwept;

  /// No description provided for @tlNSwept.
  ///
  /// In en, this message translates to:
  /// **'{n} swept'**
  String tlNSwept(String n);

  /// No description provided for @tlNotStarted.
  ///
  /// In en, this message translates to:
  /// **'not started'**
  String get tlNotStarted;

  /// No description provided for @tlDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tlDone;

  /// No description provided for @tlContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get tlContinue;

  /// No description provided for @tlMore.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get tlMore;

  /// No description provided for @tlSemMore.
  ///
  /// In en, this message translates to:
  /// **'{n} more photos'**
  String tlSemMore(String n);

  /// No description provided for @tlSemPhotoFrom.
  ///
  /// In en, this message translates to:
  /// **'Photo from {date}'**
  String tlSemPhotoFrom(String date);

  /// No description provided for @tlSemReview.
  ///
  /// In en, this message translates to:
  /// **'Review again {month}'**
  String tlSemReview(String month);

  /// No description provided for @tlSemContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue {month}'**
  String tlSemContinue(String month);

  /// No description provided for @tlSemSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe {month}'**
  String tlSemSwipe(String month);

  /// No description provided for @tlSemSort.
  ///
  /// In en, this message translates to:
  /// **'Newest first. Tap to show oldest first'**
  String get tlSemSort;

  /// No description provided for @tlSemSortOld.
  ///
  /// In en, this message translates to:
  /// **'Oldest first. Tap to show newest first'**
  String get tlSemSortOld;

  /// No description provided for @trashNothingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Nothing was deleted.'**
  String get trashNothingDeleted;

  /// No description provided for @trashDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything?'**
  String get trashDeleteTitle;

  /// No description provided for @trashDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{files} ({size}) will be deleted from your phone. Android may ask once more.'**
  String trashDeleteBody(String files, String size);

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @emptyAll.
  ///
  /// In en, this message translates to:
  /// **'Empty all'**
  String get emptyAll;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// No description provided for @trashWillFree.
  ///
  /// In en, this message translates to:
  /// **'{files} · {size} will be freed'**
  String trashWillFree(String files, String size);

  /// No description provided for @trashLandHere.
  ///
  /// In en, this message translates to:
  /// **'Swiped-away photos land here.'**
  String get trashLandHere;

  /// No description provided for @trashSelected.
  ///
  /// In en, this message translates to:
  /// **'{n} selected · {size} · recoverable until you empty'**
  String trashSelected(int n, String size);

  /// No description provided for @restoreN.
  ///
  /// In en, this message translates to:
  /// **'Restore {n}'**
  String restoreN(int n);

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForever;

  /// No description provided for @freedTitle.
  ///
  /// In en, this message translates to:
  /// **'{size} freed'**
  String freedTitle(String size);

  /// No description provided for @freedSub.
  ///
  /// In en, this message translates to:
  /// **'{files} deleted'**
  String freedSub(String files);

  /// No description provided for @daysToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get daysToday;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String daysLeft(int n);

  /// No description provided for @movedToTrash.
  ///
  /// In en, this message translates to:
  /// **'{files} moved to trash'**
  String movedToTrash(String files);

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get sortLargest;

  /// No description provided for @allApps.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get allApps;

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get nothingHere;

  /// No description provided for @catSelected.
  ///
  /// In en, this message translates to:
  /// **'{n} selected · {size} · recoverable from the trash'**
  String catSelected(int n, String size);

  /// No description provided for @moveNToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move {n} to trash'**
  String moveNToTrash(int n);

  /// No description provided for @groupsSummary.
  ///
  /// In en, this message translates to:
  /// **'{groups} · {size} to free'**
  String groupsSummary(String groups, String size);

  /// No description provided for @groupsInTrash.
  ///
  /// In en, this message translates to:
  /// **' · {count} in trash ({size})'**
  String groupsInTrash(int count, String size);

  /// No description provided for @sortSaving.
  ///
  /// In en, this message translates to:
  /// **'Biggest'**
  String get sortSaving;

  /// No description provided for @sortCopies.
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get sortCopies;

  /// No description provided for @nothingLeft.
  ///
  /// In en, this message translates to:
  /// **'Nothing left here.'**
  String get nothingLeft;

  /// No description provided for @groupsSelectedBar.
  ///
  /// In en, this message translates to:
  /// **'{groups} selected · best photo of each is kept'**
  String groupsSelectedBar(String groups);

  /// No description provided for @cleanGroups.
  ///
  /// In en, this message translates to:
  /// **'Clean {groups} · save {size}'**
  String cleanGroups(String groups, String size);

  /// No description provided for @groupSemantics.
  ///
  /// In en, this message translates to:
  /// **'{kind} group, {count} files, {state}'**
  String groupSemantics(String kind, int count, String state);

  /// No description provided for @stateSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get stateSelected;

  /// No description provided for @stateNotSelected.
  ///
  /// In en, this message translates to:
  /// **'not selected'**
  String get stateNotSelected;

  /// No description provided for @semSort.
  ///
  /// In en, this message translates to:
  /// **'Sort: {label}'**
  String semSort(String label);

  /// No description provided for @groupSave.
  ///
  /// In en, this message translates to:
  /// **'save {size}'**
  String groupSave(String size);

  /// No description provided for @pagerGroupOf.
  ///
  /// In en, this message translates to:
  /// **'Group {i} of {n}'**
  String pagerGroupOf(int i, int n);

  /// No description provided for @pagerNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review.'**
  String get pagerNothing;

  /// No description provided for @tipAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get tipAllGroups;

  /// No description provided for @pagerKeepAll.
  ///
  /// In en, this message translates to:
  /// **'Keep all · next'**
  String get pagerKeepAll;

  /// No description provided for @pagerTrashN.
  ///
  /// In en, this message translates to:
  /// **'Trash {n} · save {size}'**
  String pagerTrashN(int n, String size);

  /// No description provided for @whyOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest copy'**
  String get whyOldest;

  /// No description provided for @whySharpest.
  ///
  /// In en, this message translates to:
  /// **'Sharpest'**
  String get whySharpest;

  /// No description provided for @pillBestPick.
  ///
  /// In en, this message translates to:
  /// **'BEST PICK'**
  String get pillBestPick;

  /// No description provided for @pillBest.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get pillBest;

  /// No description provided for @pillKeep.
  ///
  /// In en, this message translates to:
  /// **'KEEP'**
  String get pillKeep;

  /// No description provided for @pillTrash.
  ///
  /// In en, this message translates to:
  /// **'TRASH'**
  String get pillTrash;

  /// No description provided for @semKeptCopy.
  ///
  /// In en, this message translates to:
  /// **'Keep this copy. Tap to trash it'**
  String get semKeptCopy;

  /// No description provided for @semTrashCopy.
  ///
  /// In en, this message translates to:
  /// **'Trash this copy. Tap to keep it'**
  String get semTrashCopy;

  /// No description provided for @pagerTip.
  ///
  /// In en, this message translates to:
  /// **'Tap to compare · hold to flip KEEP/TRASH · pull down to trash all'**
  String get pagerTip;

  /// No description provided for @pagerTrashAllN.
  ///
  /// In en, this message translates to:
  /// **'Trash all {n} · save {size}'**
  String pagerTrashAllN(int n, String size);

  /// No description provided for @stampTrashAll.
  ///
  /// In en, this message translates to:
  /// **'TRASH ALL'**
  String get stampTrashAll;

  /// No description provided for @secScreenRecordings.
  ///
  /// In en, this message translates to:
  /// **'Screen recordings'**
  String get secScreenRecordings;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Sweeep is scanning'**
  String get notifTitle;

  /// No description provided for @notifChannel.
  ///
  /// In en, this message translates to:
  /// **'Library scan'**
  String get notifChannel;

  /// No description provided for @notifStart.
  ///
  /// In en, this message translates to:
  /// **'Scanning your library'**
  String get notifStart;

  /// No description provided for @notifHashing.
  ///
  /// In en, this message translates to:
  /// **'Hashing photos · {done} of {total}'**
  String notifHashing(String done, String total);

  /// No description provided for @notifChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking duplicates · {done} of {total}'**
  String notifChecking(String done, String total);

  /// No description provided for @scanOfFiles.
  ///
  /// In en, this message translates to:
  /// **'{done} OF {total} FILES'**
  String scanOfFiles(String done, String total);

  /// No description provided for @scanStepRead.
  ///
  /// In en, this message translates to:
  /// **'Reading library'**
  String get scanStepRead;

  /// No description provided for @scanStepFinger.
  ///
  /// In en, this message translates to:
  /// **'Fingerprinting photos'**
  String get scanStepFinger;

  /// No description provided for @scanStepCompare.
  ///
  /// In en, this message translates to:
  /// **'Comparing similar shots'**
  String get scanStepCompare;

  /// No description provided for @scanStepGroup.
  ///
  /// In en, this message translates to:
  /// **'Grouping & ranking'**
  String get scanStepGroup;

  /// No description provided for @scanStatusDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get scanStatusDone;

  /// No description provided for @scanStatusNext.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get scanStatusNext;

  /// No description provided for @scanCountGroups.
  ///
  /// In en, this message translates to:
  /// **'groups'**
  String get scanCountGroups;

  /// No description provided for @scanCountShots.
  ///
  /// In en, this message translates to:
  /// **'screenshots'**
  String get scanCountShots;

  /// No description provided for @scanCountFound.
  ///
  /// In en, this message translates to:
  /// **'found so far'**
  String get scanCountFound;

  /// No description provided for @scanPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Analyzed on this device. Nothing is uploaded.'**
  String get scanPrivacy;

  /// No description provided for @scanPausedNote.
  ///
  /// In en, this message translates to:
  /// **'Paused. Progress is saved.'**
  String get scanPausedNote;

  /// No description provided for @scanPause.
  ///
  /// In en, this message translates to:
  /// **'Pause scan'**
  String get scanPause;

  /// No description provided for @scanResume.
  ///
  /// In en, this message translates to:
  /// **'Resume scan'**
  String get scanResume;

  /// No description provided for @scanLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get scanLater;

  /// No description provided for @modeGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get modeGrid;

  /// No description provided for @modeSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get modeSwipe;

  /// No description provided for @modeMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get modeMonths;

  /// No description provided for @groupsMonthLine.
  ///
  /// In en, this message translates to:
  /// **'{groups} · save {size}'**
  String groupsMonthLine(String groups, String size);

  /// No description provided for @videoPlay.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get videoPlay;

  /// No description provided for @videoPause.
  ///
  /// In en, this message translates to:
  /// **'Pause video'**
  String get videoPause;

  /// No description provided for @videoFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t play this video'**
  String get videoFailed;

  /// No description provided for @storUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get storUpdated;

  /// No description provided for @storSafeLabel.
  ///
  /// In en, this message translates to:
  /// **'YOU CAN SAFELY FREE'**
  String get storSafeLabel;

  /// No description provided for @storOfTotal.
  ///
  /// In en, this message translates to:
  /// **'of {size} your photos and videos take up'**
  String storOfTotal(String size);

  /// No description provided for @storCutMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get storCutMonths;

  /// No description provided for @storCutTypes.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get storCutTypes;

  /// No description provided for @storCutSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get storCutSources;

  /// No description provided for @storLegend.
  ///
  /// In en, this message translates to:
  /// **'the part you can clear in this block'**
  String get storLegend;

  /// No description provided for @storClear.
  ///
  /// In en, this message translates to:
  /// **'clear {size}'**
  String storClear(String size);

  /// No description provided for @storReview.
  ///
  /// In en, this message translates to:
  /// **'Review this block'**
  String get storReview;

  /// No description provided for @storQuickTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick wins'**
  String get storQuickTitle;

  /// No description provided for @storQuickSub.
  ///
  /// In en, this message translates to:
  /// **'Safe to clear, one tap each'**
  String get storQuickSub;

  /// No description provided for @storQuickTotal.
  ///
  /// In en, this message translates to:
  /// **'{size} total'**
  String storQuickTotal(String size);

  /// No description provided for @storSafe.
  ///
  /// In en, this message translates to:
  /// **'SAFE'**
  String get storSafe;

  /// No description provided for @storClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get storClean;

  /// No description provided for @storEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get storEarlier;

  /// No description provided for @storEarlierSub.
  ///
  /// In en, this message translates to:
  /// **'before {month} · {n} files'**
  String storEarlierSub(String month, String n);

  /// No description provided for @storMonthSub.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 photo or video} other{{n} photos and videos}}'**
  String storMonthSub(int n);

  /// No description provided for @storTypeVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get storTypeVideos;

  /// No description provided for @storTypePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get storTypePhotos;

  /// No description provided for @storTypeChat.
  ///
  /// In en, this message translates to:
  /// **'Chat media'**
  String get storTypeChat;

  /// No description provided for @storTypeShots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get storTypeShots;

  /// No description provided for @storTypeRecs.
  ///
  /// In en, this message translates to:
  /// **'Screen rec.'**
  String get storTypeRecs;

  /// No description provided for @storSubVideos.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 clip} other{{n} clips}}'**
  String storSubVideos(int n);

  /// No description provided for @storSubPhotos.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 photo} other{{n} photos}}'**
  String storSubPhotos(int n);

  /// No description provided for @storSubChat.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 file from messengers} other{{n} files from messengers}}'**
  String storSubChat(int n);

  /// No description provided for @storSubShots.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 screenshot} other{{n} screenshots}}'**
  String storSubShots(int n);

  /// No description provided for @storSubRecs.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 recording} other{{n} recordings}}'**
  String storSubRecs(int n);

  /// No description provided for @storSrcCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get storSrcCamera;

  /// No description provided for @storSrcDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get storSrcDownloads;

  /// No description provided for @storSrcOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get storSrcOther;

  /// No description provided for @storSubCamera.
  ///
  /// In en, this message translates to:
  /// **'taken on this phone'**
  String get storSubCamera;

  /// No description provided for @storSubChatSrc.
  ///
  /// In en, this message translates to:
  /// **'received and sent media'**
  String get storSubChatSrc;

  /// No description provided for @storSubShotsSrc.
  ///
  /// In en, this message translates to:
  /// **'screen captures'**
  String get storSubShotsSrc;

  /// No description provided for @storSubDownloads.
  ///
  /// In en, this message translates to:
  /// **'saved from the browser'**
  String get storSubDownloads;

  /// No description provided for @storSubInstagram.
  ///
  /// In en, this message translates to:
  /// **'saved posts and stories'**
  String get storSubInstagram;

  /// No description provided for @storSubOther.
  ///
  /// In en, this message translates to:
  /// **'everything else'**
  String get storSubOther;

  /// No description provided for @qwOldShots.
  ///
  /// In en, this message translates to:
  /// **'Old screenshots'**
  String get qwOldShots;

  /// No description provided for @qwOldShotsSub.
  ///
  /// In en, this message translates to:
  /// **'Older than 90 days, never opened since'**
  String get qwOldShotsSub;

  /// No description provided for @qwBlurry.
  ///
  /// In en, this message translates to:
  /// **'Blurry and dark'**
  String get qwBlurry;

  /// No description provided for @qwBlurrySub.
  ///
  /// In en, this message translates to:
  /// **'Out of focus or nearly black frames'**
  String get qwBlurrySub;

  /// No description provided for @qwChat.
  ///
  /// In en, this message translates to:
  /// **'Chat leftovers'**
  String get qwChat;

  /// No description provided for @qwChatSub.
  ///
  /// In en, this message translates to:
  /// **'Memes and forwards you already have in a chat'**
  String get qwChatSub;

  /// No description provided for @qwRecs.
  ///
  /// In en, this message translates to:
  /// **'Long screen recordings'**
  String get qwRecs;

  /// No description provided for @qwRecsSub.
  ///
  /// In en, this message translates to:
  /// **'Over a minute, saved months ago'**
  String get qwRecsSub;

  /// No description provided for @qwDups.
  ///
  /// In en, this message translates to:
  /// **'Exact duplicates'**
  String get qwDups;

  /// No description provided for @qwDupsSub.
  ///
  /// In en, this message translates to:
  /// **'Identical files, the oldest copy stays'**
  String get qwDupsSub;

  /// No description provided for @sessTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Session'**
  String get sessTitle;

  /// No description provided for @sessSub.
  ///
  /// In en, this message translates to:
  /// **'A short run through your oldest photos.\nNo pressure, stop any time.'**
  String get sessSub;

  /// No description provided for @sessDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String sessDays(int n);

  /// No description provided for @sessPhotosAbout.
  ///
  /// In en, this message translates to:
  /// **'photos · about {m} min'**
  String sessPhotosAbout(int m);

  /// No description provided for @sessWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get sessWeek;

  /// No description provided for @sessBest.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{best streak 1 day} other{best streak {n} days}}'**
  String sessBest(int n);

  /// No description provided for @sessFreeze.
  ///
  /// In en, this message translates to:
  /// **'1 freeze'**
  String get sessFreeze;

  /// No description provided for @sessFreezeSub.
  ///
  /// In en, this message translates to:
  /// **'covers one missed day, so a busy week does not break the streak'**
  String get sessFreezeSub;

  /// No description provided for @sessFreezeUsed.
  ///
  /// In en, this message translates to:
  /// **'This week\'s freeze is already used'**
  String get sessFreezeUsed;

  /// No description provided for @sessMonths.
  ///
  /// In en, this message translates to:
  /// **'Months swept'**
  String get sessMonths;

  /// No description provided for @sessOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'oldest first'**
  String get sessOldestFirst;

  /// No description provided for @sessStartsWith.
  ///
  /// In en, this message translates to:
  /// **'Starts with {month} · lookalikes first, then the rest'**
  String sessStartsWith(String month);

  /// No description provided for @sessStart.
  ///
  /// In en, this message translates to:
  /// **'Start · {photos}'**
  String sessStart(String photos);

  /// No description provided for @sessNothing.
  ///
  /// In en, this message translates to:
  /// **'Everything is swept'**
  String get sessNothing;

  /// No description provided for @sessEntryNoStreak.
  ///
  /// In en, this message translates to:
  /// **'Start your streak'**
  String get sessEntryNoStreak;

  /// No description provided for @sessEntrySub.
  ///
  /// In en, this message translates to:
  /// **'A short run through your oldest photos'**
  String get sessEntrySub;

  /// No description provided for @sessProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal}'**
  String sessProgress(int done, int goal);

  /// No description provided for @remTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get remTitle;

  /// No description provided for @remSub.
  ///
  /// In en, this message translates to:
  /// **'A nudge on days you have not swept yet'**
  String get remSub;

  /// No description provided for @remTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get remTime;

  /// No description provided for @remNeedPerm.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to get reminders'**
  String get remNeedPerm;

  /// No description provided for @remAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get remAllow;

  /// No description provided for @remNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for a quick sweep'**
  String get remNotifTitle;

  /// No description provided for @remNotifBody.
  ///
  /// In en, this message translates to:
  /// **'A minute for your photos? Keep the streak going.'**
  String get remNotifBody;

  /// No description provided for @remChannel.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remChannel;

  /// No description provided for @doneSwept.
  ///
  /// In en, this message translates to:
  /// **'{photos} swept in {time}'**
  String doneSwept(String photos, String time);

  /// No description provided for @doneTimeMS.
  ///
  /// In en, this message translates to:
  /// **'{m} min {s} s'**
  String doneTimeMS(int m, int s);

  /// No description provided for @doneTimeS.
  ///
  /// In en, this message translates to:
  /// **'{s} s'**
  String doneTimeS(int s);

  /// No description provided for @doneInTrash.
  ///
  /// In en, this message translates to:
  /// **'IN TRASH'**
  String get doneInTrash;

  /// No description provided for @doneInTrashSub.
  ///
  /// In en, this message translates to:
  /// **'{unit} · {files}'**
  String doneInTrashSub(String unit, String files);

  /// No description provided for @doneKept.
  ///
  /// In en, this message translates to:
  /// **'KEPT'**
  String get doneKept;

  /// No description provided for @donePhotosStay.
  ///
  /// In en, this message translates to:
  /// **'photos stay'**
  String get donePhotosStay;

  /// No description provided for @doneStreak.
  ///
  /// In en, this message translates to:
  /// **'{n} day streak'**
  String doneStreak(int n);

  /// No description provided for @doneStreakUp.
  ///
  /// In en, this message translates to:
  /// **'one more than yesterday · best is {best}'**
  String doneStreakUp(int best);

  /// No description provided for @doneStreakNew.
  ///
  /// In en, this message translates to:
  /// **'a fresh start · best is {best}'**
  String doneStreakNew(int best);

  /// No description provided for @doneStreakSame.
  ///
  /// In en, this message translates to:
  /// **'already counted today · best is {best}'**
  String doneStreakSame(int best);

  /// No description provided for @doneMonthProgress.
  ///
  /// In en, this message translates to:
  /// **'{from}% to {to}%'**
  String doneMonthProgress(int from, int to);

  /// No description provided for @doneLeft.
  ///
  /// In en, this message translates to:
  /// **'{photos} left in {month}. '**
  String doneLeft(String photos, String month);

  /// No description provided for @doneMoreSessions.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{About 1 more session and it is done} other{About {n} more sessions and it is done}}'**
  String doneMoreSessions(int n);

  /// No description provided for @doneMonthDone.
  ///
  /// In en, this message translates to:
  /// **'{month} is fully swept!'**
  String doneMonthDone(String month);

  /// No description provided for @doneNote.
  ///
  /// In en, this message translates to:
  /// **'Photos are in the Sweeep trash for 30 days. Nothing leaves your phone until you empty it.'**
  String get doneNote;

  /// No description provided for @doneDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneDone;

  /// No description provided for @doneAnother.
  ///
  /// In en, this message translates to:
  /// **'Another {n}'**
  String doneAnother(int n);

  /// No description provided for @toolsWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get toolsWater;

  /// No description provided for @toolsDust.
  ///
  /// In en, this message translates to:
  /// **'Dust'**
  String get toolsDust;

  /// No description provided for @toolsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound test'**
  String get toolsSound;

  /// No description provided for @toolsSweepStatus.
  ///
  /// In en, this message translates to:
  /// **'Sweep · 20 Hz to 20 kHz'**
  String get toolsSweepStatus;

  /// No description provided for @toolsLeftOnly.
  ///
  /// In en, this message translates to:
  /// **'Left speaker only'**
  String get toolsLeftOnly;

  /// No description provided for @toolsRightOnly.
  ///
  /// In en, this message translates to:
  /// **'Right speaker only'**
  String get toolsRightOnly;

  /// No description provided for @toolsSteady.
  ///
  /// In en, this message translates to:
  /// **'Steady tone'**
  String get toolsSteady;

  /// No description provided for @toolsPulsing.
  ///
  /// In en, this message translates to:
  /// **'Pulsing tone · {tail}'**
  String toolsPulsing(String tail);

  /// No description provided for @toolsTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String toolsTimeLeft(String time);

  /// No description provided for @toolsFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get toolsFrequency;

  /// No description provided for @toolsEject.
  ///
  /// In en, this message translates to:
  /// **'Eject water'**
  String get toolsEject;

  /// No description provided for @toolsShake.
  ///
  /// In en, this message translates to:
  /// **'Shake out dust'**
  String get toolsShake;

  /// No description provided for @toolsPlay.
  ///
  /// In en, this message translates to:
  /// **'Play tone'**
  String get toolsPlay;

  /// No description provided for @toolsStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get toolsStop;

  /// No description provided for @toolsBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get toolsBoth;

  /// No description provided for @toolsLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get toolsLeft;

  /// No description provided for @toolsRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get toolsRight;

  /// No description provided for @toolsBass.
  ///
  /// In en, this message translates to:
  /// **'Bass 60 Hz'**
  String get toolsBass;

  /// No description provided for @toolsTreble.
  ///
  /// In en, this message translates to:
  /// **'Treble 8 kHz'**
  String get toolsTreble;

  /// No description provided for @toolsSweep.
  ///
  /// In en, this message translates to:
  /// **'Sweep'**
  String get toolsSweep;

  /// No description provided for @toolsWarning.
  ///
  /// In en, this message translates to:
  /// **'Start at low volume and keep the phone away from your ear. Results aren\'t guaranteed.'**
  String get toolsWarning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
