import 'matching/matcher_groups.dart';
import 'token.dart';
import 'tokenizer.dart';

class HtmlScraper {
  final String _htmlString;
  final Map<String, String> results = {};

  HtmlScraper(this._htmlString);

  Map<String, String> parseHtml(MatcherGroups matcherGroups) {

    HtmlTokenizer tokenizer = HtmlTokenizer(_htmlString, attributeSpans: true);

    while (tokenizer.moveNext()) {
      switch (tokenizer.current.kind) {
        case TokenKind.startTag:
          var tag = tokenizer.current as StartTagToken;
          matcherGroups.match(tokenizer, tag);
          if(matcherGroups.haveAllRequired()) {
            return matcherGroups.getResults();
          }
      }
    }

    return matcherGroups.getResults();
  }
}
