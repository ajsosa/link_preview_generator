class Matcher {
  final String tag;
  String key;
  String matchAttrName;
  String matchAttrValue;
  String attrName;
  final RegExp? contentRegex;
  bool isAttrNameStarMatch = false;
  bool matchTagOnly;
  bool getTagContent;
  bool matched = false;
  bool caseInsensitive;

  Matcher(
      {required this.key,
      required this.tag,
      this.matchAttrName = '',
      this.matchAttrValue = '',
      this.attrName = '',
      this.contentRegex,
      this.matchTagOnly = false,
      this.getTagContent = false,
      this.caseInsensitive = false}) {
    if (matchAttrName.contains('*')) {
      matchAttrName = matchAttrName.replaceAll('*', '');
      isAttrNameStarMatch = true;
    }

    if(caseInsensitive) {
      matchAttrValue = matchAttrValue.toLowerCase();
    }
  }

  bool isTag(String otherTag) {
    return tag == otherTag || tag == '*';
  }

  bool isMatchAttrName(String attr) {
    return matchAttrName == attr;
  }

  bool isMatchOrInAttrValue(String attr) {
    String otherAttr = attr;
    if (caseInsensitive) {
      otherAttr = attr.toLowerCase();
    }
    return isAttrNameStarMatch ? otherAttr.contains(matchAttrValue) : otherAttr == matchAttrValue;
  }

  bool isMatchReturnAttrName(String attr) {
    return attrName == attr;
  }
}
