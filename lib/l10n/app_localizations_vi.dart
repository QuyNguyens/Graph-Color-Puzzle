// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String actionHintDaily(int count) {
    return 'Gợi ý ($count/1)';
  }

  @override
  String actionHintMultiple(int count) {
    return 'Gợi ý ($count)';
  }

  @override
  String get actionRestart => 'Chơi lại';

  @override
  String get actionUndoAvailable => 'Hoàn tác (1/1)';

  @override
  String get actionUndoUsed => 'Hoàn tác (0/1)';

  @override
  String get adLoading => 'Đang tải video...';

  @override
  String get adNotReady =>
      'Quảng cáo chưa sẵn sàng. Vui lòng thử lại sau giây lát.';

  @override
  String get appDescription =>
      'Trò chơi giải đố logic toán học dựa trên Bài toán tô màu đồ thị (Graph Coloring Problem). Thử thách tư duy logic qua 6 Chapters với 180 màn chơi được thiết kế thủ công chuẩn mực.';

  @override
  String get appLegalese =>
      '© 2026 Graph Coloring Game.\nBản quyền mã nguồn mở tuân thủ các giấy phép thành phần tương ứng.';

  @override
  String get appName => 'Graph Coloring';

  @override
  String get backTooltip => 'Quay lại';

  @override
  String get boardRefreshed => 'Đã làm mới bàn cờ!';

  @override
  String get buttonBackToCampaign => 'Về danh sách màn chơi';

  @override
  String get buttonBackToHome => 'Về màn hình chính';

  @override
  String get buttonCampaign => 'Campaign';

  @override
  String get buttonCancel => 'Hủy';

  @override
  String get buttonClose => 'Đóng';

  @override
  String get buttonContinue => 'Chơi tiếp';

  @override
  String get buttonGotIt => 'Đã hiểu';

  @override
  String get buttonLater => 'Để sau';

  @override
  String get buttonNextLevel => 'Màn tiếp theo';

  @override
  String buttonNextLevelWithIndex(int overallIndex) {
    return 'Màn tiếp theo ($overallIndex)';
  }

  @override
  String get buttonReplay => 'Chơi lại';

  @override
  String get buttonReset => 'Đặt lại';

  @override
  String get buttonRestartCost => 'Chơi lại (-1 ⚡)';

  @override
  String get buttonRetryLevel => 'Thử lại màn này';

  @override
  String get buttonReviveWithShields => 'Hồi sinh (+2 Lượt lỗi 🛡️)';

  @override
  String get buttonViewLicenses => 'Xem giấy phép nguồn mở';

  @override
  String get buttonWatchAdEnergy => 'Xem video (+1 ⚡)';

  @override
  String get buttonWatchAdHint => 'Xem quảng cáo (+1 Gợi ý)';

  @override
  String get campaignBannerSubtitle =>
      '180 màn chơi câu đố logic được thiết kế thủ công.';

  @override
  String get campaignBannerTitle => 'Chiến dịch 6 Chapters';

  @override
  String get chapter1Subtitle => 'Làm quen với luật kề và cách tô màu cơ bản';

  @override
  String get chapter1Title => 'First Connection';

  @override
  String get chapter2Subtitle => 'Quản lý kho màu chính xác và tránh ngõ cụt';

  @override
  String get chapter2Title => 'Color Balance';

  @override
  String get chapter3Subtitle =>
      'Tư duy chiến thuật xoay quanh các Node cố định';

  @override
  String get chapter3Title => 'Locked Connections';

  @override
  String get chapter4Subtitle =>
      'Mạng lưới kết nối phức tạp và điểm nghẽn logic';

  @override
  String get chapter4Title => 'Complex Network';

  @override
  String get chapter5Subtitle => 'Ràng buộc tập màu giới hạn theo từng Node';

  @override
  String get chapter5Title => 'Restricted Choices';

  @override
  String get chapter6Subtitle => 'Thử thách đỉnh cao kết hợp toàn bộ cơ chế';

  @override
  String get chapter6Title => 'Master Network';

  @override
  String chapterHeaderTitle(int id, String title) {
    return 'Chapter $id: $title';
  }

  @override
  String chapterLevelsProgress(int completed, int total) {
    return 'Màn chơi: $completed/$total';
  }

  @override
  String chapterShort(int chapterId) {
    return 'Chapter $chapterId';
  }

  @override
  String get colorBlue => 'Xanh dương';

  @override
  String get colorGreen => 'Xanh lá';

  @override
  String get colorPurple => 'Tím';

  @override
  String get colorRed => 'Đỏ';

  @override
  String get colorYellow => 'Vàng';

  @override
  String get colorSymbolBlue => 'X';

  @override
  String get colorSymbolGreen => 'L';

  @override
  String get colorSymbolPurple => 'T';

  @override
  String get colorSymbolRed => 'Đ';

  @override
  String get colorSymbolYellow => 'V';

  @override
  String get coloredLinesLabel => 'Line màu';

  @override
  String get coloredLinesOnTooltip => 'Tắt đường nối màu';

  @override
  String get coloredLinesOffTooltip => 'Bật đường nối màu';

  @override
  String get coloredLinesAdDialogTitle => 'LINE MÀU HẰNG NGÀY';

  @override
  String coloredLinesDefaultNeed(int max) {
    return 'Mỗi ngày bạn có $max lượt sử dụng Line màu miễn phí.\nXem một đoạn video ngắn để nhận thêm +1 lượt và bật Line màu!';
  }

  @override
  String get coloredLinesDefaultWatch =>
      'Xem một đoạn video ngắn để nhận thêm +1 lượt và bật Line màu!';

  @override
  String coloredLinesOutOfFreeDaily(int max) {
    return 'Bạn đã dùng hết $max lượt Line màu miễn phí hôm nay!\nHãy xem một video quảng cáo ngắn để nhận thêm +1 lượt và bật Line màu.';
  }

  @override
  String coloredLinesQuotaBadge(int count) {
    return 'Lượt Line màu: $count/5';
  }

  @override
  String get coloredLinesRewardSuccess =>
      'Đã nhận +1 lượt Line màu và bật hiển thị!';

  @override
  String get coloredLinesWatchAdToUnlock => 'Xem quảng cáo (+1 Lượt)';

  @override
  String get coloredLinesExhaustedToast =>
      'Đã dùng hết 5 lượt Line màu hôm nay. Hãy xem quảng cáo để mở lại!';

  @override
  String completedCountText(int count) {
    return 'Hoàn thành: $count/30';
  }

  @override
  String get energyAdDialogTitle => 'NĂNG LƯỢNG HÀNG NGÀY';

  @override
  String energyDefaultFull(int max) {
    return 'Năng lượng của bạn đang ở mức tối đa ($max/$max). Bạn có thể tiếp tục chơi thoải mái!';
  }

  @override
  String energyDefaultNeed(int max) {
    return 'Bạn cần Năng lượng để Chơi lại ván này.\nXem một video quảng cáo ngắn để nạp ngay +1 Năng lượng (tối đa $max/$max)!';
  }

  @override
  String energyDefaultWatch(int max) {
    return 'Xem một video quảng cáo ngắn để nạp thêm +1 Năng lượng (tối đa $max/$max)!';
  }

  @override
  String get energyReasonContinue =>
      'Bạn đã hết Năng lượng để tiếp tục ván chơi này.\nXem video quảng cáo để nạp ngay +1 Năng lượng và tiếp tục giải đố!';

  @override
  String get energyReasonOutOfEnergy =>
      'Bạn đã hết Năng lượng để chơi lại. Xem quảng cáo để nhận ngay +1 Năng lượng!';

  @override
  String get energyReasonPlay =>
      'Bạn đã hết Năng lượng để chơi màn này.\nXem video quảng cáo để nạp ngay +1 Năng lượng và bắt đầu giải đố!';

  @override
  String get energyReasonRestart =>
      'Bạn cần ít nhất 1 Năng lượng để Chơi lại ván này.\nXem một video quảng cáo ngắn để nạp ngay +1 Năng lượng và tiếp tục chơi!';

  @override
  String get energyReasonRetry =>
      'Bạn đã hết Năng lượng để thử lại màn chơi này.\nXem video quảng cáo để nạp ngay +1 Năng lượng và tiếp tục thử thách!';

  @override
  String get energyResetSchedule => 'Tự động hồi phục 3/3 lúc 00:00 (giờ VN)';

  @override
  String get energyRewardSuccess => 'Đã nạp +1 ⚡ thành công!';

  @override
  String get errorAdjacentSameColor =>
      'Hai node nối với nhau không được có cùng màu!';

  @override
  String get errorAllNodesColored => 'Tất cả các node đã được tô màu!';

  @override
  String get errorCannotEraseLocked => 'Không thể xóa màu của Node bị khóa!';

  @override
  String get errorDeadEndNoSolution => 'Nước đi ngõ cụt, không còn lời giải!';

  @override
  String errorInventoryEmpty(String color) {
    return 'Màu $color đã dùng hết số lượng trong kho!';
  }

  @override
  String get errorLockedNode => 'Node đã bị khóa cố định, không thể đổi màu!';

  @override
  String get errorNoSolutionWithChoice =>
      'Không còn cách hoàn thành với lựa chọn này.';

  @override
  String get errorOutOfEnergyAbandon =>
      'Bạn đã hết Năng lượng (0/3). Không thể bỏ cuộc!';

  @override
  String get errorOutOfEnergyRestart =>
      'Bạn đã hết Năng lượng (0/3). Cần Năng lượng để chơi lại!';

  @override
  String get errorOutOfEnergyRetry =>
      'Bạn đã hết Năng lượng (0/3). Cần Năng lượng để thử lại!';

  @override
  String get errorOutOfMistakes => 'Bạn đã hết lượt lỗi! Màn chơi kết thúc.';

  @override
  String errorRestrictedColor(String color) {
    return 'Node này không cho phép sử dụng màu $color!';
  }

  @override
  String get errorUndoLimit => 'Mỗi màn chơi chỉ được hoàn tác tối đa 1 lần!';

  @override
  String get finaleBadge => 'FINALE';

  @override
  String get gameInfoTooltip => 'Thông tin trò chơi';

  @override
  String get gameOverBannerText => 'Hết lượt lỗi! Vui lòng chơi lại màn này.';

  @override
  String gameOverEnergyBadge(int current, int max) {
    return 'Năng lượng: $current/$max';
  }

  @override
  String get gameOverMessage =>
      'Bạn đã dùng hết 2 lượt lỗi cho màn chơi này.\nHãy thử lại hoặc xem quảng cáo để nhận thêm lượt lỗi nhé!';

  @override
  String get gameOverRechargeTag => '+ Nạp ⚡';

  @override
  String get gameOverTitle => 'HẾT LƯỢT LỖI';

  @override
  String get greetingChapter1Finale =>
      'Chung Kết Chapter 1: Vương Miện Ngũ Sắc!';

  @override
  String get greetingGreenUnlocked =>
      'Mở khóa Màu Xanh lá! Mạng lưới 4 màu xuất hiện.';

  @override
  String get greetingPurpleUnlocked =>
      'Mở khóa Màu Tím! Chinh phục phổ 5 màu trọn vẹn.';

  @override
  String get greetingYellowUnlocked =>
      'Mở khóa Màu Vàng! Thử thách 3 màu bắt đầu.';

  @override
  String get hintAdDialogTitle => 'NHẬN THÊM GỢI Ý';

  @override
  String get hintBoardChanged =>
      'Bàn cờ đã thay đổi và không còn lời giải hợp lệ từ thế cờ này.';

  @override
  String hintCountBadge(int count) {
    return 'Lượt gợi ý: $count';
  }

  @override
  String hintCurrentInstruction(String color, String nodeId) {
    return 'Gợi ý hiện tại: Hãy tô màu $color cho node $nodeId.';
  }

  @override
  String hintDefaultNeed(int max) {
    return 'Mỗi ngày bạn có $max lượt gợi ý miễn phí.\nXem một đoạn quảng cáo ngắn để nhận thêm +1 lượt Gợi ý giải đố!';
  }

  @override
  String get hintDefaultWatch =>
      'Xem một đoạn quảng cáo ngắn để tích lũy thêm +1 lượt Gợi ý giải đố!';

  @override
  String get hintNoSolutionFound =>
      'Không tìm thấy lời giải hợp lệ từ thế cờ hiện tại. Hãy thử Hoàn tác (Undo) hoặc Chơi lại!';

  @override
  String get hintOutOfFreeDaily =>
      'Bạn đã dùng hết lượt gợi ý miễn phí hôm nay! Hãy xem quảng cáo để nhận thêm.';

  @override
  String get hintReceivedToast => 'Đã nhận +1 Gợi ý! 💡';

  @override
  String get hintRewardSuccess => 'Đã nhận +1 Gợi ý thành công! 💡';

  @override
  String hintSuggestion(String color, String nodeId) {
    return 'Gợi ý: Hãy tô màu $color cho node $nodeId.';
  }

  @override
  String get homeTooltip => 'Về trang chủ';

  @override
  String get inProgressBadge => 'ĐANG DỞ DANG';

  @override
  String get instructionsBannerText =>
      'Kéo màu hoặc chạm chọn màu rồi chạm node. Nhấn node để xóa.\nNước đi dẫn đến ngõ cụt sẽ bị trừ 1 lượt lỗi.';

  @override
  String levelCompletedBannerDescEarned(int stars) {
    return 'Đạt $stars/3 sao! Kho màu đạt chuẩn.';
  }

  @override
  String get levelCompletedBannerDescGeneric =>
      'Tất cả node đã tô hợp lệ và kho màu đạt chuẩn!';

  @override
  String levelCompletedBannerTitle(String stars) {
    return 'HOÀN THÀNH MÀN CHƠI!$stars';
  }

  @override
  String get levelHeaderFallback => 'Màn chơi';

  @override
  String levelHeaderTitle(int chapterId, int levelNumber, String title) {
    return 'Chapter $chapterId - Màn $levelNumber: $title';
  }

  @override
  String levelTitleWithIndex(int overallIndex, String title) {
    return 'Màn $overallIndex: $title';
  }

  @override
  String levelsRange(int start, int end) {
    return 'Màn $start – $end';
  }

  @override
  String get mistakePenaltyTag => '-1 LỖI';

  @override
  String mistakesBadge(int count) {
    return 'Lỗi: $count/2';
  }

  @override
  String get resetProgressButton => 'Đặt lại toàn bộ tiến trình';

  @override
  String get resetProgressConfirmMessage =>
      'Thao tác này sẽ xóa toàn bộ tiến trình chơi, số sao đạt được và ván chơi đang lưu, đưa game về trạng thái ban đầu.';

  @override
  String get resetProgressConfirmTitle => 'Đặt lại toàn bộ tiến trình?';

  @override
  String get resetProgressSuccessToast =>
      'Đã đặt lại toàn bộ game về trạng thái ban đầu.';

  @override
  String restartConfirmContent(int energy, int max) {
    return 'Chơi lại màn này sẽ tiêu hao 1 Năng lượng (còn lại: $energy/$max).\nToàn bộ các nước đi đã tô sẽ được đưa về trạng thái ban đầu.';
  }

  @override
  String get restartConfirmTitle => 'Chơi lại màn này?';

  @override
  String get restartFreeTooltip => 'Chơi lại';

  @override
  String get revivedSuccessToast => 'Đã hồi sinh! Bạn nhận thêm 2 lượt lỗi 🛡️';

  @override
  String get soundOffTooltip => 'Tắt âm thanh';

  @override
  String get soundOnTooltip => 'Bật âm thanh';

  @override
  String starsCountText(int stars) {
    return 'Sao: $stars/90';
  }

  @override
  String get statEnergy => 'Năng lượng';

  @override
  String get statLevels => 'Màn chơi';

  @override
  String get statTotalStars => 'Tổng sao';

  @override
  String get tapToContinue => 'Nhấn để tiếp tục màn chơi';

  @override
  String unlockChapterRequirement(int chapterId) {
    return 'Hoàn thành Chapter $chapterId để mở khóa';
  }

  @override
  String get victoryCampaignFinalMessage =>
      'Chúc mừng bạn đã xuất sắc phá đảo toàn bộ 180 màn chơi của Graph Coloring!';

  @override
  String get victoryCampaignFinalTitle => 'CHIẾN THẮNG CAMPAIGN!';

  @override
  String victoryStarsSummary(int earned, int best) {
    return 'Lượt chơi: $earned/3 sao • Kỷ lục: $best/3 sao';
  }

  @override
  String get victoryTitle => 'HOÀN THÀNH MÀN CHƠI!';

  @override
  String get howToPlayButton => 'Hướng dẫn chơi';

  @override
  String get howToPlayTooltip => 'Xem hướng dẫn chơi';

  @override
  String get howToPlayBannerTitle => 'Hướng dẫn chơi Graph Coloring';

  @override
  String get howToPlayBannerSubtitle =>
      'Nắm vững luật chơi và mẹo giải đố trong 6 bước';

  @override
  String get tutorialTitle => 'Hướng dẫn chơi';

  @override
  String tutorialStepProgress(int current, int total) {
    return 'Bước $current / $total';
  }

  @override
  String get tutorialButtonNext => 'Tiếp theo';

  @override
  String get tutorialButtonPrevious => 'Trước';

  @override
  String get tutorialButtonSkip => 'Bỏ qua';

  @override
  String get tutorialButtonStart => 'Bắt đầu chơi';

  @override
  String get tutorialStep1Title => 'Chào mừng đến với Graph Coloring';

  @override
  String get tutorialStep1Subtitle => 'Câu đố logic toán học';

  @override
  String get tutorialStep1Description =>
      'Graph Coloring là trò chơi giải đố logic dựa trên bài toán tô màu đồ thị nổi tiếng. Nhiệm vụ của bạn là tô màu tất cả các đỉnh trong mạng lưới sao cho thỏa mãn quy tắc kết nối và số lượng bóng quy định.';

  @override
  String get tutorialStep2Title => 'Đỉnh, Cạnh & Quy tắc cốt lõi';

  @override
  String get tutorialStep2Subtitle => 'Quy tắc vàng trong tô màu';

  @override
  String get tutorialStep2Description =>
      '• Đỉnh (Nodes): Các hình tròn trên bàn cờ cần được tô màu.\n• Cạnh (Edges): Các đường thẳng nối giữa hai đỉnh. Bạn có thể bật/tắt vẽ đường nối màu bằng biểu tượng trên thanh công cụ (5 lượt miễn phí mỗi ngày).\n• Quy tắc vàng: Hai đỉnh được nối trực tiếp với nhau TUYỆT ĐỐI KHÔNG ĐƯỢC có cùng màu!';

  @override
  String get tutorialValidLabel => 'Hợp lệ';

  @override
  String get tutorialValidDesc => 'Hai đỉnh kề mang màu khác nhau';

  @override
  String get tutorialConflictLabel => 'Xung đột!';

  @override
  String get tutorialConflictDesc => 'Hai đỉnh kề không được trùng màu';

  @override
  String get tutorialStep3Title => 'Cách chọn & tô màu';

  @override
  String get tutorialStep3Subtitle => 'Hai cách thao tác thuận tiện';

  @override
  String get tutorialStep3Description =>
      '• Chạm để chọn: Chạm vào màu ở thanh công cụ bên dưới, sau đó chạm vào đỉnh để tô màu.\n• Kéo & Thả: Chạm và kéo quả bóng màu trực tiếp vào đỉnh muốn tô.\n• Xóa màu: Chạm vào đỉnh đã tô khi không chọn màu nào để thu hồi bóng về kho.';

  @override
  String get tutorialTapToSelectLabel => 'Chạm hoặc Kéo thả';

  @override
  String get tutorialStep4Title => 'Giới hạn kho màu chính xác';

  @override
  String get tutorialStep4Subtitle => 'Phải sử dụng đúng số lượng màu';

  @override
  String get tutorialStep4Description =>
      '• Mỗi màn chơi quy định số lượng bóng chính xác cho từng màu.\n• Con số bên dưới mỗi màu cho biết số lượng bóng còn lại trong kho.\n• Để chiến thắng, bạn phải sử dụng chính xác 100% toàn bộ số bóng được giao — không thừa và không thiếu!';

  @override
  String get tutorialInventoryGoalLabel =>
      'Mục tiêu: Dùng hết bóng (còn lại 0)';

  @override
  String get tutorialStep5Title => 'Công cụ hỗ trợ & Khiên lỗi';

  @override
  String get tutorialStep5Subtitle => 'Hoàn tác, Gợi ý, Chơi lại & Khiên lỗi';

  @override
  String get tutorialStep5Description =>
      '• Hoàn tác (1 lượt/màn): Đảo ngược nước đi gần nhất. Mỗi màn được hoàn tác 1 lần.\n• Gợi ý (1 lượt/ngày): Chỉ dẫn nước đi chính xác theo thuật toán giải. Xem quảng cáo để nhận thêm gợi ý.\n• Chơi lại: Đặt lại bàn cờ. Miễn phí nếu chưa đặt bóng; tốn 1 Năng lượng nếu đã đặt bóng.\n• Khiên lỗi (2 🛡️): Bạn được phép phạm tối đa 2 lần đi sai trước khi hết lượt và kết thúc ván chơi.\n• Line màu (5 lượt/ngày): Mỗi ngày bạn có 5 lượt mở vẽ line màu. Khi bật, mỗi màn chơi xong (hoàn thành hoặc thất bại) sẽ trừ 1 lượt. Hết lượt có thể xem quảng cáo để mở thêm.';

  @override
  String get tutorialActionUndo => 'Hoàn tác';

  @override
  String get tutorialActionHint => 'Gợi ý';

  @override
  String get tutorialActionRestart => 'Chơi lại';

  @override
  String get tutorialActionShields => 'Khiên lỗi';

  @override
  String get tutorialStep6Title => 'Chiến thắng & Chinh phục';

  @override
  String get tutorialStep6Subtitle => 'Vượt màn chơi và thu thập sao';

  @override
  String get tutorialStep6Description =>
      'Để vượt qua màn chơi:\n1. Tất cả các đỉnh đều được tô màu.\n2. Không có hai đỉnh nối nhau nào bị trùng màu.\n3. Dùng hết chính xác 100% số lượng bóng trong kho.\nChinh phục 3 Sao qua 180 màn chơi trong 6 Chapter. Chúc bạn chơi vui vẻ!';

  @override
  String get tutorialReadyTitle => 'Bạn đã sẵn sàng!';
}
