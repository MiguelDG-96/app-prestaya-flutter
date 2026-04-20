import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Listo',
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Listo',
    VoidCallback? onDismiss,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: SuccessDialog(
              title: title,
              message: message,
              buttonText: buttonText,
              onDismiss: onDismiss,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 20.0, offset: Offset(0.0, 10.0)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de Check Verde
            Container(
              height: 100,
              width: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 30),
            
            // Título
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            
            // Mensaje
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 35),
            
            // Botón "Listo"
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onDismiss != null) onDismiss!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppTheme.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
