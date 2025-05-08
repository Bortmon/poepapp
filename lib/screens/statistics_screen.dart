// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../main.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  String _formatDurationStats(Duration duration) {
    if (duration == Duration.zero) return "N.v.t.";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    List<String> parts = [];
    if (hours > 0) parts.add("${hours}u");
    if (minutes > 0) parts.add("${twoDigits(minutes)}m");
    if (seconds > 0 || parts.isEmpty) parts.add("${twoDigits(seconds)}s");
    return parts.join(" ");
  }

  Widget _buildStatItem(BuildContext context, String label, String value, {IconData? icon, Color? iconColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: iconColor ?? theme.colorScheme.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(label, style: theme.textTheme.titleMedium),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;
    List<FlSpot> spots = appState.earningsOverTimeSpots;

    if (spots.isEmpty) {
      return const Center(child: Text("Nog geen data voor lijngrafiek."));
    }
    if (spots.length == 1) { // Special case for a single data point
        spots = [FlSpot(0,0), FlSpot(1, spots[0].y)]; // Create a start and end point
    }


    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(right: 18.0, top: 24, bottom: 12, left: 6),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: (spots.map((s) => s.y).reduce((a,b) => a > b ? a : b) / 5).clamp(0.1, double.infinity),
              verticalInterval: (spots.length / 5).clamp(1, double.infinity),
              getDrawingHorizontalLine: (value) {
                return FlLine(color: theme.dividerColor.withAlpha(50), strokeWidth: 1);
              },
              getDrawingVerticalLine: (value) {
                return FlLine(color: theme.dividerColor.withAlpha(50), strokeWidth: 1);
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (spots.length / 5).clamp(1, double.infinity),
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < appState.sessionsHistory.length && spots.length > 1) { // Check spots.length > 1
                       return SideTitleWidget(axisSide: meta.axisSide, child: Text('S${value.toInt()+1}', style: theme.textTheme.bodySmall));
                    } else if (spots.length == 1 && value.toInt() == 1) { // For single spot case
                       return SideTitleWidget(axisSide: meta.axisSide, child: Text('S1', style: theme.textTheme.bodySmall));
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(formatCurrency(value).replaceAll('€', '').trim(), style: theme.textTheme.bodySmall);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: theme.dividerColor.withAlpha(80))),
            minX: 0,
            maxX: spots.length == 1 ? 1 : spots.length.toDouble() -1, // Adjust maxX for single spot
            minY: 0,
            maxY: spots.map((s) => s.y).reduce((a,b) => a > b ? a : b) * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: LinearGradient(colors: [myColors.moneyColor!, myColors.moneyColor!.withAlpha(100)]),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [myColors.moneyColor!.withAlpha(80), myColors.moneyColor!.withAlpha(0)])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;
    Map<String, double> dailyData = appState.earningsPerDay;

    if (dailyData.isEmpty) {
      return const Center(child: Text("Nog geen data voor staafdiagram."));
    }

    List<BarChartGroupData> barGroups = [];
    int i = 0;
    dailyData.forEach((day, earnings) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: earnings, gradient: LinearGradient(colors: [myColors.moneyColor!, theme.colorScheme.primary]), width: 16, borderRadius: BorderRadius.circular(4))],
        )
      );
      i++;
    });

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(right: 18.0, top: 24, bottom: 12, left: 6),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: dailyData.values.reduce((a,b) => a > b ? a : b) * 1.2,
            barTouchData: BarTouchData( // Tooltip data hier
              enabled: true, // Zorg dat touch interactie aan staat
              touchTooltipData: BarTouchTooltipData(
                // tooltipBackgroundColor: theme.colorScheme.surface, // VERWIJDER DEZE REGEL
                tooltipRoundedRadius: 8, // Voor afgeronde hoeken van de tooltip
                getTooltipColor: (group) => theme.colorScheme.surface.withAlpha(230), // Callback voor achtergrondkleur
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String day = dailyData.keys.elementAt(group.x);
                  return BarTooltipItem(
                    '$day\n',
                    TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatCurrency(rod.toY),
                        style: TextStyle(color: myColors.moneyColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value.toInt() < dailyData.keys.length) {
                      return SideTitleWidget(axisSide: meta.axisSide, angle: -0.5, child: Text(dailyData.keys.elementAt(value.toInt()), style: theme.textTheme.bodySmall));
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                     return Text(formatCurrency(value).replaceAll('€', '').trim(), style: theme.textTheme.bodySmall);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: theme.dividerColor.withAlpha(80))),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (dailyData.values.reduce((a,b) => a > b ? a : b) / 5).clamp(0.1, double.infinity),
              getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor.withAlpha(50), strokeWidth: 1),
            ),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, AppState appState) {
    // final theme = Theme.of(context); // AANGEPAST: Verwijderd omdat het niet gebruikt wordt
    List<PieChartSectionData> sections = appState.durationPieChartSections;

    if (sections.isEmpty) {
      return const Center(child: Text("Nog geen data voor cirkeldiagram."));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Hier kun je interactie toevoegen
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.lightBlueAccent, "< 1 min"),
                _buildLegendItem(Colors.orangeAccent, "1-3 min"),
                _buildLegendItem(Colors.pinkAccent, "> 3 min"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistieken & Inzichten'),
      ),
      body: appState.sessionsHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined, size: 80, color: theme.iconTheme.color?.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    'Nog geen data voor statistieken.',
                    style: theme.textTheme.headlineSmall?.copyWith(color: theme.textTheme.headlineSmall?.color?.withAlpha(150)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voltooi wat sessies om hier leuke feitjes te zien!',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leuke Feitjes', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildStatItem(context, 'Gem. Sessieduur:', _formatDurationStats(appState.averageSessionDuration), icon: Icons.timer_outlined),
                          const Divider(),
                          _buildStatItem(context, 'Gem. Verdiensten/Sessie:', formatCurrency(appState.averageEarningsPerSession), icon: Icons.paid_outlined, iconColor: myColors.moneyColor),
                          const Divider(),
                          _buildStatItem(context, 'Langste Sessie:', _formatDurationStats(appState.longestSession?.duration ?? Duration.zero), icon: Icons.hourglass_bottom_outlined),
                          const Divider(),
                          _buildStatItem(context, 'Kortste Productieve Sessie:', _formatDurationStats(appState.shortestProductiveSession?.duration ?? Duration.zero), icon: Icons.flash_on_outlined),
                          const Divider(),
                          _buildStatItem(context, 'Productiefste Dag:', appState.mostProductiveDayOfWeek, icon: Icons.calendar_today_outlined),
                          const Divider(),
                          _buildStatItem(context, 'Productiefste Uur:', appState.mostProductiveHourOfDay, icon: Icons.access_time_outlined),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Verdiensten Over Tijd', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(child: Padding(padding: const EdgeInsets.all(8.0), child: _buildLineChart(context, appState))),
                  const SizedBox(height: 24),
                  Text('Verdiensten per Dag', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(child: Padding(padding: const EdgeInsets.all(8.0), child: _buildBarChart(context, appState))),
                  const SizedBox(height: 24),
                  Text('Sessieduur Categorieën', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(child: Padding(padding: const EdgeInsets.all(16.0), child: _buildPieChart(context, appState))),
                ],
              ),
            ),
    );
  }
}