import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import 'max_width_container_web.dart';

class TermsAcceptanceFooter extends StatelessWidget {
  final VoidCallback onAccept;

  const TermsAcceptanceFooter({super.key, required this.onAccept});

  void _launchUrl(String path, BuildContext context) async {
    final url = Uri.parse('https://alertzone.help/$path');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Não foi possível abrir esse link!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ao prosseguir, você concorda com a nossa ',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              InkWell(
                onTap: () => _launchUrl('politica-e-privacidade.pdf', context),
                child: Text(
                  'Política de Privacidade',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'e nossos ',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              InkWell(
                onTap: () => _launchUrl('termos-de-service.pdf', context),
                child: Text(
                  'Termos de Serviço',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text('.', style: TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          MaxWidthContainerWeb(
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: const Text(
                  'Aceitar e Continuar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ),
          ),
        ],
      ),
    );
  }
}