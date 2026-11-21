// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String actionHintDaily(int count) {
    return 'Hint ($count/1)';
  }

  @override
  String actionHintMultiple(int count) {
    return 'Hint ($count)';
  }

  @override
  String get actionRestart => 'Restart';

  @override
  String get actionUndoAvailable => 'Undo (1/1)';

  @override
  String get actionUndoUsed => 'Undo (0/1)';

  @override
  String get adLoading => 'Loading video...';

  @override
  String get adNotReady => 'Ad is not ready yet. Please try again in a moment.';

  @override
  String get appDescription =>
      'Mathematical logic puzzle game based on the Graph Coloring Problem. Challenge your logical thinking across 6 Chapters with 180 handcrafted levels.';

  @override
  String get appLegalese =>
      '© 2026 Graph Coloring Game.\nOpen source compliant with respective component licenses.';

  @override
  String get appName => 'Graph Coloring';

  @override
  String get backTooltip => 'Back';

  @override
  String get boardRefreshed => 'Board refreshed!';

  @override
  String get buttonBackToCampaign => 'Back to Levels';

  @override
  String get buttonBackToHome => 'Back to Home';

  @override
  String get buttonCampaign => 'Campaign';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonClose => 'Close';

  @override
  String get buttonContinue => 'Continue';

  @override
  String get buttonGotIt => 'Got It';

  @override
  String get buttonLater => 'Not Now';

  @override
  String get buttonNextLevel => 'Next Level';

  @override
  String buttonNextLevelWithIndex(int overallIndex) {
    return 'Next Level ($overallIndex)';
  }

  @override
  String get buttonReplay => 'Replay';

  @override
  String get buttonReset => 'Reset';

  @override
  String get buttonRestartCost => 'Restart (-1 ⚡)';

  @override
  String get buttonRetryLevel => 'Retry This Level';

  @override
  String get buttonReviveWithShields => 'Revive (+2 Mistake Shields 🛡️)';

  @override
  String get buttonViewLicenses => 'View Open Source Licenses';

  @override
  String get buttonWatchAdEnergy => 'Watch Video (+1 ⚡)';

  @override
  String get buttonWatchAdHint => 'Watch Ad (+1 Hint)';

  @override
  String get campaignBannerSubtitle => '180 handcrafted logic puzzle levels.';

  @override
  String get campaignBannerTitle => '6-Chapter Campaign';

  @override
  String get chapter1Subtitle => 'Learn adjacency rules and basic coloring';

  @override
  String get chapter1Title => 'First Connection';

  @override
  String get chapter2Subtitle => 'Manage color inventory and avoid dead ends';

  @override
  String get chapter2Title => 'Color Balance';

  @override
  String get chapter3Subtitle => 'Strategic thinking around locked nodes';

  @override
  String get chapter3Title => 'Locked Connections';

  @override
  String get chapter4Subtitle => 'Complex network and logical bottlenecks';

  @override
  String get chapter4Title => 'Complex Network';

  @override
  String get chapter5Subtitle => 'Color set restrictions per node';

  @override
  String get chapter5Title => 'Restricted Choices';

  @override
  String get chapter6Subtitle =>
      'The ultimate challenge combining all mechanics';

  @override
  String get chapter6Title => 'Master Network';

  @override
  String chapterHeaderTitle(int id, String title) {
    return 'Chapter $id: $title';
  }

  @override
  String chapterLevelsProgress(int completed, int total) {
    return 'Levels: $completed/$total';
  }

  @override
  String chapterShort(int chapterId) {
    return 'Chapter $chapterId';
  }

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorRed => 'Red';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorSymbolBlue => 'B';

  @override
  String get colorSymbolGreen => 'G';

  @override
  String get colorSymbolPurple => 'P';

  @override
  String get colorSymbolRed => 'R';

  @override
  String get colorSymbolYellow => 'Y';

  @override
  String get coloredLinesLabel => 'Colored Lines';

  @override
  String get coloredLinesOnTooltip => 'Turn off colored lines';

  @override
  String get coloredLinesOffTooltip => 'Turn on colored lines';

  @override
  String get coloredLinesAdDialogTitle => 'DAILY COLORED LINES';

  @override
  String coloredLinesDefaultNeed(int max) {
    return 'You get $max free Colored Lines turns each day.\nWatch a short video ad to get +1 turn and enable Colored Lines!';
  }

  @override
  String get coloredLinesDefaultWatch =>
      'Watch a short video ad to get +1 turn and enable Colored Lines!';

  @override
  String coloredLinesOutOfFreeDaily(int max) {
    return 'You\'ve used all $max free Colored Lines turns today!\nWatch a short video ad to get +1 turn and enable Colored Lines.';
  }

  @override
  String coloredLinesQuotaBadge(int count) {
    return 'Line turns: $count/5';
  }

  @override
  String get coloredLinesRewardSuccess =>
      'Earned +1 Colored Lines turn and enabled!';

  @override
  String get coloredLinesWatchAdToUnlock => 'Watch Ad (+1 Turn)';

  @override
  String get coloredLinesExhaustedToast =>
      'You\'ve used all 5 Colored Lines turns today. Watch an ad to unlock more!';

  @override
  String completedCountText(int count) {
    return 'Completed: $count/30';
  }

  @override
  String get energyAdDialogTitle => 'DAILY ENERGY';

  @override
  String energyDefaultFull(int max) {
    return 'Your Energy is at maximum ($max/$max). Enjoy playing freely!';
  }

  @override
  String energyDefaultNeed(int max) {
    return 'You need Energy to restart this puzzle.\nWatch a short video ad to restore +1 Energy (up to $max/$max)!';
  }

  @override
  String energyDefaultWatch(int max) {
    return 'Watch a short video ad to restore +1 Energy (up to $max/$max)!';
  }

  @override
  String get energyReasonContinue =>
      'You are out of Energy to continue this puzzle.\nWatch a video ad to restore +1 Energy and keep solving!';

  @override
  String get energyReasonOutOfEnergy =>
      'You are out of Energy. Watch an ad to get +1 Energy!';

  @override
  String get energyReasonPlay =>
      'You are out of Energy to play this level.\nWatch a video ad to restore +1 Energy and start solving!';

  @override
  String get energyReasonRestart =>
      'You need at least 1 Energy to restart this level.\nWatch a short video ad to restore +1 Energy and keep playing!';

  @override
  String get energyReasonRetry =>
      'You are out of Energy to retry this level.\nWatch a video ad to restore +1 Energy and challenge again!';

  @override
  String get energyResetSchedule => 'Auto-restores 3/3 at 00:00 (VN time)';

  @override
  String get energyRewardSuccess => 'Recharged +1 ⚡ successfully!';

  @override
  String get errorAdjacentSameColor =>
      'Connected nodes cannot have the same color!';

  @override
  String get errorAllNodesColored => 'All nodes are already colored!';

  @override
  String get errorCannotEraseLocked => 'Cannot erase color from a locked node!';

  @override
  String get errorDeadEndNoSolution => 'Dead end, no solution remains!';

  @override
  String errorInventoryEmpty(String color) {
    return 'All $color balls have been used from inventory!';
  }

  @override
  String get errorLockedNode => 'Node is locked and cannot change color!';

  @override
  String get errorNoSolutionWithChoice =>
      'No way to complete with this choice.';

  @override
  String get errorOutOfEnergyAbandon =>
      'You are out of Energy (0/3). Cannot abandon!';

  @override
  String get errorOutOfEnergyRestart =>
      'You are out of Energy (0/3). Energy needed to restart!';

  @override
  String get errorOutOfEnergyRetry =>
      'You are out of Energy (0/3). Energy needed to retry!';

  @override
  String get errorOutOfMistakes =>
      'You have used all mistake shields! Level over.';

  @override
  String errorRestrictedColor(String color) {
    return 'This node does not allow $color!';
  }

  @override
  String get errorUndoLimit => 'Undo can only be used at most once per level!';

  @override
  String get finaleBadge => 'FINALE';

  @override
  String get gameInfoTooltip => 'Game Information';

  @override
  String get gameOverBannerText => 'Out of mistakes! Please replay this level.';

  @override
  String gameOverEnergyBadge(int current, int max) {
    return 'Energy: $current/$max';
  }

  @override
  String get gameOverMessage =>
      'You have used all 2 mistakes for this level.\nTry again or watch an ad to get extra mistake shields!';

  @override
  String get gameOverRechargeTag => '+ Refill ⚡';

  @override
  String get gameOverTitle => 'OUT OF MISTAKES';

  @override
  String get greetingChapter1Finale => 'Chapter 1 Finale: The 5-Color Crown!';

  @override
  String get greetingGreenUnlocked =>
      'Green Color unlocked! 4-color network appears.';

  @override
  String get greetingPurpleUnlocked =>
      'Purple Color unlocked! Conquer the full 5-color spectrum.';

  @override
  String get greetingYellowUnlocked =>
      'Yellow Color unlocked! 3-color challenge begins.';

  @override
  String get hintAdDialogTitle => 'GET MORE HINTS';

  @override
  String get hintBoardChanged =>
      'Board has changed and no valid solution remains from this state.';

  @override
  String hintCountBadge(int count) {
    return 'Hints: $count';
  }

  @override
  String hintCurrentInstruction(String color, String nodeId) {
    return 'Current hint: Color node $nodeId with $color.';
  }

  @override
  String hintDefaultNeed(int max) {
    return 'You get $max free hint daily.\nWatch a short video ad to get +1 puzzle hint!';
  }

  @override
  String get hintDefaultWatch =>
      'Watch a short video ad to collect +1 puzzle hint!';

  @override
  String get hintNoSolutionFound =>
      'No valid solution found from current state. Try Undo or Restart!';

  @override
  String get hintOutOfFreeDaily =>
      'You have used all free hints today! Watch an ad to get more.';

  @override
  String get hintReceivedToast => '+1 Hint received! 💡';

  @override
  String get hintRewardSuccess => 'Received +1 Hint successfully! 💡';

  @override
  String hintSuggestion(String color, String nodeId) {
    return 'Hint: Color node $nodeId with $color.';
  }

  @override
  String get homeTooltip => 'Home';

  @override
  String get inProgressBadge => 'IN PROGRESS';

  @override
  String get instructionsBannerText =>
      'Drag color or tap to select color, then tap node. Tap node to erase.\nMoves leading to a dead end will cost 1 mistake shield.';

  @override
  String levelCompletedBannerDescEarned(int stars) {
    return 'Earned $stars/3 stars! Color inventory verified.';
  }

  @override
  String get levelCompletedBannerDescGeneric =>
      'All nodes validly colored and inventory verified!';

  @override
  String levelCompletedBannerTitle(String stars) {
    return 'LEVEL COMPLETED!$stars';
  }

  @override
  String get levelHeaderFallback => 'Puzzle Level';

  @override
  String levelHeaderTitle(int chapterId, int levelNumber, String title) {
    return 'Chapter $chapterId - Level $levelNumber: $title';
  }

  @override
  String levelTitleWithIndex(int overallIndex, String title) {
    return 'Level $overallIndex: $title';
  }

  @override
  String levelsRange(int start, int end) {
    return 'Levels $start – $end';
  }

  @override
  String get mistakePenaltyTag => '-1 MISTAKE';

  @override
  String mistakesBadge(int count) {
    return 'Mistakes: $count/2';
  }

  @override
  String get resetProgressButton => 'Reset All Progress';

  @override
  String get resetProgressConfirmMessage =>
      'This will clear all game progress, earned stars, and saved sessions, resetting the game to its initial state.';

  @override
  String get resetProgressConfirmTitle => 'Reset All Progress?';

  @override
  String get resetProgressSuccessToast =>
      'All game progress has been reset to initial state.';

  @override
  String restartConfirmContent(int energy, int max) {
    return 'Restarting will consume 1 Energy (remaining: $energy/$max).\nAll colored moves will be reset to initial state.';
  }

  @override
  String get restartConfirmTitle => 'Restart this level?';

  @override
  String get restartFreeTooltip => 'Restart';

  @override
  String get revivedSuccessToast => 'Revived! Received +2 Mistake Shields 🛡️';

  @override
  String get soundOffTooltip => 'Mute sound';

  @override
  String get soundOnTooltip => 'Unmute sound';

  @override
  String starsCountText(int stars) {
    return 'Stars: $stars/90';
  }

  @override
  String get statEnergy => 'Energy';

  @override
  String get statLevels => 'Levels';

  @override
  String get statTotalStars => 'Total Stars';

  @override
  String get tapToContinue => 'Tap to continue level';

  @override
  String unlockChapterRequirement(int chapterId) {
    return 'Complete Chapter $chapterId to unlock';
  }

  @override
  String get victoryCampaignFinalMessage =>
      'Congratulations! You have conquered all 180 levels of Graph Coloring!';

  @override
  String get victoryCampaignFinalTitle => 'CAMPAIGN CONQUERED!';

  @override
  String victoryStarsSummary(int earned, int best) {
    return 'This round: $earned/3 stars • Record: $best/3 stars';
  }

  @override
  String get victoryTitle => 'LEVEL COMPLETED!';

  @override
  String get howToPlayButton => 'How to Play';

  @override
  String get howToPlayTooltip => 'How to Play tutorial';

  @override
  String get howToPlayBannerTitle => 'How to Play Graph Coloring';

  @override
  String get howToPlayBannerSubtitle => 'Learn rules and tips in 6 easy steps';

  @override
  String get tutorialTitle => 'How to Play';

  @override
  String tutorialStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get tutorialButtonNext => 'Next';

  @override
  String get tutorialButtonPrevious => 'Previous';

  @override
  String get tutorialButtonSkip => 'Skip';

  @override
  String get tutorialButtonStart => 'Start Playing';

  @override
  String get tutorialStep1Title => 'Welcome to Graph Coloring';

  @override
  String get tutorialStep1Subtitle => 'Mathematical Logic Puzzle';

  @override
  String get tutorialStep1Description =>
      'Graph Coloring is a logic puzzle based on graph theory. Your mission is to color every node in the network while strictly respecting connection rules and color inventory requirements.';

  @override
  String get tutorialStep2Title => 'Nodes & Connection Rules';

  @override
  String get tutorialStep2Subtitle => 'The Golden Rule of Coloring';

  @override
  String get tutorialStep2Description =>
      '• Nodes (Circles): Points on the board that need coloring.\n• Edges (Lines): Connections between two nodes. You can toggle colored lines using the toolbar icon (5 free turns daily).\n• Golden Rule: Two directly connected nodes can NEVER share the same color!';

  @override
  String get tutorialValidLabel => 'Valid';

  @override
  String get tutorialValidDesc => 'Different colors on adjacent nodes';

  @override
  String get tutorialConflictLabel => 'Conflict!';

  @override
  String get tutorialConflictDesc => 'Connected nodes cannot have same color';

  @override
  String get tutorialStep3Title => 'Select & Place Colors';

  @override
  String get tutorialStep3Subtitle => 'Two intuitive ways to play';

  @override
  String get tutorialStep3Description =>
      '• Tap-to-Select: Tap a color from the inventory at the bottom, then tap any node to place it.\n• Drag & Drop: Touch and drag a color ball directly onto the target node.\n• Remove Color: Tap an already colored node without selecting any color to return it to inventory.';

  @override
  String get tutorialTapToSelectLabel => 'Tap or Drag';

  @override
  String get tutorialStep4Title => 'Exact Color Inventory';

  @override
  String get tutorialStep4Subtitle => 'Every ball must be used';

  @override
  String get tutorialStep4Description =>
      '• Each level provides an exact number of balls for each color.\n• The number below each color shows remaining balls.\n• To win, you must place 100% of the required balls — no more, no less!';

  @override
  String get tutorialInventoryGoalLabel =>
      'Goal: Use all available balls (0 remaining)';

  @override
  String get tutorialStep5Title => 'Actions & Mistake Shields';

  @override
  String get tutorialStep5Subtitle => 'Undo, Hint, Restart & Shields';

  @override
  String get tutorialStep5Description =>
      '• Undo (1/level): Reverse your previous move. Allowed 1 time per level.\n• Hint (1/day): Reveals a guaranteed valid move. Watch ads for extra hints.\n• Restart: Reset board. Free if no balls placed; costs 1 Energy if balls were placed.\n• Mistake Shields (2 🛡️): You can make up to 2 mistakes before Game Over.\n• Colored Lines (5 turns/day): You have 5 free Colored Lines turns each day. When enabled, finishing a level (win or defeat) deducts 1 turn. When exhausted, watch an ad to unlock more.';

  @override
  String get tutorialActionUndo => 'Undo';

  @override
  String get tutorialActionHint => 'Hint';

  @override
  String get tutorialActionRestart => 'Restart';

  @override
  String get tutorialActionShields => 'Shields';

  @override
  String get tutorialStep6Title => 'Victory & Progression';

  @override
  String get tutorialStep6Subtitle => 'Solve puzzles and earn stars';

  @override
  String get tutorialStep6Description =>
      'To complete a level:\n1. All nodes are colored.\n2. No adjacent nodes share the same color.\n3. All color counts are exactly satisfied.\nEarn up to 3 Stars across 180 levels in 6 Chapters. Enjoy the game!';

  @override
  String get tutorialReadyTitle => 'You are ready to play!';
}
