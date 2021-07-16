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
        fontFamily: _getFontFamily(language),
        fontWeight: fontWeight,
        color: color);
  }

  String _getFontFamily(Language language) {
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
    double size;
    switch (language) {
      case Language.en:
        switch (fontSize) {
          case VSFontSize.xsmall:
            size = 12;
            break;
          case VSFontSize.small:
            size = 14;
            break;
          case VSFontSize.normal:
            size = 16;
            break;
          case VSFontSize.large:
            size = 18;
            break;
          case VSFontSize.xlarge:
            size = 22;
            break;
          case VSFontSize.xxlarge:
            size = 28;
            break;
        }
        break;
      case Language.jp:
      case Language.kr:
        switch (fontSize) {
          case VSFontSize.xsmall:
            size = 10;
            break;
          case VSFontSize.small:
            size = 12;
            break;
          case VSFontSize.normal:
            size = 14;
            break;
          case VSFontSize.large:
            size = 16;
            break;
          case VSFontSize.xlarge:
            size = 20;
            break;
          case VSFontSize.xxlarge:
            size = 24;
            break;
        }
        break;
    }
    return size;
  }
}
