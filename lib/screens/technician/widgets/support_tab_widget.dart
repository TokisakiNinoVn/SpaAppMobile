import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportTabWidget extends StatelessWidget {
  const SupportTabWidget({super.key});

  final String zaloNumber = '0867807841';
  final String facebookUrl = 'https://www.facebook.com/yourprofile';

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label đã được sao chép')),
    );
  }

  void _openFacebook(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết Facebook')),
      );
    }
  }

  Widget _buildSupportItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAction,
    required IconData actionIcon,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: ColorConfig.secondary, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: Icon(actionIcon),
          tooltip: tooltip,
          onPressed: onAction,
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
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Hỗ trợ',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          _buildSupportItem(
            context: context,
            icon: Icons.phone_android,
            title: 'Zalo hỗ trợ',
            subtitle: zaloNumber,
            onAction: () => _copyToClipboard(context, zaloNumber, 'Số Zalo'),
            actionIcon: Icons.copy,
            tooltip: 'Sao chép số Zalo',
          ),
          _buildSupportItem(
            context: context,
            icon: Icons.facebook,
            title: 'Facebook hỗ trợ',
            subtitle: facebookUrl,
            onAction: () => _openFacebook(context, facebookUrl),
            actionIcon: Icons.open_in_new,
            tooltip: 'Mở Facebook',
          ),
        ],
      ),
    );
  }
}
