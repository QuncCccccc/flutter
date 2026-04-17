// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('ColorSchemeTemplate uses all tokens from color data files', () {
    var templatePath = 'lib/src/material/gen_defaults/templates/color_scheme_template.dart';
    if (!File(templatePath).existsSync()) {
      templatePath = 'templates/color_scheme_template.dart';
    }
    final templateFile = File(templatePath);
    final String templateContent = templateFile.readAsStringSync();

    final dataFiles = <String>[
      'lib/src/material/gen_defaults/data/color.dart',
      'lib/src/material/gen_defaults/data/color_dark.dart',
      'lib/src/material/gen_defaults/data/color_light_medium_contrast.dart',
      'lib/src/material/gen_defaults/data/color_light_high_contrast.dart',
      'lib/src/material/gen_defaults/data/color_dark_medium_contrast.dart',
      'lib/src/material/gen_defaults/data/color_dark_high_contrast.dart',
    ];

    for (final filePath in dataFiles) {
      var path = filePath;
      if (!File(path).existsSync()) {
        path = filePath.replaceFirst('lib/src/material/gen_defaults/', '');
      }
      final file = File(path);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'File $path should exist. Current directory: ${Directory.current.path}',
      );

      final String content = file.readAsStringSync();
      // Regex to find "static const String tokenName ="
      final regex = RegExp(r'static const String (\w+) =');
      final Iterable<RegExpMatch> matches = regex.allMatches(content);

      expect(matches, isNotEmpty, reason: 'File $filePath should contain token definitions.');

      for (final match in matches) {
        final String tokenName = match.group(1)!;
        // Check if the token name appears in the template content.
        final bool isUsed =
            templateContent.contains('$tokenName: ') || templateContent.contains('.$tokenName}');

        expect(
          isUsed,
          isTrue,
          reason: 'Token $tokenName from $filePath should be used in the template',
        );
      }
    }
  });
}
