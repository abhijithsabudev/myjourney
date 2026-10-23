import 'models.dart';

/// Parses the portfolio Markdown file into a [Portfolio].
///
/// Conventions (see `assets/content.md` for a full example):
/// - `# Name`, then a `**bold line**` for the role, an optional `> tagline`
///   and an optional `![Photo](assets/images/profile.jpg)` profile photo.
/// - Each `## Heading` starts a section. Its type is picked from keywords in
///   the heading (summary/about, highlights, skills, experience, projects,
///   open source/packages, education, certifications/awards, contact). Any
///   other heading becomes a plain text section.
/// - `<!-- comments -->` and `---` rules are ignored.
Portfolio parsePortfolio(String source) {
  final lines = source
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
      .split('\n');

  var name = '';
  var role = '';
  var tagline = '';
  var photo = '';
  final raw = <_RawSection>[];

  for (final line in lines) {
    final t = line.trim();
    if (t.startsWith('# ')) {
      name = stripInline(t.substring(2));
    } else if (t.startsWith('## ')) {
      raw.add(_RawSection(stripInline(t.substring(3))));
    } else if (raw.isNotEmpty) {
      raw.last.lines.add(line);
    } else if (t.startsWith('![')) {
      photo = _image.firstMatch(t)?.group(1)?.trim() ?? '';
    } else if (role.isEmpty && t.startsWith('**')) {
      role = stripInline(t);
    } else if (t.startsWith('>')) {
      tagline = stripInline(t.substring(1));
    }
  }

  final stats = <Stat>[];
  final sections = <PortfolioSection>[];
  for (final section in raw) {
    final key = section.title.toLowerCase();
    if (key.contains('highlight')) {
      stats.addAll(_parseStats(section));
    } else {
      sections.add(_parseSection(key, section));
    }
  }

  return Portfolio(
    name: name,
    role: role,
    tagline: tagline,
    stats: stats,
    sections: sections,
    photo: photo,
  );
}

PortfolioSection _parseSection(String key, _RawSection s) {
  bool has(List<String> words) => words.any(key.contains);

  if (has(['summary', 'about', 'profile'])) {
    return SummarySection(s.title, s.paragraphs);
  }
  if (has(['skill', 'tech stack'])) return _parseSkills(s);
  if (has(['experience', 'employment', 'work history'])) {
    return _parseExperience(s);
  }
  if (has(['open-source', 'open source', 'package', 'contribution'])) {
    return _parsePackages(s);
  }
  if (has(['project', 'portfolio', 'apps'])) return _parseProjects(s);
  if (has(['education', 'academic'])) return _parseEducation(s);
  if (has(['certification', 'award', 'achievement', 'course'])) {
    return ListSection(s.title, s.bullets.map(stripInline).toList());
  }
  if (has(['contact', 'connect', 'get in touch'])) return _parseContact(s);
  return TextSection(s.title, s.paragraphs, s.bullets.map(_bullet).toList());
}

/// `- **6+** Years of experience`
List<Stat> _parseStats(_RawSection s) => [
  for (final b in s.bullets.map(_bullet))
    if (b.label != null) Stat(b.label!, b.text) else Stat(b.text, ''),
];

/// A Markdown table (`| Category | a, b, c |`) or bullets
/// (`- **Category:** a, b, c`).
SkillsSection _parseSkills(_RawSection s) {
  final groups = <SkillGroup>[];
  final rows = s.lines
      .map((l) => l.trim())
      .where(
        (l) => l.startsWith('|') && !RegExp(r'^\|[\s:|-]+\|?$').hasMatch(l),
      )
      .toList();
  // The first table row is the header.
  for (final row in rows.skip(1)) {
    final cells = row.split('|').map((c) => c.trim()).toList();
    final values = cells.where((c) => c.isNotEmpty).toList();
    if (values.length >= 2) {
      groups.add(SkillGroup(stripInline(values[0]), _splitList(values[1])));
    }
  }
  for (final b in s.bullets.map(_bullet)) {
    if (b.label != null) groups.add(SkillGroup(b.label!, _splitList(b.text)));
  }
  return SkillsSection(s.title, groups);
}

/// ```
/// ### Company — Start – End
/// *Role*
/// - **Label:** text
/// ```
ExperienceSection _parseExperience(_RawSection s) {
  final jobs = [
    for (final sub in s.subsections)
      Job(
        company: _splitHeading(sub.title).$1,
        period: _splitHeading(sub.title).$2,
        role: sub.paragraphs.map(stripInline).firstOrNull ?? '',
        points: sub.bullets.map(_bullet).toList(),
      ),
  ];
  return ExperienceSection(s.title, jobs);
}

/// `- **Title** (Category) — description [link](url) ![](screenshot.png)`,
/// optionally grouped under `### Group` headings.
ProjectsSection _parseProjects(_RawSection s) {
  final projects = <Project>[];
  void addAll(List<String> bullets, String group) {
    for (var text in bullets) {
      var image = '';
      final img = _image.firstMatch(text);
      if (img != null) {
        image = img.group(1)!.trim();
        text = text.replaceFirst(img.group(0)!, '').trim();
      }
      var url = '';
      final link = _link.firstMatch(text);
      if (link != null) {
        url = link.group(2)!.trim();
        text = text.replaceFirst(link.group(0)!, '').trim();
      }
      final b = _bullet(text);
      // Without a bold title, the whole line is the title.
      final title = b.label ?? stripInline(text);
      var rest = b.label == null ? '' : b.text;
      var category = '';
      final paren = RegExp(r'^\(([^)]*)\)\s*').firstMatch(rest);
      if (paren != null) {
        category = paren.group(1)!.trim();
        rest = rest.substring(paren.end);
      }
      projects.add(
        Project(
          title: title,
          group: group,
          category: category,
          description: _trimSeparator(rest),
          url: url,
          image: image,
        ),
      );
    }
  }

  addAll(s.ownBullets, '');
  for (final sub in s.subsections) {
    addAll(sub.bullets, sub.title);
  }
  return ProjectsSection(s.title, projects);
}

/// `- **package_name** – description`. Links to pub.dev unless the line has
/// its own `[link](url)`.
PackagesSection _parsePackages(_RawSection s) {
  final packages = <Package>[];
  for (var text in s.bullets) {
    final link = _link.firstMatch(text);
    if (link != null) text = text.replaceFirst(link.group(0)!, '').trim();
    final b = _bullet(text);
    final name = b.label ?? stripInline(text);
    packages.add(
      Package(
        name,
        b.label == null ? '' : b.text,
        link?.group(2)?.trim() ?? 'https://pub.dev/packages/$name',
      ),
    );
  }
  return PackagesSection(s.title, packages, s.paragraphs);
}

/// ```
/// ### Degree — Start – End
/// Institution
/// - Note
/// ```
EducationSection _parseEducation(_RawSection s) {
  final entries = [
    for (final sub in s.subsections)
      EducationEntry(
        degree: _splitHeading(sub.title).$1,
        period: _splitHeading(sub.title).$2,
        institution: sub.paragraphs.map(stripInline).join('\n'),
        notes: sub.bullets.map(stripInline).toList(),
      ),
  ];
  return EducationSection(s.title, entries);
}

/// `- Label: value`. `Email`, `Phone`, `Location`, `Resume` and `Coffee` are
/// special; every other label becomes a link button. A line with no value is
/// skipped, so empty fields hide their buttons.
ContactSection _parseContact(_RawSection s) {
  var email = '';
  var phone = '';
  var location = '';
  var resume = '';
  var coffee = '';
  final links = <ContactLink>[];
  for (final text in s.bullets) {
    final match = RegExp(r'^\**([^:*]+?)\**\s*:\**\s*(.+)$').firstMatch(text);
    if (match == null) continue;
    final label = match.group(1)!.trim();
    var value = match.group(2)!.trim();
    final link = _link.firstMatch(value);
    if (link != null) value = link.group(2)!.trim();
    switch (label.toLowerCase()) {
      case 'email':
        email = value;
      case 'location':
        location = stripInline(value);
      case 'resume' || 'cv':
        resume = driveDownloadUrl(value);
      case 'coffee' || 'buy me a coffee':
        coffee = value.contains('://') ? value : 'https://$value';
      case 'phone' || 'mobile':
        phone = indianPhone(value);
      default:
        links.add(ContactLink(label, value));
    }
  }
  return ContactSection(
    s.title,
    intro: s.paragraphs.join('\n\n'),
    headline: s.quote,
    email: email,
    phone: phone,
    location: location,
    resumeUrl: resume,
    coffeeUrl: coffee,
    links: links,
  );
}

// ---------------------------------------------------------------------------
// Helpers

final _image = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
final _link = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

/// Turns a Google Drive share link (`.../file/d/<id>/view`, `open?id=<id>`)
/// into a direct-download link; any other URL is returned unchanged.
String driveDownloadUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'drive.google.com') return url;
  final segments = uri.pathSegments;
  final i = segments.indexOf('d');
  final id = i >= 0 && i + 1 < segments.length
      ? segments[i + 1]
      : uri.queryParameters['id'];
  if (id == null || id.isEmpty) return url;
  return 'https://drive.google.com/uc?export=download&id=$id';
}

/// Formats an Indian mobile number as "+91 98765 43210", accepting it with or
/// without the +91 / 91 / 0 prefix and any spacing. Other numbers (another
/// country code, landlines) are returned as written.
String indianPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final local = switch (digits.length) {
    10 => digits,
    11 when digits.startsWith('0') => digits.substring(1),
    12 when digits.startsWith('91') => digits.substring(2),
    _ => null,
  };
  if (local == null ||
      value.trim().startsWith('+') && !digits.startsWith('91')) {
    return value.trim();
  }
  return '+91 ${local.substring(0, 5)} ${local.substring(5)}';
}

/// Removes Markdown emphasis and turns `[text](url)` into `text`.
String stripInline(String s) => s
    .replaceAll(_image, '')
    .replaceAllMapped(_link, (m) => m.group(1)!)
    .replaceAll(RegExp(r'\*\*|__'), '')
    .replaceAllMapped(
      RegExp(r'(^|\s)[*_](\S.*?)[*_](?=\s|$|[.,;:])'),
      (m) => '${m.group(1)}${m.group(2)}',
    )
    .trim();

/// Splits `**Label:** text` / `**Label** – text` into label and text.
Bullet _bullet(String line) {
  final m = RegExp(r'^\*\*(.+?)\*\*(.*)$').firstMatch(line.trim());
  if (m == null) return Bullet(line.trim());
  var label = m.group(1)!.trim();
  if (label.endsWith(':')) label = label.substring(0, label.length - 1);
  return Bullet(_trimSeparator(m.group(2)!), label: stripInline(label));
}

String _trimSeparator(String s) =>
    s.replaceFirst(RegExp(r'^\s*[:—–-]?\s*'), '').trim();

/// `Left — Right`; splits on the first em dash, en dash or pipe surrounded by
/// spaces, so the right side may itself contain dashes ("May 2023 – Present").
(String, String) _splitHeading(String heading) {
  final m = RegExp(r'^(.*?)\s+[—–|]\s+(.*)$').firstMatch(heading);
  if (m == null) return (stripInline(heading), '');
  return (stripInline(m.group(1)!), stripInline(m.group(2)!));
}

List<String> _splitList(String s) => s
    .split(RegExp(r'[,;]'))
    .map(stripInline)
    .where((e) => e.isNotEmpty)
    .toList();

class _RawSection {
  _RawSection(this.title);
  final String title;
  final List<String> lines = [];

  static bool _isBullet(String t) => t.startsWith('- ') || t.startsWith('* ');

  /// Bullets anywhere in the section, including inside `###` subsections.
  List<String> get bullets => [
    for (final l in lines)
      if (_isBullet(l.trim())) l.trim().substring(2).trim(),
  ];

  /// Bullets that appear before the first `###` subsection.
  List<String> get ownBullets {
    final out = <String>[];
    for (final l in lines) {
      final t = l.trim();
      if (t.startsWith('### ')) break;
      if (_isBullet(t)) out.add(t.substring(2).trim());
    }
    return out;
  }

  /// Plain-text paragraphs (blank-line separated), excluding bullets, tables,
  /// headings and rules.
  List<String> get paragraphs {
    final out = <String>[];
    final buffer = <String>[];
    void flush() {
      if (buffer.isNotEmpty) out.add(buffer.join(' '));
      buffer.clear();
    }

    for (final l in lines) {
      final t = l.trim();
      if (t.isEmpty ||
          t == '---' ||
          t.startsWith('#') ||
          t.startsWith('|') ||
          t.startsWith('>')) {
        flush();
      } else if (_isBullet(t)) {
        flush();
      } else {
        buffer.add(t);
      }
    }
    flush();
    return out;
  }

  /// The first `> blockquote` line, used as a headline.
  String get quote {
    for (final l in lines) {
      final t = l.trim();
      if (t.startsWith('>')) return stripInline(t.substring(1));
    }
    return '';
  }

  List<_RawSection> get subsections {
    final out = <_RawSection>[];
    for (final l in lines) {
      final t = l.trim();
      if (t.startsWith('### ')) {
        out.add(_RawSection(t.substring(4).trim()));
      } else if (out.isNotEmpty) {
        out.last.lines.add(l);
      }
    }
    return out;
  }
}
