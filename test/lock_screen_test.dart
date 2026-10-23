import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/widgets/phone.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('lock screen notifications pop in over time', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: PhoneFrame(
            width: 270,
            screen: LockScreen(
              photo: '',
              initials: 'YN',
              notifications: [
                LockNotification(
                  'CI/CD',
                  'Pipeline passed',
                  Icons.rocket_launch,
                ),
                LockNotification('Highlights', '6+ Years', Icons.bolt),
              ],
            ),
          ),
        ),
      ),
    );

    double opacityOf(String text) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    expect(opacityOf('Pipeline passed'), 0);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 600));
    expect(opacityOf('Pipeline passed'), 1);
    expect(opacityOf('6+ Years'), 0);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(opacityOf('6+ Years'), 1);
    expect(tester.takeException(), isNull);
  });
}
