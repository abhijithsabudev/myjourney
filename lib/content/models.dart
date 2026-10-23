/// Data parsed from `assets/content.md`. See `markdown_parser.dart` for the
/// Markdown conventions that produce each type.
class Portfolio {
  const Portfolio({
    required this.name,
    required this.role,
    required this.tagline,
    required this.stats,
    required this.sections,
    this.photo = '',
  });

  final String name;
  final String role;
  final String tagline;

  /// Asset path of the profile photo; empty shows initials instead.
  final String photo;
  final List<Stat> stats;
  final List<PortfolioSection> sections;

  ContactSection? get contact =>
      sections.whereType<ContactSection>().firstOrNull;

  /// "Senior Flutter Developer | iOS • Android" → "Senior Flutter Developer".
  String get roleTitle => role.split('|').first.trim();

  /// "Senior Flutter Developer | iOS • Android" → ["iOS", "Android"].
  List<String> get platforms {
    final parts = role.split('|');
    if (parts.length < 2) return const [];
    return parts[1]
        .split(RegExp(r'[•,·/]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  String get initials => name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

class Stat {
  const Stat(this.value, this.label);
  final String value;
  final String label;
}

class Bullet {
  const Bullet(this.text, {this.label});
  final String? label;
  final String text;
}

sealed class PortfolioSection {
  const PortfolioSection(this.title);
  final String title;

  /// Stable id used for in-page navigation.
  String get id => title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  /// Short label shown in the nav bar; null hides the section from the nav.
  String? get navLabel => title;
}

class SummarySection extends PortfolioSection {
  const SummarySection(super.title, this.paragraphs);
  final List<String> paragraphs;
  @override
  String get navLabel => 'About';
}

class SkillsSection extends PortfolioSection {
  const SkillsSection(super.title, this.groups);
  final List<SkillGroup> groups;
  @override
  String get navLabel => 'Skills';
}

class SkillGroup {
  const SkillGroup(this.title, this.skills);
  final String title;
  final List<String> skills;
}

class ExperienceSection extends PortfolioSection {
  const ExperienceSection(super.title, this.jobs);
  final List<Job> jobs;
  @override
  String get navLabel => 'Experience';
}

class Job {
  const Job({
    required this.company,
    required this.period,
    required this.role,
    required this.points,
  });
  final String company;
  final String period;
  final String role;
  final List<Bullet> points;
}

class ProjectsSection extends PortfolioSection {
  const ProjectsSection(super.title, this.projects);
  final List<Project> projects;
  @override
  String get navLabel => 'Projects';

  List<String> get groups =>
      projects.map((p) => p.group).where((g) => g.isNotEmpty).toSet().toList();
}

class Project {
  const Project({
    required this.title,
    this.group = '',
    this.category = '',
    this.description = '',
    this.url = '',
    this.image = '',
  });
  final String title;
  final String group;
  final String category;
  final String description;
  final String url;

  /// Optional screenshot asset shown inside the phone mockup.
  final String image;
}

class PackagesSection extends PortfolioSection {
  const PackagesSection(super.title, this.packages, this.paragraphs);
  final List<Package> packages;
  final List<String> paragraphs;
  @override
  String get navLabel => 'Open Source';
}

class Package {
  const Package(this.name, this.description, this.url);
  final String name;
  final String description;
  final String url;
}

class EducationSection extends PortfolioSection {
  const EducationSection(super.title, this.entries);
  final List<EducationEntry> entries;
  @override
  String get navLabel => 'Education';
}

class EducationEntry {
  const EducationEntry({
    required this.degree,
    required this.period,
    required this.institution,
    required this.notes,
  });
  final String degree;
  final String period;
  final String institution;
  final List<String> notes;
}

/// A simple list, e.g. certifications or awards.
class ListSection extends PortfolioSection {
  const ListSection(super.title, this.items);
  final List<String> items;
  @override
  String? get navLabel => null;
}

/// Fallback for any heading the parser doesn't recognise.
class TextSection extends PortfolioSection {
  const TextSection(super.title, this.paragraphs, this.bullets);
  final List<String> paragraphs;
  final List<Bullet> bullets;
}

class ContactSection extends PortfolioSection {
  const ContactSection(
    super.title, {
    required this.intro,
    this.headline = '',
    required this.email,
    this.phone = '',
    required this.location,
    required this.resumeUrl,
    this.coffeeUrl = '',
    required this.links,
  });
  final String intro;
  final String headline;
  final String email;

  /// Display form, e.g. "+91 98765 43210"; empty hides the call buttons.
  final String phone;
  String get phoneUrl => 'tel:${phone.replaceAll(RegExp(r'[^+0-9]'), '')}';
  final String location;
  final String resumeUrl;

  /// Buy Me a Coffee page; empty hides the button.
  final String coffeeUrl;
  final List<ContactLink> links;
  @override
  String get navLabel => 'Contact';
}

class ContactLink {
  const ContactLink(this.label, this.url);
  final String label;
  final String url;
}
