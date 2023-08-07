import 'matcher.dart';

class MatcherGroups {
  List<List<Matcher>> _groups;

  MatcherGroups(this._groups) {}

  List<Matcher> matchTag(String tag) {
    List<Matcher> allMatchers = [];
    for (List<Matcher> group in _groups) {
      List<Matcher> matchedTags = [];
      bool groupHasMatch = false;
      for (Matcher matcher in group) {
        groupHasMatch = groupHasMatch || matcher.matched;
        if (matcher.isTag(tag)) {
          matchedTags.add(matcher);
        }
      }

      if(!groupHasMatch) {
        allMatchers.addAll(matchedTags);
      }
    }
    
    return allMatchers;
  }

  bool haveAllRequired() {
    for (List<Matcher> group in _groups) {
      bool groupMatched = false;
      for (Matcher matcher in group) {
        if (matcher.matched) {
          groupMatched = true;
          break;
        }
      }
      if (!groupMatched) {
        return false;
      }
    }

    return true;
  }
}