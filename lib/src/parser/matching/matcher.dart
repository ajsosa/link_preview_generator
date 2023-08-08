import '../token.dart';
import '../tokenizer.dart';

abstract class Matcher {
  bool match(HtmlTokenizer tokenizer, StartTagToken tag);

  bool isMatched();

  String getResult();
}
