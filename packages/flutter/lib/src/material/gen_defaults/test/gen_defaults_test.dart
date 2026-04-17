// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart';
import '../templates/color_scheme_template.dart';
import '../templates/token_template.dart';

class TestTemplate extends TokenTemplate {
  TestTemplate(super.blockName, super.fileName, {this.generatedContent = '  // Generated code\n'});

  final String generatedContent;

  @override
  String generate() => generatedContent;
}

void main() {
  group('TokenTemplate', () {
    test('Templates will append to the end of a file', () {
      final Directory tempDir = Directory.systemTemp.createTempSync('gen_defaults');
      try {
        final file = File('${tempDir.path}/test_file.dart');
        file.writeAsStringSync('''
// This is a file with stuff in it.
// This part shouldn't be changed by
// the template.
''');

        final template = TestTemplate('TestBlock', file.path);
        template.updateFile();

        expect(file.readAsStringSync(), '''
// This is a file with stuff in it.
// This part shouldn't be changed by
// the template.

// BEGIN GENERATED TOKEN PROPERTIES - TestBlockM3E

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart.

// dart format off
  // Generated code
// dart format on
// END GENERATED TOKEN PROPERTIES - TestBlockM3E
''');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Templates will update over previously generated code at the end of a file', () {
      final Directory tempDir = Directory.systemTemp.createTempSync('gen_defaults');
      try {
        final file = File('${tempDir.path}/test_file.dart');
        file.writeAsStringSync('''
// This is a file with stuff in it.
// This part shouldn't be changed by
// the template.

// BEGIN GENERATED TOKEN PROPERTIES - TestBlockM3E

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart.

// dart format off
  // Old Generated code
// dart format on
// END GENERATED TOKEN PROPERTIES - TestBlockM3E
''');

        final template = TestTemplate(
          'TestBlock',
          file.path,
          generatedContent: '  // New Generated code\n',
        );
        template.updateFile();

        expect(file.readAsStringSync(), '''
// This is a file with stuff in it.
// This part shouldn't be changed by
// the template.


// BEGIN GENERATED TOKEN PROPERTIES - TestBlockM3E

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart.

// dart format off
  // New Generated code
// dart format on
// END GENERATED TOKEN PROPERTIES - TestBlockM3E
''');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Multiple templates can modify different code blocks in the same file', () {
      final Directory tempDir = Directory.systemTemp.createTempSync('gen_defaults');
      try {
        final file = File('${tempDir.path}/test_file.dart');
        file.writeAsStringSync('void foo() {}\n');

        final templateA = TestTemplate(
          'BlockA',
          file.path,
          generatedContent: '  // Block A code\n',
        );
        final templateB = TestTemplate(
          'BlockB',
          file.path,
          generatedContent: '  // Block B code\n',
        );

        templateA.updateFile();
        templateB.updateFile();

        expect(file.readAsStringSync(), '''
void foo() {}

// BEGIN GENERATED TOKEN PROPERTIES - BlockAM3E

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart.

// dart format off
  // Block A code
// dart format on
// END GENERATED TOKEN PROPERTIES - BlockAM3E

// BEGIN GENERATED TOKEN PROPERTIES - BlockBM3E

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart.

// dart format off
  // Block B code
// dart format on
// END GENERATED TOKEN PROPERTIES - BlockBM3E
''');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  test('ColorSchemeTemplate uses all tokens from color data files', () {
    const ColorSchemeTemplate template = ColorSchemeTemplate('ColorScheme', 'color_scheme.dart');
    final String generatedCode = template.generate();

    final List<String> dataFiles = <String>[
      'lib/src/material/gen_defaults/data/color.dart',
      'lib/src/material/gen_defaults/data/color_dark.dart',
      'lib/src/material/gen_defaults/data/color_light_medium_contrast.dart',
      'lib/src/material/gen_defaults/data/color_light_high_contrast.dart',
      'lib/src/material/gen_defaults/data/color_dark_medium_contrast.dart',
      'lib/src/material/gen_defaults/data/color_dark_high_contrast.dart',
    ];

    for (final String filePath in dataFiles) {
      final File file = File(filePath);
      expect(file.existsSync(), isTrue, reason: 'File $filePath should exist. Current directory: ${Directory.current.path}');
      
      final String content = file.readAsStringSync();
      final RegExp regex = RegExp(r'static const Color (\w+) =');
      final Iterable<RegExpMatch> matches = regex.allMatches(content);

      expect(matches, isNotEmpty, reason: 'File $filePath should contain token definitions.');

      for (final RegExpMatch match in matches) {
        final String tokenName = match.group(1)!;
        final bool isUsed = generatedCode.contains('$tokenName: ') || 
                            generatedCode.contains('.$tokenName}');
        
        expect(isUsed, isTrue, reason: 'Token $tokenName from $filePath should be used in the template');
      }
    }
  });
}
