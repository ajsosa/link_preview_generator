import '../token.dart';

abstract class Matcher {
  bool match(StartTagToken? tag, EndTagToken? endTag, String? content);

  bool isMatched();

  bool stopMatching();

  String getResult();
}
