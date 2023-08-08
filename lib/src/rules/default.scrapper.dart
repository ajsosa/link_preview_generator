import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/parser/matching/tag_attribute_matcher.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';
import 'package:universal_html/html.dart';

import '../parser/html_scraper.dart';
import '../parser/matching/matcher_group.dart';
import '../parser/matching/matcher_groups.dart';

class DefaultScrapper {
  static WebInfo scrape(HtmlScraper scraper, String url) {
    MatcherGroup domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    MatcherGroup iconDefaultMatchers = LinkPreviewScrapper.getIconMatchers('iconDefault');
    MatcherGroup baseUrlMatchers = LinkPreviewScrapper.getBaseUrlMatchers('base');

    MatcherGroup mainTitleMatchers = LinkPreviewScrapper.getPrimaryTitleMatchers('mainTitle');
    MatcherGroup secondTitleMatchers = LinkPreviewScrapper.getSecondaryTitleMatchers('secondTitle');
    MatcherGroup lastTitleMatchers = LinkPreviewScrapper.getLastResortTitleMatchers('lastTitle');

    MatcherGroup imageMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:logo', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'itemprop', attrValueToMatch: 'logo', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'img', attrToMatch: 'itemprop', attrValueToMatch: 'logo', attrToReturn: 'src'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'img', attrToMatch: 'class*', attrValueToMatch: 'logo', attrToReturn: 'content', caseInsensitiveMatch: true),
      TagAttributeMatcher(tagToMatch: 'img', attrToMatch: 'src*', attrValueToMatch: 'logo', attrToReturn: 'content', caseInsensitiveMatch: true),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image:secure_url', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image:url', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:image', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'twitter:image:src', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'twitter:image', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'itemprop', attrValueToMatch: 'image', attrToReturn: 'content'),
    ], key: 'image');

    MatcherGroup iconMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:logo', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'itemprop', attrValueToMatch: 'logo', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'img',  attrToMatch: 'itemprop', attrValueToMatch: 'logo', attrToReturn: 'src'),
    ], key: 'icon');

    // Purposely left out the <p> matcher that was implemented in the original. Can always add later if we need it.
    MatcherGroup descriptionMatchers = MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'description', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'twitter:description', attrToReturn: 'content'),
    ], key: 'description');

    Map<String, String> results = scraper
        .parseHtml(MatcherGroups([baseUrlMatchers, imageMatchers, iconMatchers, descriptionMatchers, domainMatchers, iconDefaultMatchers, mainTitleMatchers, secondTitleMatchers, lastTitleMatchers]));

    try {
      var baseUrl = LinkPreviewScrapper.getBaseUrl(results['base'], url);
      var image = results['image'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['image']!) : null;
      var icon = results['icon'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['icon']!) : null;

      return WebInfo(
        description: results['description'] ?? '',
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: LinkPreviewScrapper.getIcon(results['iconDefault'], url) ?? icon ?? '',
        // TODO: Implement the last resort image scraping
        image: image ?? '',
        //_getDocImage(doc, url) ?? '',
        video: '',
        title: results['mainTitle'] ?? results['secondTitle'] ?? results['lastTitle'] ?? '',
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

  static String? _getDescription(HtmlDocument doc) {
    try {
      final ogDescription = doc.querySelector('meta[name=description]');
      if (ogDescription != null && ogDescription.attributes['content'] != null && ogDescription.attributes['content']!.isNotEmpty) {
        return ogDescription.attributes['content'];
      }
      final twitterDescription = doc.querySelector('meta[name="twitter:description"]');
      if (twitterDescription != null && twitterDescription.attributes['content'] != null && twitterDescription.attributes['content']!.isNotEmpty) {
        return twitterDescription.attributes['content'];
      }
      final metaDescription = doc.querySelector('meta[name="description"]');
      if (metaDescription != null && metaDescription.attributes['content'] != null && metaDescription.attributes['content']!.isNotEmpty) {
        return metaDescription.attributes['content'];
      }
      final paragraphs = doc.querySelectorAll('p');
      String? fstVisibleParagraph;
      for (var i = 0; i < paragraphs.length; i++) {
        // if object is visible
        if (paragraphs[i].offsetParent != null) {
          fstVisibleParagraph = paragraphs[i].text;
          break;
        }
      }
      return fstVisibleParagraph;
    } catch (e) {
      print('Get default description resolution failure Error: $e');
      return null;
    }
  }

  static String? _getDocImage(HtmlDocument doc, String url) {
    try {
      List<ImageElement> imgs = doc.querySelectorAll('img');
      var src = <String?>[];
      if (imgs.isNotEmpty) {
        imgs = imgs.where((img) {
          // ignore: unnecessary_null_comparison
          if (img == null ||
              // ignore: unnecessary_null_comparison
              img.naturalHeight == null ||
              // ignore: unnecessary_null_comparison
              img.naturalWidth == null) return false;
          var addImg = true;
          // ignore: unnecessary_non_null_assertion
          if (img.naturalWidth! > img.naturalHeight!) {
            // ignore: unnecessary_non_null_assertion
            if (img.naturalWidth! / img.naturalHeight! > 3) {
              addImg = false;
            }
          } else {
            // ignore: unnecessary_non_null_assertion
            if (img.naturalHeight! / img.naturalWidth! > 3) {
              addImg = false;
            }
          }
          // ignore: unnecessary_non_null_assertion
          if (img.naturalHeight! <= 50 || img.naturalWidth! <= 50) {
            addImg = false;
          }
          return addImg;
        }).toList();
        if (imgs.isNotEmpty) {
          imgs.forEach((img) {
            if (img.src != null && !img.src!.contains('//')) {
              src.add('${Uri.parse(url).origin}/${img.src!}');
            }
          });
          return LinkPreviewScrapper.handleUrl(src.first!, 'image');
        }
      }
      return null;
    } catch (e) {
      print('Get default image resolution failure Error: $e');
      return null;
    }
  }
}
