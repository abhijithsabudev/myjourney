import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/content/markdown_parser.dart';
import 'package:portfolio/content/models.dart';

void main() {
  test('parses the bundled content file', () {
    final p = parsePortfolio(File('assets/content.md').readAsStringSync());

    expect(p.name, isNotEmpty);
    expect(p.role, startsWith('Senior Flutter Developer'));
    expect(p.tagline, isNotEmpty);
    expect(p.stats, hasLength(4));
    expect(p.stats.first.value, '6+');

    final types = p.sections.map((s) => s.runtimeType).toList();
    expect(types, [
      SummarySection,
      SkillsSection,
      ExperienceSection,
      ProjectsSection,
      PackagesSection,
      EducationSection,
      ListSection,
      ContactSection,
    ]);

    final skills = p.sections.whereType<SkillsSection>().single;
    expect(skills.groups, hasLength(9));
    expect(skills.groups.first.title, 'Platforms');
    expect(skills.groups.first.skills, contains('Flutter'));

    final jobs = p.sections.whereType<ExperienceSection>().single.jobs;
    expect(jobs, hasLength(2));
    expect(jobs.first.period, 'May 2023 – Present');
    expect(jobs.first.role, startsWith('Senior Software Engineer'));
    expect(jobs.first.points.first.label, 'End-to-end ownership');
    expect(jobs.last.points.first.label, isNull);

    final projects = p.sections.whereType<ProjectsSection>().single;
    expect(projects.groups, ['Production Apps', 'Personal']);
    expect(projects.projects.first.title, 'Slavic401k');
    expect(projects.projects.first.category, 'Banking / Finance');
    expect(projects.projects.first.url, startsWith('https://play.google.com/'));
    expect(projects.projects.last.description, startsWith('Built Web'));

    final packages = p.sections.whereType<PackagesSection>().single.packages;
    expect(packages.first.name, 'human_detection');
    expect(packages.first.url, 'https://pub.dev/packages/human_detection');

    final edu = p.sections.whereType<EducationSection>().single.entries.single;
    expect(edu.period, '2016 – 2020');
    expect(edu.notes, hasLength(1));

    final contact = p.contact!;
    expect(contact.email, contains('@'));
    expect(contact.links, isNotEmpty);
    expect(contact.headline, isNotEmpty);
    expect(p.photo, startsWith('assets/images/'));
    expect(p.roleTitle, 'Senior Flutter Developer');
    expect(p.platforms, ['iOS', 'Android', 'Web', 'macOS']);
  });

  test('unknown headings become text sections and links are extracted', () {
    final p = parsePortfolio('''
# A
**Role**

## Interests
Some prose with **bold**.
- **Running:** weekends

## Side Projects
- **Tool** (CLI) — does things [Repo](https://example.com/tool) ![](assets/images/tool.png)
''');
    final text = p.sections.first as TextSection;
    expect(text.paragraphs.single, 'Some prose with **bold**.');
    expect(text.bullets.single.label, 'Running');

    final project = (p.sections.last as ProjectsSection).projects.single;
    expect(project.url, 'https://example.com/tool');
    expect(project.description, 'does things');
    expect(project.image, 'assets/images/tool.png');
  });

  test('Google Drive resume links become direct downloads', () {
    const direct = 'https://drive.google.com/uc?export=download&id=abc123';
    expect(
      driveDownloadUrl(
        'https://drive.google.com/file/d/abc123/view?usp=sharing',
      ),
      direct,
    );
    expect(driveDownloadUrl('https://drive.google.com/open?id=abc123'), direct);
    expect(driveDownloadUrl('resume.pdf'), 'resume.pdf');

    final p = parsePortfolio('''
# A
**Role**

## Contact
- Resume: [CV](https://drive.google.com/file/d/abc123/view)
''');
    expect(p.contact!.resumeUrl, direct);
  });
}
