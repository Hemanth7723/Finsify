import 'package:finsify/widgets/analytics_bar_chart.dart';
import 'package:finsify/theme/finsify_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chart bars fit a short and narrow plot area', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 98,
              child: AnalyticsBarChart(
                currency: '\u20b9',
                data: const [
                  AnalyticsDatum(label: '10/01', value: 1200),
                  AnalyticsDatum(label: '10/02', value: 350),
                  AnalyticsDatum(label: '10/03', value: 80),
                  AnalyticsDatum(label: '10/04', value: 1800),
                  AnalyticsDatum(label: '10/05', value: 650),
                  AnalyticsDatum(label: '10/06', value: 100),
                  AnalyticsDatum(label: '10/07', value: 900),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('chart labels and baseline use the active dark palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinsifyTheme(dark: true),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: AnalyticsBarChart(
              currency: '\u20b9',
              data: const [AnalyticsDatum(label: 'Today', value: 1200)],
            ),
          ),
        ),
      ),
    );

    final amount = tester.widget<Text>(find.text('\u20b91200'));
    expect(amount.style?.color, FinsifyColors.dark.accent);
    expect(
      tester.widget<Text>(find.text('Today')).style?.color,
      FinsifyColors.dark.secondaryText,
    );
    final baseline = tester.widget<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration == null &&
            widget.color == FinsifyColors.dark.chartBaseline,
      ),
    );
    expect(baseline.color, FinsifyColors.dark.chartBaseline);
    expect(tester.takeException(), isNull);
  });
}
