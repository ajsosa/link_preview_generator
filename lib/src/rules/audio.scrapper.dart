import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';

import '../parser/html_scraper.dart';
import '../parser/matching/matcher_group.dart';
import '../parser/matching/matcher_groups.dart';

class AudioScrapper {
  static WebInfo scrape(HtmlScraper scraper, String url) {

    MatcherGroup domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    MatcherGroup iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');

    Map<String, String> results = scraper.parseHtml(MatcherGroups([domainMatchers, iconMatchers]));

    try {
      return WebInfo(
        description: url.substring(url.lastIndexOf('/') + 1),
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: LinkPreviewScrapper.getIcon(results['icon'], url) ?? '',
        image: '',
        video: '',
        title: url.substring(url.lastIndexOf('/') + 1),
        type: LinkPreviewType.audio,
      );
    } catch (e) {
      print('Audio scrapper failure Error: $e');
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
