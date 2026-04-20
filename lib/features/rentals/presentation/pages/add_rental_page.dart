import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/core/widgets/success_dialog.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/tenant_entity.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_bloc.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_event.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_state.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_prestaya_flutter/features/notifications/domain/entities/notification_entity.dart';

class AddRentalPage extends StatefulWidget {
  final RentalEntity? rental;
  const AddRentalPage({super.key, this.rental});

  @override
  State<AddRentalPage> createState() => _AddRentalPageState();
}

class _AddRentalPageState extends State<AddRentalPage> {
  // Tenant Controllers
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  // Rental Controllers
  final _roomController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _customDurationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  int _selectedDuration = 3; // Default 3 months
  bool _isOtherDuration = false;

  @override
  void initState() {
    super.initState();
    if (widget.rental != null) {
      final r = widget.rental!;
      _nameController.text = r.tenant?.name ?? '';
      _dniController.text = r.tenant?.dni ?? '';
      _phoneController.text = r.tenant?.phone ?? '';
      _addressController.text = r.tenant?.address ?? '';
      _emailController.text = r.tenant?.email ?? '';
      _roomController.text = r.roomNumber;
      _rentController.text = r.amount.toStringAsFixed(0);
      _depositController.text = r.securityDeposit?.toStringAsFixed(0) ?? '';
      _startDate = r.startDate;
      _selectedDuration = r.totalMonths;
      
      if (![3, 6, 12].contains(_selectedDuration)) {
        _isOtherDuration = true;
        _customDurationController.text = _selectedDuration.toString();
      }
    }
    
    _rentController.addListener(() => setState(() {}));
    _customDurationController.addListener(() {
      if (_isOtherDuration) {
        setState(() {
          _selectedDuration = int.tryParse(_customDurationController.text) ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _roomController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  void _selectDuration(int months) {
    setState(() {
      _selectedDuration = months;
      _isOtherDuration = false;
    });
  }

  void _selectOtherDuration() {
    setState(() {
      _isOtherDuration = true;
      _selectedDuration = int.tryParse(_customDurationController.text) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RentalsBloc, RentalsState>(
        listener: (context, state) {
          if (state is RentalAddedSuccess) {
            // Trigger Notification
            context.read<NotificationsBloc>().add(AddNotificationRequested(
              NotificationEntity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: widget.rental != null ? 'Alquiler Actualizado' : 'Nuevo Alquiler',
                content: widget.rental != null 
                  ? 'Se han guardado los cambios para ${_nameController.text}.'
                  : 'Has registrado correctamente a ${_nameController.text} en el cuarto ${_roomController.text}.',
                timestamp: DateTime.now(),
                type: NotificationType.newClient,
              ),
            ));

            SuccessDialog.show(
              context,
              title: widget.rental != null ? '¡Alquiler Actualizado!' : '¡Alquiler Registrado!',
              message: widget.rental != null 
                ? 'Los cambios para ${_nameController.text} se han guardado.'
                : 'El contrato para ${_nameController.text} se ha guardado correctamente.',
              onDismiss: () => Navigator.pop(context),
            );
          } else if (state is RentalsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('DATOS DEL INQUILINO'),
                      const SizedBox(height: 12),
                      _buildTenantCard(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('DETALLES DEL ALQUILER'),
                      const SizedBox(height: 12),
                      _buildRentalCard(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Simulación de Periodos'),
                      const SizedBox(height: 12),
                      _buildSimulationCard(),
                      const SizedBox(height: 20),
                      _buildNotificationHint(),
                      const SizedBox(height: 30),
                      BlocBuilder<RentalsBloc, RentalsState>(
                        builder: (context, state) {
                          return CustomButton(
                            title: widget.rental != null ? 'Guardar Cambios' : 'Registrar Alquiler',
                            loading: state is RentalsLoading,
                            onPress: () => _handleRegister(context),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  void _handleRegister(BuildContext context) {
    if (_nameController.text.isEmpty || _roomController.text.isEmpty || _rentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa los campos obligatorios (*)')),
      );
      return;
    }

    if (widget.rental != null) {
      final updateData = {
        'roomId': _roomController.text,
        'monthlyRent': double.tryParse(_rentController.text) ?? 0,
        'startDate': _startDate.toIso8601String().split('T')[0],
        'totalMonths': _selectedDuration,
        'securityDeposit': double.tryParse(_depositController.text),
        'tenant': {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'dni': _dniController.text,
          'address': _addressController.text,
          'email': _emailController.text,
        }
      };
      context.read<RentalsBloc>().add(UpdateRentalRequested(widget.rental!.id!, updateData));
    } else {
      final tenant = TenantEntity(
        name: _nameController.text,
        phone: _phoneController.text,
        dni: _dniController.text,
        address: _addressController.text,
        roomNumber: _roomController.text,
        email: _emailController.text,
      );

      final rental = RentalEntity(
        tenant: tenant,
        amount: double.tryParse(_rentController.text) ?? 0,
        roomNumber: _roomController.text,
        startDate: _startDate,
        totalMonths: _selectedDuration,
        securityDeposit: double.tryParse(_depositController.text),
      );

      context.read<RentalsBloc>().add(AddRentalRequested(rental));
    }
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding + 10, bottom: 20),
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
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            widget.rental != null ? 'Editar Alquiler' : 'Nuevo Alquiler',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTenantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomInput(
            label: 'Nombre Completo *',
            placeholder: 'Ej. Juan Pérez',
            controller: _nameController,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  label: 'DNI',
                  placeholder: '12345678',
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomInput(
                  label: 'Teléfono',
                  placeholder: '987654321',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomInput(
            label: 'Dirección',
            placeholder: 'Ej. Av. Siempre Viva 123',
            controller: _addressController,
          ),
          const SizedBox(height: 16),
          CustomInput(
            label: 'Correo Electrónico (Para Notificaciones)',
            placeholder: 'inquilino@ejemplo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  label: 'Número de Cuarto *',
                  placeholder: 'Ej. 101',
                  controller: _roomController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomInput(
                  label: 'Renta Mensual (S/) *',
                  placeholder: '0.00',
                  controller: _rentController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  label: 'Garantía (Opcional)',
                  placeholder: '0.00',
                  controller: _depositController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePickerField()),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Duración del Contrato *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDurationChip(3, '3 Meses'),
              const SizedBox(width: 8),
              _buildDurationChip(6, '6 Meses'),
              const SizedBox(width: 8),
              _buildDurationChip(12, '12 Meses'),
              const SizedBox(width: 8),
              _buildDurationChip(-1, 'Otro'),
            ],
          ),
          if (_isOtherDuration) ...[
            const SizedBox(height: 16),
            CustomInput(
              label: 'Especificar Meses',
              placeholder: 'Ej. 18',
              controller: _customDurationController,
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationChip(int months, String label) {
    bool isSelected = (_isOtherDuration && months == -1) || (!_isOtherDuration && _selectedDuration == months);
    return Expanded(
      child: GestureDetector(
        onTap: () => months == -1 ? _selectOtherDuration() : _selectDuration(months),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.1) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha de Inicio *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.text),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _startDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(_startDate),
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.calendar_month_outlined, color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationCard() {
    if (_selectedDuration <= 0) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: List.generate(_selectedDuration > 5 ? 5 : _selectedDuration, (index) {
          final monthStart = DateTime(_startDate.year, _startDate.month + index, _startDate.day);
          final monthEnd = DateTime(_startDate.year, _startDate.month + index + 1, _startDate.day);
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Mes ${index + 1}: ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(monthStart)} - ${DateFormat('dd/MM/yyyy').format(monthEnd)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }) + [
          if (_selectedDuration > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 18),
              child: Text(
                '... y ${_selectedDuration - 5} meses más',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildNotificationHint() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Se enviará una notificación automática a las 8:00 AM de cada fecha de vencimiento.',
              style: TextStyle(
                color: Color(0xFF5B21B6),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
