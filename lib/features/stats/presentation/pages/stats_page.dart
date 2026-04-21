import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/stats/presentation/bloc/stats_bloc.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:app_prestaya_flutter/core/services/export_service.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<StatsBloc>()..add(LoadStatsRequested()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppTheme.text,
          actions: [
            BlocBuilder<StatsBloc, StatsState>(
              builder: (context, state) {
                final currentFilter = (state is StatsLoaded) ? state.filter : StatsFilter.year;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButton<StatsFilter>(
                    value: currentFilter,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.filter_list, color: AppTheme.primary),
                    items: const [
                      DropdownMenuItem(value: StatsFilter.today, child: Text('Hoy')),
                      DropdownMenuItem(value: StatsFilter.week, child: Text('Semana')),
                      DropdownMenuItem(value: StatsFilter.month, child: Text('Mes')),
                      DropdownMenuItem(value: StatsFilter.year, child: Text('Año')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        context.read<StatsBloc>().add(LoadStatsRequested(filter: val));
                      }
                    },
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primary),
              onPressed: () {
                final state = context.read<StatsBloc>().state;
                if (state is StatsLoaded) {
                  _showReportOptions(context, state.filter);
                }
              },
            ),
          ],
        ),
        body: BlocBuilder<StatsBloc, StatsState>(
          builder: (context, state) {
            if (state is StatsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StatsError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }
            if (state is StatsLoaded) {
              return RefreshIndicator(
                onRefresh: () async => context.read<StatsBloc>().add(LoadStatsRequested()),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDailySummary(state.daily, state.filter),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Estado de Cobranza ${_getFilterText(state.filter)}'),
                      const SizedBox(height: 15),
                      _buildPieChart(state.overall, state.filter),
                      const SizedBox(height: 30),
                      _buildSectionTitle('Histórico de Cobros ${_getFilterText(state.filter)}'),
                      const SizedBox(height: 15),
                      _buildBarChart(state.monthly, state.filter),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  String _getFilterText(StatsFilter filter) {
    switch (filter) {
      case StatsFilter.today: return '(Hoy)';
      case StatsFilter.week: return '(Esta Semana)';
      case StatsFilter.month: return '(Este Mes)';
      case StatsFilter.year: return '(Este Año)';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
    );
  }

  Widget _buildDailySummary(Map<String, dynamic> daily, StatsFilter filter) {
    String label = 'Recaudación ';
    dynamic amount = daily['today'];
    
    switch (filter) {
      case StatsFilter.today: label += 'Hoy'; break;
      case StatsFilter.week: label += 'Semana'; break; // Aquí deberíamos tener data de semana
      case StatsFilter.month: label += 'Mes'; break;
      case StatsFilter.year: label += 'Anual'; break;
    }

    final double growth = (daily['growth'] as num).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recaudación Hoy', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                'S/ ${daily['today']}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  growth >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  '${growth.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> overall, StatsFilter filter) {
    // Para simplificar, si el filtro es "Hoy", usamos 'today' como cobrado y 'pending' como 0 para ejemplo
    // Lo ideal es que el backend devuelva overall filtrado.
    double collected = (overall['total_collected'] as num).toDouble();
    double pending = (overall['total_pending'] as num).toDouble();
    
    if (filter == StatsFilter.today) {
      // Simulamos visualmente el cambio si no tenemos el endpoint exacto aún
      // pending = 0; // O un valor proporcional
    }

    double total = collected + pending;

    if (total == 0) return const Center(child: Text('No hay datos suficientes'));

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: AppTheme.primary,
                    value: collected,
                    title: '${((collected / total) * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: pending,
                    title: '${((pending / total) * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(AppTheme.primary, 'Cobrado'),
              const SizedBox(height: 10),
              _buildLegendItem(Colors.orange, 'Por Cobrar'),
              const SizedBox(height: 20),
              Text('Total: S/ $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> monthly, StatsFilter filter) {
    // Si el filtro es "Hoy", podríamos mostrar horas o días. 
    // Por ahora, si es Mensual o Anual, mostramos los meses.
    
    return Container(
      height: 300,
      padding: const EdgeInsets.only(top: 20, right: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(monthly),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= monthly.length) return const SizedBox();
                  final item = monthly[index];
                  final isDaily = item.containsKey('day');
                  final label = isDaily ? item['day'].toString() : item['month'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: monthly.asMap().entries.map((entry) {
            final isDaily = entry.value.containsKey('day');
            final value = (entry.value[isDaily ? 'amount' : 'paid'] as num).toDouble();
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: AppTheme.primary,
                  width: isDaily ? 6 : 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> monthly) {
    double max = 0;
    for (var m in monthly) {
      final isDaily = m.containsKey('day');
      double val = (m[isDaily ? 'amount' : 'paid'] as num).toDouble();
      if (val > max) max = val;
    }
    return max == 0 ? 100 : max * 1.2;
  }

  void _showReportOptions(BuildContext context, StatsFilter currentFilter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Generar Reportes PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildReportItem(
                context,
                icon: Icons.money,
                title: 'Reporte de Préstamos',
                subtitle: 'Situación actual y cobros mensuales/anuales',
                onTap: () => _showLoanReportOptions(context, currentFilter),
              ),
              const SizedBox(height: 10),
              _buildReportItem(
                context,
                icon: Icons.home_work,
                title: 'Reporte de Alquileres',
                subtitle: 'Situación actual y cobros mensuales',
                onTap: () => _showRentalReportOptions(context, currentFilter),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLoanReportOptions(BuildContext context, StatsFilter currentFilter) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Opciones de Préstamos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.blue),
                title: const Text('Reporte Mensual'),
                subtitle: const Text('Cobros del mes seleccionado'),
                onTap: () {
                  Navigator.pop(context);
                  _generatePdf(context, 'monthly', 'loan', month: _getMonthFromFilter(currentFilter));
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.orange),
                title: const Text('Reporte Anual'),
                subtitle: const Text('Todos los cobros del año'),
                onTap: () {
                  Navigator.pop(context);
                  _generatePdf(context, 'annual', 'loan');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRentalReportOptions(BuildContext context, StatsFilter currentFilter) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Opciones de Alquileres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.green),
                title: const Text('Reporte Mensual'),
                subtitle: const Text('Cobros del mes seleccionado'),
                onTap: () {
                  Navigator.pop(context);
                  _generatePdf(context, 'monthly', 'rental', month: _getMonthFromFilter(currentFilter));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int _getMonthFromFilter(StatsFilter filter) {
    return DateTime.now().month; // Por ahora el mes actual, podra ser dinmico
  }

  Future<void> _generatePdf(BuildContext context, String type, String category, {int? month}) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF...'), duration: Duration(seconds: 2)),
      );
      
      final exportService = sl<ExportService>();
      await exportService.downloadAndOpenPdf(
        type: type,
        category: category,
        month: month,
        year: DateTime.now().year,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
