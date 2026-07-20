import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/core/widgets/success_dialog.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/rental_entity.dart';
import 'package:app_prestaya_flutter/core/services/apis_peru_service.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/entities/tenant_entity.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_bloc.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_event.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_state.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_prestaya_flutter/features/notifications/domain/entities/notification_entity.dart';
import 'package:app_prestaya_flutter/features/clients/domain/repositories/client_repository.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/widgets/client_selection_sheet.dart';

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
  bool _isSearchingDni = false;
  String? _selectedTenantId;

  final _dniFocus = FocusNode();
  final _emailFocus = FocusNode();

  // Validation Errors
  String? _nameError;
  String? _dniError;
  String? _phoneError;
  String? _emailError;
  String? _roomError;
  String? _rentError;

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

    _dniFocus.addListener(() async {
      if (!_dniFocus.hasFocus && _dniController.text.length == 8) {
        bool shouldCheck = true;
        if (widget.rental != null && _dniController.text == widget.rental!.tenant?.dni) {
          shouldCheck = false;
        }
        if (_selectedTenantId != null) {
          shouldCheck = false;
        }
        
        if (shouldCheck) {
          final result = await sl<ClientRepository>().checkDni(_dniController.text);
          result.fold((_) => null, (isTaken) async {
            if (isTaken) {
              setState(() => _dniError = 'Este DNI ya está registrado');
            } else {
              setState(() => _dniError = null);
              
              // Buscar en ApisPeru para auto-completar nombre del inquilino
              if (_nameController.text.isEmpty) {
                final dniData = await sl<ApisPeruService>().getDniData(_dniController.text);
                if (dniData != null) {
                  setState(() {
                    _nameController.text = dniData['nombre_completo'] ?? '';
                  });
                }
              }
            }
          });
        }
      }
    });

    _emailFocus.addListener(() async {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!_emailFocus.hasFocus && emailRegex.hasMatch(_emailController.text)) {
        bool shouldCheck = true;
        if (widget.rental != null && _emailController.text == widget.rental!.tenant?.email) {
          shouldCheck = false;
        }

        if (shouldCheck) {
          final result = await sl<ClientRepository>().checkEmail(_emailController.text);
          result.fold((_) => null, (isTaken) {
            if (isTaken) {
              setState(() => _emailError = 'Este correo ya está registrado');
            } else if (_emailError == 'Este correo ya está registrado') {
              setState(() => _emailError = null);
            }
          });
        }
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
    _dniFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _searchDni() async {
    if (_dniController.text.length != 8) {
      setState(() => _dniError = 'DNI debe tener 8 dígitos');
      return;
    }

    setState(() {
      _isSearchingDni = true;
      _dniError = null;
      _selectedTenantId = null; // Clear if searching manually
    });

    try {
      // 1. Verificar en nuestra BD
      final checkResult = await sl<ClientRepository>().checkDni(_dniController.text);
      bool isTaken = false;
      checkResult.fold((_) => null, (val) => isTaken = val);

      if (isTaken) {
        setState(() {
          _dniError = 'Este DNI ya está registrado';
          _isSearchingDni = false;
        });
        return;
      }

      // 2. Consultar ApisPeru
      final dniData = await sl<ApisPeruService>().getDniData(_dniController.text);
      if (dniData != null) {
        final nombres = dniData['nombres'] ?? '';
        final pApellido = dniData['apellidoPaterno'] ?? '';
        final mApellido = dniData['apellidoMaterno'] ?? '';
        final fullName = '$nombres $pApellido $mApellido'.trim().replaceAll(RegExp(r'\s+'), ' ');
        
        setState(() {
          _nameController.text = fullName;
          _isSearchingDni = false;
        });
      } else {
        setState(() => _isSearchingDni = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró información para este DNI')),
          );
        }
      }
    } catch (e) {
      setState(() => _isSearchingDni = false);
    }
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
              onDismiss: () {
                Navigator.pop(context, true); // Regresar con éxito
              },
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

  Future<void> _handleRegister(BuildContext context) async {
    final name = _nameController.text.trim();
    final dni = _dniController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final room = _roomController.text.trim();
    final rentStr = _rentController.text.trim();

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    final dniRegex = RegExp(r'^\d{8}$');
    final phoneRegex = RegExp(r'^\d{9}$');

    setState(() {
      _nameError = name.isEmpty ? 'El nombre es requerido' : null;
      _dniError = !dniRegex.hasMatch(dni) ? 'DNI debe tener 8 números' : null;
      _phoneError = !phoneRegex.hasMatch(phone) ? 'Celular debe tener 9 números' : null;
      _emailError = !emailRegex.hasMatch(email) ? 'Correo inválido' : null;
      _roomError = room.isEmpty ? 'Nº de cuarto requerido' : null;
      _rentError = double.tryParse(rentStr) == null ? 'Monto inválido' : null;
    });

    if (_nameError != null || _dniError != null || _phoneError != null || _emailError != null || _roomError != null || _rentError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor corrige los errores en el formulario'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Verificación final de duplicados solo si no es un cliente seleccionado
    bool isDniTaken = false;
    bool isEmailTaken = false;

    if (_selectedTenantId == null) {
      if (dni != (widget.rental?.tenant?.dni ?? '')) {
        final check = await sl<ClientRepository>().checkDni(dni);
        check.fold((_) => null, (val) => isDniTaken = val);
      }
      if (email.isNotEmpty && email != (widget.rental?.tenant?.email ?? '')) {
        final check = await sl<ClientRepository>().checkEmail(email);
        check.fold((_) => null, (val) => isEmailTaken = val);
      }
    }

    if (isDniTaken || isEmailTaken) {
      setState(() {
        if (isDniTaken) _dniError = 'Este DNI ya está registrado';
        if (isEmailTaken) _emailError = 'Este correo ya está registrado';
      });
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
        id: _selectedTenantId,
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
          if (widget.rental == null) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final selectedClient = await ClientSelectionSheet.show(context);
                if (selectedClient != null) {
                  setState(() {
                    _selectedTenantId = selectedClient.id;
                    _nameController.text = selectedClient.name;
                    _dniController.text = selectedClient.dni ?? '';
                    _phoneController.text = selectedClient.phone ?? '';
                    _addressController.text = selectedClient.address ?? '';
                    _emailController.text = selectedClient.email ?? '';
                    _dniError = null;
                    _emailError = null;
                  });
                }
              },
              icon: const Icon(Icons.person_search, color: AppTheme.primary),
              label: const Text('Seleccionar Cliente Existente', style: TextStyle(color: AppTheme.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 16),
          ],
          CustomInput(
            label: 'Nombre Completo *',
            placeholder: 'Ej. Juan Pérez',
            controller: _nameController,
            errorText: _nameError,
          ),
          const SizedBox(height: 16),
          CustomInput(
            label: 'DNI *',
            placeholder: '8 dígitos',
            controller: _dniController,
            keyboardType: TextInputType.number,
            errorText: _dniError,
            focusNode: _dniFocus,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            suffixIcon: Padding(
              padding: const EdgeInsets.all(6.0),
              child: SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed: _isSearchingDni ? null : _searchDni,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: _isSearchingDni 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomInput(
            label: 'Teléfono',
            placeholder: '9 dígitos',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            errorText: _phoneError,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
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
            errorText: _emailError,
            focusNode: _emailFocus,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomInput(
                  label: 'Número de Cuarto *',
                  placeholder: 'Ej. 101',
                  controller: _roomController,
                  errorText: _roomError,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomInput(
                  label: 'Renta Mensual (S/) *',
                  placeholder: '0.00',
                  controller: _rentController,
                  keyboardType: TextInputType.number,
                  errorText: _rentError,
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
