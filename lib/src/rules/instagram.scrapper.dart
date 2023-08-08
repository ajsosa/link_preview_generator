import 'dart:convert';

import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';

import '../parser/html_scraper.dart';
import '../parser/matching/matcher_group.dart';
import '../parser/matching/matcher_groups.dart';

class InstagramScrapper {
  static WebInfo scrape(HtmlScraper scraper, String data, String url, {bool showDomain = false}) {
    try {
      final dynamic scrappedData = json.decode(data);

      MatcherGroup domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
      MatcherGroup iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');

      MatcherGroups groups = MatcherGroups([iconMatchers]);

      if (showDomain) {
        groups.add(domainMatchers);
      }

      Map<String, String> results = scraper.scrapeHtml(groups);

      return WebInfo(
        description: scrappedData['title'] ?? scrappedData['graphql']['shortcode_media']['edge_media_to_caption']['edges'][0]['node']['text'] ?? '',
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: LinkPreviewScrapper.getIcon(results['icon'], url) ?? '',
        image: scrappedData['graphql']['shortcode_media']['display_url'] ?? '',
        video: '',
        title: scrappedData['graphql']['shortcode_media']['accessibility_caption'] ?? '',
        type: LinkPreviewType.instagram,
      );
    } catch (e) {
      print('Instagram scrapper failure Error: $e');
      return WebInfo(
        description: 'Create an account or log in to Instagram - A simple, fun & creative way to capture, edit & share photos, videos & messages with friends & family.',
        domain: 'instagram.com',
        icon: 'https://instagram.com/favicon.ico',
        image: 'https://instagram.com/static/images/ico/favicon-200.png/ab6eff595bb1.png',
        video: '',
        title: 'Instagram',
        type: LinkPreviewType.error,
      );
    }
  }
}
