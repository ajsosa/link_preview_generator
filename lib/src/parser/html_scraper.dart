import 'matching/matcher_groups.dart';
import 'token.dart';
import 'tokenizer.dart';

class HtmlScraper {
  final String _htmlString;
  final Map<String, String> results = {};

  HtmlScraper(this._htmlString);

  Map<String, String> scrapeHtml(MatcherGroups matcherGroups) {
    HtmlTokenizer tokenizer = HtmlTokenizer(_htmlString);

    Map<String, String> results = parse(tokenizer, matcherGroups);
    return results.isNotEmpty ? results : matcherGroups.getResults();
  }

  Map<String, String> parse(HtmlTokenizer tokenizer, MatcherGroups matcherGroups) {
    Stack<StartTagToken> tags = Stack();
    String content = '';

    while (tokenizer.moveNext()) {
      switch (tokenizer.current.kind) {
        case TokenKind.startTag:
          StartTagToken tag = tokenizer.current as StartTagToken;
          Map<String, String>? results;

          // meta and link tags don't have to be closed. Treat as self closing
          // so we match on them now since there will be no end tag.
          if (tag.selfClosing || tag.name == 'meta' || tag.name == 'link') {
            results = match(tag, null, null, matcherGroups);
          } else {
            tags.push(tag);
          }

          if (results != null && results.isNotEmpty) {
            return results;
          }
          break;
        case TokenKind.characters:
          content = (tokenizer.current as CharactersToken).data;
          break;
        case TokenKind.endTag:
          EndTagToken endTag = tokenizer.current as EndTagToken;
          StartTagToken tag = tags.pop();
          Map<String, String>? results = match(tag, endTag, content, matcherGroups);

          if (results.isNotEmpty) {
            return results;
          }
      }
    }

    return {};
  }

  Map<String, String> match(StartTagToken? tag, EndTagToken? endTag, String? content, MatcherGroups matcherGroups) {
    matcherGroups.match(tag, endTag, content);
    if (matcherGroups.haveAllRequired()) {
      return matcherGroups.getResults();
    }

    return {};
  }
}

class Stack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E pop() => _list.removeLast();

  E get peek => _list.last;

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  String toString() => _list.toString();
}
