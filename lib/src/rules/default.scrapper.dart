import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/parser/matching/tag_attribute_matcher.dart';
import 'package:link_preview_generator/src/parser/matching/tag_matcher.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';

import '../parser/html_scraper.dart';
import '../parser/matching/matcher_group.dart';
import '../parser/matching/matcher_groups.dart';

class DefaultScrapper {
  static WebInfo scrape(HtmlScraper scraper, String url, {bool showBody = false, bool showDomain = false, bool showTitle = false}) {
    MatcherGroup domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    MatcherGroup iconMatchers = LinkPreviewScrapper.getIconMatchers('icon');
    MatcherGroup baseUrlMatchers = LinkPreviewScrapper.getBaseUrlMatchers('base');

    MatcherGroup titleMatchers = LinkPreviewScrapper.getTitleMatchers('title');

    MatcherGroup imageMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:logo', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'itemprop', attrValueToMatch: 'logo', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'img', attrToMatch: 'itemprop', attrValueToMatch: 'logo', attrToReturn: 'src'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'img', attrToMatch: 'class', attrValueToMatch: 'logo', attrToReturn: 'src', caseInsensitiveMatch: true, wildCardAttrMatch: true, excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'img', attrToMatch: 'src', attrValueToMatch: 'logo', attrToReturn: 'src', caseInsensitiveMatch: true, wildCardAttrMatch: true, excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image:secure_url', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image:url', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'twitter:image:src', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'twitter:image', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'itemprop', attrValueToMatch: 'image', attrToReturn: 'content', excludeExt: '.svg'),
      TagMatcher(tagToMatch: 'img', attrToReturn: 'src')
    ], key: 'image');

    // Purposely left out the <p> matcher that was implemented in the original. Can always add later if we need it.
    MatcherGroup descriptionMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'description', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'twitter:description', attrToReturn: 'content'),
    ], key: 'description');

    MatcherGroups groups = MatcherGroups([iconMatchers, imageMatchers, baseUrlMatchers]);

    if (showBody) {
      groups.add(descriptionMatchers);
    }

    if (showTitle) {
      groups.add(titleMatchers);
    }

    if (showDomain) {
      groups.add(domainMatchers);
    }

    Map<String, String> results = scraper.scrapeHtml(groups);

    try {
      var baseUrl = LinkPreviewScrapper.getBaseUrl(results['base'], url);
      var image = results['image'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['image']!) : null;
      var icon = results['icon'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['icon']!) : null;

      return WebInfo(
        description: results['description'] ?? '',
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: icon ?? '',
        image: image ?? _getLastResortImage(results['lastImage'], url) ?? '',
        video: '',
        title: results['title'] ?? '',
        type: LinkPreviewType.def,
      );
    } catch (e) {
      print('Default scrapper failure Error: $e');
      return WebInfo(
        description: '',
        domain: url,
        icon: '',
        image: '',
        video: '',
        title: '',
        type: LinkPreviewType.error,
      );
    }
  }

  static String? _getLastResortImage(String? img, String url) {
    String? finalLink;

    if (img != null && !img.contains('//')) {
      String imgUrl = '${Uri.parse(url).origin}/$img';

      finalLink = LinkPreviewScrapper.handleUrl(imgUrl, 'image');
    }

    return finalLink;
  }
}
