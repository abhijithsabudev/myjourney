// Fills the built site's <head> and manifest from assets/content.md, so link
// previews (LinkedIn, WhatsApp, Slack) and search engines see real content.
// Flutter draws on a canvas, so crawlers otherwise find almost no text.
//
// Run after `flutter build web`:
//   dart run tool/web_meta.dart [build/web] [--site-url=https://example.com/]
import 'dart:convert';
import 'dart:io';

import 'package:portfolio/content/markdown_parser.dart';
import 'package:portfolio/content/models.dart';

void main(List<String> args) {
  final dir = args.firstWhere(
    (a) => !a.startsWith('--'),
    orElse: () => 'build/web',
  );
  final siteUrl = args
      .firstWhere((a) => a.startsWith('--site-url='), orElse: () => '')
      .replaceFirst('--site-url=', '');

  final p = parsePortfolio(File('assets/content.md').readAsStringSync());
  final title = p.name.isEmpty
      ? 'Portfolio'
      : '${p.displayName} · ${p.roleTitle}';
  final description = _truncate(
    p.sections
            .whereType<SummarySection>()
            .firstOrNull
            ?.paragraphs
            .firstOrNull ??
        p.tagline,
    160,
  );

  final indexFile = File('$dir/index.html');
  var html = indexFile.readAsStringSync();
  html = html
      .replaceFirst(
        RegExp(r'<title>.*?</title>'),
        '<title>${_esc(title)}</title>',
      )
      .replaceFirst(
        RegExp(r'<meta name="description"[^>]*>'),
        '<meta name="description" content="${_esc(description)}">',
      )
      .replaceFirst(
        RegExp(r'<meta name="apple-mobile-web-app-title"[^>]*>'),
        '<meta name="apple-mobile-web-app-title" content="${_esc(p.displayName)}">',
      );

  final image = siteUrl.isEmpty
      ? ''
      : Uri.parse(siteUrl).resolve('og-image.jpg').toString();
  final head = [
    '<meta property="og:type" content="website">',
    '<meta property="og:title" content="${_esc(title)}">',
    '<meta property="og:description" content="${_esc(description)}">',
    if (siteUrl.isNotEmpty)
      '<meta property="og:url" content="${_esc(siteUrl)}">',
    if (image.isNotEmpty) '<meta property="og:image" content="${_esc(image)}">',
    '<meta name="twitter:card" content="summary">',
    if (siteUrl.isNotEmpty) '<link rel="canonical" href="${_esc(siteUrl)}">',
  ];
  html = _replaceBlock(html, 'head', head.join('\n  '), before: '</head>');
  html = _replaceBlock(html, 'body', _seoContent(p), after: '<body>');
  indexFile.writeAsStringSync(html);

  final manifestFile = File('$dir/manifest.json');
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  manifest
    ..['name'] = title
    ..['short_name'] = p.name.isEmpty
        ? 'Portfolio'
        : p.displayName.split(' ').first
    ..['description'] = description;
  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('    ').convert(manifest),
  );

  stdout.writeln('web_meta: updated $dir/index.html and manifest.json');
}

/// Readable copy of the page for crawlers and screen readers without JS.
/// Visually hidden; Flutter renders the real page on top.
String _seoContent(Portfolio p) {
  final b = StringBuffer('<main class="seo">\n');
  b.writeln('<h1>${_esc(p.displayName)}</h1>');
  b.writeln('<p>${_esc(p.role)}</p>');
  if (p.tagline.isNotEmpty) b.writeln('<p>${_esc(p.tagline)}</p>');
  for (final s in p.sections) {
    switch (s) {
      case SummarySection():
        b.writeln('<h2>${_esc(s.title)}</h2>');
        for (final para in s.paragraphs) {
          b.writeln('<p>${_esc(stripInline(para))}</p>');
        }
      case ProjectsSection():
        b.writeln('<h2>${_esc(s.title)}</h2><ul>');
        for (final pr in s.projects) {
          final name = pr.url.isEmpty
              ? _esc(pr.title)
              : '<a href="${_esc(pr.url)}">${_esc(pr.title)}</a>';
          final extra = [
            pr.category,
            pr.description,
          ].where((t) => t.isNotEmpty).join(' — ');
          b.writeln(
            '<li>$name${extra.isEmpty ? '' : ' (${_esc(extra)})'}</li>',
          );
        }
        b.writeln('</ul>');
      case PackagesSection():
        b.writeln('<h2>${_esc(s.title)}</h2><ul>');
        for (final pkg in s.packages) {
          b.writeln(
            '<li><a href="${_esc(pkg.url)}">${_esc(pkg.name)}</a> — ${_esc(pkg.description)}</li>',
          );
        }
        b.writeln('</ul>');
      case ContactSection():
        final links = [
          ...s.links.where((l) => l.url.startsWith('http')),
          if (s.resumeUrl.isNotEmpty) ContactLink('Resume', s.resumeUrl),
          if (s.coffeeUrl.isNotEmpty)
            ContactLink('Buy me a coffee', s.coffeeUrl),
        ];
        if (links.isEmpty) continue;
        b.writeln('<h2>${_esc(s.title)}</h2><ul>');
        for (final l in links) {
          b.writeln('<li><a href="${_esc(l.url)}">${_esc(l.label)}</a></li>');
        }
        b.writeln('</ul>');
      default:
    }
  }
  b.write('</main>');
  return b.toString();
}

/// Inserts [content] between `<!-- web-meta:name -->` markers, replacing any
/// earlier run's output so the script is safe to run twice.
String _replaceBlock(
  String html,
  String name,
  String content, {
  String? before,
  String? after,
}) {
  final start = '<!-- web-meta:$name -->', end = '<!-- /web-meta:$name -->';
  final block = '$start\n  $content\n  $end';
  final existing = RegExp(
    '${RegExp.escape(start)}.*?${RegExp.escape(end)}',
    dotAll: true,
  );
  if (existing.hasMatch(html)) return html.replaceFirst(existing, block);
  if (before != null) return html.replaceFirst(before, '  $block\n$before');
  return html.replaceFirst(after!, '$after\n  $block');
}

String _truncate(String s, int max) {
  s = stripInline(s);
  if (s.length <= max) return s;
  final cut = s.substring(0, max - 1);
  return '${cut.substring(0, cut.lastIndexOf(' '))}…';
}

/// Like `HtmlEscape()` but leaves `/` alone so URLs stay readable.
const _escape = HtmlEscape(
  HtmlEscapeMode(escapeLtGt: true, escapeQuot: true, escapeApos: true),
);

String _esc(String s) => _escape.convert(s);
