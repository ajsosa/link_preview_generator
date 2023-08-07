import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/utils/scrapper.dart';
import 'package:universal_html/html.dart';

import '../parser/html_scraper.dart';
import '../parser/matcher.dart';
import '../parser/matcher_groups.dart';

class DefaultScrapper {
  static WebInfo scrape(HtmlScraper scraper, String url) {

    List<Matcher> domainMatchers = LinkPreviewScrapper.getDomainMatchers('domain');
    List<Matcher> iconDefaultMatchers = LinkPreviewScrapper.getIconMatchers('iconDefault');
    List<Matcher> baseUrlMatchers = LinkPreviewScrapper.getBaseUrlMatchers('base');

    List<Matcher> mainTitleMatchers = LinkPreviewScrapper.getPrimaryTitleMatchers('mainTitle');
    List<Matcher> secondTitleMatchers = LinkPreviewScrapper.getSecondaryTitleMatchers('secondTitle');
    List<Matcher> lastTitleMatchers = LinkPreviewScrapper.getLastResortTitleMatchers('lastTitle');

    List<Matcher> imageMatchers = [
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:logo', attrName: 'content'),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'itemprop', matchAttrValue: 'logo', attrName: 'content'),
      Matcher(key: 'image', tag: 'img', matchAttrName: 'itemprop', matchAttrValue: 'logo', attrName: 'src'),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:image', attrName: 'content'),
      Matcher(key: 'image', tag: 'img', matchAttrName: 'class*', matchAttrValue: 'logo', attrName: 'content', caseInsensitive: true),
      Matcher(key: 'image', tag: 'img', matchAttrName: 'src*', matchAttrValue: 'logo', attrName: 'content', caseInsensitive: true),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:image:secure_url', attrName: 'content'),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:image:url', attrName: 'content'),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:image', attrName: 'content'),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'name', matchAttrValue: 'twitter:image:src', attrName: 'content'),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'name', matchAttrValue: 'twitter:image', attrName: 'content'),
      Matcher(key: 'image', tag: 'meta', matchAttrName: 'itemprop', matchAttrValue: 'image', attrName: 'content'),
    ];

    List<Matcher> iconMatchers = [
      Matcher(key: 'icon', tag: 'meta', matchAttrName: 'property', matchAttrValue: 'og:logo', attrName: 'content'),
      Matcher(key: 'icon', tag: 'meta', matchAttrName: 'itemprop', matchAttrValue: 'logo', attrName: 'content'),
      Matcher(key: 'icon', tag: 'img', matchAttrName: 'itemprop', matchAttrValue: 'logo', attrName: 'src'),
    ];

    // Purposely left out the <p> matcher that was implemented in the original. Can always add later if we need it.
    List<Matcher> descriptionMatchers = [
      Matcher(key: 'description', tag: 'meta', matchAttrName: 'name', matchAttrValue: 'description', attrName: 'content'),
      Matcher(key: 'description', tag: 'meta', matchAttrName: 'name', matchAttrValue: 'twitter:description', attrName: 'content'),
    ];

    Map<String, String> results = scraper.parseHtml(MatcherGroups([
      baseUrlMatchers,
      imageMatchers,
      iconMatchers,
      descriptionMatchers,
      domainMatchers,
      iconDefaultMatchers,
      mainTitleMatchers,
      secondTitleMatchers,
      lastTitleMatchers]));

    try {
      var baseUrl = LinkPreviewScrapper.getBaseUrl(results['base'], url);
      var image = results['image'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['image']!) : null;
      var icon = results['icon'] != null ? LinkPreviewScrapper.fixRelativeUrls(baseUrl, results['icon']!) : null;

      return WebInfo(
        description: results['description'] ?? '',
        domain: LinkPreviewScrapper.getDomain(results['domain'], url) ?? url,
        icon: LinkPreviewScrapper.getIcon(results['iconDefault'], url) ?? icon ?? '',
        // TODO: Implement the last resort image scraping
        image: image ?? '',//_getDocImage(doc, url) ?? '',
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
      if (ogDescription != null &&
          ogDescription.attributes['content'] != null &&
          ogDescription.attributes['content']!.isNotEmpty) {
        return ogDescription.attributes['content'];
      }
      final twitterDescription =
          doc.querySelector('meta[name="twitter:description"]');
      if (twitterDescription != null &&
          twitterDescription.attributes['content'] != null &&
          twitterDescription.attributes['content']!.isNotEmpty) {
        return twitterDescription.attributes['content'];
      }
      final metaDescription = doc.querySelector('meta[name="description"]');
      if (metaDescription != null &&
          metaDescription.attributes['content'] != null &&
          metaDescription.attributes['content']!.isNotEmpty) {
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
