import 'dart:io';

import 'package:graph_coloring/features/campaign/data/levels/chapter_1_levels.dart';
import 'package:graph_coloring/features/campaign/data/levels/chapter_2_levels.dart';
import 'package:graph_coloring/features/campaign/data/levels/chapter_3_levels.dart';
import 'package:graph_coloring/features/campaign/data/levels/chapter_4_levels.dart';
import 'package:graph_coloring/features/campaign/data/levels/chapter_5_levels.dart';
import 'package:graph_coloring/features/campaign/data/levels/chapter_6_levels.dart';
import 'package:graph_coloring/features/campaign/domain/services/level_validator.dart';

void main() {
  final allLevels = [
    ...chapter1Levels,
    ...chapter2Levels,
    ...chapter3Levels,
    ...chapter4Levels,
    ...chapter5Levels,
    ...chapter6Levels,
  ];

  print('Loaded ${allLevels.length} total levels.');
  final validator = LevelValidator();
  final report = validator.validateAll(allLevels);

  print('Validation result: ${report.isValid ? "SUCCESS" : "FAILED"}');
  if (!report.isValid) {
    print('Errors:');
    for (final err in report.errors) {
      print(' - $err');
    }
    exit(1);
  } else {
    print('All 180 levels are 100% VALID according to LevelValidator!');
  }
}
