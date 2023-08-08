import '../token.dart';
import 'matcher.dart';

class TagAttributeMatcher implements Matcher {
  String tagToMatch;
  String attrToMatch;
  String attrValueToMatch;
  String? attrToReturn;
  String? giveUpAfterTag;
  String? excludeExt;
  bool giveUp = false;
  bool isTagWildCard = false;
  bool caseInsensitiveMatch;
  bool wildCardAttrMatch;
  String _result = '';

  TagAttributeMatcher(
      {required this.tagToMatch,
      required this.attrToMatch,
      required this.attrValueToMatch,
      this.attrToReturn,
      this.giveUpAfterTag,
      this.excludeExt,
      this.caseInsensitiveMatch = false,
      this.wildCardAttrMatch = false}) {
    if (tagToMatch.contains('*')) {
      isTagWildCard = true;
    }

    if (caseInsensitiveMatch) {
      attrValueToMatch = attrValueToMatch.toLowerCase();
    }
  }

  @override
  String getResult() {
    return _result;
  }

  @override
  bool isMatched() {
    return _result.isNotEmpty;
  }

  @override
  bool stopMatching() {
    return giveUp;
  }

  @override
  bool match(StartTagToken? tag, EndTagToken? endTag, String? content) {
    if (endTag != null && giveUpAfterTag == endTag.name) {
      giveUp = true;
    }

    if (tag == null || (!isTagWildCard && tagToMatch != tag.name!) || isMatched()) {
      return false;
    }

    bool matchedAttr = false;
    String? returnAttr;

    for (MapEntry<Object, String> attrPair in tag.data.entries) {
      if (attrPair.key is! String) {
        continue;
      }

      String attrName = attrPair.key as String;
      String attrValue = attrPair.value;

      if (attrName == attrToMatch) {
        String tagAttrValue = attrValue;
        if (caseInsensitiveMatch) {
          tagAttrValue = attrValue.toLowerCase();
        }

        bool isValueMatch = wildCardAttrMatch ? tagAttrValue.contains(attrValueToMatch) : tagAttrValue == attrValueToMatch;

        if (isValueMatch) {
          matchedAttr = true;
        }
      }

      if (attrName == attrToReturn) {
        returnAttr = attrValue;
      }

      if (matchedAttr && (returnAttr != null || attrToReturn == null)) {
        break;
      }
    }

    if (!matchedAttr) {
      return false;
    }

    if (attrToReturn == null) {
      _result = _isResultValid(content) ? content! : '';
      return _result.isNotEmpty;
    }

    if (returnAttr == null) {
      return false;
    }

    _result = _isResultValid(returnAttr) ? returnAttr : '';

    return _result.isNotEmpty;
  }

  bool _isResultValid(String? content) {
    if (content == null) {
      return false;
    }

    if (excludeExt == null) {
      return true;
    }

    return !content.endsWith(excludeExt!);
  }
}
