import '../token.dart';
import 'matcher.dart';

class MatcherGroup {
  final List<Matcher> _matchers;
  bool _hasMatch = false;
  String _result = '';
  final String key;

  MatcherGroup(this._matchers, {required this.key});

  void match(StartTagToken? tag, EndTagToken? endTag, String? content) {
    if (_hasMatch) {
      return;
    }

    bool hasActiveMatcher = false;
    for (Matcher matcher in _matchers) {
      if (matcher.stopMatching()) {
        continue;
      }

      hasActiveMatcher = true;

      if (matcher.match(tag, endTag, content)) {
        _result = matcher.getResult();
        _hasMatch = true;
        break;
      }
    }

    if (!hasActiveMatcher) {
      _hasMatch = true;
    }
  }

  bool isDone() {
    return _hasMatch;
  }

  String get result => _result;
}
