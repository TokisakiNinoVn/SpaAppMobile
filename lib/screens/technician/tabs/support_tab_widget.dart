import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportTabWidget extends StatelessWidget {
  const SupportTabWidget({super.key});

  static const String zaloNumber = AppConfig.adminZalo;
  static const String facebookUrl = 'https://www.facebook.com';

  Future<void> _copyToClipboard(
      BuildContext context,
      String text,
      ) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thông tin liên hệ đã được sao chép'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openLink(
      BuildContext context,
      String url,
      ) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở liên kết'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ColorConfig.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: ColorConfig.secondary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          const Text(
            'Liên hệ hỗ trợ',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Liên hệ với đội ngũ hỗ trợ nếu bạn cần trợ giúp về tài khoản hoặc dịch vụ.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          _buildContactCard(
            context: context,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Zalo',
            subtitle: zaloNumber,
            onTap: () => _copyToClipboard(
              context,
              zaloNumber,
            ),
          ),

          _buildContactCard(
            context: context,
            icon: Icons.public,
            title: 'Trang hỗ trợ',
            subtitle: 'Mở trang liên hệ',
            onTap: () => _openLink(
              context,
              AppConfig.urlSupport,
            ),
          ),
        ],
      ),
    );
  }
}