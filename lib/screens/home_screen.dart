import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import 'three_d_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon. We are building this feature.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _balayyaIncoming(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Balayya on the way. Jai Balayya!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'VL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Vllama'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _comingSoon(context),
            child: const Text('Studio'),
          ),
          TextButton(
            onPressed: () => _comingSoon(context),
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => _comingSoon(context),
            child: const Text('Pricing'),
          ),
          TextButton(
            onPressed: () => _comingSoon(context),
            child: const Text('About'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _comingSoon(context),
            child: const Text('Log in'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: () => _comingSoon(context),
              child: const Text('Sign up'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final crossAxisCount = maxWidth >= 1100 ? 2 : 1;
          final horizontalPadding = maxWidth >= 1100 ? 24.0 : 16.0;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: crossAxisCount == 2 ? 2.7 : 2.3,
                  ),
                  children: [
                    FeatureCard(
                      icon: Icons.image_outlined,
                      iconBg: const Color(0xFFE9D5FF),
                      iconFg: const Color(0xFF7B2CBF),
                      title: 'Image',
                      subtitle: 'Generate AI-powered images from text prompts',
                      cta: 'Start Creating',
                      onTap: () => _balayyaIncoming(context),
                    ),
                    FeatureCard(
                      icon: Icons.videocam_outlined,
                      iconBg: const Color(0xFFD6E4FF),
                      iconFg: const Color(0xFF2563EB),
                      title: 'Video',
                      subtitle: 'Create dynamic videos with AI',
                      cta: 'Start Creating',
                      onTap: () => _balayyaIncoming(context),
                    ),
                    FeatureCard(
                      icon: Icons.audiotrack_outlined,
                      iconBg: const Color(0xFFD1FAE5),
                      iconFg: const Color(0xFF16A34A),
                      title: 'Audio',
                      subtitle: 'Generate speech and audio from text',
                      cta: 'Start Creating',
                      onTap: () => _balayyaIncoming(context),
                    ),
                    FeatureCard(
                      icon: Icons.view_in_ar_outlined,
                      iconBg: const Color(0xFFFFEDD5),
                      iconFg: const Color(0xFFEA580C),
                      title: '3D Model',
                      subtitle: 'Create interactive 3D models',
                      cta: 'Start Creating',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ThreeDScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


