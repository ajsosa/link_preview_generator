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

    if (tag == null ||
        (!isTagWildCard && tagToMatch != tag.name!) ||
        isMatched()) {
      return false;
    }

    TagAttribute? matchAttr;
    TagAttribute? returnAttr;

    for (TagAttribute tagAttr in tag.attributeSpans ?? []) {
      if (tagAttr.name == attrToMatch) {
        String tagAttrValue = tagAttr.value;
        if (caseInsensitiveMatch) {
          tagAttrValue = tagAttr.value.toLowerCase();
        }

        bool isValueMatch = wildCardAttrMatch
            ? tagAttrValue.contains(attrValueToMatch)
            : tagAttrValue == attrValueToMatch;

        if (isValueMatch) {
          matchAttr = tagAttr;
        }
      }

      if (tagAttr.name == attrToReturn) {
        returnAttr = tagAttr;
      }

      if (matchAttr != null && (returnAttr != null || attrToReturn == null)) {
        break;
      }
    }

    if (matchAttr == null) {
      return false;
    }

    if (attrToReturn == null) {
      _result = _isResultValid(content) ? content! : '';
      return _result.isNotEmpty;
    }

    if (returnAttr == null) {
      return false;
    }

    _result = _isResultValid(returnAttr.value) ? returnAttr.value : '';

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
