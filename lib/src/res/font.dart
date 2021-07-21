import 'package:flutter/material.dart';

import '../../src/models/virtusize_enums.dart';

enum VSFontSize { xsmall, small, normal, large, xlarge, xxlarge }

class VSFont {
  final Language language;

  VSFont(this.language);

  TextStyle getTextStyle(
      {@required VSFontSize fontSize, FontWeight fontWeight, Color color}) {
    return TextStyle(
        fontSize: _getFontSize(fontSize),
        fontFamily: _getFontFamily(),
        fontWeight: fontWeight,
        color: color);
  }

  String _getFontFamily() {
    String fontFamilyName;
    switch(language) {
      case Language.en:
        fontFamilyName = "ProximaNova";
        break;
      case Language.jp:
        fontFamilyName = "NotoSansJP";
        break;
      case Language.kr:
        fontFamilyName = "NotoSansKR";
        break;
    }
    return fontFamilyName;
  }

  double _getFontSize(VSFontSize fontSize) {
    Map<List<Language>, Map<VSFontSize, double>> langFontSizeMap = {
      [Language.en]: {
        VSFontSize.xsmall: 12.0,
        VSFontSize.small: 14.0,
        VSFontSize.normal: 16.0,
        VSFontSize.large: 18.0,
        VSFontSize.xlarge: 22.0,
        VSFontSize.xxlarge: 28.0
      },
      [Language.jp, Language.kr]: {
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
