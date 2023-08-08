import '../token.dart';
import '../tokenizer.dart';
import 'matcher.dart';

class MatcherGroup {
  final List<Matcher> _matchers;
  bool _hasMatch = false;
  String _result = '';
  final String key;

  MatcherGroup(this._matchers, {required this.key});

  void match(HtmlTokenizer tokenizer, StartTagToken tag) {
    if (_hasMatch) {
      return;
    }

    for (Matcher matcher in _matchers) {
      if (matcher.match(tokenizer, tag)) {
        _result = matcher.getResult();
        _hasMatch = true;
        break;
      }
    }
  }

  bool isDone() {
    return _hasMatch;
  }

  String get result => _result;
}
