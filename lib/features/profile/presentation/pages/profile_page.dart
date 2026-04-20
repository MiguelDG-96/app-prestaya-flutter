import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_prestaya_flutter/features/auth/domain/entities/user_entity.dart';
import 'about_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = (state is Authenticated) ? state.user : null;
          
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 30),
                _buildProfileAvatar(context, user),
                const SizedBox(height: 20),
                Text(
                  user?.name ?? 'Usuario',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text),
                ),
                Text(
                  user?.email ?? 'correo@ejemplo.com',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('INFORMACIÓN PERSONAL'),
                      const SizedBox(height: 15),
                      _buildPersonalInfoCard(context, user),
                      
                      const SizedBox(height: 30),
                      _buildSectionTitle('PREFERENCIAS'),
                      const SizedBox(height: 15),
                      _buildPreferencesCard(context),
                      
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 10, left: 10, right: 10, bottom: 20),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Text(
            'Mi Perfil',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, UserEntity? user) {
    final photoUrl = user?.photoUrl;
    final String? fullPhotoUrl = (photoUrl != null && photoUrl.isNotEmpty)
        ? (photoUrl.startsWith('http') ? photoUrl : 'https://servicio.teamrecios.com$photoUrl')
        : null;

    return Stack(
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
            ],
            image: fullPhotoUrl != null 
                ? DecorationImage(
                    image: NetworkImage(fullPhotoUrl), 
                    fit: BoxFit.cover,
                  )
                : const DecorationImage(
                    image: AssetImage('assets/images/dev/developer.jpg'), 
                    fit: BoxFit.cover
                  ),
          ),
          child: (fullPhotoUrl == null && user == null)
              ? const Center(
                  child: Icon(Icons.person, size: 60, color: AppTheme.primary),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 5,
          child: Material(
            color: AppTheme.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              onTap: () {
                if (user != null) {
                  _showPickerMenu(context, user.id);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inicia sesión para cambiar tu foto')),
                  );
                }
              },
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPickerMenu(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Foto de Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primary),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(context, userId, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(context, userId, ImageSource.camera);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, String userId, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1000,
    );

    if (pickedFile != null && context.mounted) {
      context.read<AuthBloc>().add(PhotoUploadRequested(userId, pickedFile.path));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, UserEntity? user) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Datos de Contacto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.text),
              ),
              TextButton.icon(
                onPressed: () => _showEditProfileDialog(context, user),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoItem(Icons.person_outline, 'Nombre completo', user?.name ?? 'No disponible'),
          const Divider(height: 30, color: AppTheme.border),
          _buildInfoItem(Icons.email_outlined, 'Correo electrónico', user?.email ?? 'No disponible'),
          const Divider(height: 30, color: AppTheme.border),
          _buildInfoItem(Icons.phone_outlined, 'Teléfono', user?.phone ?? 'No especificado'),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserEntity? user) {
    final nameController = TextEditingController(text: user?.name);
    final phoneController = TextEditingController(text: user?.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Perfil'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(UpdateProfileRequested(
                name: nameController.text,
                phone: phoneController.text,
              ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar'),
          ),
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
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildPreferenceItem(Icons.notifications_none_outlined, 'Notificaciones'),
          const Divider(height: 1, indent: 60, color: AppTheme.border),
          _buildPreferenceItem(Icons.security_outlined, 'Seguridad'),
          const Divider(height: 1, indent: 60, color: AppTheme.border),
          _buildPreferenceItem(Icons.info_outline, 'Acerca de la App', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.text),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.border),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de la aplicación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
