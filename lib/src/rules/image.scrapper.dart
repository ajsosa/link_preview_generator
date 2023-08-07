import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';

import '../parser/html_scraper.dart';
import '../parser/matcher.dart';
import '../parser/matcher_groups.dart';

class ImageScrapper {
  static WebInfo scrape(HtmlScraper scraper, String url) {

    List<Matcher> domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    List<Matcher> iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');

    Map<String, String> results = scraper.parseHtml(MatcherGroups([domainMatchers, iconMatchers]));

    try {
      return WebInfo(
        description: url,
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: LinkPreviewScrapper.getIcon(results['icon'], url) ?? '',
        image: '',
        video: '',
        title: url.substring(url.lastIndexOf('/') + 1),
        type: LinkPreviewType.image,
      );
    } catch (e) {
      print('Image scrapper failure Error: $e');
      return WebInfo(
        description: url,
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: '',
        image: '',
        video: '',
        title: url.substring(url.lastIndexOf('/') + 1),
        type: LinkPreviewType.error,
      );
    }
  }
}
