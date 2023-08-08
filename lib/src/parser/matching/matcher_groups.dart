import '../token.dart';
import '../tokenizer.dart';
import 'matcher_group.dart';

class MatcherGroups {
  final List<MatcherGroup> _groups;
  bool hasMatch = false;

  MatcherGroups(this._groups);

  void match(HtmlTokenizer tokenizer, StartTagToken tag) {
    for (MatcherGroup group in _groups) {
      if (group.isDone()) {
        continue;
      }

      group.match(tokenizer, tag);
    }
  }

  bool haveAllRequired() {
    for (MatcherGroup group in _groups) {
      if (!group.isDone()) {
        return false;
      }
    }

    return true;
  }

  Map<String, String> getResults() {
    Map<String, String> results = {};

    for (MatcherGroup group in _groups) {
      if (!group.isDone()) {
        continue;
      }

      results[group.key] = group.result;
    }

    return results;
  }
}
