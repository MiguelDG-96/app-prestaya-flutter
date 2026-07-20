import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/loan_entity.dart';
import 'package:app_prestaya_flutter/features/loans/domain/entities/payment_entity.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/bloc/loans_bloc.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/pages/payment_history_page.dart';
import 'package:intl/intl.dart';

class RegisterPaymentPage extends StatefulWidget {
  final LoanEntity loan;
  const RegisterPaymentPage({super.key, required this.loan});

  @override
  State<RegisterPaymentPage> createState() => _RegisterPaymentPageState();
}

class _RegisterPaymentPageState extends State<RegisterPaymentPage> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final List<int> _selectedInstallments = [];
  DateTime _selectedDate = DateTime.now();
  bool _forceCompletion = false;
  double _adjustmentBalance = 0;
  int _extraInstallmentsCreated = 0;

  int get _totalInstallmentsLimit {
    int maxInstallmentFromPayments = widget.loan.installments;
    for (var p in widget.loan.payments) {
      final regExp = RegExp(r'cuota (\d+)', caseSensitive: false);
      final match = regExp.firstMatch(p.notes ?? '');
      if (match != null) {
        final num = int.tryParse(match.group(1) ?? '');
        if (num != null && num > maxInstallmentFromPayments) {
          maxInstallmentFromPayments = num;
        }
      }
    }
    return maxInstallmentFromPayments + _extraInstallmentsCreated;
  }

  bool _isInstallmentPaid(int i) {
    if ((widget.loan.paidAmount ?? 0) >= (widget.loan.totalToPay ?? 0) - 0.01) {
      return true;
    }
    if (i <= (widget.loan.currentInstallment ?? 0)) {
      return true;
    }
    final isForcedPaid = widget.loan.payments.any((p) => 
      (p.notes ?? '').toLowerCase().contains('cuota $i') && 
      (p.notes ?? '').toLowerCase().contains('completada')
    );
    if (isForcedPaid) return true;
    
    final isExtra = i > widget.loan.installments;
    if (isExtra) {
      final paymentsForThisInst = widget.loan.payments.where((p) => 
        (p.notes ?? '').toLowerCase().contains('cuota $i')
      );
      final totalPaidForThisInst = paymentsForThisInst.fold<double>(0.0, (acc, p) => acc + (p.amount ?? 0.0));
      
      final baseAmount = (widget.loan.totalToPay ?? 0) / widget.loan.installments;
      double amount = baseAmount;
      if (totalPaidForThisInst > 0) {
        amount = totalPaidForThisInst;
      } else {
        amount = baseAmount;
      }
      
      if (totalPaidForThisInst >= amount) {
        return true;
      }
    }
    return false;
  }

  double _getInstallmentTargetAmount(int number) {
    final totalToPay = widget.loan.totalToPay ?? 0;
    final totalInstallments = widget.loan.installments;
    final installmentAmount = totalToPay / totalInstallments;
    if (number <= totalInstallments) {
      return installmentAmount;
    }
    
    final paymentsForThisInst = widget.loan.payments.where((p) => 
      (p.notes ?? '').toLowerCase().contains('cuota $number')
    );
    final totalPaidForThisInst = paymentsForThisInst.fold<double>(0.0, (acc, p) => acc + (p.amount ?? 0.0));
    if (totalPaidForThisInst > 0) {
      return totalPaidForThisInst;
    }
    
    final paidAmount = widget.loan.paidAmount ?? 0;
    return (totalToPay - paidAmount).clamp(0.0, installmentAmount);
  }

  int get _effectivePaidCount {
    int count = 0;
    int limit = _totalInstallmentsLimit;
    for (int i = 1; i <= limit; i++) {
      if (_isInstallmentPaid(i)) {
        count = i;
      } else {
        break;
      }
    }
    return count;
  }

  bool get _isLoanFullyPaid {
    return (widget.loan.paidAmount ?? 0) >= (widget.loan.totalToPay ?? 0) - 0.01;
  }

  bool get _canCreateExtraInstallment {
    if (_isLoanFullyPaid) return false;
    int limit = _totalInstallmentsLimit;
    for (int i = 1; i <= limit; i++) {
      if (!_isInstallmentPaid(i)) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    
    if (_canCreateExtraInstallment) {
      _extraInstallmentsCreated = 1;
    }

    final next = _effectivePaidCount + 1;
    if (next <= _totalInstallmentsLimit && !_isLoanFullyPaid) {
      _selectedInstallments.add(next);
      _updateAmount();
    }
  }

  void _updateAmount() {
    final totalToPay = widget.loan.totalToPay ?? 0;
    final paidAmount = widget.loan.paidAmount ?? 0;
    final totalInstallments = widget.loan.installments;
    final installmentAmount = totalToPay / totalInstallments;
    
    bool hasExtraSelected = _selectedInstallments.any((num) => num > totalInstallments);
    
    if (hasExtraSelected) {
      final remainingBalance = (totalToPay - paidAmount).clamp(0.0, double.infinity);
      _adjustmentBalance = 0;
      
      double finalAmount = installmentAmount;
      if (remainingBalance < installmentAmount) {
        finalAmount = remainingBalance;
      }
      _amountController.text = finalAmount.toStringAsFixed(2);
    } else {
      final expectedPaid = _effectivePaidCount * installmentAmount;
      final balance = paidAmount - expectedPaid;
      
      _adjustmentBalance = balance;
      
      double totalSelectedBase = _selectedInstallments.length * installmentAmount;
      double finalAmount = totalSelectedBase - balance;
      
      _amountController.text = finalAmount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePaidCount = _effectivePaidCount;
    final next = effectivePaidCount + 1;
    final total = widget.loan.totalToPay ?? 0;
    final paid = widget.loan.paidAmount ?? 0;
    final pending = total - paid;
    
    // Cálculo de abono parcial
    final totalInstallments = widget.loan.installments;
    final installmentAmount = total / totalInstallments;
    final expectedPaidForCompleted = effectivePaidCount * installmentAmount;
    final accumulatedForNext = paid - expectedPaidForCompleted;
    final remainingToComplete = installmentAmount - accumulatedForNext;
    final hasPartialAbono = accumulatedForNext > 0.05 && !_isLoanFullyPaid;

    return BlocListener<LoansBloc, LoansState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Pago registrado con éxito!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        } else if (state is LoansError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Registrar Pago',
            style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLoanSummaryCard(total, paid, pending, next),
              if (hasPartialAbono || _adjustmentBalance.abs() > 0.01) ...[
                const SizedBox(height: 20),
                _buildInfoBox(accumulatedForNext, remainingToComplete),
              ],
              const SizedBox(height: 30),
              const Text('Monto a pagar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              CustomInput(
                label: 'Monto',
                controller: _amountController,
                placeholder: '0.00',
                keyboardType: TextInputType.number,
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 15),
              
              // Alerta de Pago Parcial y Switch de Completado
              if (_amountController.text.isNotEmpty && 
                  (double.tryParse(_amountController.text) ?? 0) < 
                  (_selectedInstallments.length * ((widget.loan.totalToPay ?? 0) / widget.loan.installments) - _adjustmentBalance))
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFC2410C), size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'El monto es menor al total sugerido. ¿Deseas marcar la cuota como completada?',
                              style: TextStyle(color: Color(0xFFC2410C), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: _forceCompletion,
                        onChanged: (val) => setState(() => _forceCompletion = val),
                        title: const Text('Completar cuota y pasar saldo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        activeColor: const Color(0xFF10B981),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              const Text('Fecha de Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppTheme.primary,
                            onPrimary: Colors.white,
                            onSurface: AppTheme.text,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd / MM / yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.text),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_outlined, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                title: _isLoanFullyPaid ? 'Préstamo Completado' : 'Confirmar Pago',
                onPress: () {
                  if (_isLoanFullyPaid) return;
                  if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor ingresa un monto válido')),
                    );
                    return;
                  }
                  _showConfirmationDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanSummaryCard(double total, double paid, double pending, int next) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.loan.clientName ?? 'Cliente',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showInstallmentSelector(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.layers_outlined, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    next > widget.loan.installments
                        ? 'Siguiente: Cuota $next (Adicional)'
                        : 'Siguiente: Cuota $next de ${widget.loan.installments}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppTheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSimpleInfo('Total Deuda', 'S/ ${total.toStringAsFixed(2)}', AppTheme.text),
              const SizedBox(width: 20),
              _buildSimpleInfo('Saldo Pendiente', 'S/ ${pending.toStringAsFixed(2)}', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfo(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  void _showInstallmentSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
                const SizedBox(height: 20),
                const Text('Seleccionar Cuotas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Elige las cuotas que deseas amortizar hoy', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _totalInstallmentsLimit,
                    itemBuilder: (context, index) {
                      final number = index + 1;
                      final isAlreadyPaid = _isInstallmentPaid(number);
                      final isSelected = _selectedInstallments.contains(number);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isAlreadyPaid ? Colors.grey[50] : (isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: isAlreadyPaid 
                            ? null 
                            : () {
                                setModalState(() {
                                  if (isSelected) {
                                    _selectedInstallments.remove(number);
                                  } else {
                                    _selectedInstallments.add(number);
                                  }
                                  _updateAmount();
                                });
                                setState(() {});
                              },
                          leading: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isAlreadyPaid ? const Color(0xFF10B981) : (isSelected ? AppTheme.primary : Colors.white),
                              shape: BoxShape.circle,
                              border: Border.all(color: isAlreadyPaid ? const Color(0xFF10B981) : (isSelected ? AppTheme.primary : Colors.grey[300]!)),
                            ),
                            child: isAlreadyPaid 
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : Center(
                                  child: Text(
                                    '$number', 
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.bold
                                    )
                                  )
                                ),
                          ),
                          title: Text(
                            number > widget.loan.installments 
                                ? 'Cuota $number (Adicional)' 
                                : 'Cuota $number', 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text(isAlreadyPaid 
                              ? 'Pagado' 
                              : 'S/ ${(_getInstallmentTargetAmount(number)).toStringAsFixed(2)}'),
                          trailing: isAlreadyPaid 
                            ? const Text('PAGADO', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12))
                            : Checkbox(
                                value: isSelected,
                                activeColor: AppTheme.primary,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      _selectedInstallments.add(number);
                                    } else {
                                      _selectedInstallments.remove(number);
                                    }
                                    _updateAmount();
                                  });
                                  setState(() {});
                                },
                              ),
                        ),
                      );
                    },
                  ),
                ),
                if (_canCreateExtraInstallment) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      icon: const Icon(Icons.add, color: AppTheme.primary),
                      label: const Text('Crear Cuota Adicional', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setModalState(() {
                          _extraInstallmentsCreated++;
                          final next = _effectivePaidCount + 1;
                          if (!_selectedInstallments.contains(next)) {
                            _selectedInstallments.add(next);
                          }
                          _updateAmount();
                        });
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: CustomButton(
                    title: 'Confirmar Selección',
                    onPress: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Column(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primary, size: 40),
            SizedBox(height: 15),
            Text('¿Confirmar Pago?', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Estás a punto de registrar un pago para:',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              widget.loan.clientName ?? 'Cliente',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Monto: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'S/ ${_amountController.text}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    final amount = double.parse(_amountController.text);
                    
                    // Generar nota automática que incluya el número de cuota para el mapeo
                    final installmentsText = _selectedInstallments.isEmpty 
                        ? ((widget.loan.currentInstallment ?? 0) + 1).toString()
                        : _selectedInstallments.join(', ');
                        
                    final baseNote = 'Pago de Cuota $installmentsText. ${_notesController.text}'.trim();
                    final finalNote = _forceCompletion ? '$baseNote [COMPLETADA]' : baseNote;

                    context.read<LoansBloc>().add(
                      AddPaymentRequested(
                        PaymentEntity(
                          loanId: widget.loan.id!,
                          amount: amount,
                          notes: finalNote,
                          paymentDate: _selectedDate,
                        ),
                      ),
                    );

                    Navigator.pop(context);
                  },
                  child: const Text('Sí, confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildInfoBox(double accumulated, double remaining) {
    String message = '';
    if (_adjustmentBalance < 0) {
      message = 'Se incluye un recargo de S/ ${(-_adjustmentBalance).toStringAsFixed(2)} por saldo pendiente anterior.';
    } else if (_adjustmentBalance > 0) {
      message = 'Se aplica un descuento de S/ ${_adjustmentBalance.toStringAsFixed(2)} por pago excedente anterior.';
    } else {
      message = 'Abono actual: S/ ${accumulated.toStringAsFixed(2)} | Falta: S/ ${remaining.toStringAsFixed(2)} para completar.';
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _adjustmentBalance != 0 ? const Color(0xFFEEF2FF) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _adjustmentBalance != 0 ? const Color(0xFFE0E7FF) : const Color(0xFFFFEDD5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _adjustmentBalance != 0 ? Icons.info_outline : Icons.info, 
            color: _adjustmentBalance != 0 ? const Color(0xFF4338CA) : const Color(0xFFC2410C), 
            size: 20
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _adjustmentBalance != 0 ? const Color(0xFF4338CA) : const Color(0xFFC2410C), 
                fontSize: 13, 
                height: 1.4,
                fontWeight: _adjustmentBalance != 0 ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ),
        ],
      ),
    );
  }
}
