import '../token.dart';
import '../tokenizer.dart';

String parseContent(HtmlTokenizer tokenizer) {
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
