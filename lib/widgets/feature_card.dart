import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconFg),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onTap,
                icon: Text(
                  cta,
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                ),
                label: Icon(Icons.arrow_forward, size: 18, color: cs.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


