import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/parser/matching/tag_attribute_matcher.dart';
import 'package:link_preview_generator/src/parser/matching/tag_matcher.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';

import '../parser/html_scraper.dart';
import '../parser/matching/matcher_group.dart';
import '../parser/matching/matcher_groups.dart';

class YouTubeScrapper {
  static String? getYouTubeVideoId(String url) {
    final youtubeRegex = RegExp(r'.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*');
    if (youtubeRegex.hasMatch(url)) {
      return youtubeRegex.firstMatch(url)?.group(7);
    }

    return null;
  }

  static WebInfo scrape(HtmlScraper scraper, String url) {
    MatcherGroup domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    MatcherGroup iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');

    MatcherGroup descriptionMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'description', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'twitter:description', attrToReturn: 'content'),
    ], key: 'description');

    RegExp titleReg = RegExp('"title":"(.+?)"');

    MatcherGroup titleMatchers = MatcherGroup([
      TagMatcher(tagToMatch: 'title'),
      TagMatcher(tagToMatch: 'script', contentRegex: titleReg)
    ], key: 'title');

    Map<String, String> results = scraper.parseHtml(MatcherGroups([domainMatchers, iconMatchers, descriptionMatchers, titleMatchers]));

    try {
      final id = getYouTubeVideoId(url);

      return WebInfo(
        description: results['description'] ?? url,
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: LinkPreviewScrapper.getIcon(results['icon'], url) ?? '',
        image: id != null ? 'https://img.youtube.com/vi/$id/0.jpg' : '',
        video: '',
        title: results['title'] ?? '',
        type: LinkPreviewType.youtube,
      );
    } catch (e) {
      print('Youtube scrapper failure Error: $e');
      return WebInfo(
        description: 'Enjoy the videos and music that you love, upload original content and share it all with friends, family and the world on YouTube.',
        domain: 'youtube.com',
        icon: 'https://www.youtube.com/s/desktop/ff5301c8/img/favicon_96x96.png',
        image: '',
        video: '',
        title: 'YouTube',
        type: LinkPreviewType.error,
      );
    }
  }
}
