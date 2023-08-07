import 'matcher.dart';
import 'matcher_groups.dart';
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
          var startTag = tokenizer.current as StartTagToken;

          List<Matcher> relMatchers = matcherGroups.matchTag(startTag.name!);
          if (relMatchers.isNotEmpty) {
            for (Matcher relMatcher in relMatchers) {
              _AttrMatchResult? matchedAttrs;
              if (!relMatcher.getTagContent) {
                matchedAttrs = _findMatcherAttrs(startTag.attributeSpans ?? [], relMatcher);
              }
              _getMatcherValue(tokenizer, relMatcher, matchedAttrs);
              if (matcherGroups.haveAllRequired()) {
                return results;
              }
            }
          }
          break;
      }
    }

    return results;
  }

  String _parseContent(HtmlTokenizer tokenizer) {
    String content = '';
    while (tokenizer.moveNext()) {
      switch (tokenizer.current.kind) {
        case TokenKind.characters:
          content = (tokenizer.current as CharactersToken).data;
          break;
        case TokenKind.endTag:
          return content;
      }
    }

    return content;
  }

  void _getMatcherValue(HtmlTokenizer tokenizer, Matcher matcher, _AttrMatchResult? attrs) {
    int resultSize = results.length;

    if (attrs != null) {
      if (attrs.matchingAttr != null && matcher.isMatchOrInAttrValue(attrs.matchingAttr!.value)) {
        if (matcher.getTagContent) {
          String content = _parseContent(tokenizer);
          if (content.isNotEmpty) {
            results[matcher.key] = content;
          }
        } else {
          results[matcher.key] = attrs.returnAttr.value;
        }
      } else if (matcher.matchTagOnly) {
        results[matcher.key] = attrs.returnAttr.value;
      }
    } else if(matcher.getTagContent) {
      String content = _parseContent(tokenizer);
      if (content.isNotEmpty) {
        if(matcher.contentRegex != null) {
          String? result = matcher.contentRegex!
              .firstMatch(content)
              ?.group(0)
              ?.split(':')[1]
              .trim();

          if (result != null) {
            results[matcher.key] = result;
          }
        } else {
          results[matcher.key] = content;
        }
      }
    }

    if (results.length > resultSize) {
      matcher.matched = true;
    }
  }

  _AttrMatchResult? _findMatcherAttrs(
      List<TagAttribute>? attrs, Matcher matcher) {
    TagAttribute? matchingAttr;
    TagAttribute? returnAttr;

    for (TagAttribute attr in attrs!) {
      if (!matcher.matchTagOnly && matcher.isMatchAttrName(attr.name!)) {
        matchingAttr = attr;
      } else if (matcher.isMatchReturnAttrName(attr.name!)) {
        returnAttr = attr;
      }
    }

    if ((matchingAttr != null || matcher.matchTagOnly) && returnAttr != null) {
      return _AttrMatchResult(matchingAttr, returnAttr);
    }

    return null;
  }
}

class _AttrMatchResult {
  final TagAttribute? matchingAttr;
  final TagAttribute returnAttr;

  _AttrMatchResult(this.matchingAttr, this.returnAttr) {}
}
