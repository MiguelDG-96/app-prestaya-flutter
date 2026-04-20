import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_bloc.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_event.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_state.dart';
import 'package:app_prestaya_flutter/core/widgets/success_dialog.dart';
import 'package:app_prestaya_flutter/injection_container.dart';

class AddRentalPaymentPage extends StatefulWidget {
  final RentalEntity rental;
  const AddRentalPaymentPage({super.key, required this.rental});

  @override
  State<AddRentalPaymentPage> createState() => _AddRentalPaymentPageState();
}

class _AddRentalPaymentPageState extends State<AddRentalPaymentPage> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.rental.amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RentalsBloc, RentalsState>(
        listener: (context, state) {
          if (state is RentalPaymentSuccess) {
            SuccessDialog.show(
              context,
              title: '¡Cobro Exitoso!',
              message: 'El pago ha sido registrado correctamente y el saldo ha sido actualizado.',
              onDismiss: () => Navigator.pop(context, true),
            );
          } else if (state is RentalsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.text),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Cobrar Alquiler',
                style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTenantSummary(),
                  const SizedBox(height: 30),
                  const Text(
                    'Monto a cobrar',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _amountController,
                    hintText: 'Monto',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Notas (Opcional)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _notesController,
                    hintText: 'Ej. Pago adelantado',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: state is RentalsLoading 
                        ? null 
                        : () => _showConfirmationDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: state is RentalsLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Confirmar Cobro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildTenantSummary() {
    final pending = (widget.rental.amount * widget.rental.totalMonths) - widget.rental.amountPaid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inquilino',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            widget.rental.tenant?.name ?? 'Marcus',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Costo Alquiler', 'S/ ${widget.rental.amount.toStringAsFixed(0)}'),
                _buildSummaryItem(
                  'Saldo Pendiente', 
                  'S/ ${pending.toStringAsFixed(0)}', 
                  valueColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          border: InputBorder.none,
          suffixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese un monto válido')),
      );
      return;
    }

    final blocContext = context; // Guardamos el context que tiene el Bloc

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Column(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primary, size: 40),
            SizedBox(height: 15),
            Text('¿Confirmar Cobro?', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Estás a punto de registrar un cobro para:',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              widget.rental.tenant?.name ?? 'Inquilino',
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
                    'S/ $amountText',
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
                  onPressed: () => Navigator.pop(dialogContext),
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
                    Navigator.pop(dialogContext);
                    _onConfirm(blocContext);
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

  void _onConfirm(BuildContext context) {
    final amountText = _amountController.text.trim();
    final amount = double.parse(amountText);

    context.read<RentalsBloc>().add(AddRentalPaymentRequested(
      rentalId: widget.rental.id!,
      amount: amount,
      notes: _notesController.text.trim(),
    ));
  }
}
