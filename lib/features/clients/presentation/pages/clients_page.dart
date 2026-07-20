import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:app_prestaya_flutter/core/widgets/success_dialog.dart';
import 'client_detail_page.dart';
import '../bloc/clients_bloc.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import 'package:app_prestaya_flutter/core/utils/permission_helper.dart';
import 'package:app_prestaya_flutter/core/services/apis_peru_service.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late ClientsBloc _clientsBloc;

  @override
  void initState() {
    super.initState();
    _clientsBloc = sl<ClientsBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _clientsBloc.add(LoadClients());
    });
  }

  @override
  void dispose() {
    _clientsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _clientsBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            _buildFixedHeader(context),
            Expanded(
              child: BlocBuilder<ClientsBloc, ClientsState>(
                builder: (context, state) {
                  if (state is ClientsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ClientsLoaded) {
                    if (state.filteredClients.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.filteredClients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildClientCard(context, state.filteredClients[index]);
                      },
                    );
                  } else if (state is ClientsError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 10, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Clientes',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              PermissionHelper.guarded(
                context: context,
                permission: AppPermissions.clientesCreate,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddClientForm(context),
                  icon: const Icon(Icons.add, size: 18, color: AppTheme.primary),
                  label: const Text('Nuevo', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(100, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => _clientsBloc.add(SearchClients(val)),
                          decoration: const InputDecoration(
                            hintText: 'Buscar por nombre...',
                            hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _clientsBloc.add(LoadClients()),
                child: BlocBuilder<ClientsBloc, ClientsState>(
                  builder: (context, state) {
                    return Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: state is ClientsLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.refresh, color: Colors.white, size: 20),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              BlocBuilder<ClientsBloc, ClientsState>(
                builder: (context, state) {
                  final isSorted = state is ClientsLoaded && state.isSorted;
                  return GestureDetector(
                    onTap: () => context.read<ClientsBloc>().add(SortClientsAlphabetically()),
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: isSorted ? Colors.white : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          isSorted ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined,
                          color: isSorted ? AppTheme.primary : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: AppTheme.border),
          const SizedBox(height: 15),
          const Text('No tienes clientes registrados aún.', style: TextStyle(color: AppTheme.textSecondary)),
          TextButton(
            onPressed: () => _showAddClientForm(context),
            child: const Text('Registrar mi primer cliente', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, ClientEntity client) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClientDetailPage(client: client)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    '${client.dni ?? 'Sin DNI'} • ${client.phone ?? 'Sin teléfono'}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.border),
          ],
        ),
      ),
    );
  }

  void _showAddClientForm(BuildContext context) {
    final nameController = TextEditingController();
    final dniController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

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
              // 1. Verificar en nuestra BD
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
                setModalState(() {
                  isSearchingDni = false;
                });
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

          // Listeners para validación en tiempo real (Blur)
          dniFocus.addListener(() async {
            if (!dniFocus.hasFocus && dniController.text.length == 8) {
              // 1. Verificar si ya existe en nuestra BD
              final result = await sl<ClientRepository>().checkDni(dniController.text);
              result.fold((_) => null, (isTaken) async {
                if (isTaken) {
                  setModalState(() => dniError = 'Este DNI ya está registrado');
                } else {
                  setModalState(() => dniError = null);
                  
                  // 2. Si no existe, buscar en ApisPeru para auto-completar
                  if (nameController.text.isEmpty) {
                    final dniData = await sl<ApisPeruService>().getDniData(dniController.text);
                    if (dniData != null) {
                      setModalState(() {
                        nameController.text = dniData['nombre_completo'] ?? '';
                      });
                    } else {
                      // Opcional: mostrar un mensaje si no se encuentra
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se encontró información para este DNI'), duration: Duration(seconds: 2)),
                        );
                      }
                    }
                  }
                }
              });
            }
          });

          emailFocus.addListener(() async {
            final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
            if (!emailFocus.hasFocus && emailRegex.hasMatch(emailController.text)) {
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
                  const Text('Nuevo Cliente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  CustomInput(
                    label: 'Nombre *', 
                    placeholder: 'Ej. Juan Pérez', 
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
                    label: 'Correo para notificaciones', 
                    placeholder: 'usuario@correo.com', 
                    controller: emailController, 
                    keyboardType: TextInputType.emailAddress,
                    errorText: emailError,
                    focusNode: emailFocus,
                  ),
                  CustomInput(label: 'Dirección', placeholder: 'Ej. Av. Principal 123', controller: addressController),
                  
                  const SizedBox(height: 25),
                  CustomButton(
                    title: 'Guardar Cliente',
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
                        // Verificación final antes de enviar
                        final checkDni = await sl<ClientRepository>().checkDni(dni);
                        final checkEmail = await sl<ClientRepository>().checkEmail(email);

                        bool isDniTaken = false;
                        bool isEmailTaken = false;

                        checkDni.fold((_) => null, (val) => isDniTaken = val);
                        checkEmail.fold((_) => null, (val) => isEmailTaken = val);

                        if (isDniTaken || isEmailTaken) {
                          setModalState(() {
                            if (isDniTaken) dniError = 'Este DNI ya está registrado';
                            if (isEmailTaken) emailError = 'Este correo ya está registrado';
                          });
                          return;
                        }

                        _clientsBloc.add(AddClient({
                          'name': name,
                          'dni': dni,
                          'phone': phone,
                          'email': email,
                          'address': addressController.text,
                        }));
                        Navigator.pop(modalContext);
                        
                        SuccessDialog.show(
                          context,
                          title: '¡Registrado!',
                          message: 'El cliente $name se ha registrado correctamente en el sistema.',
                        );
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
}
