import '../token.dart';
import '../tokenizer.dart';
import 'matcher.dart';
import 'get_tag_content.dart';

class TagMatcher implements Matcher {
  String tagToMatch;
  String? attrToReturn;
  String _result = '';
  bool isWildCard = false;
  final RegExp? contentRegex;

  TagMatcher({required this.tagToMatch, this.contentRegex, this.attrToReturn}) {
    if (tagToMatch.contains('*')) {
      isWildCard = true;
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
    if ((!isWildCard && tagToMatch != tag.name!) || isMatched()) {
      return false;
    }

    String content = parseContent(tokenizer);

    if (attrToReturn != null) {
      for (TagAttribute tagAttr in tag.attributeSpans ?? []) {
        if (tagAttr.name == attrToReturn) {
          _result = tagAttr.value;
          return true;
        }
      }

      return false;
    }

    if (contentRegex == null) {
      _result = content;
      return true;
    }

    String? regexResult = contentRegex!.firstMatch(content)?.group(0)?.split(':')[1].trim();

    if (regexResult != null) {
      _result = regexResult;
      return true;
    }

    return false;
  }
}
