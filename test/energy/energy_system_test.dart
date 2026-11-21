import 'package:flutter_test/flutter_test.dart';
import 'package:graph_coloring/features/graph_coloring/data/datasources/daily_energy_local_datasource.dart';
import 'package:graph_coloring/features/graph_coloring/data/repositories/daily_energy_repository_impl.dart';
import 'package:graph_coloring/features/graph_coloring/domain/repositories/daily_energy_repository.dart';

class FakeDailyEnergyDataSource extends DailyEnergyLocalDataSource {
  String? _raw;

  @override
  Future<String?> getRawEnergy() async => _raw;

  @override
  Future<void> saveRawEnergy(String jsonString) async {
    _raw = jsonString;
  }

  @override
  Future<void> clearRawEnergy() async {
    _raw = null;
  }
}

void main() {
  group('DailyEnergyRepository Tests', () {
    late FakeDailyEnergyDataSource dataSource;
    late DateTime currentDate;

    setUp(() {
      dataSource = FakeDailyEnergyDataSource();
      currentDate = DateTime(2026, 11, 14, 10, 0);
    });

    DailyEnergyRepositoryImpl createRepo() {
      return DailyEnergyRepositoryImpl(
        localDataSource: dataSource,
        nowProvider: () => currentDate,
      );
    }

    test('Khởi tạo mặc định mỗi ngày có 10 Energy', () async {
      final repo = createRepo();
      final energy = await repo.getRemainingEnergy();
      expect(energy, 10);
    });

    test('consumeEnergy trừ đúng số lượng và chặn khi không đủ', () async {
      final repo = createRepo();

      // Trừ 1 energy: 10 -> 9
      final e1 = await repo.consumeEnergy(amount: 1);
      expect(e1, 9);

      // Trừ 5 energy: 9 -> 4
      final e2 = await repo.consumeEnergy(amount: 5);
      expect(e2, 4);

      // Trừ 4 energy: 4 -> 0
      final e3 = await repo.consumeEnergy(amount: 4);
      expect(e3, 0);

      // Khi đã về 0, không thể trừ tiếp, trả về null
      final e4 = await repo.consumeEnergy(amount: 1);
      expect(e4, isNull);

      final current = await repo.getRemainingEnergy();
      expect(current, 0);
    });

    test('Reset ngày mới luôn về đúng 10 Energy, không cộng dồn', () async {
      final repo = createRepo();
      await repo.consumeEnergy(amount: 4);
      expect(await repo.getRemainingEnergy(), 6);

      // Bước sang ngày hôm sau
      currentDate = DateTime(2026, 11, 15, 8, 0);

      // Phải được reset về đúng 10, không cộng dồn thành 16
      expect(await repo.getRemainingEnergy(), 10);
    });

    test('addEnergy không vượt quá giới hạn tối đa 10', () async {
      final repo = createRepo();
      await repo.consumeEnergy(amount: 2); // 10 -> 8
      expect(await repo.getRemainingEnergy(), 8);

      // Thưởng 3 energy (từ Rewarded Ad): 8 + 3 = 11 -> clamp về 10
      final newEnergy = await repo.addEnergy(3);
      expect(newEnergy, 10);
      expect(await repo.getRemainingEnergy(), 10);
    });

    test('Serialize thao tác gọi consumeEnergy đồng thời không gây race condition', () async {
      final repo = createRepo();

      // 12 yêu cầu trừ 1 Energy đồng thời
      final results = await Future.wait(
        List.generate(12, (_) => repo.consumeEnergy(amount: 1)),
      );

      // Đúng 10 yêu cầu thành công (10..1 -> 0) và đúng 2 yêu cầu thất bại (null)
      final successful = results.where((r) => r != null).toList();
      final failed = results.where((r) => r == null).toList();

      expect(successful.length, 10);
      expect(failed.length, 2);
      expect(await repo.getRemainingEnergy(), 0);
    });

    test('Lỗi dữ liệu JSON bị hỏng được fallback về 10 an toàn', () async {
      await dataSource.saveRawEnergy('{malformed_json}');
      final repo = createRepo();

      // Không crash và fallback về 10
      final energy = await repo.getRemainingEnergy();
      expect(energy, 10);
    });
  });
}

