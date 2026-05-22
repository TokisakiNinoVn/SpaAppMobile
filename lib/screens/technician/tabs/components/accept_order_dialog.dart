import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';

class AcceptOrderDialog extends StatefulWidget {
  final Future<void> Function(String message) onConfirm;

  const AcceptOrderDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<AcceptOrderDialog> createState() => _AcceptOrderDialogState();
}

class _AcceptOrderDialogState extends State<AcceptOrderDialog> {
  final TextEditingController _messageController =
  TextEditingController();

  bool _isLoading = false;

  final List<String> _hintMessages = [
    'Em sẽ đến trong khoảng 15 phút nữa ạ',
    'Anh/Chị vui lòng để ý điện thoại giúp em nhé',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final message = _messageController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onConfirm(message);

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Xác nhận nhận đơn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Sau khi nhận đơn, khách hàng sẽ nhận được thông báo và có thể liên hệ với bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // INPUT
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.done,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                  'Gửi lời nhắn cho khách (không bắt buộc)',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gợi ý nhanh',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hintMessages.map((msg) {
                return InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () {
                    _messageController.text = msg;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Huỷ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                    _isLoading ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: ColorConfig.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                        : Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flash_on_rounded,
                          size: 18,
                          color: ColorConfig.textWhite,
                        ),
                        const SizedBox(width: 6),
                         Text(
                          'Nhận đơn',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w700,
                            color: ColorConfig.textWhite
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}