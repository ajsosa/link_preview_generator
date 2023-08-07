import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';

import '../parser/html_scraper.dart';
import '../parser/matcher.dart';
import '../parser/matcher_groups.dart';

class AmazonScrapper {
  static WebInfo scrape(HtmlScraper scraper, String url) {
    List<Matcher> domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    List<Matcher> iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');
    List<Matcher> baseUrlMatchers = LinkPreviewScrapper.getBaseUrlMatchers('base');
    List<Matcher> mainTitleMatchers = LinkPreviewScrapper.getPrimaryTitleMatchers('mainTitle');
    List<Matcher> secondTitleMatchers = LinkPreviewScrapper.getSecondaryTitleMatchers('secondTitle');
    List<Matcher> lastTitleMatchers = LinkPreviewScrapper.getLastResortTitleMatchers('lastTitle');

    List<Matcher> imageMatchers = [
      Matcher(key: 'image', tag: '*', matchAttrName: 'class*', matchAttrValue: 'a-dynamic-image', attrName: 'data-old-hires'),
      Matcher(key: 'image', tag: '*', matchAttrName: 'class*', matchAttrValue: 'a-dynamic-image', attrName: 'src')
    ];

    List<Matcher> descriptionMatchers = [
      Matcher(key: 'description', tag: 'meta', matchAttrName: 'name', matchAttrValue: 'description', attrName: 'content'),
    ];

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
