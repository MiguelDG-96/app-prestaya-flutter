import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/core/widgets/success_dialog.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import '../widgets/client_selection_sheet.dart';
import '../widgets/installments_simulation_sheet.dart';
import '../../domain/entities/loan_entity.dart';
import '../bloc/loans_bloc.dart';
import 'package:app_prestaya_flutter/features/clients/domain/entities/client_entity.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_prestaya_flutter/features/notifications/domain/entities/notification_entity.dart';

class AddLoanPage extends StatefulWidget {
  const AddLoanPage({super.key});

  @override
  State<AddLoanPage> createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  ClientEntity? _selectedClient;
  final _amountController = TextEditingController();
  final _interestController = TextEditingController(text: '20');
  final _installmentsController = TextEditingController(text: '1');
  String _frequency = 'Mensual';
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _interestController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoansBloc, LoansState>(
      listener: (context, state) {
        if (state is LoanAddedSuccess) {
          // Trigger Notification
          context.read<NotificationsBloc>().add(AddNotificationRequested(
            NotificationEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Nuevo Préstamo',
              content: 'Has registrado correctamente un préstamo de S/ ${_amountController.text} para ${_selectedClient?.name}.',
              timestamp: DateTime.now(),
              type: NotificationType.payment,
            ),
          ));

          SuccessDialog.show(
            context,
            title: '¡Préstamo Registrado!',
            message: 'El préstamo para ${_selectedClient?.name} se ha guardado correctamente.',
          onDismiss: () {
            Navigator.pop(context, true); // Regresar con éxito
          },
          );
        } else if (state is LoansError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          elevation: 0,
          title: const Text('Nuevo Préstamo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: BlocBuilder<LoansBloc, LoansState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('DATOS DEL CLIENTE'),
                  const SizedBox(height: 12),
                  _buildClientSelector(),
                  const SizedBox(height: 25),
                  _buildSectionTitle('DETALLES DEL PRÉSTAMO'),
                  const SizedBox(height: 12),
                  _buildLoanDetailsCard(),
                  const SizedBox(height: 30),
                  _buildTotalCard(),
                  const SizedBox(height: 40),
                  CustomButton(
                    title: 'Registrar Préstamo',
                    loading: state is LoansLoading,
                    onPress: () {
                      if (_selectedClient == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor selecciona un cliente')),
                        );
                        return;
                      }
                      
                      final amount = double.tryParse(_amountController.text) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un monto válido')),
                        );
                        return;
                      }

                      final loan = LoanEntity(
                        clientId: _selectedClient!.id,
                        amount: amount,
                        interest: double.tryParse(_interestController.text) ?? 0,
                        installments: int.tryParse(_installmentsController.text) ?? 1,
                        frequency: _frequency,
                        startDate: _startDate,
                        dueDate: _startDate.add(const Duration(days: 1)),
                      );

                      context.read<LoansBloc>().add(AddLoanRequested(loan));
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildClientSelector() {
    return GestureDetector(
      onTap: () async {
        final client = await ClientSelectionSheet.show(context);
        if (client != null) {
          setState(() => _selectedClient = client);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _selectedClient != null ? AppTheme.primary.withOpacity(0.3) : Colors.transparent),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_outlined, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedClient?.name ?? 'Seleccionar Cliente *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedClient != null ? AppTheme.text : AppTheme.textSecondary,
                    ),
                  ),
                  if (_selectedClient != null)
                    Text(
                      'DNI: ${_selectedClient!.dni}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
            const Icon(Icons.search, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          CustomInput(
            label: 'Monto Prestado (S/) *',
            placeholder: '0.00',
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  label: 'Interés (%)',
                  placeholder: '20',
                  controller: _interestController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomInput(
                  label: 'Nº de Cuotas',
                  placeholder: '1',
                  controller: _installmentsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdownField('Frecuencia', ['Diario', 'Semanal', 'Quincenal', 'Mensual'], (val) {
            setState(() => _frequency = val!);
          }, _frequency),
          const SizedBox(height: 16),
          _buildDatePickerField(),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> options, void Function(String?) onChanged, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.text)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
              items: options.map((String opt) {
                return DropdownMenuItem(value: opt, child: Text(opt));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Fecha de Préstamo *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.text)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18, color: AppTheme.primary),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    title: Row(
                      children: const [
                        Icon(Icons.help_outline, color: AppTheme.primary),
                        SizedBox(width: 10),
                        Text('¿Qué es esta fecha?'),
                      ],
                    ),
                    content: const Text(
                      'Es la fecha en la que se entregó el préstamo al cliente. El sistema calculará automáticamente las fechas de pago según la frecuencia elegida.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) setState(() => _startDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(_startDate), style: const TextStyle(fontSize: 15)),
                const Icon(Icons.calendar_month_outlined, color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double interest = double.tryParse(_interestController.text) ?? 0;
    double total = amount + (amount * (interest / 100));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a Devolver:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                'S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final amountValue = double.tryParse(_amountController.text) ?? 0;
                if (amountValue <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un monto válido primero')),
                  );
                  return;
                }
                
                InstallmentsSimulationSheet.show(
                  context: context,
                  amount: amountValue,
                  interestRate: double.tryParse(_interestController.text) ?? 0,
                  installments: int.tryParse(_installmentsController.text) ?? 1,
                  frequency: _frequency,
                  startDate: _startDate,
                );
              },
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Simular Cuotas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
