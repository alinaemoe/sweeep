import '../../index/storage_service.dart';
import '../../l10n/l10n.dart';

String quickWinTitle(QuickWin w) => switch (w) {
      QuickWin.oldScreenshots => l10n.qwOldShots,
      QuickWin.blurry => l10n.qwBlurry,
      QuickWin.chatLeftovers => l10n.qwChat,
      QuickWin.longRecordings => l10n.qwRecs,
      QuickWin.duplicates => l10n.qwDups,
    };

String quickWinSub(QuickWin w) => switch (w) {
      QuickWin.oldScreenshots => l10n.qwOldShotsSub,
      QuickWin.blurry => l10n.qwBlurrySub,
      QuickWin.chatLeftovers => l10n.qwChatSub,
      QuickWin.longRecordings => l10n.qwRecsSub,
      QuickWin.duplicates => l10n.qwDupsSub,
    };

/// Month name without the year, for blocks too narrow for it.
String tileShortLabel(StorageCut cut, String key) =>
    cut == StorageCut.months && key != 'earlier' ? fmtMonthAbbr(int.parse(key.substring(0, 4)), int.parse(key.substring(5))) : tileLabel(cut, key);

/// Label of a map block, for the cut it belongs to.
String tileLabel(StorageCut cut, String key) {
  switch (cut) {
    case StorageCut.months:
      return key == 'earlier' ? l10n.storEarlier : fmtMonthShort(int.parse(key.substring(0, 4)), int.parse(key.substring(5)));
    case StorageCut.types:
      return switch (key) {
        'videos' => l10n.storTypeVideos,
        'photos' => l10n.storTypePhotos,
        'chat' => l10n.storTypeChat,
        'screenshots' => l10n.storTypeShots,
        _ => l10n.storTypeRecs,
      };
    case StorageCut.sources:
      return switch (key) {
        'camera' => l10n.storSrcCamera,
        'downloads' => l10n.storSrcDownloads,
        'screenshots' => l10n.storTypeShots,
        'other' => l10n.storSrcOther,
        'whatsapp' => 'WhatsApp',
        _ => key[0].toUpperCase() + key.substring(1),
      };
  }
}

/// The line under a block's name in the info card.
String tileSub(StorageCut cut, StorageTile t, {String? olderThan}) {
  switch (cut) {
    case StorageCut.months:
      return t.key == 'earlier' ? l10n.storEarlierSub(olderThan ?? '', fmtNum(t.count)) : l10n.storMonthSub(t.count);
    case StorageCut.types:
      return switch (t.key) {
        'videos' => l10n.storSubVideos(t.count),
        'photos' => l10n.storSubPhotos(t.count),
        'chat' => l10n.storSubChat(t.count),
        'screenshots' => l10n.storSubShots(t.count),
        _ => l10n.storSubRecs(t.count),
      };
    case StorageCut.sources:
      return switch (t.key) {
        'camera' => l10n.storSubCamera,
        'screenshots' => l10n.storSubShotsSrc,
        'downloads' => l10n.storSubDownloads,
        'instagram' => l10n.storSubInstagram,
        'other' => l10n.storSubOther,
        _ => l10n.storSubChatSrc,
      };
  }
}
