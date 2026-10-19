import 'package:flutter/material.dart';

import '../theme/finsify_theme.dart';

class AnalyticsDatum {
  const AnalyticsDatum({required this.label, required this.value});

  final String label;
  final double value;
}

class AnalyticsBarChart extends StatelessWidget {
  const AnalyticsBarChart({
    required this.data,
    required this.currency,
    super.key,
  });

  final List<AnalyticsDatum> data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final colors = context.finsifyColors;
    final maxAmount = data
        .map((item) => item.value)
        .reduce((a, b) => a > b ? a : b);
    final chartMax = maxAmount > 0 ? maxAmount : 1.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final amountHeight = constraints.maxHeight < 56 ? 12.0 : 16.0;
                final labelGap = constraints.maxHeight < 56 ? 2.0 : 4.0;
                final availableBarHeight =
                    (constraints.maxHeight - amountHeight - labelGap).clamp(
                      0.0,
                      constraints.maxHeight,
                    );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    final targetBarHeight =
                        availableBarHeight *
                        (item.value / chartMax).clamp(0.12, 1.0);
                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, columnConstraints) => Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: amountHeight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$currency${item.value.toStringAsFixed(0)}',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: colors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: labelGap),
                            AnimatedContainer(
                              height: targetBarHeight,
                              width: (columnConstraints.maxWidth * 0.62).clamp(
                                4.0,
                                24.0,
                              ),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [colors.chartStart, colors.chartEnd],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Container(height: 2, color: colors.chartBaseline),
          const SizedBox(height: 6),
          Row(
            children: data
                .map(
                  (item) => Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
