import 'dart:async';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/parser/html_scraper.dart';
import 'package:link_preview_generator/src/parser/matching/tag_attribute_matcher.dart';
import 'package:link_preview_generator/src/parser/matching/tag_matcher.dart';
import 'package:link_preview_generator/src/rules/amazon.scrapper.dart';
import 'package:link_preview_generator/src/rules/default.scrapper.dart';
import 'package:link_preview_generator/src/rules/image.scrapper.dart';
import 'package:link_preview_generator/src/rules/instagram.scrapper.dart';
import 'package:link_preview_generator/src/rules/twitter.scrapper.dart';
import 'package:link_preview_generator/src/rules/video.scrapper.dart';
import 'package:link_preview_generator/src/rules/youtube.scrapper.dart';
import 'package:link_preview_generator/src/utils/analyzer.dart';
import 'package:link_preview_generator/src/utils/canonical_url.dart';
import 'package:universal_html/html.dart';

import '../parser/matching/matcher_group.dart';
import '../rules/audio.scrapper.dart';

/// Generate data required for a link preview.
/// Wrapper object for the link preview generator.
class LinkPreview {
  /// User agent user for making GET request to given URL.
  /// Uses `WhatsApp v2.21.12.21` user agent.
  static const _userAgent = 'WhatsApp/2.21.12.21 A';

  /// Scraps the link from the given `url` to get the data for the preview.
  /// Returns the data in the form [WebInfo]
  static Future<WebInfo> scrapeFromURL(String url, {bool showBody = false, bool showDomain = false, bool showTitle = false}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
        },
      );

      final mimeType = response.headers['content-type'] ?? '';
      final data = response.body;
      HtmlScraper scraper = HtmlScraper(data);

      if (LinkPreviewScrapper.isMimeVideo(mimeType)) {
        return VideoScrapper.scrape(scraper, url, showDomain: showDomain);
      } else if (LinkPreviewScrapper.isMimeAudio(mimeType)) {
        return AudioScrapper.scrape(scraper, url, showDomain: showDomain);
      } else if (LinkPreviewScrapper.isMimeImage(mimeType)) {
        return ImageScrapper.scrape(scraper, url, showDomain: showDomain);
      } else if (LinkPreviewScrapper.isUrlInsta(url)) {
        final instagramResponse = await http.get(
          Uri.parse('$url?__a=1&max_id=endcursor'),
        );
        return InstagramScrapper.scrape(scraper, instagramResponse.body, url, showDomain: showDomain);
      } else if (LinkPreviewScrapper.isUrlYoutube(url)) {
        return YouTubeScrapper.scrape(scraper, url, showDomain: showDomain, showBody: showBody, showTitle: showTitle);
      } else if (LinkPreviewScrapper.isUrlAmazon(url)) {
        return AmazonScrapper.scrape(scraper, url, showDomain: showDomain, showBody: showBody, showTitle: showTitle);
      } else if (LinkPreviewScrapper.isUrlTwitter(url)) {
        final twitterResponse = await http.get(
          Uri.parse('https://publish.twitter.com/oembed?url=$url'),
        );
        return TwitterScrapper.scrape(scraper, twitterResponse.body, url, showDomain: showDomain);
      } else {
        return DefaultScrapper.scrape(scraper, url, showDomain: showDomain, showBody: showBody, showTitle: showTitle);
      }
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
}

/// Utils required for the link preview generator.
class LinkPreviewScrapper {
  // static final RegExp _base64withMime = RegExp(
  //     r'^(data:(.*);base64,)?(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{4})$');
  static final RegExp _amazonUrl = RegExp(r'https?:\/\/(.*amazon\..*\/.*|.*amzn\..*\/.*|.*a\.co\/.*)$');

  static final RegExp _instaUrl = RegExp(r'^(https?:\/\/www\.)?instagram\.com(\/p\/\w+\/?)');

  static final RegExp _twitterUrl = RegExp(r'^(https?:\/\/(www)?\.?)?twitter\.com\/.+');

  static final RegExp _youtubeUrl = RegExp(r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.?be)\/.+$');

  static String fixRelativeUrls(String baseUrl, String itemUrl) {
    final normalizedUrl = itemUrl.toLowerCase();
    if (normalizedUrl.startsWith('http://') || normalizedUrl.startsWith('https://')) {
      return itemUrl;
    }
    return UrlCanonicalizer(removeFragment: true).canonicalize('$baseUrl/$itemUrl');
  }

  static String? getAttrOfDocElement(HtmlDocument doc, String query, String attr) {
    var attribute = doc.querySelectorAll(query).firstOrNull?.getAttribute(attr);

    if (attribute != null && attribute.isNotEmpty) return attribute;

    return null;
  }

  static String getBaseUrl(String? scrapedUrl, String url) => scrapedUrl ?? Uri.parse(url).origin;

  static MatcherGroup getBaseUrlMatchers(String key) {
    return MatcherGroup([
      TagMatcher(tagToMatch: 'base', attrToReturn: 'href', giveUpAfterTag: 'head'),
    ], key: key);
  }

  static String? getDomain(String? domainName, String url) {
    try {
      return domainName != null ? Uri.parse(domainName).host.replaceFirst('www.', '') : Uri.parse(url).host.replaceFirst('www.', '');
    } catch (e) {
      print('Domain resolution failure Error:$e');
      return null;
    }
  }

  static MatcherGroup getDomainMatchers(String key) {
    return MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'link', attrToMatch: 'rel', attrValueToMatch: 'canonical', attrToReturn: 'href'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:url', attrToReturn: 'content'),
    ], key: key);
  }

  static String? getIcon(String? metaIcon, String url) {
    if (metaIcon != null) {
      return LinkPreviewScrapper.handleUrl(url, metaIcon);
    }
    return '${Uri.parse(url).origin}/favicon.ico';
  }

  static MatcherGroup getIconMatchers(String key) {
    return MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'link', attrToMatch: 'rel', attrValueToMatch: 'icon', attrToReturn: 'href', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'link', attrToMatch: 'rel', attrValueToMatch: 'shortcut icon', attrToReturn: 'href', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:logo', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'itemprop', attrValueToMatch: 'logo', attrToReturn: 'content', excludeExt: '.svg'),
      TagAttributeMatcher(tagToMatch: 'img', attrToMatch: 'itemprop', attrValueToMatch: 'logo', attrToReturn: 'src', excludeExt: '.svg'),
    ], key: key);
  }

  static MatcherGroup getTitleMatchers(String key) {
    return MatcherGroup([
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'property', attrValueToMatch: 'og:title', attrToReturn: 'content'),
      TagAttributeMatcher(tagToMatch: 'meta', attrToMatch: 'name', attrValueToMatch: 'twitter:title', attrToReturn: 'content'),
      TagMatcher(tagToMatch: 'title', giveUpAfterTag: 'head'),
      TagMatcher(tagToMatch: 'h1'),
      TagMatcher(tagToMatch: 'h2'),
    ], key: key);
  }

  static String? handleUrl(String url, String? source) {
    var uri = Uri.parse(url);
    if (LinkPreviewAnalyzer.isNotEmpty(source) && !source!.startsWith('http')) {
      if (source.startsWith('//')) {
        source = '${uri.scheme}:$source';
      } else {
        if (source.startsWith('/')) {
          source = '${uri.origin}$source';
        } else {
          source = '${uri.origin}/$source';
        }
      }
    }
    return source;
  }

  static bool isMimeAudio(String mimeType) => mimeType.startsWith('audio/');

  static bool isMimeImage(String mimeType) => mimeType.startsWith('image/');

  static bool isMimeVideo(String mimeType) => mimeType.startsWith('video/');

  static bool isUrlAmazon(String url) => _amazonUrl.hasMatch(url);

  static bool isUrlInsta(String url) => _instaUrl.hasMatch(url);

  static bool isUrlTwitter(String url) => _twitterUrl.hasMatch(url);

  static bool isUrlYoutube(String url) => _youtubeUrl.hasMatch(url);
}
