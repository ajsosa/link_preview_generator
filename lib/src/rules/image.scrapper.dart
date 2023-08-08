import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';

import '../parser/html_scraper.dart';
import '../parser/matching/matcher_group.dart';
import '../parser/matching/matcher_groups.dart';

class ImageScrapper {
  static WebInfo scrape(HtmlScraper scraper, String url, {bool showDomain = false}) {
    MatcherGroup domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    MatcherGroup iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');

    MatcherGroups groups = MatcherGroups([iconMatchers]);

    if (showDomain) {
      groups.add(domainMatchers);
    }

    Map<String, String> results = scraper.scrapeHtml(groups);

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
