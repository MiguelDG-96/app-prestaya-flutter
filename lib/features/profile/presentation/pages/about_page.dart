import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF1E1B2E);
    const cardColor = Color(0xFF2D2A45);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Información', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo y Nombre
            _buildLogoSection(),
            const SizedBox(height: 30),
            
            // Tarjeta Principal
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sobre la Aplicación',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Esta es una solución integral diseñada para facilitar el control y seguimiento de préstamos, cobros de alquileres y gestión de clientes de manera profesional y eficiente.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 25),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),
                  
                  // Desarrollador
                  _buildDeveloperSection(),
                  
                  const SizedBox(height: 30),
                  // Versión
                  _buildVersionItem(Icons.account_tree_outlined, 'VERSIÓN', '1.0.0 (BETA)'),
                  const SizedBox(height: 20),
                  // Actualización
                  _buildVersionItem(Icons.calendar_today_outlined, 'ÚLTIMA ACTUALIZACIÓN', 'Abril 2026'),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Text(
              '© 2026 PrestaYa. Todos los derechos reservados.',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Usamos un placeholder si el logo no carga, o puedes poner la ruta exacta
        Image.asset(
          'assets/logos/logo-prestaya-white.png',
          height: 100,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: Colors.white, size: 80),
        ),
        const SizedBox(height: 15),
        const Text(
          'PrestaYa',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const Text(
          'Sistema de Gestión de Préstamos',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage('assets/images/dev/developer.jpg'),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DESARROLLADO POR', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Miguel A. Dolic Grandez', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildSocialIcon(
                      FontAwesomeIcons.linkedinIn, 
                      const Color(0xFF0077B5),
                      'https://www.linkedin.com/in/miguel-angel-dolic-grandez-isi/',
                    ),
                    const SizedBox(width: 10),
                    _buildSocialIcon(
                      FontAwesomeIcons.github, 
                      Colors.white70,
                      'https://github.com/MiguelDG-96',
                    ),
                    const SizedBox(width: 10),
                    _buildSocialIcon(
                      FontAwesomeIcons.whatsapp, 
                      const Color(0xFF25D366),
                      'https://wa.me/51934634772',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildVersionItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
