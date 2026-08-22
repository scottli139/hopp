import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/providers.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_theme_data.dart';
import '../../utils/app_logger.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_divider.dart';

/// About Screen - Displays app information and branding
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  /// 打开外部链接（系统默认浏览器）
  static Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    AppLogger.info('[About] open link: $url, canLaunch=$canLaunch');
    if (canLaunch) {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      AppLogger.info('[About] launchUrl result: $launched');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _buildLogo(colorScheme),
                const SizedBox(height: 24),

                // App Name
                Text(
                  'Hopp',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          colorScheme.primary,
                          const Color(0xFFEC4899),
                        ],
                      ).createShader(
                        const Rect.fromLTWH(0, 0, 200, 50),
                      ),
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Hop to your APIs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.appTheme.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),

                // Version Card
                _buildInfoCard(
                  context,
                  title: 'Version',
                  content: ref.watch(appVersionProvider).valueOrNull ??
                      AppConstants.appVersion,
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 16),

                // Description Card
                _buildInfoCard(
                  context,
                  title: 'Description',
                  content:
                      'A lightweight, cross-platform API testing tool built with Flutter. Hopp makes API testing simple, fast, and enjoyable.',
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),

                // Features Card
                _buildFeaturesCard(context),
                const SizedBox(height: 16),

                // Tech Stack Card
                _buildTechStackCard(context),
                const SizedBox(height: 16),

                // Links Card
                _buildLinksCard(context),
                const SizedBox(height: 32),

                // Brand Footer
                _buildBrandFooter(context, theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: AppMetrics.br10,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppMetrics.br10,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppMetrics.br10,
        side: BorderSide(
          color: context.appTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: context.appTheme.brand,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appTheme.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.appTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(BuildContext context) {
    final theme = Theme.of(context);
    final features = [
      '🔥 Lightweight & Fast',
      '💻 Cross-Platform (macOS, Windows, Linux)',
      '📝 Full HTTP Request Support',
      '📦 Collection Management',
      '📑 Multiple Tabs',
      '🌓 Dark Mode Support',
      '🌍 Multi-language Support',
      '🔒 Local Data Storage',
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppMetrics.br10,
        side: BorderSide(
          color: context.appTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_outline,
                  size: 20,
                  color: context.appTheme.brand,
                ),
                const SizedBox(width: 12),
                Text(
                  'Features',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appTheme.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.appTheme.brand,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.appTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTechStackCard(BuildContext context) {
    final theme = Theme.of(context);
    final techStack = [
      {'name': 'Flutter', 'version': '3.27.x', 'icon': '💙'},
      {'name': 'Dart', 'version': '3.6+', 'icon': '🔷'},
      {'name': 'Riverpod', 'version': '2.x', 'icon': '🏞️'},
      {'name': 'Dio', 'version': '5.x', 'icon': '🌐'},
      {'name': 'Hive', 'version': '2.x', 'icon': '📦'},
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppMetrics.br10,
        side: BorderSide(
          color: context.appTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code_outlined,
                  size: 20,
                  color: context.appTheme.brand,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tech Stack',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appTheme.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: techStack
                  .map((tech) => Chip(
                        avatar: Text(tech['icon']!),
                        label: Text('${tech['name']} ${tech['version']}'),
                        backgroundColor: context.appTheme.brandSoft,
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppMetrics.br10,
        side: BorderSide(
          color: context.appTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link_outlined,
                  size: 20,
                  color: context.appTheme.brand,
                ),
                const SizedBox(width: 12),
                Text(
                  'Links',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appTheme.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLinkItem(
              context,
              icon: Icons.home_outlined,
              title: 'GitHub Repository',
              subtitle: 'github.com/scottli139/hopp',
              url: 'https://github.com/scottli139/hopp',
            ),
            const AppDivider(height: 24),
            _buildLinkItem(
              context,
              icon: Icons.bug_report_outlined,
              title: 'Report Issues',
              subtitle: 'Submit bug reports and feature requests',
              url: 'https://github.com/scottli139/hopp/issues',
            ),
            const AppDivider(height: 24),
            _buildLinkItem(
              context,
              icon: Icons.favorite_outline,
              title: 'Contribute',
              subtitle: 'Help make Hopp better',
              url:
                  'https://github.com/scottli139/hopp/blob/main/CONTRIBUTING.md',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _openLink(url),
      borderRadius: AppMetrics.br8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appTheme.brandSoft,
                borderRadius: AppMetrics.br10,
              ),
              child: Icon(
                icon,
                size: 20,
                color: context.appTheme.brand,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.appTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandFooter(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        const AppDivider(height: 16),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 16,
              color: context.appTheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              'Built with passion by the Hopp team',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.appTheme.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© 2026 Hopp. All rights reserved.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.appTheme.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                const Color(0xFFEC4899).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: context.appTheme.brand,
              ),
              const SizedBox(width: 6),
              Text(
                'Powered by AI · Built with Flutter',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appTheme.brand,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
