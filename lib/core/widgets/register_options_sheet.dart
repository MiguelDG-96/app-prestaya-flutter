import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';

import 'package:app_prestaya_flutter/features/loans/presentation/pages/add_loan_page.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/pages/add_rental_page.dart';

class RegisterOptionsSheet extends StatelessWidget {
  const RegisterOptionsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const RegisterOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '¿Qué deseas registrar?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona una opción para continuar',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildOptionCard(
            context: context,
            title: 'Nuevo Préstamo',
            description: 'Registra un préstamo para un cliente existente o nuevo.',
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF6366F1),
            bgColor: const Color(0xFF6366F1).withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddLoanPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context: context,
            title: 'Nuevo Alquiler',
            description: 'Registra un nuevo inquilino y su contrato de cuarto.',
            icon: Icons.apartment_outlined,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFF10B981).withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddRentalPage()),
              );
            },
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFFFF4B4B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.border,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
