import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/loan_entity.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/pages/register_payment_page.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/pages/payment_history_page.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/bloc/loans_bloc.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:app_prestaya_flutter/core/utils/permission_helper.dart';

class LoanDetailPage extends StatelessWidget {
  final LoanEntity loan;
  const LoanDetailPage({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    // Encontrar el número máximo de cuota registrado en los pagos
    int totalInstallmentsLimit = loan.installments;
    for (var p in loan.payments) {
      final regExp = RegExp(r'cuota (\d+)', caseSensitive: false);
      final match = regExp.firstMatch(p.notes ?? '');
      if (match != null) {
        final num = int.tryParse(match.group(1) ?? '');
        if (num != null && num > totalInstallmentsLimit) {
          totalInstallmentsLimit = num;
        }
      }
    }

    // Calcular cuotas pagadas reales (incluyendo forzadas por nota y adicionales)
    int effectivePaidCount = loan.currentInstallment ?? 0;
    for (int i = effectivePaidCount + 1; i <= totalInstallmentsLimit; i++) {
      final hasForced = loan.payments.any((p) => 
        (p.notes ?? '').toLowerCase().contains('cuota $i') && 
        (p.notes ?? '').toLowerCase().contains('completada')
      );
      final hasPayment = loan.payments.any((p) => 
        (p.notes ?? '').toLowerCase().contains('cuota $i')
      );
      final isFullyPaid = (loan.paidAmount ?? 0) >= (loan.totalToPay ?? 0) - 0.01;
      
      if (hasForced || hasPayment || isFullyPaid) {
        effectivePaidCount = i;
      } else {
        break;
      }
    }

    // Si todas las cuotas actuales están pagadas pero no se ha pagado la totalidad, añadimos una virtual
    final isFullyPaid = (loan.paidAmount ?? 0) >= (loan.totalToPay ?? 0) - 0.01;
    if (effectivePaidCount == totalInstallmentsLimit && !isFullyPaid) {
      totalInstallmentsLimit++;
    }

    final progress = totalInstallmentsLimit > 0 ? (effectivePaidCount / totalInstallmentsLimit) : 0.0;
    final hasPayments = effectivePaidCount > 0 || (loan.paidAmount ?? 0) > 0;

    return BlocListener<LoansBloc, LoansState>(
      listener: (context, state) {
        if (state is LoanUpdatedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Préstamo actualizado correctamente'), backgroundColor: Colors.green),
          );
        } else if (state is LoanDeletedSuccess) {
          Navigator.pop(context);
        } else if (state is LoansError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            _buildHeader(context, hasPayments),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainInfoCard(progress, isFullyPaid),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DETALLES DEL CRÉDITO',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2),
                        ),
                        PermissionHelper.guarded(
                          context: context,
                          permission: AppPermissions.prestamosUpdate,
                          child: IconButton(
                            onPressed: () {
                              if (hasPayments) {
                                _showPaymentWarningDialog(context, 'editar');
                                return;
                              }
                              _showEditForm(context);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildDetailsGrid(effectivePaidCount, totalInstallmentsLimit),
                    const SizedBox(height: 30),
                    _buildActionButtons(context),
                    if (hasPayments) ...[
                      const SizedBox(height: 25),
                      _buildWarningBanner(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool hasPayments) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 5,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          PermissionHelper.guarded(
            context: context,
            permission: AppPermissions.prestamosDelete,
            child: Positioned(
              right: 5,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                onPressed: () {
                  if (hasPayments) {
                    _showPaymentWarningDialog(context, 'eliminar');
                    return;
                  }
                  _showDeleteConfirmation(context);
                },
              ),
            ),
          ),
          const Text(
            'Detalle del Préstamo',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showPaymentWarningDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Acción no permitida', style: TextStyle(color: Colors.orange)),
          ],
        ),
        content: Text(
          'No puedes $action este préstamo porque ya cuenta con pagos registrados.\n\n'
          'Si necesitas corregir algo, deberás eliminar los pagos primero (si el sistema lo permite) o crear un nuevo registro.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Préstamo?'),
        content: Text('¿Estás seguro de que deseas eliminar el préstamo de ${loan.clientName}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<LoansBloc>().add(DeleteLoanRequested(loan.id!));
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(double progress, bool isFullyPaid) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text('CLIENTE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(loan.clientName ?? 'Cliente', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(
              color: isFullyPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFullyPaid ? 'Finalizado' : 'Pendiente', 
              style: TextStyle(
                color: isFullyPaid ? const Color(0xFF065F46) : const Color(0xFFC2410C), 
                fontWeight: FontWeight.bold, 
                fontSize: 13
              )
            ),
          ),
          const SizedBox(height: 25),
          const Text('Total a Pagar', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          const SizedBox(height: 5),
          Text('S/ ${(loan.totalToPay ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progreso de Pago', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(int effectivePaidCount, int totalInstallmentsLimit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          _buildDetailRow('Monto Capital', 'S/ ${loan.amount.toStringAsFixed(0)}', 'Interés', '${loan.interest.toStringAsFixed(0)}%'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Color(0xFFF1F5F9))),
          _buildDetailRow('Cuotas Totales', '$totalInstallmentsLimit', 'Cuotas Pagadas', '$effectivePaidCount'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Color(0xFFF1F5F9))),
          _buildDetailRow(
            'Fecha Inicio', 
            DateFormat('dd/MM/yyyy').format(loan.startDate), 
            'Frecuencia', 
            _translateFrequency(loan.frequency)
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Color(0xFFF1F5F9))),
          _buildDetailRow(
            'Próximo Vencimiento', 
            DateFormat('dd/MM/yyyy').format(loan.dueDate),
            '',
            ''
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 4),
              Text(value1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.text)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 4),
              Text(value2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.text)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isFullyPaid = (loan.paidAmount ?? 0) >= (loan.totalToPay ?? 0) - 0.01;
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Registrar Pago',
            icon: Icons.payments_outlined,
            color: const Color(0xFF10B981),
            onTap: () {
              if (isFullyPaid) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Préstamo Completado'),
                    content: const Text('Este cliente ya no tiene deuda pendiente.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPaymentPage(loan: loan)));
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            label: 'Ver Historial',
            icon: Icons.access_time,
            color: const Color(0xFF6366F1),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentHistoryPage(loan: loan))),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este préstamo no puede ser editado porque ya tiene cuotas pagadas.',
              style: TextStyle(color: Color(0xFF92400E), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context) {
    final amountController = TextEditingController(text: loan.amount.toStringAsFixed(0));
    final interestController = TextEditingController(text: loan.interest.toStringAsFixed(0));
    final installmentsController = TextEditingController(text: loan.installments.toString());
    String frequency = loan.frequency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (stfContext, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(stfContext).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Editar Préstamo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                CustomInput(label: 'Monto (S/)', placeholder: '0.00', controller: amountController, keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: CustomInput(label: 'Interés (%)', placeholder: '20', controller: interestController, keyboardType: TextInputType.number)),
                    const SizedBox(width: 15),
                    Expanded(child: CustomInput(label: 'Cuotas', placeholder: '1', controller: installmentsController, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('Frecuencia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.text)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(15)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: frequency,
                      isExpanded: true,
                      items: [
                        {'val': 'DAILY', 'label': 'Diario'},
                        {'val': 'WEEKLY', 'label': 'Semanal'},
                        {'val': 'BIWEEKLY', 'label': 'Quincenal'},
                        {'val': 'MONTHLY', 'label': 'Mensual'},
                      ].map((f) => DropdownMenuItem(value: f['val'] as String, child: Text(f['label'] as String))).toList(),
                      onChanged: (val) => setModalState(() => frequency = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                CustomButton(
                  title: 'Guardar Cambios',
                  onPress: () {
                    final data = {
                      'clientId': loan.clientId,
                      'amount': double.tryParse(amountController.text) ?? 0.0,
                      'interestRate': double.tryParse(interestController.text) ?? 0.0,
                      'totalInstallments': int.tryParse(installmentsController.text) ?? 1,
                      'paymentFrequency': frequency,
                      'startDate': DateFormat('yyyy-MM-dd').format(loan.startDate),
                    };
                    context.read<LoansBloc>().add(UpdateLoanRequested(loan.id!, data));
                    Navigator.pop(modalContext);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _translateFrequency(String? freq) {
    switch (freq?.toUpperCase()) {
      case 'DAILY': return 'Diario';
      case 'WEEKLY': return 'Semanal';
      case 'BIWEEKLY': return 'Quincenal';
      case 'MONTHLY': return 'Mensual';
      default: return freq ?? 'No definida';
    }
  }
}
