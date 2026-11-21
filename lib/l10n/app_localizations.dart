import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('vi'),
  ];

  /// No description provided for @actionHintDaily.
  ///
  /// In en, this message translates to:
  /// **'Hint ({count}/1)'**
  String actionHintDaily(int count);

  /// No description provided for @actionHintMultiple.
  ///
  /// In en, this message translates to:
  /// **'Hint ({count})'**
  String actionHintMultiple(int count);

  /// No description provided for @actionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get actionRestart;

  /// No description provided for @actionUndoAvailable.
  ///
  /// In en, this message translates to:
  /// **'Undo (1/1)'**
  String get actionUndoAvailable;

  /// No description provided for @actionUndoUsed.
  ///
  /// In en, this message translates to:
  /// **'Undo (0/1)'**
  String get actionUndoUsed;

  /// No description provided for @adLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get adLoading;

  /// No description provided for @adNotReady.
  ///
  /// In en, this message translates to:
  /// **'Ad is not ready yet. Please try again in a moment.'**
  String get adNotReady;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Mathematical logic puzzle game based on the Graph Coloring Problem. Challenge your logical thinking across 6 Chapters with 180 handcrafted levels.'**
  String get appDescription;

  /// No description provided for @appLegalese.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Graph Coloring Game.\nOpen source compliant with respective component licenses.'**
  String get appLegalese;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Graph Coloring'**
  String get appName;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @boardRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Board refreshed!'**
  String get boardRefreshed;

  /// No description provided for @buttonBackToCampaign.
  ///
  /// In en, this message translates to:
  /// **'Back to Levels'**
  String get buttonBackToCampaign;

  /// No description provided for @buttonBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get buttonBackToHome;

  /// No description provided for @buttonCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get buttonCampaign;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get buttonClose;

  /// No description provided for @buttonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// No description provided for @buttonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get buttonGotIt;

  /// No description provided for @buttonLater.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get buttonLater;

  /// No description provided for @buttonNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get buttonNextLevel;

  /// No description provided for @buttonNextLevelWithIndex.
  ///
  /// In en, this message translates to:
  /// **'Next Level ({overallIndex})'**
  String buttonNextLevelWithIndex(int overallIndex);

  /// No description provided for @buttonReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get buttonReplay;

  /// No description provided for @buttonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get buttonReset;

  /// No description provided for @buttonRestartCost.
  ///
  /// In en, this message translates to:
  /// **'Restart (-1 ⚡)'**
  String get buttonRestartCost;

  /// No description provided for @buttonRetryLevel.
  ///
  /// In en, this message translates to:
  /// **'Retry This Level'**
  String get buttonRetryLevel;

  /// No description provided for @buttonReviveWithShields.
  ///
  /// In en, this message translates to:
  /// **'Revive (+2 Mistake Shields 🛡️)'**
  String get buttonReviveWithShields;

  /// No description provided for @buttonViewLicenses.
  ///
  /// In en, this message translates to:
  /// **'View Open Source Licenses'**
  String get buttonViewLicenses;

  /// No description provided for @buttonWatchAdEnergy.
  ///
  /// In en, this message translates to:
  /// **'Watch Video (+1 ⚡)'**
  String get buttonWatchAdEnergy;

  /// No description provided for @buttonWatchAdHint.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad (+1 Hint)'**
  String get buttonWatchAdHint;

  /// No description provided for @campaignBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'180 handcrafted logic puzzle levels.'**
  String get campaignBannerSubtitle;

  /// No description provided for @campaignBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'6-Chapter Campaign'**
  String get campaignBannerTitle;

  /// No description provided for @chapter1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn adjacency rules and basic coloring'**
  String get chapter1Subtitle;

  /// No description provided for @chapter1Title.
  ///
  /// In en, this message translates to:
  /// **'First Connection'**
  String get chapter1Title;

  /// No description provided for @chapter2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage color inventory and avoid dead ends'**
  String get chapter2Subtitle;

  /// No description provided for @chapter2Title.
  ///
  /// In en, this message translates to:
  /// **'Color Balance'**
  String get chapter2Title;

  /// No description provided for @chapter3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Strategic thinking around locked nodes'**
  String get chapter3Subtitle;

  /// No description provided for @chapter3Title.
  ///
  /// In en, this message translates to:
  /// **'Locked Connections'**
  String get chapter3Title;

  /// No description provided for @chapter4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complex network and logical bottlenecks'**
  String get chapter4Subtitle;

  /// No description provided for @chapter4Title.
  ///
  /// In en, this message translates to:
  /// **'Complex Network'**
  String get chapter4Title;

  /// No description provided for @chapter5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Color set restrictions per node'**
  String get chapter5Subtitle;

  /// No description provided for @chapter5Title.
  ///
  /// In en, this message translates to:
  /// **'Restricted Choices'**
  String get chapter5Title;

  /// No description provided for @chapter6Subtitle.
  ///
  /// In en, this message translates to:
  /// **'The ultimate challenge combining all mechanics'**
  String get chapter6Subtitle;

  /// No description provided for @chapter6Title.
  ///
  /// In en, this message translates to:
  /// **'Master Network'**
  String get chapter6Title;

  /// No description provided for @chapterHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter {id}: {title}'**
  String chapterHeaderTitle(int id, String title);

  /// No description provided for @chapterLevelsProgress.
  ///
  /// In en, this message translates to:
  /// **'Levels: {completed}/{total}'**
  String chapterLevelsProgress(int completed, int total);

  /// No description provided for @chapterShort.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapterId}'**
  String chapterShort(int chapterId);

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorSymbolBlue.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get colorSymbolBlue;

  /// No description provided for @colorSymbolGreen.
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get colorSymbolGreen;

  /// No description provided for @colorSymbolPurple.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get colorSymbolPurple;

  /// No description provided for @colorSymbolRed.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get colorSymbolRed;

  /// No description provided for @colorSymbolYellow.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get colorSymbolYellow;

  /// No description provided for @coloredLinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Colored Lines'**
  String get coloredLinesLabel;

  /// No description provided for @coloredLinesOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn off colored lines'**
  String get coloredLinesOnTooltip;

  /// No description provided for @coloredLinesOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn on colored lines'**
  String get coloredLinesOffTooltip;

  /// No description provided for @coloredLinesAdDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'DAILY COLORED LINES'**
  String get coloredLinesAdDialogTitle;

  /// No description provided for @coloredLinesDefaultNeed.
  ///
  /// In en, this message translates to:
  /// **'You get {max} free Colored Lines turns each day.\nWatch a short video ad to get +1 turn and enable Colored Lines!'**
  String coloredLinesDefaultNeed(int max);

  /// No description provided for @coloredLinesDefaultWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video ad to get +1 turn and enable Colored Lines!'**
  String get coloredLinesDefaultWatch;

  /// No description provided for @coloredLinesOutOfFreeDaily.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all {max} free Colored Lines turns today!\nWatch a short video ad to get +1 turn and enable Colored Lines.'**
  String coloredLinesOutOfFreeDaily(int max);

  /// No description provided for @coloredLinesQuotaBadge.
  ///
  /// In en, this message translates to:
  /// **'Line turns: {count}/5'**
  String coloredLinesQuotaBadge(int count);

  /// No description provided for @coloredLinesRewardSuccess.
  ///
  /// In en, this message translates to:
  /// **'Earned +1 Colored Lines turn and enabled!'**
  String get coloredLinesRewardSuccess;

  /// No description provided for @coloredLinesWatchAdToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad (+1 Turn)'**
  String get coloredLinesWatchAdToUnlock;

  /// No description provided for @coloredLinesExhaustedToast.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all 5 Colored Lines turns today. Watch an ad to unlock more!'**
  String get coloredLinesExhaustedToast;

  /// No description provided for @completedCountText.
  ///
  /// In en, this message translates to:
  /// **'Completed: {count}/30'**
  String completedCountText(int count);

  /// No description provided for @energyAdDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'DAILY ENERGY'**
  String get energyAdDialogTitle;

  /// No description provided for @energyDefaultFull.
  ///
  /// In en, this message translates to:
  /// **'Your Energy is at maximum ({max}/{max}). Enjoy playing freely!'**
  String energyDefaultFull(int max);

  /// No description provided for @energyDefaultNeed.
  ///
  /// In en, this message translates to:
  /// **'You need Energy to restart this puzzle.\nWatch a short video ad to restore +1 Energy (up to {max}/{max})!'**
  String energyDefaultNeed(int max);

  /// No description provided for @energyDefaultWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video ad to restore +1 Energy (up to {max}/{max})!'**
  String energyDefaultWatch(int max);

  /// No description provided for @energyReasonContinue.
  ///
  /// In en, this message translates to:
  /// **'You are out of Energy to continue this puzzle.\nWatch a video ad to restore +1 Energy and keep solving!'**
  String get energyReasonContinue;

  /// No description provided for @energyReasonOutOfEnergy.
  ///
  /// In en, this message translates to:
  /// **'You are out of Energy. Watch an ad to get +1 Energy!'**
  String get energyReasonOutOfEnergy;

  /// No description provided for @energyReasonPlay.
  ///
  /// In en, this message translates to:
  /// **'You are out of Energy to play this level.\nWatch a video ad to restore +1 Energy and start solving!'**
  String get energyReasonPlay;

  /// No description provided for @energyReasonRestart.
  ///
  /// In en, this message translates to:
  /// **'You need at least 1 Energy to restart this level.\nWatch a short video ad to restore +1 Energy and keep playing!'**
  String get energyReasonRestart;

  /// No description provided for @energyReasonRetry.
  ///
  /// In en, this message translates to:
  /// **'You are out of Energy to retry this level.\nWatch a video ad to restore +1 Energy and challenge again!'**
  String get energyReasonRetry;

  /// No description provided for @energyResetSchedule.
  ///
  /// In en, this message translates to:
  /// **'Auto-restores 3/3 at 00:00 (VN time)'**
  String get energyResetSchedule;

  /// No description provided for @energyRewardSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recharged +1 ⚡ successfully!'**
  String get energyRewardSuccess;

  /// No description provided for @errorAdjacentSameColor.
  ///
  /// In en, this message translates to:
  /// **'Connected nodes cannot have the same color!'**
  String get errorAdjacentSameColor;

  /// No description provided for @errorAllNodesColored.
  ///
  /// In en, this message translates to:
  /// **'All nodes are already colored!'**
  String get errorAllNodesColored;

  /// No description provided for @errorCannotEraseLocked.
  ///
  /// In en, this message translates to:
  /// **'Cannot erase color from a locked node!'**
  String get errorCannotEraseLocked;

  /// No description provided for @errorDeadEndNoSolution.
  ///
  /// In en, this message translates to:
  /// **'Dead end, no solution remains!'**
  String get errorDeadEndNoSolution;

  /// No description provided for @errorInventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'All {color} balls have been used from inventory!'**
  String errorInventoryEmpty(String color);

  /// No description provided for @errorLockedNode.
  ///
  /// In en, this message translates to:
  /// **'Node is locked and cannot change color!'**
  String get errorLockedNode;

  /// No description provided for @errorNoSolutionWithChoice.
  ///
  /// In en, this message translates to:
  /// **'No way to complete with this choice.'**
  String get errorNoSolutionWithChoice;

  /// No description provided for @errorOutOfEnergyAbandon.
  ///
  /// In en, this message translates to:
  /// **'You are out of Energy (0/3). Cannot abandon!'**
  String get errorOutOfEnergyAbandon;

  /// No description provided for @errorOutOfEnergyRestart.
  ///
  /// In en, this message translates to:
  /// **'You are out of Energy (0/3). Energy needed to restart!'**
  String get errorOutOfEnergyRestart;

  /// No description provided for @errorOutOfEnergyRetry.
  ///
  /// In en, this message translates to:
  /// **'You are out of Energy (0/3). Energy needed to retry!'**
  String get errorOutOfEnergyRetry;

  /// No description provided for @errorOutOfMistakes.
  ///
  /// In en, this message translates to:
  /// **'You have used all mistake shields! Level over.'**
  String get errorOutOfMistakes;

  /// No description provided for @errorRestrictedColor.
  ///
  /// In en, this message translates to:
  /// **'This node does not allow {color}!'**
  String errorRestrictedColor(String color);

  /// No description provided for @errorUndoLimit.
  ///
  /// In en, this message translates to:
  /// **'Undo can only be used at most once per level!'**
  String get errorUndoLimit;

  /// No description provided for @finaleBadge.
  ///
  /// In en, this message translates to:
  /// **'FINALE'**
  String get finaleBadge;

  /// No description provided for @gameInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Game Information'**
  String get gameInfoTooltip;

  /// No description provided for @gameOverBannerText.
  ///
  /// In en, this message translates to:
  /// **'Out of mistakes! Please replay this level.'**
  String get gameOverBannerText;

  /// No description provided for @gameOverEnergyBadge.
  ///
  /// In en, this message translates to:
  /// **'Energy: {current}/{max}'**
  String gameOverEnergyBadge(int current, int max);

  /// No description provided for @gameOverMessage.
  ///
  /// In en, this message translates to:
  /// **'You have used all 2 mistakes for this level.\nTry again or watch an ad to get extra mistake shields!'**
  String get gameOverMessage;

  /// No description provided for @gameOverRechargeTag.
  ///
  /// In en, this message translates to:
  /// **'+ Refill ⚡'**
  String get gameOverRechargeTag;

  /// No description provided for @gameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'OUT OF MISTAKES'**
  String get gameOverTitle;

  /// No description provided for @greetingChapter1Finale.
  ///
  /// In en, this message translates to:
  /// **'Chapter 1 Finale: The 5-Color Crown!'**
  String get greetingChapter1Finale;

  /// No description provided for @greetingGreenUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Green Color unlocked! 4-color network appears.'**
  String get greetingGreenUnlocked;

  /// No description provided for @greetingPurpleUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Purple Color unlocked! Conquer the full 5-color spectrum.'**
  String get greetingPurpleUnlocked;

  /// No description provided for @greetingYellowUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Yellow Color unlocked! 3-color challenge begins.'**
  String get greetingYellowUnlocked;

  /// No description provided for @hintAdDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'GET MORE HINTS'**
  String get hintAdDialogTitle;

  /// No description provided for @hintBoardChanged.
  ///
  /// In en, this message translates to:
  /// **'Board has changed and no valid solution remains from this state.'**
  String get hintBoardChanged;

  /// No description provided for @hintCountBadge.
  ///
  /// In en, this message translates to:
  /// **'Hints: {count}'**
  String hintCountBadge(int count);

  /// No description provided for @hintCurrentInstruction.
  ///
  /// In en, this message translates to:
  /// **'Current hint: Color node {nodeId} with {color}.'**
  String hintCurrentInstruction(String color, String nodeId);

  /// No description provided for @hintDefaultNeed.
  ///
  /// In en, this message translates to:
  /// **'You get {max} free hint daily.\nWatch a short video ad to get +1 puzzle hint!'**
  String hintDefaultNeed(int max);

  /// No description provided for @hintDefaultWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video ad to collect +1 puzzle hint!'**
  String get hintDefaultWatch;

  /// No description provided for @hintNoSolutionFound.
  ///
  /// In en, this message translates to:
  /// **'No valid solution found from current state. Try Undo or Restart!'**
  String get hintNoSolutionFound;

  /// No description provided for @hintOutOfFreeDaily.
  ///
  /// In en, this message translates to:
  /// **'You have used all free hints today! Watch an ad to get more.'**
  String get hintOutOfFreeDaily;

  /// No description provided for @hintReceivedToast.
  ///
  /// In en, this message translates to:
  /// **'+1 Hint received! 💡'**
  String get hintReceivedToast;

  /// No description provided for @hintRewardSuccess.
  ///
  /// In en, this message translates to:
  /// **'Received +1 Hint successfully! 💡'**
  String get hintRewardSuccess;

  /// No description provided for @hintSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Hint: Color node {nodeId} with {color}.'**
  String hintSuggestion(String color, String nodeId);

  /// No description provided for @homeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTooltip;

  /// No description provided for @inProgressBadge.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get inProgressBadge;

  /// No description provided for @instructionsBannerText.
  ///
  /// In en, this message translates to:
  /// **'Drag color or tap to select color, then tap node. Tap node to erase.\nMoves leading to a dead end will cost 1 mistake shield.'**
  String get instructionsBannerText;

  /// No description provided for @levelCompletedBannerDescEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned {stars}/3 stars! Color inventory verified.'**
  String levelCompletedBannerDescEarned(int stars);

  /// No description provided for @levelCompletedBannerDescGeneric.
  ///
  /// In en, this message translates to:
  /// **'All nodes validly colored and inventory verified!'**
  String get levelCompletedBannerDescGeneric;

  /// No description provided for @levelCompletedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'LEVEL COMPLETED!{stars}'**
  String levelCompletedBannerTitle(String stars);

  /// No description provided for @levelHeaderFallback.
  ///
  /// In en, this message translates to:
  /// **'Puzzle Level'**
  String get levelHeaderFallback;

  /// No description provided for @levelHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapterId} - Level {levelNumber}: {title}'**
  String levelHeaderTitle(int chapterId, int levelNumber, String title);

  /// No description provided for @levelTitleWithIndex.
  ///
  /// In en, this message translates to:
  /// **'Level {overallIndex}: {title}'**
  String levelTitleWithIndex(int overallIndex, String title);

  /// No description provided for @levelsRange.
  ///
  /// In en, this message translates to:
  /// **'Levels {start} – {end}'**
  String levelsRange(int start, int end);

  /// No description provided for @mistakePenaltyTag.
  ///
  /// In en, this message translates to:
  /// **'-1 MISTAKE'**
  String get mistakePenaltyTag;

  /// No description provided for @mistakesBadge.
  ///
  /// In en, this message translates to:
  /// **'Mistakes: {count}/2'**
  String mistakesBadge(int count);

  /// No description provided for @resetProgressButton.
  ///
  /// In en, this message translates to:
  /// **'Reset All Progress'**
  String get resetProgressButton;

  /// No description provided for @resetProgressConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will clear all game progress, earned stars, and saved sessions, resetting the game to its initial state.'**
  String get resetProgressConfirmMessage;

  /// No description provided for @resetProgressConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset All Progress?'**
  String get resetProgressConfirmTitle;

  /// No description provided for @resetProgressSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'All game progress has been reset to initial state.'**
  String get resetProgressSuccessToast;

  /// No description provided for @restartConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Restarting will consume 1 Energy (remaining: {energy}/{max}).\nAll colored moves will be reset to initial state.'**
  String restartConfirmContent(int energy, int max);

  /// No description provided for @restartConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart this level?'**
  String get restartConfirmTitle;

  /// No description provided for @restartFreeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartFreeTooltip;

  /// No description provided for @revivedSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Revived! Received +2 Mistake Shields 🛡️'**
  String get revivedSuccessToast;

  /// No description provided for @soundOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mute sound'**
  String get soundOffTooltip;

  /// No description provided for @soundOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unmute sound'**
  String get soundOnTooltip;

  /// No description provided for @starsCountText.
  ///
  /// In en, this message translates to:
  /// **'Stars: {stars}/90'**
  String starsCountText(int stars);

  /// No description provided for @statEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get statEnergy;

  /// No description provided for @statLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get statLevels;

  /// No description provided for @statTotalStars.
  ///
  /// In en, this message translates to:
  /// **'Total Stars'**
  String get statTotalStars;

  /// No description provided for @tapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue level'**
  String get tapToContinue;

  /// No description provided for @unlockChapterRequirement.
  ///
  /// In en, this message translates to:
  /// **'Complete Chapter {chapterId} to unlock'**
  String unlockChapterRequirement(int chapterId);

  /// No description provided for @victoryCampaignFinalMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You have conquered all 180 levels of Graph Coloring!'**
  String get victoryCampaignFinalMessage;

  /// No description provided for @victoryCampaignFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'CAMPAIGN CONQUERED!'**
  String get victoryCampaignFinalTitle;

  /// No description provided for @victoryStarsSummary.
  ///
  /// In en, this message translates to:
  /// **'This round: {earned}/3 stars • Record: {best}/3 stars'**
  String victoryStarsSummary(int earned, int best);

  /// No description provided for @victoryTitle.
  ///
  /// In en, this message translates to:
  /// **'LEVEL COMPLETED!'**
  String get victoryTitle;

  /// No description provided for @howToPlayButton.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToPlayButton;

  /// No description provided for @howToPlayTooltip.
  ///
  /// In en, this message translates to:
  /// **'How to Play tutorial'**
  String get howToPlayTooltip;

  /// No description provided for @howToPlayBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Play Graph Coloring'**
  String get howToPlayBannerTitle;

  /// No description provided for @howToPlayBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn rules and tips in 6 easy steps'**
  String get howToPlayBannerSubtitle;

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get tutorialTitle;

  /// No description provided for @tutorialStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String tutorialStepProgress(int current, int total);

  /// No description provided for @tutorialButtonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialButtonNext;

  /// No description provided for @tutorialButtonPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tutorialButtonPrevious;

  /// No description provided for @tutorialButtonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialButtonSkip;

  /// No description provided for @tutorialButtonStart.
  ///
  /// In en, this message translates to:
  /// **'Start Playing'**
  String get tutorialButtonStart;

  /// No description provided for @tutorialStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Graph Coloring'**
  String get tutorialStep1Title;

  /// No description provided for @tutorialStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Mathematical Logic Puzzle'**
  String get tutorialStep1Subtitle;

  /// No description provided for @tutorialStep1Description.
  ///
  /// In en, this message translates to:
  /// **'Graph Coloring is a logic puzzle based on graph theory. Your mission is to color every node in the network while strictly respecting connection rules and color inventory requirements.'**
  String get tutorialStep1Description;

  /// No description provided for @tutorialStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Nodes & Connection Rules'**
  String get tutorialStep2Title;

  /// No description provided for @tutorialStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'The Golden Rule of Coloring'**
  String get tutorialStep2Subtitle;

  /// No description provided for @tutorialStep2Description.
  ///
  /// In en, this message translates to:
  /// **'• Nodes (Circles): Points on the board that need coloring.\n• Edges (Lines): Connections between two nodes. You can toggle colored lines using the toolbar icon (5 free turns daily).\n• Golden Rule: Two directly connected nodes can NEVER share the same color!'**
  String get tutorialStep2Description;

  /// No description provided for @tutorialValidLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get tutorialValidLabel;

  /// No description provided for @tutorialValidDesc.
  ///
  /// In en, this message translates to:
  /// **'Different colors on adjacent nodes'**
  String get tutorialValidDesc;

  /// No description provided for @tutorialConflictLabel.
  ///
  /// In en, this message translates to:
  /// **'Conflict!'**
  String get tutorialConflictLabel;

  /// No description provided for @tutorialConflictDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected nodes cannot have same color'**
  String get tutorialConflictDesc;

  /// No description provided for @tutorialStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Select & Place Colors'**
  String get tutorialStep3Title;

  /// No description provided for @tutorialStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Two intuitive ways to play'**
  String get tutorialStep3Subtitle;

  /// No description provided for @tutorialStep3Description.
  ///
  /// In en, this message translates to:
  /// **'• Tap-to-Select: Tap a color from the inventory at the bottom, then tap any node to place it.\n• Drag & Drop: Touch and drag a color ball directly onto the target node.\n• Remove Color: Tap an already colored node without selecting any color to return it to inventory.'**
  String get tutorialStep3Description;

  /// No description provided for @tutorialTapToSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap or Drag'**
  String get tutorialTapToSelectLabel;

  /// No description provided for @tutorialStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Exact Color Inventory'**
  String get tutorialStep4Title;

  /// No description provided for @tutorialStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Every ball must be used'**
  String get tutorialStep4Subtitle;

  /// No description provided for @tutorialStep4Description.
  ///
  /// In en, this message translates to:
  /// **'• Each level provides an exact number of balls for each color.\n• The number below each color shows remaining balls.\n• To win, you must place 100% of the required balls — no more, no less!'**
  String get tutorialStep4Description;

  /// No description provided for @tutorialInventoryGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal: Use all available balls (0 remaining)'**
  String get tutorialInventoryGoalLabel;

  /// No description provided for @tutorialStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Actions & Mistake Shields'**
  String get tutorialStep5Title;

  /// No description provided for @tutorialStep5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Undo, Hint, Restart & Shields'**
  String get tutorialStep5Subtitle;

  /// No description provided for @tutorialStep5Description.
  ///
  /// In en, this message translates to:
  /// **'• Undo (1/level): Reverse your previous move. Allowed 1 time per level.\n• Hint (1/day): Reveals a guaranteed valid move. Watch ads for extra hints.\n• Restart: Reset board. Free if no balls placed; costs 1 Energy if balls were placed.\n• Mistake Shields (2 🛡️): You can make up to 2 mistakes before Game Over.\n• Colored Lines (5 turns/day): You have 5 free Colored Lines turns each day. When enabled, finishing a level (win or defeat) deducts 1 turn. When exhausted, watch an ad to unlock more.'**
  String get tutorialStep5Description;

  /// No description provided for @tutorialActionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tutorialActionUndo;

  /// No description provided for @tutorialActionHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get tutorialActionHint;

  /// No description provided for @tutorialActionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get tutorialActionRestart;

  /// No description provided for @tutorialActionShields.
  ///
  /// In en, this message translates to:
  /// **'Shields'**
  String get tutorialActionShields;

  /// No description provided for @tutorialStep6Title.
  ///
  /// In en, this message translates to:
  /// **'Victory & Progression'**
  String get tutorialStep6Title;

  /// No description provided for @tutorialStep6Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Solve puzzles and earn stars'**
  String get tutorialStep6Subtitle;

  /// No description provided for @tutorialStep6Description.
  ///
  /// In en, this message translates to:
  /// **'To complete a level:\n1. All nodes are colored.\n2. No adjacent nodes share the same color.\n3. All color counts are exactly satisfied.\nEarn up to 3 Stars across 180 levels in 6 Chapters. Enjoy the game!'**
  String get tutorialStep6Description;

  /// No description provided for @tutorialReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You are ready to play!'**
  String get tutorialReadyTitle;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
