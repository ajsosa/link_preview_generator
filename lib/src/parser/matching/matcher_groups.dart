import '../token.dart';
import 'matcher_group.dart';

class MatcherGroups {
  final List<MatcherGroup> _groups;
  bool hasMatch = false;

  MatcherGroups(this._groups);

  void add(MatcherGroup group) {
    _groups.add(group);
  }

  void match(StartTagToken? tag, EndTagToken? endTag, String? content) {
    for (MatcherGroup group in _groups) {
      if (group.isDone()) {
        continue;
      }

      group.match(tag, endTag, content);
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

      if (group.result.isNotEmpty) {
        results[group.key] = group.result;
      }
    }

    return results;
  }
}
