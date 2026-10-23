// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navClean => 'Pulisci';

  @override
  String get navSwipe => 'Swipe';

  @override
  String get navTools => 'Strumenti';

  @override
  String get navTrash => 'Cestino';

  @override
  String get back => 'Indietro';

  @override
  String get cancel => 'Annulla';

  @override
  String get undo => 'Annulla';

  @override
  String get selectAll => 'Seleziona tutto';

  @override
  String get clear => 'Azzera';

  @override
  String get seeAll => 'Tutte';

  @override
  String get actionSwipe => 'Swipe';

  @override
  String get skip => 'Salta';

  @override
  String filesCount(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString file',
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
      other: '$nString foto',
      one: '1 foto',
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
      other: '$nString gruppi',
      one: '1 gruppo',
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
  String get onbTitle => 'Le tue foto\nnon lasciano mai\nil telefono.';

  @override
  String get onbPoint1 => 'Tutto viene analizzato su questo dispositivo.';

  @override
  String get onbPoint2 => 'Niente upload, niente account, niente pubblicità.';

  @override
  String get onbPoint3 => 'Non viene eliminato nulla finché non confermi.';

  @override
  String get onbDenied =>
      'L\'accesso è disattivato. Consenti foto e video per Sweeep in Impostazioni › App › Sweeep › Autorizzazioni, poi torna qui.';

  @override
  String get onbCheckAgain => 'Controlla di nuovo';

  @override
  String get onbAllow => 'Consenti l\'accesso alle foto';

  @override
  String get secDuplicates => 'Duplicati';

  @override
  String get secSimilar => 'Foto simili';

  @override
  String get secScreenshots => 'Screenshot';

  @override
  String get secVideos => 'Video';

  @override
  String get secChat => 'Media delle chat';

  @override
  String get secBlurry => 'Mosse e scure';

  @override
  String get srcAll => 'Tutte le foto';

  @override
  String get tagBlurry => 'mossa';

  @override
  String get tagDark => 'scura';

  @override
  String get scanReading => 'LETTURA DELLA LIBRERIA';

  @override
  String scanAnalyzing(String done, String total) {
    return 'ANALISI $done DI $total';
  }

  @override
  String get scanComparing => 'CONFRONTO DEI FILE';

  @override
  String get homeNothing =>
      'Niente da pulire per ora. Aggiungi altre foto o rianalizza più tardi.';

  @override
  String ovalReclaimableOf(String size) {
    return 'RECUPERABILI SU $size';
  }

  @override
  String get ovalScanning => 'ANALISI';

  @override
  String get ovalReclaimable => 'RECUPERABILI';

  @override
  String get ctaScanning => 'Analisi…';

  @override
  String get ctaAllClean => 'Tutto pulito';

  @override
  String ctaFreeUp(String size) {
    return 'Libera $size';
  }

  @override
  String get tipLibraryDetails => 'Dettagli della libreria';

  @override
  String semGroupDup(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Gruppo di duplicati, $countString foto, risparmio $size';
  }

  @override
  String semGroupSim(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Gruppo di foto simili, $countString foto, risparmio $size';
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
    return 'Foto, $size';
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

    return '$iString di $nString';
  }

  @override
  String get tipTrash => 'Sposta nel cestino';

  @override
  String get tipKeep => 'Tieni';

  @override
  String get stampLater => 'DOPO';

  @override
  String get stampTrash => 'AL CESTINO';

  @override
  String get stampKeep => 'TIENI';

  @override
  String swipeInTrash(String files) {
    return 'Nel cestino: $files ';
  }

  @override
  String get swipeDoneNothing => 'Niente da rivedere';

  @override
  String get swipeDoneAll => 'Tutto rivisto';

  @override
  String get swipeDoneHint => 'Puoi ripristinare qualsiasi cosa dal cestino.';

  @override
  String get hintTitle => 'Scorri per ordinare';

  @override
  String get hintTrash => 'Cestino';

  @override
  String get hintKeep => 'Tieni';

  @override
  String get hintLater => 'Dopo';

  @override
  String get hintTap => 'Tocca per iniziare';

  @override
  String get tlNewestFirst => 'Prima le recenti';

  @override
  String get tlOldestFirst => 'Prima le vecchie';

  @override
  String get tlHeadline => 'Scorri\nogni mese';

  @override
  String tlSummary(String photos, String swept) {
    return '$photos · $swept sistemate finora';
  }

  @override
  String get tlNoPhotos => 'Ancora nessuna foto.';

  @override
  String tlContinueMonth(String month) {
    return 'Continua · $month';
  }

  @override
  String tlMonthLine(String photos, String status) {
    return '$photos · $status';
  }

  @override
  String get tlAllSwept => 'tutto sistemato';

  @override
  String tlNSwept(String n) {
    return '$n sistemate';
  }

  @override
  String get tlNotStarted => 'non iniziato';

  @override
  String get tlDone => 'Fatto';

  @override
  String get tlContinue => 'Continua';

  @override
  String get tlMore => 'altre';

  @override
  String tlSemMore(String n) {
    return 'Altre $n foto';
  }

  @override
  String tlSemPhotoFrom(String date) {
    return 'Foto del $date';
  }

  @override
  String tlSemReview(String month) {
    return 'Rivedi di nuovo $month';
  }

  @override
  String tlSemContinue(String month) {
    return 'Continua $month';
  }

  @override
  String tlSemSwipe(String month) {
    return 'Scorri $month';
  }

  @override
  String get tlSemSort =>
      'Prima le recenti. Tocca per mostrare prima le vecchie';

  @override
  String get tlSemSortOld =>
      'Prima le vecchie. Tocca per mostrare prima le recenti';

  @override
  String get trashNothingDeleted => 'Non è stato eliminato nulla.';

  @override
  String get trashDeleteTitle => 'Eliminare tutto?';

  @override
  String trashDeleteBody(String files, String size) {
    return '$files ($size) verranno eliminati dal telefono. Android potrebbe chiedere un\'altra conferma.';
  }

  @override
  String get deleteAll => 'Elimina tutto';

  @override
  String get emptyAll => 'Svuota tutto';

  @override
  String get trashEmpty => 'Il cestino è vuoto';

  @override
  String trashWillFree(String files, String size) {
    return '$files · si libereranno $size';
  }

  @override
  String get trashLandHere => 'Le foto scartate finiscono qui.';

  @override
  String trashSelected(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$nString selezionate · $size · recuperabili finché non svuoti';
  }

  @override
  String restoreN(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Ripristina $nString';
  }

  @override
  String get deleteForever => 'Elimina per sempre';

  @override
  String freedTitle(String size) {
    return '$size liberati';
  }

  @override
  String freedSub(String files) {
    return '$files eliminati';
  }

  @override
  String get daysToday => 'oggi';

  @override
  String daysLeft(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '${nString}g';
  }

  @override
  String movedToTrash(String files) {
    return '$files spostati nel cestino';
  }

  @override
  String get sortNewest => 'Recenti';

  @override
  String get sortLargest => 'Più grandi';

  @override
  String get allApps => 'Tutte le app';

  @override
  String get nothingHere => 'Qui non c\'è niente.';

  @override
  String catSelected(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$nString selezionate · $size · recuperabili dal cestino';
  }

  @override
  String moveNToTrash(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Sposta $nString nel cestino';
  }

  @override
  String groupsSummary(String groups, String size) {
    return '$groups · $size da liberare';
  }

  @override
  String groupsInTrash(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return ' · $countString nel cestino ($size)';
  }

  @override
  String get sortSaving => 'Più grandi';

  @override
  String get sortCopies => 'Copie';

  @override
  String get nothingLeft => 'Qui non è rimasto niente.';

  @override
  String groupsSelectedBar(String groups) {
    return '$groups selezionati · si tiene la foto migliore di ciascuno';
  }

  @override
  String cleanGroups(String groups, String size) {
    return 'Pulisci $groups · risparmia $size';
  }

  @override
  String groupSemantics(String kind, int count, String state) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Gruppo $kind, $countString file, $state';
  }

  @override
  String get stateSelected => 'selezionato';

  @override
  String get stateNotSelected => 'non selezionato';

  @override
  String semSort(String label) {
    return 'Ordina: $label';
  }

  @override
  String groupSave(String size) {
    return 'risparmio $size';
  }

  @override
  String pagerGroupOf(int i, int n) {
    final intl.NumberFormat iNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String iString = iNumberFormat.format(i);
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Gruppo $iString di $nString';
  }

  @override
  String get pagerNothing => 'Niente da rivedere.';

  @override
  String get tipAllGroups => 'Tutti i gruppi';

  @override
  String get pagerKeepAll => 'Tieni tutte · avanti';

  @override
  String pagerTrashN(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Cestina $nString · risparmia $size';
  }

  @override
  String get whyOldest => 'Copia più vecchia';

  @override
  String get whySharpest => 'La più nitida';

  @override
  String get pillBestPick => 'LA MIGLIORE';

  @override
  String get pillBest => 'MIGLIORE';

  @override
  String get pillKeep => 'TIENI';

  @override
  String get pillTrash => 'CESTINA';

  @override
  String get semKeptCopy => 'Tieni questa copia. Tocca per cestinarla';

  @override
  String get semTrashCopy => 'Cestina questa copia. Tocca per tenerla';

  @override
  String get pagerTip =>
      'Tocca per confrontare · tieni premuto per passare da TIENI a CESTINA · trascina giù per cestinare tutto';

  @override
  String pagerTrashAllN(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Cestina tutte e $nString · risparmia $size';
  }

  @override
  String get stampTrashAll => 'CESTINA TUTTO';

  @override
  String get secScreenRecordings => 'Registrazioni dello schermo';

  @override
  String get notifTitle => 'Sweeep sta analizzando';

  @override
  String get notifChannel => 'Analisi della libreria';

  @override
  String get notifStart => 'Analisi della libreria in corso';

  @override
  String notifHashing(String done, String total) {
    return 'Impronte delle foto · $done di $total';
  }

  @override
  String notifChecking(String done, String total) {
    return 'Controllo dei duplicati · $done di $total';
  }

  @override
  String scanOfFiles(String done, String total) {
    return '$done DI $total FILE';
  }

  @override
  String get scanStepRead => 'Lettura della libreria';

  @override
  String get scanStepFinger => 'Impronte delle foto';

  @override
  String get scanStepCompare => 'Confronto degli scatti simili';

  @override
  String get scanStepGroup => 'Raggruppamento e classifica';

  @override
  String get scanStatusDone => 'fatto';

  @override
  String get scanStatusNext => 'prossimo';

  @override
  String get scanCountGroups => 'gruppi';

  @override
  String get scanCountShots => 'screenshot';

  @override
  String get scanCountFound => 'trovati finora';

  @override
  String get scanPrivacy =>
      'Analizzato su questo dispositivo. Non viene caricato nulla.';

  @override
  String get scanPausedNote => 'In pausa. I progressi sono salvati.';

  @override
  String get scanPause => 'Metti in pausa';

  @override
  String get scanResume => 'Riprendi';

  @override
  String get scanLater => 'Dopo';

  @override
  String get modeGrid => 'Griglia';

  @override
  String get modeSwipe => 'Swipe';

  @override
  String get modeMonths => 'Mesi';

  @override
  String groupsMonthLine(String groups, String size) {
    return '$groups · risparmio $size';
  }

  @override
  String get videoPlay => 'Riproduci il video';

  @override
  String get videoPause => 'Metti in pausa il video';

  @override
  String get videoFailed => 'Impossibile riprodurre questo video';

  @override
  String get storUpdated => 'Aggiornato ora';

  @override
  String get storSafeLabel => 'PUOI LIBERARE IN SICUREZZA';

  @override
  String storOfTotal(String size) {
    return 'dei $size occupati da foto e video';
  }

  @override
  String get storCutMonths => 'Mesi';

  @override
  String get storCutTypes => 'Tipi';

  @override
  String get storCutSources => 'Fonti';

  @override
  String get storLegend => 'la parte che puoi eliminare in questo blocco';

  @override
  String storClear(String size) {
    return 'eliminabili $size';
  }

  @override
  String get storReview => 'Rivedi questo blocco';

  @override
  String get storQuickTitle => 'Pulizie rapide';

  @override
  String get storQuickSub => 'Sicure da eliminare, un tocco ciascuna';

  @override
  String storQuickTotal(String size) {
    return '$size in totale';
  }

  @override
  String get storSafe => 'SICURO';

  @override
  String get storClean => 'Pulisci';

  @override
  String get storEarlier => 'Prima';

  @override
  String storEarlierSub(String month, String n) {
    return 'prima di $month · $n file';
  }

  @override
  String storMonthSub(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString foto e video',
      one: '1 foto o video',
    );
    return '$_temp0';
  }

  @override
  String get storTypeVideos => 'Video';

  @override
  String get storTypePhotos => 'Foto';

  @override
  String get storTypeChat => 'Chat';

  @override
  String get storTypeShots => 'Screenshot';

  @override
  String get storTypeRecs => 'Reg. schermo';

  @override
  String storSubVideos(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString clip',
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
      other: '$nString foto',
      one: '1 foto',
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
      other: '$nString file dai messenger',
      one: '1 file dai messenger',
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
      other: '$nString screenshot',
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
      other: '$nString registrazioni',
      one: '1 registrazione',
    );
    return '$_temp0';
  }

  @override
  String get storSrcCamera => 'Fotocamera';

  @override
  String get storSrcDownloads => 'Download';

  @override
  String get storSrcOther => 'Altro';

  @override
  String get storSubCamera => 'scattate con questo telefono';

  @override
  String get storSubChatSrc => 'media ricevuti e inviati';

  @override
  String get storSubShotsSrc => 'catture dello schermo';

  @override
  String get storSubDownloads => 'salvati dal browser';

  @override
  String get storSubInstagram => 'post e storie salvati';

  @override
  String get storSubOther => 'tutto il resto';

  @override
  String get qwOldShots => 'Vecchi screenshot';

  @override
  String get qwOldShotsSub => 'Più vecchi di 90 giorni, mai riaperti';

  @override
  String get qwBlurry => 'Mosse e scure';

  @override
  String get qwBlurrySub => 'Fuori fuoco o quasi nere';

  @override
  String get qwChat => 'Avanzi delle chat';

  @override
  String get qwChatSub => 'Meme e inoltrati che hai già in una chat';

  @override
  String get qwRecs => 'Registrazioni lunghe';

  @override
  String get qwRecsSub => 'Oltre un minuto, salvate mesi fa';

  @override
  String get qwDups => 'Duplicati esatti';

  @override
  String get qwDupsSub => 'File identici, resta la copia più vecchia';

  @override
  String get sessTitle => 'Sessione di pulizia';

  @override
  String get sessSub =>
      'Un giro veloce tra le tue foto più vecchie.\nNessuna fretta, fermati quando vuoi.';

  @override
  String sessDays(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String sessPhotosAbout(int m) {
    final intl.NumberFormat mNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String mString = mNumberFormat.format(m);

    return 'foto · circa $mString min';
  }

  @override
  String get sessWeek => 'Questa settimana';

  @override
  String sessBest(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'record: $nString giorni',
      one: 'record: 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get sessFreeze => '1 congelamento';

  @override
  String get sessFreezeSub =>
      'copre un giorno saltato, così una settimana piena non spezza la serie';

  @override
  String get sessFreezeUsed =>
      'Il congelamento di questa settimana è già usato';

  @override
  String get sessMonths => 'Mesi sistemati';

  @override
  String get sessOldestFirst => 'prima i più vecchi';

  @override
  String sessStartsWith(String month) {
    return 'Si parte da $month · prima le foto simili, poi il resto';
  }

  @override
  String sessStart(String photos) {
    return 'Via · $photos';
  }

  @override
  String get sessNothing => 'È tutto sistemato';

  @override
  String get sessEntryNoStreak => 'Inizia la tua serie';

  @override
  String get sessEntrySub => 'Un giro veloce tra le tue foto più vecchie';

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
  String get remTitle => 'Promemoria giornaliero';

  @override
  String get remSub =>
      'Un promemoria nei giorni in cui non hai ancora sistemato nulla';

  @override
  String get remTime => 'Orario';

  @override
  String get remNeedPerm => 'Consenti le notifiche per ricevere i promemoria';

  @override
  String get remAllow => 'Consenti';

  @override
  String get remNotifTitle => 'È ora di una pulizia veloce';

  @override
  String get remNotifBody => 'Un minuto per le tue foto? Mantieni la serie.';

  @override
  String get remChannel => 'Promemoria';

  @override
  String doneSwept(String photos, String time) {
    return '$photos sistemate in $time';
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
  String get doneInTrash => 'NEL CESTINO';

  @override
  String doneInTrashSub(String unit, String files) {
    return '$unit · $files';
  }

  @override
  String get doneKept => 'TENUTE';

  @override
  String get donePhotosStay => 'foto restano';

  @override
  String doneStreak(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Serie di $nString giorni';
  }

  @override
  String doneStreakUp(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'uno in più di ieri · record: $bestString';
  }

  @override
  String doneStreakNew(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'un nuovo inizio · record: $bestString';
  }

  @override
  String doneStreakSame(int best) {
    final intl.NumberFormat bestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bestString = bestNumberFormat.format(best);

    return 'già contato oggi · record: $bestString';
  }

  @override
  String doneMonthProgress(int from, int to) {
    final intl.NumberFormat fromNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String fromString = fromNumberFormat.format(from);
    final intl.NumberFormat toNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String toString = toNumberFormat.format(to);

    return 'dal $fromString% al $toString%';
  }

  @override
  String doneLeft(String photos, String month) {
    return '$photos rimaste a $month. ';
  }

  @override
  String doneMoreSessions(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ancora circa $nString sessioni e hai finito',
      one: 'Ancora circa 1 sessione e hai finito',
    );
    return '$_temp0';
  }

  @override
  String doneMonthDone(String month) {
    return '$month è tutto sistemato!';
  }

  @override
  String get doneNote =>
      'Le foto restano nel cestino di Sweeep per 30 giorni. Dal telefono non esce nulla finché non lo svuoti.';

  @override
  String get doneDone => 'Fatto';

  @override
  String doneAnother(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Altre $nString';
  }

  @override
  String get limTitle => 'Sweeep vede solo le foto che hai scelto';

  @override
  String get limSub => 'Consenti tutto per pulire l\'intera libreria.';

  @override
  String get limAllow => 'Consenti tutto';

  @override
  String get wrapLabel => 'RIEPILOGO DEL MESE';

  @override
  String get wrapSwept => '100% SISTEMATO';

  @override
  String wrapLooked(String photos) {
    return '$photos riviste';
  }

  @override
  String wrapCleared(String unit) {
    return '$unit liberati';
  }

  @override
  String get wrapBest => 'LE TUE MIGLIORI DEL MESE';

  @override
  String get wrapKept => 'tenute';

  @override
  String get wrapTrashed => 'eliminate';

  @override
  String wrapSessions(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'sessioni',
      one: 'sessione',
    );
    return '$_temp0';
  }

  @override
  String get wrapStreak => 'serie';

  @override
  String get wrapNote =>
      'L\'immagine viene creata sul tuo telefono. Non viene caricato nulla, a meno che tu non scelga di condividerla.';

  @override
  String get wrapSave => 'Salva immagine';

  @override
  String wrapNext(String month) {
    return 'Avanti: $month';
  }

  @override
  String get wrapSaved => 'Salvata in Pictures/Sweeep';

  @override
  String get wrapSaveFailed => 'Impossibile salvare l\'immagine';

  @override
  String get goalLabel => 'MI SERVONO';

  @override
  String get goalSub =>
      'Sweeep sceglie prima i file più sicuri e si ferma quando ne hai abbastanza.';

  @override
  String goalPicked(String size) {
    return '$size selezionati';
  }

  @override
  String get goalReached => 'obiettivo raggiunto';

  @override
  String goalAllFound(String size) {
    return 'è tutto ciò che abbiamo trovato: $size';
  }

  @override
  String get goalWhatFirst => 'Cosa va per primo';

  @override
  String get goalSafestTop => 'in alto i più sicuri';

  @override
  String get goalNote =>
      'Prima confermi la lista. I file vanno nel cestino di Sweeep per 30 giorni.';

  @override
  String goalReview(String size) {
    return 'Controlla la lista · $size';
  }

  @override
  String get goalReviewTitle => 'Controlla la lista';

  @override
  String get goalSubDup => 'File identici';

  @override
  String get goalSubOldShots => 'Più vecchi di 90 giorni';

  @override
  String get goalSubBlurry => 'Guarda le prime';

  @override
  String get goalSubChat => 'Già presenti in una chat';

  @override
  String get goalSubRecs => 'Oltre un minuto, vecchie di mesi';

  @override
  String get goalSubSimilar => 'La migliore resta, decidi tu';

  @override
  String get goalEntryTitle => 'Mi serve spazio';

  @override
  String get goalEntrySub =>
      'Scegli un obiettivo, Sweeep trova i file più sicuri';

  @override
  String get navSpace => 'Spazio';

  @override
  String get tipHub => 'Hub';

  @override
  String get hubTitle => 'Hub';

  @override
  String get hubVersion => 'Sweeep 1.0';

  @override
  String get proTag => 'SWEEEP PRO';

  @override
  String get proTitle => 'Tutti i cleaner, senza limiti';

  @override
  String get proSub =>
      'Sessioni illimitate, pulizie rapide e compressione video.';

  @override
  String get proButton => 'Vedi i piani';

  @override
  String get proSoon => 'I piani arriveranno presto';

  @override
  String get hubMore => 'ALTRI CLEANER';

  @override
  String get cleanerEmail => 'Email';

  @override
  String get cleanerEmailSub => 'Newsletter e spazzatura';

  @override
  String get cleanerApps => 'App';

  @override
  String get cleanerAppsSub => 'Inutilizzate e pesanti';

  @override
  String get cleanerCache => 'Cache';

  @override
  String get cleanerCacheSub => 'File temporanei';

  @override
  String get soonBadge => 'PRESTO';

  @override
  String get soonWord => 'Presto';

  @override
  String get hubTools => 'STRUMENTI';

  @override
  String get hubWater => 'Espelli l\'acqua';

  @override
  String get hubWaterSub => 'Tono dall\'altoparlante, 165-200 Hz';

  @override
  String get hubDust => 'Scuoti via la polvere';

  @override
  String get hubDustSub => 'Tono pulsante basso per la griglia';

  @override
  String get hubSound => 'Test audio';

  @override
  String get hubSoundSub => 'Sinistra, destra e sweep';

  @override
  String get hubInsights => 'RIEPILOGHI';

  @override
  String get hubWeek => 'La tua settimana';

  @override
  String get hubWeekSub => 'Spazio liberato e serie';

  @override
  String get hubWidgets => 'Widget per la home';

  @override
  String get hubWidgetsSub => 'Serie e obiettivo del giorno';

  @override
  String get hubSettings => 'IMPOSTAZIONI';

  @override
  String get hubLanguage => 'Lingua';

  @override
  String get langAuto => 'Auto';

  @override
  String hubRemindOn(String time) {
    return 'Ogni giorno alle $time';
  }

  @override
  String get hubRemindOff => 'Disattivato';

  @override
  String get hubAccess => 'Accesso alle foto';

  @override
  String get hubAccessAll => 'Tutte le foto e i video';

  @override
  String get hubAccessLimited => 'Solo le foto selezionate';

  @override
  String get hubAccessNone => 'Nessun accesso';

  @override
  String get hubScan => 'Analizza di nuovo';

  @override
  String hubScanSub(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString file indicizzati',
      one: '1 file indicizzato',
    );
    return '$_temp0';
  }

  @override
  String get hubFoot1 =>
      'Tutto viene analizzato su questo telefono. Non viene caricato nulla.';

  @override
  String get hubFoot2 =>
      'Tieni premuto il numero di versione per la schermata sviluppatore.';

  @override
  String get spaceTitle => 'Spazio';

  @override
  String spaceCanGo(String unit) {
    return '$unit da liberare';
  }

  @override
  String spaceFind(String size) {
    return 'Trova $size dei file più sicuri';
  }

  @override
  String get spaceMap => 'Mappa dello spazio';

  @override
  String get spaceOpen => 'Apri';

  @override
  String get spaceShrink => 'Comprimi i video';

  @override
  String get toolsWater => 'Acqua';

  @override
  String get toolsDust => 'Polvere';

  @override
  String get toolsSound => 'Test audio';

  @override
  String get toolsSweepStatus => 'Sweep · da 20 Hz a 20 kHz';

  @override
  String get toolsLeftOnly => 'Solo altoparlante sinistro';

  @override
  String get toolsRightOnly => 'Solo altoparlante destro';

  @override
  String get toolsSteady => 'Tono continuo';

  @override
  String toolsPulsing(String tail) {
    return 'Tono pulsante · $tail';
  }

  @override
  String toolsTimeLeft(String time) {
    return 'ancora $time';
  }

  @override
  String get toolsFrequency => 'Frequenza';

  @override
  String get toolsEject => 'Espelli l\'acqua';

  @override
  String get toolsShake => 'Scuoti via la polvere';

  @override
  String get toolsPlay => 'Riproduci il tono';

  @override
  String get toolsStop => 'Stop';

  @override
  String get toolsBoth => 'Entrambi';

  @override
  String get toolsLeft => 'Sinistro';

  @override
  String get toolsRight => 'Destro';

  @override
  String get toolsBass => 'Bassi 60 Hz';

  @override
  String get toolsTreble => 'Acuti 8 kHz';

  @override
  String get toolsSweep => 'Sweep';

  @override
  String get toolsWarning =>
      'Parti con il volume basso e tieni il telefono lontano dall\'orecchio. I risultati non sono garantiti.';

  @override
  String get appsTitle => 'Pulizia app';

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
      other: '$nString app',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get appsUnusedLabel => 'NON APERTE DA 60+ GIORNI';

  @override
  String get appsAllLabel => 'TUTTE LE APP';

  @override
  String appsUnusedIn(int n, String unit) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$unit in $nString app',
      one: '$unit in 1 app',
    );
    return '$_temp0';
  }

  @override
  String appsOfTotal(String size) {
    return 'su $size usati da tutte le app. Le dimensioni includono i dati.';
  }

  @override
  String appsOfTotalApk(String size) {
    return 'su $size usati da tutte le app. Solo i file, senza dati.';
  }

  @override
  String get appsSortSize => 'Più grandi';

  @override
  String get appsSortUnused => 'Inutilizzate';

  @override
  String get appsSortRecent => 'Recenti';

  @override
  String appsAgeDays(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Non aperta da $nString giorni',
      one: 'Non aperta da 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get appsOpenedToday => 'Aperta oggi';

  @override
  String get appsNeverOpened => 'Mai aperta';

  @override
  String get appsOpenedYesterday => 'Aperta ieri';

  @override
  String get appsUninstallNote =>
      'Android chiede di confermare ogni disinstallazione.';

  @override
  String appsUninstall(int n, String size) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Disinstalla $nString · libera $size';
  }

  @override
  String get appsEmpty => 'Nessuna app da mostrare';

  @override
  String get appsNoAccess =>
      'Solo dimensioni. Consenti l\'accesso all\'utilizzo per vedere quali app non usi.';

  @override
  String get appsAllowAccess => 'Mostra le app inutilizzate';

  @override
  String appsUninstallFail(String name) {
    return 'Impossibile rimuovere $name';
  }

  @override
  String get usageTitle => 'Scopri quali app hai dimenticato';

  @override
  String get usageSub =>
      'Per distinguere le app usate da quelle dimenticate, Android ha bisogno del tuo OK una volta.';

  @override
  String get usageDoneTitle => 'Tutto pronto';

  @override
  String get usageDoneSub =>
      'Ora Sweeep sa quali app restano inutilizzate. Nulla lascia il telefono.';

  @override
  String get usageReadLabel => 'LEGGIAMO';

  @override
  String get usageReadText =>
      'La data dell\'ultima apertura di ogni app e quanto spazio occupa.';

  @override
  String get usageNeverLabel => 'NON FACCIAMO MAI';

  @override
  String get usageNeverText =>
      'Non vediamo cosa fai dentro un\'app, non inviamo nulla fuori dal telefono e non rimuoviamo un\'app senza il tuo tocco.';

  @override
  String get usageCanLabel => 'PUOI';

  @override
  String get usageCanText =>
      'Disattivarlo in qualsiasi momento nelle impostazioni di Android. Le dimensioni funzionano anche senza.';

  @override
  String get usageOpen => 'Apri le impostazioni di Android';

  @override
  String get usageSee => 'Vedi le mie app';

  @override
  String get usageSkip => 'Salta, mostra solo le dimensioni';

  @override
  String get weekLabelNow => 'LA TUA SETTIMANA';

  @override
  String get weekLabelPast => 'RIEPILOGO SETTIMANA';

  @override
  String get weekPrev => 'Settimana precedente';

  @override
  String get weekNext => 'Settimana successiva';

  @override
  String weekRange(String a, String b) {
    return '$a – $b';
  }

  @override
  String weekCleared(String unit) {
    return '$unit liberati';
  }

  @override
  String weekMore(int pct) {
    final intl.NumberFormat pctNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pctString = pctNumberFormat.format(pct);

    return '$pctString% in più della settimana prima';
  }

  @override
  String weekLess(int pct) {
    final intl.NumberFormat pctNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pctString = pctNumberFormat.format(pct);

    return '$pctString% in meno della settimana prima';
  }

  @override
  String get weekSame => 'Come la settimana prima';

  @override
  String get weekFirst => 'Prima settimana registrata';

  @override
  String get weekNothingBefore => 'Niente liberato la settimana prima';

  @override
  String get weekChartTitle => 'Foto sfogliate al giorno';

  @override
  String weekGoal(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'obiettivo $nString';
  }

  @override
  String weekPhotosSwept(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString foto sfogliate',
      one: '1 foto sfogliata',
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
      other: '$nString sessioni',
      one: '1 sessione',
    );
    return '$_temp0';
  }

  @override
  String weekDaySub(String a, String b) {
    return '$a · $b';
  }

  @override
  String get weekNoSession => 'Nessuna sessione questo giorno';

  @override
  String get weekClearedWord => 'liberati';

  @override
  String weekStreak(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString giorni di fila',
      one: '1 giorno di fila',
    );
    return '$_temp0';
  }

  @override
  String weekGoalsHit(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return '$nString giorni su 7 hanno raggiunto l\'obiettivo';
  }

  @override
  String get weekSwept => 'SFOGLIATE';

  @override
  String get weekKept => 'TENUTE';

  @override
  String get weekClearedCaps => 'LIBERATE';

  @override
  String get weekWhatWent => 'Cosa è andato via';

  @override
  String get catDuplicates => 'Duplicati';

  @override
  String get catSimilar => 'Foto simili';

  @override
  String get catScreenshots => 'Screenshot';

  @override
  String get catBlurry => 'Sfocate e scure';

  @override
  String get catOther => 'Altro';

  @override
  String get weekStorage => 'Memoria del telefono';

  @override
  String weekStorageFromTo(int a, int b) {
    final intl.NumberFormat aNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String aString = aNumberFormat.format(a);
    final intl.NumberFormat bNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bString = bNumberFormat.format(b);

    return 'dal $aString% al $bString%';
  }

  @override
  String weekStorageNow(int p) {
    final intl.NumberFormat pNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pString = pNumberFormat.format(p);

    return '$pString% occupato';
  }

  @override
  String weekStorageNote(String size) {
    return 'Lo spazio si libera solo dopo aver svuotato il cestino di Sweeep. Ora ci sono $size.';
  }

  @override
  String weekHubSub(String size, String streak) {
    return '$size liberati, $streak';
  }

  @override
  String weekSpaceSub(String size) {
    return '$size liberati questa settimana';
  }

  @override
  String weekSpaceSubMore(String size, int pct) {
    final intl.NumberFormat pctNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pctString = pctNumberFormat.format(pct);

    return '$size liberati, $pctString% in più della settimana scorsa';
  }

  @override
  String wOfToday(int goal) {
    final intl.NumberFormat goalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String goalString = goalNumberFormat.format(goal);

    return '/ $goalString oggi';
  }

  @override
  String wLeftStreak(int left, int n) {
    final intl.NumberFormat leftNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String leftString = leftNumberFormat.format(left);
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Ne mancano $leftString per $nString giorni di fila';
  }

  @override
  String get wGoalReached => 'Obiettivo di oggi raggiunto';

  @override
  String get wStreakNone => 'Nessuna serie per ora';

  @override
  String get wContinue => 'Continua';

  @override
  String wSwipeNow(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'Sfoglia $nString ora';
  }

  @override
  String wAbout(int n) {
    final intl.NumberFormat nNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String nString = nNumberFormat.format(n);

    return 'circa $nString min';
  }

  @override
  String get wCanFree => 'PUOI LIBERARE';

  @override
  String get wTapMap => 'Tocca per aprire la mappa della memoria';

  @override
  String get wEmpty => 'Apri Sweeep per iniziare';

  @override
  String get widgetsTitle => 'Widget';

  @override
  String get widgetsNote =>
      'I widget leggono i numeri dal database sul telefono e aprono l\'app al tocco. Mostrano solo numeri, mai foto, così sulla schermata home non resta nulla di privato.';

  @override
  String get widgetToday => 'WIDGET 4×2 · OGGI';

  @override
  String get widgetOneMin => 'WIDGET 2×2 · UN MINUTO';

  @override
  String get widgetCanFree => 'WIDGET 2×2 · PUOI LIBERARE';

  @override
  String get widgetAdd => 'Aggiungi alla schermata home';

  @override
  String get widgetAdded => 'Aggiunto';

  @override
  String get widgetHowTo => 'Tieni premuta la schermata home, Widget, Sweeep';

  @override
  String wLeftGoal(int left) {
    final intl.NumberFormat leftNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String leftString = leftNumberFormat.format(left);

    return 'Ne mancano $leftString all\'obiettivo di oggi';
  }
}
