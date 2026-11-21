import 'dart:convert';

import '../../domain/entities/campaign_progress.dart';
import '../../domain/repositories/campaign_progress_repository.dart';
import '../datasources/campaign_progress_local_datasource.dart';
import '../models/campaign_progress_dto.dart';

/// Implementation của CampaignProgressRepository.
/// Tầng Data Layer, xử lý chuyển đổi thực thể và bảo vệ dữ liệu khi parsing lỗi.
class CampaignProgressRepositoryImpl implements CampaignProgressRepository {
  CampaignProgressRepositoryImpl({
    CampaignProgressLocalDataSource? localDataSource,
  }) : _localDataSource =
            localDataSource ?? CampaignProgressLocalDataSourceImpl();

  final CampaignProgressLocalDataSource _localDataSource;

  @override
  Future<CampaignProgress> loadProgress() async {
    try {
      final rawJson = await _localDataSource.getRawProgress();
      if (rawJson == null || rawJson.trim().isEmpty) {
        return CampaignProgress.initial();
      }

      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return CampaignProgress.initial();
      }

      final dto = CampaignProgressDto.fromJson(decoded);
      return dto.toEntity();
    } catch (_) {
      // Fallback an toàn tuyệt đối khi JSON hỏng hoặc không tương thích schema
      return CampaignProgress.initial();
    }
  }

  @override
  Future<void> saveProgress(CampaignProgress progress) async {
    final dto = CampaignProgressDto.fromEntity(progress);
    final rawJson = jsonEncode(dto.toJson());
    await _localDataSource.saveRawProgress(rawJson);
  }

  @override
  Future<void> resetProgress() async {
    await _localDataSource.clearRawProgress();
    // Khởi tạo lại trạng thái mặc định
    await saveProgress(CampaignProgress.initial());
  }
}

