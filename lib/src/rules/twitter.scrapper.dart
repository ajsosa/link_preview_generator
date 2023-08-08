import 'dart:convert';

import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/parser/matching/tag_attribute_matcher.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';
import 'package:universal_html/html.dart';

import '../parser/html_scraper.dart';
import '../parser/matching/matcher_group.dart';
import '../parser/matching/matcher_groups.dart';

class TwitterScrapper {
  static WebInfo scrape(HtmlScraper scraper, String data, String url, {bool showDomain = false}) {
    MatcherGroup domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    MatcherGroup iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');
    MatcherGroup baseUrlMatchers = LinkPreviewScrapper.getBaseUrlMatchers('base');

    MatcherGroup imageMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image:user_generated', attrToReturn: 'content'),
    ], key: 'image');

    MatcherGroup videoMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:video:url', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:video:secure_url', attrToReturn: 'content'),
    ], key: 'video');

    MatcherGroups groups = MatcherGroups([iconMatchers, baseUrlMatchers, imageMatchers, videoMatchers]);

    if (showDomain) {
      groups.add(domainMatchers);
    }

    Map<String, String> results = scraper.scrapeHtml(groups);

    try {
      final scrappedData = json.decode(data);
      final htmlElement = document.createElement('html');
      htmlElement.innerHtml = scrappedData['html'];

      final baseUrl = LinkPreviewScrapper.getBaseUrl(results['base'], url);
      final image = results['image'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['image']!) : null;
      final video = results['video'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['video']!) : null;

      return WebInfo(
        description: htmlElement.querySelector('p')?.text ?? '',
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: LinkPreviewScrapper.getIcon(results['icon'], url) ?? '',
        image: image ?? '',
        video: video ?? '',
        title: '${scrappedData['author_name']} on Twitter',
        type: LinkPreviewType.twitter,
      );
    } catch (e) {
      print('Twitter scrapper failure Error: $e');
      return WebInfo(
        description: "It's what's happening / Twitter",
        domain: 'twitter.com',
        icon: 'https://twitter.com/favicon.ico',
        image: 'https://abs.twimg.com/responsive-web/client-web/icon-ios.b1fc7275.png',
        video: '',
        title: 'Twitter',
        type: LinkPreviewType.error,
      );
    }
  }
}
