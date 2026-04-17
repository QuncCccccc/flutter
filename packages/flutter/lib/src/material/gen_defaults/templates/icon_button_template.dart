// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../data/icon_button_standard.dart';
import 'token_template.dart';

class IconButtonTemplate extends TokenTemplate {
  const IconButtonTemplate(super.blockName, super.fileName, {super.colorSchemePrefix = '_colors.'});

  @override
  String generate() {
    return '''
class _${blockName}DefaultsM3E extends ButtonStyle {
  _${blockName}DefaultsM3E(this.context, this.toggleable)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  // No default text style

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    const MaterialStatePropertyAll<Color?>(Colors.transparent);

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor(TokenIconButtonStandard.disabledIconColor, 0.38)};
      }
      if (states.contains(WidgetState.selected)) {
        return ${color(TokenIconButtonStandard.selectedIconColor)};
      }
      return ${color(TokenIconButtonStandard.iconColor)};
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor(TokenIconButtonStandard.selectedPressedStateLayerColor, 0.1)};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor(TokenIconButtonStandard.selectedHoveredStateLayerColor, 0.08)};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor(TokenIconButtonStandard.selectedFocusedStateLayerColor, 0.1)};
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor(TokenIconButtonStandard.pressedStateLayerColor, 0.1)};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor(TokenIconButtonStandard.hoveredStateLayerColor, 0.08)};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor(TokenIconButtonStandard.focusedStateLayerColor, 0.1)};
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const MaterialStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    const MaterialStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.all(8.0));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    const MaterialStatePropertyAll<Size>(Size(40.0, 40.0));

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    const MaterialStatePropertyAll<double>(24.0);

  @override
  WidgetStateProperty<BorderSide?>? get side => null;

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    const MaterialStatePropertyAll<OutlinedBorder>(StadiumBorder());

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor => WidgetStateMouseCursor.adaptiveClickable;

  @override
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}
''';
  }
}
