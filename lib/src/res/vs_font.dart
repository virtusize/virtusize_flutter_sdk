import 'package:flutter/material.dart';

import '../../src/models/virtusize_enums.dart';

/// All the available font sizes based on the Virtusize design system
enum VSFontSize { xsmall, small, normal, large, xlarge, xxlarge }

class VSFont {
  final VSLanguage language;

  VSFont(this.language);

  /// Gets the [TextStyle]
  TextStyle getTextStyle(
      {@required VSFontSize fontSize, FontWeight fontWeight, Color color}) {
    return TextStyle(
        fontSize: _getFontSize(language, fontSize),
        fontFamily: _getFontFamily(language),
        fontWeight: fontWeight,
        color: color);
  }

  /// Gets the font family based on the [VSLanguage] value
  String _getFontFamily(VSLanguage language) {
    String fontFamilyName;
    switch(language) {
      case VSLanguage.en:
        // TODO: Proxima Nova is not a open source font. Need to find an alternative
        fontFamilyName = "ProximaNova";
        break;
      case VSLanguage.jp:
        fontFamilyName = "NotoSansJP";
        break;
      case VSLanguage.kr:
        fontFamilyName = "NotoSansKR";
        break;
    }
    return fontFamilyName;
  }

  /// Gets the font size based on the [VSLanguage] and [VSFontSize] values
  double _getFontSize(VSLanguage language, VSFontSize fontSize) {
    Map<List<VSLanguage>, Map<VSFontSize, double>> langFontSizeMap = {
      [VSLanguage.en]: {
        VSFontSize.xsmall: 12.0,
        VSFontSize.small: 14.0,
        VSFontSize.normal: 16.0,
        VSFontSize.large: 18.0,
        VSFontSize.xlarge: 22.0,
        VSFontSize.xxlarge: 28.0
      },
      [VSLanguage.jp, VSLanguage.kr]: {
        VSFontSize.xsmall: 10.0,
        VSFontSize.small: 12.0,
        VSFontSize.normal: 14.0,
        VSFontSize.large: 16.0,
        VSFontSize.xlarge: 20.0,
        VSFontSize.xxlarge: 24.0
      }
    };
    Map<VSFontSize, double> fontSizeMap = langFontSizeMap.entries
        .firstWhere((entry) => entry.key.contains(language))
        .value;
    return fontSizeMap.entries
        .firstWhere((entry) => entry.key == fontSize)
        .value;
  }
}
