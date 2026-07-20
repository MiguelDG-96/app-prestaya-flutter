import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:app_prestaya_flutter/core/widgets/success_dialog.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../bloc/clients_bloc.dart';
import 'package:app_prestaya_flutter/core/services/apis_peru_service.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:app_prestaya_flutter/core/utils/permission_helper.dart';

class ClientDetailPage extends StatefulWidget {
  final ClientEntity client;

  const ClientDetailPage({super.key, required this.client});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  late ClientEntity currentClient;

  @override
  void initState() {
    super.initState();
    currentClient = widget.client;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Púrpura con Avatar
            _buildHeader(context),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('INFORMACIÓN PERSONAL'),
                  const SizedBox(height: 15),
                  _buildInfoCard(),
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle('RESUMEN DE ACTIVIDAD'),
                  const SizedBox(height: 15),
                  _buildActivitySummary(),
                  
                  const SizedBox(height: 40),
                  // Botón Editar Información
                  PermissionHelper.guarded(
                    context: context,
                    permission: AppPermissions.clientesUpdate,
                    child: CustomButton(
                      title: 'Editar Información',
                      onPress: () => _showEditClientForm(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding + 10, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                const Text(
                  'Perfil del Cliente',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                PermissionHelper.guarded(
                  context: context,
                  permission: AppPermissions.clientesDelete,
                  child: IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Card de Perfil
          Container(
            width: MediaQuery.of(context).size.width * 0.88,
            padding: const EdgeInsets.symmetric(vertical: 30),
            margin: const EdgeInsets.only(bottom: 35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    currentClient.name.isNotEmpty ? currentClient.name[0] : '?',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  currentClient.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Cliente Activo',
                  style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildInfoCard() {
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
          _buildInfoItem(Icons.badge_outlined, 'DNI / Documento', currentClient.dni ?? 'No registrado'),
          const Divider(height: 30, color: AppTheme.border),
          _buildInfoItem(Icons.phone_outlined, 'Teléfono', currentClient.phone ?? 'No registrado'),
          const Divider(height: 30, color: AppTheme.border),
          _buildInfoItem(Icons.email_outlined, 'Correo Electrónico', currentClient.email ?? 'No registrado'),
          const Divider(height: 30, color: AppTheme.border),
          _buildInfoItem(Icons.location_on_outlined, 'Dirección', currentClient.address ?? 'No registrado'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySummary() {
    return Row(
      children: [
        _buildSummaryBox('Préstamos', '-'),
        const SizedBox(width: 15),
        _buildSummaryBox('Alquileres', '-'),
      ],
    );
  }

  Widget _buildSummaryBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text)),
          ],
        ),
      ),
    );
  }

  void _showEditClientForm(BuildContext context) {
    final nameController = TextEditingController(text: currentClient.name);
    final dniController = TextEditingController(text: currentClient.dni);
    final phoneController = TextEditingController(text: currentClient.phone);
    final emailController = TextEditingController(text: currentClient.email);
    final addressController = TextEditingController(text: currentClient.address);

    final dniFocus = FocusNode();
    final emailFocus = FocusNode();

    String? nameError;
    String? dniError;
    String? phoneError;
    String? emailError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (stfContext, setModalState) {
          bool isSearchingDni = false;

          Future<void> searchDni() async {
            if (dniController.text.length != 8) {
              setModalState(() => dniError = 'DNI debe tener 8 dígitos');
              return;
            }

            setModalState(() {
              isSearchingDni = true;
              dniError = null;
            });

            try {
              // 1. Verificar en nuestra BD (si cambió el DNI)
              if (dniController.text != currentClient.dni) {
                final checkResult = await sl<ClientRepository>().checkDni(dniController.text);
                bool isTaken = false;
                checkResult.fold((_) => null, (val) => isTaken = val);

                if (isTaken) {
                  setModalState(() {
                    dniError = 'Este DNI ya está registrado';
                    isSearchingDni = false;
                  });
                  return;
                }
              }

              // 2. Consultar ApisPeru
              final dniData = await sl<ApisPeruService>().getDniData(dniController.text);
              if (dniData != null) {
                final nombres = dniData['nombres'] ?? '';
                final pApellido = dniData['apellidoPaterno'] ?? '';
                final mApellido = dniData['apellidoMaterno'] ?? '';
                final fullName = '$nombres $pApellido $mApellido'.trim().replaceAll(RegExp(r'\s+'), ' ');
                
                setModalState(() {
                  nameController.text = fullName;
                  isSearchingDni = false;
                });
              } else {
                setModalState(() => isSearchingDni = false);
                if (stfContext.mounted) {
                  ScaffoldMessenger.of(stfContext).showSnackBar(
                    const SnackBar(content: Text('No se encontró información para este DNI')),
                  );
                }
              }
            } catch (e) {
              setModalState(() => isSearchingDni = false);
            }
          }

          dniFocus.addListener(() async {
            if (!dniFocus.hasFocus && dniController.text.length == 8 && dniController.text != currentClient.dni) {
              final result = await sl<ClientRepository>().checkDni(dniController.text);
              result.fold((_) => null, (isTaken) async {
                if (isTaken) {
                  setModalState(() => dniError = 'Este DNI ya está registrado');
                } else {
                  setModalState(() => dniError = null);
                  
                  // Auto-completar si el nombre está vacío o es el anterior y queremos actualizarlo
                  final dniData = await sl<ApisPeruService>().getDniData(dniController.text);
                  if (dniData != null) {
                    setModalState(() {
                      nameController.text = dniData['nombre_completo'] ?? '';
                    });
                  }
                }
              });
            }
          });

          emailFocus.addListener(() async {
            final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
            if (!emailFocus.hasFocus && emailRegex.hasMatch(emailController.text) && emailController.text != currentClient.email) {
              final result = await sl<ClientRepository>().checkEmail(emailController.text);
              result.fold((_) => null, (isTaken) {
                if (isTaken) {
                  setModalState(() => emailError = 'Este correo ya está registrado');
                } else if (emailError == 'Este correo ya está registrado') {
                  setModalState(() => emailError = null);
                }
              });
            }
          });

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
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
                  const Text('Editar Cliente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  CustomInput(
                    label: 'Nombre *', 
                    placeholder: 'Nombre', 
                    controller: nameController,
                    errorText: nameError,
                  ),
                  CustomInput(
                    label: 'DNI *', 
                    placeholder: '8 dígitos', 
                    controller: dniController, 
                    keyboardType: TextInputType.number,
                    errorText: dniError,
                    focusNode: dniFocus,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: SizedBox(
                        width: 50,
                        child: ElevatedButton(
                          onPressed: isSearchingDni ? null : searchDni,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                          ),
                          child: isSearchingDni 
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
                    controller: phoneController, 
                    keyboardType: TextInputType.phone,
                    errorText: phoneError,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                  ),
                  CustomInput(
                    label: 'Correo', 
                    placeholder: 'usuario@correo.com', 
                    controller: emailController, 
                    keyboardType: TextInputType.emailAddress,
                    errorText: emailError,
                    focusNode: emailFocus,
                  ),
                  CustomInput(label: 'Dirección', placeholder: 'Dirección', controller: addressController),
                  const SizedBox(height: 25),
                  CustomButton(
                    title: 'Guardar Cambios',
                    onPress: () async {
                      final name = nameController.text.trim();
                      final dni = dniController.text.trim();
                      final phone = phoneController.text.trim();
                      final email = emailController.text.trim();

                      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                      final dniRegex = RegExp(r'^\d{8}$');
                      final phoneRegex = RegExp(r'^\d{9}$');

                      setModalState(() {
                        nameError = name.isEmpty ? 'El nombre es requerido' : null;
                        dniError = !dniRegex.hasMatch(dni) ? 'Debe tener 8 números' : null;
                        phoneError = !phoneRegex.hasMatch(phone) ? 'Debe tener 9 números' : null;
                        emailError = !emailRegex.hasMatch(email) ? 'Correo inválido' : null;
                      });

                      if (nameError == null && dniError == null && phoneError == null && emailError == null) {
                        // Verificación final si cambiaron los datos
                        bool isDniTaken = false;
                        bool isEmailTaken = false;

                        if (dni != currentClient.dni) {
                          final check = await sl<ClientRepository>().checkDni(dni);
                          check.fold((_) => null, (val) => isDniTaken = val);
                        }
                        if (email != currentClient.email) {
                          final check = await sl<ClientRepository>().checkEmail(email);
                          check.fold((_) => null, (val) => isEmailTaken = val);
                        }

                        if (isDniTaken || isEmailTaken) {
                          setModalState(() {
                            if (isDniTaken) dniError = 'Este DNI ya está registrado';
                            if (isEmailTaken) emailError = 'Este correo ya está registrado';
                          });
                          return;
                        }

                        final updatedData = {
                          'name': name,
                          'dni': dni,
                          'phone': phone,
                          'email': email,
                          'address': addressController.text,
                        };
                        context.read<ClientsBloc>().add(UpdateClient(currentClient.id, updatedData));
                        setState(() {
                          currentClient = ClientEntity(
                            id: currentClient.id,
                            name: name,
                            dni: dni,
                            phone: phone,
                            email: email,
                            address: addressController.text,
                          );
                        });
                        Navigator.pop(modalContext);
                        SuccessDialog.show(context, title: '¡Actualizado!', message: 'Los datos de $name se actualizaron correctamente.');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Cliente?'),
        content: Text('¿Estás seguro de que deseas eliminar a ${currentClient.name}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<ClientsBloc>().add(DeleteClient(currentClient.id));
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cliente ${currentClient.name} eliminado')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
