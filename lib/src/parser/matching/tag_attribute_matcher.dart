import '../token.dart';
import '../tokenizer.dart';
import 'get_tag_content.dart';
import 'matcher.dart';

class TagAttributeMatcher implements Matcher {
  String tagToMatch;
  String attrToMatch;
  String attrValueToMatch;
  String? attrToReturn;
  bool isTagWildCard = false;
  bool caseInsensitiveMatch;
  bool wildCardAttrMatch;
  String _result = '';

  TagAttributeMatcher({required this.tagToMatch, required this.attrToMatch, required this.attrValueToMatch, this.attrToReturn, this.caseInsensitiveMatch = false, this.wildCardAttrMatch = false}) {
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
  bool match(HtmlTokenizer tokenizer, StartTagToken tag) {
    if ((!isTagWildCard && tagToMatch != tag.name!) || isMatched()) {
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

        bool isValueMatch = wildCardAttrMatch ? tagAttrValue.contains(attrValueToMatch) : tagAttrValue == attrValueToMatch;

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
      _result = parseContent(tokenizer);
      return true;
    }

    if (returnAttr == null) {
      return false;
    }

    _result = returnAttr.value;

    return true;
  }
}
