import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every ARB file in the repo keeps one key order, so two branches adding
/// keys rarely touch the same lines: `@@locale` first, then the keys sorted
/// by name, each `@key` metadata block right after its key.
void main() {
  group('arbOrderProblems', () {
    test('accepts a well-ordered file', () {
      expect(
        arbOrderProblems(<String>[
          '@@locale',
          'alpha',
          '@alpha',
          'beta',
          'gamma',
          '@gamma',
        ]),
        isEmpty,
      );
    });

    test('rejects a file that does not start with @@locale', () {
      expect(arbOrderProblems(<String>['alpha', '@@locale']), isNotEmpty);
    });

    test('rejects unsorted keys', () {
      expect(
          arbOrderProblems(<String>['@@locale', 'beta', 'alpha']), isNotEmpty);
    });

    test('rejects metadata away from its key', () {
      expect(
        arbOrderProblems(<String>['@@locale', 'alpha', 'beta', '@alpha']),
        isNotEmpty,
      );
    });

    test('rejects metadata for a missing key', () {
      expect(arbOrderProblems(<String>['@@locale', '@alpha']), isNotEmpty);
    });
  });

  test('every ARB file in the repo keeps the key order', () {
    final List<File> files = _arbFiles();
    expect(files, isNotEmpty, reason: 'no ARB files found');

    final Map<String, List<String>> problems = <String, List<String>>{};
    for (final File file in files) {
      final Object? json = jsonDecode(file.readAsStringSync());
      final List<String> keys = (json! as Map<String, Object?>).keys.toList();
      final List<String> fileProblems = arbOrderProblems(keys);
      if (fileProblems.isNotEmpty) problems[file.path] = fileProblems;
    }

    expect(problems, isEmpty);
  });
}

/// The order problems in an ARB file whose keys are [keys], in file order.
List<String> arbOrderProblems(List<String> keys) {
  final List<String> problems = <String>[];
  if (keys.isEmpty || keys.first != '@@locale') {
    problems.add('the first key must be @@locale');
  }

  String? previous;
  for (int i = 0; i < keys.length; i++) {
    final String key = keys[i];
    if (key == '@@locale') continue;
    if (key.startsWith('@')) {
      final String owner = key.substring(1);
      if (i == 0 || keys[i - 1] != owner) {
        problems.add('$key must come right after $owner');
      }
      continue;
    }
    if (previous != null && previous.compareTo(key) >= 0) {
      problems.add('$key must come before $previous');
    }
    previous = key;
  }
  return problems;
}

List<File> _arbFiles() {
  final dir = Directory('lib/l10n');
  if (!dir.existsSync()) return <File>[];
  return dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .toList();
}
