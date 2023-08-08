import '../token.dart';
import 'matcher.dart';

class TagMatcher implements Matcher {
  String tagToMatch;
  String? attrToReturn;
  String? giveUpAfterTag;
  String? excludeExt;
  String _result = '';
  bool isWildCard = false;
  bool giveUp = false;
  final RegExp? contentRegex;

  TagMatcher(
      {required this.tagToMatch,
        this.contentRegex,
        this.attrToReturn,
        this.giveUpAfterTag,
        this.excludeExt}) {
    if (tagToMatch.contains('*')) {
      isWildCard = true;
    }
  }

  @override
  String getResult() {
    return _result;
  }

  @override
  bool stopMatching() {
    return giveUp;
  }

  @override
  bool isMatched() {
    return _result.isNotEmpty;
  }

  @override
  bool match(StartTagToken? tag, EndTagToken? endTag, String? content) {
    if (endTag != null && giveUpAfterTag == endTag.name) {
      giveUp = true;
    }

    if (tag == null ||
        (!isWildCard && tagToMatch != tag.name!) ||
        isMatched()) {
      return false;
    }

    if (attrToReturn != null) {
      for (TagAttribute tagAttr in tag.attributeSpans ?? []) {
        if (tagAttr.name == attrToReturn) {
          _result = _isResultValid(tagAttr.value) ? tagAttr.value : '';
          return _result.isNotEmpty;
        }
      }

      return false;
    }

    if (contentRegex == null) {
      _result = _isResultValid(content) ? content! : '';
      return _result.isNotEmpty;
    }

    String? regexResult =
    contentRegex!.firstMatch(content!)?.group(0)?.split(':')[1].trim();

    if (regexResult != null) {
      _result = _isResultValid(regexResult) ? regexResult : '';
      return _result.isNotEmpty;
    }

    return false;
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
