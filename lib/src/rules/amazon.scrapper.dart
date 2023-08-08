import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/parser/matching/tag_attribute_matcher.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';

import '../parser/html_scraper.dart';
import '../parser/matching/matcher_group.dart';
import '../parser/matching/matcher_groups.dart';

class AmazonScrapper {
  static WebInfo scrape(HtmlScraper scraper, String url) {
    MatcherGroup domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    MatcherGroup iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');
    MatcherGroup baseUrlMatchers = LinkPreviewScrapper.getBaseUrlMatchers('base');
    MatcherGroup mainTitleMatchers = LinkPreviewScrapper.getPrimaryTitleMatchers('mainTitle');
    MatcherGroup secondTitleMatchers = LinkPreviewScrapper.getSecondaryTitleMatchers('secondTitle');
    MatcherGroup lastTitleMatchers = LinkPreviewScrapper.getLastResortTitleMatchers('lastTitle');

    MatcherGroup imageMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: '*', attrToMatch: 'class*', attrValueToMatch: 'a-dynamic-image', attrToReturn: 'data-old-hires'),
      TagAttributeMatcher(tagToMatch: '*', attrToMatch: 'class*', attrValueToMatch: 'a-dynamic-image', attrToReturn: 'src')
    ], key: 'image');

    MatcherGroup descriptionMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'description', attrToReturn: 'content'),
    ], key: 'description');

    Map<String, String> results = scraper.parseHtml(MatcherGroups([
      domainMatchers,
      iconMatchers,
      baseUrlMatchers,
      imageMatchers,
      descriptionMatchers,
      mainTitleMatchers,
      secondTitleMatchers,
      lastTitleMatchers,
    ]));

    try {
      var baseUrl = LinkPreviewScrapper.getBaseUrl(results['base'], url);

      var image = results['image'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['image']!) : null;

      return WebInfo(
        description: results['description'] ?? '',
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: LinkPreviewScrapper.getIcon(results['icon'], url) ?? '',
        image: image ?? '',
        video: '',
        title: results['mainTitle'] ?? results['secondTitle'] ?? results['lastTitle'] ?? '',
        type: LinkPreviewType.amazon,
      );
    } catch (e) {
      print('Amazon scrapper failure Error: $e');
      return WebInfo(
        description:
            'Free shipping on millions of items. Get the best of Shopping and Entertainment with Prime. Enjoy low prices and great deals on the largest selection of everyday essentials and other products, including fashion, home, beauty, electronics, Alexa Devices, sporting goods, toys, automotive, pets, baby, books, video games, musical instruments, office supplies, and more.',
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: 'https://www.amazon.com/favicon.ico',
        image: 'http://g-ec2.images-amazon.com/images/G/01/social/api-share/amazon_logo_500500._V323939215_.png',
        video: '',
        title: 'Amazon.com. Spend less. Smile more.',
        type: LinkPreviewType.error,
      );
    }
  }
}
