import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:app_prestaya_flutter/core/widgets/success_dialog.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:app_prestaya_flutter/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:app_prestaya_flutter/features/clients/domain/entities/client_entity.dart';
import 'package:app_prestaya_flutter/features/clients/domain/repositories/client_repository.dart';
import 'package:app_prestaya_flutter/core/services/apis_peru_service.dart';
import 'package:intl/intl.dart';

class ClientSelectionSheet extends StatefulWidget {
  const ClientSelectionSheet({super.key});

  static Future<ClientEntity?> show(BuildContext context) {
    return showModalBottomSheet<ClientEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ClientSelectionSheet(),
    );
  }

  @override
  State<ClientSelectionSheet> createState() => _ClientSelectionSheetState();
}

class _ClientSelectionSheetState extends State<ClientSelectionSheet> {
  late ClientsBloc _clientsBloc;

  @override
  void initState() {
    super.initState();
    _clientsBloc = sl<ClientsBloc>();
    _clientsBloc.add(LoadClients());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(),
          Expanded(
            child: BlocBuilder<ClientsBloc, ClientsState>(
              bloc: _clientsBloc,
              builder: (context, state) {
                if (state is ClientsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ClientsLoaded) {
                  if (state.filteredClients.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.filteredClients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final client = state.filteredClients[index];
                      return _buildClientItem(client);
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Seleccionar Cliente',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (val) => _clientsBloc.add(SearchClients(val)),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o DNI...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientItem(ClientEntity client) {
    return InkWell(
      onTap: () => Navigator.pop(context, client),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(
                client.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    'DNI: ${client.dni} • ${client.phone}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.border, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person_search_outlined, size: 60, color: AppTheme.border),
          SizedBox(height: 10),
          Text('No se encontraron clientes', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, MediaQuery.of(context).padding.bottom + 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: CustomButton(
        title: 'Crear Nuevo Cliente',
        icon: Icons.person_add_outlined,
        onPress: () => _showAddClientForm(context),
      ),
    );
  }

  void _showAddClientForm(BuildContext context) {
    final nameController = TextEditingController();
    final dniController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (stfContext, setModalState) {
          bool isSearchingDni = false;
          String? dniError;

          Future<void> searchDni() async {
            if (dniController.text.length != 8) return;

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

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registrar Nuevo Cliente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  CustomInput(label: 'Nombre Completo *', placeholder: 'Ej. Juan Pérez', controller: nameController),
                  CustomInput(
                    label: 'DNI *', 
                    placeholder: '8 dígitos', 
                    controller: dniController, 
                    keyboardType: TextInputType.number,
                    errorText: dniError,
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
                  CustomInput(label: 'Celular', placeholder: '987...', controller: phoneController, keyboardType: TextInputType.phone),
                  CustomInput(label: 'Correo Electrónico', placeholder: 'usuario@correo.com', controller: emailController, keyboardType: TextInputType.emailAddress),
                  CustomInput(label: 'Dirección', placeholder: 'Ej. Av. Principal 123', controller: addressController),
                  const SizedBox(height: 25),
                  CustomButton(
                    title: 'Guardar y Seleccionar',
                    onPress: () {
                      if (nameController.text.isNotEmpty) {
                        final newClientData = {
                          'name': nameController.text,
                          'dni': dniController.text,
                          'phone': phoneController.text,
                          'email': emailController.text,
                          'address': addressController.text,
                        };
                        _clientsBloc.add(AddClient(newClientData));
                        
                        Navigator.pop(modalContext); // Cerrar formulario
                        
                        SuccessDialog.show(
                          context,
                          title: '¡Cliente Creado!',
                          message: 'Ahora puedes continuar con el registro del préstamo.',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
