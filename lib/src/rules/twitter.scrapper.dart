import 'dart:convert';

import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';
import 'package:universal_html/html.dart';

import '../parser/html_scraper.dart';
import '../parser/matcher.dart';
import '../parser/matcher_groups.dart';

class TwitterScrapper {
  static WebInfo scrape(HtmlScraper scraper, String data, String url) {

    List<Matcher> domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    List<Matcher> iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');
    List<Matcher> baseUrlMatchers = LinkPreviewScrapper.getBaseUrlMatchers('base');

    List<Matcher> imageMatchers = [
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:image', attrName: 'content'),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:image:user_generated', attrName: 'content'),
    ];

    List<Matcher> videoMatchers = [
      Matcher(key: 'video', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:video:url', attrName: 'content'),
      Matcher(key: 'video', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:video:secure_url', attrName: 'content'),
    ];

    Map<String, String> results = scraper.parseHtml(MatcherGroups([domainMatchers, iconMatchers, baseUrlMatchers, imageMatchers, videoMatchers]));

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
        image:
            'https://abs.twimg.com/responsive-web/client-web/icon-ios.b1fc7275.png',
        video: '',
        title: 'Twitter',
        type: LinkPreviewType.error,
      );
    }
  }
}
