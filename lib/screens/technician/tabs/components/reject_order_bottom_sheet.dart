import 'package:flutter/material.dart';

class RejectOrderBottomSheet extends StatefulWidget {
  final Future<void> Function(String reason) onConfirm;

  const RejectOrderBottomSheet({
    super.key,
    required this.onConfirm,
  });

  @override
  State<RejectOrderBottomSheet> createState() =>
      _RejectOrderBottomSheetState();
}

class _RejectOrderBottomSheetState
    extends State<RejectOrderBottomSheet> {
  final List<String> _quickReasons = [
    'Quá xa',
    'Đang bận việc khác',
    'Sức khỏe không tốt',
    'Không phù hợp với dịch vụ',
    'Lý do khác',
  ];

  final TextEditingController _customReasonController =
  TextEditingController();

  String? _selectedReason;

  bool _isLoading = false;

  bool get _isOtherSelected =>
      _selectedReason == 'Lý do khác';

  bool get _isValid =>
      _selectedReason != null &&
          (_selectedReason != 'Lý do khác' ||
              _customReasonController.text.trim().isNotEmpty);

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    FocusScope.of(context).unfocus();

    final finalReason =
    _selectedReason == 'Lý do khác'
        ? _customReasonController.text.trim()
        : _selectedReason!;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onConfirm(finalReason);

      if (mounted) {
        Navigator.pop(context, finalReason);
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    /// HANDLE
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius:
                          BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    /// HEADER
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color:
                            Colors.red.withOpacity(.08),
                            borderRadius:
                            BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.red.shade400,
                            size: 26,
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Từ chối đơn',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Hãy cho khách một lý do ngắn gọn nhé',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.grey,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// LABEL
                    Text(
                      'Lý do nhanh',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// CHIPS
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                      _quickReasons.map((reason) {
                        final isSelected =
                            _selectedReason == reason;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedReason = null;
                              } else {
                                _selectedReason = reason;
                              }

                              if (_selectedReason !=
                                  'Lý do khác') {
                                _customReasonController
                                    .clear();
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 180,
                            ),
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.red
                                  .withOpacity(.08)
                                  : Colors.grey.shade100,
                              borderRadius:
                              BorderRadius.circular(
                                  14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.red.shade300
                                    : Colors.grey.shade200,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors
                                        .red.shade400,
                                  ),
                                  const SizedBox(
                                      width: 6),
                                ],
                                Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight:
                                    FontWeight.w600,
                                    color: isSelected
                                        ? Colors
                                        .red.shade400
                                        : Colors.grey
                                        .shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    /// OTHER REASON
                    AnimatedSwitcher(
                      duration:
                      const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _isOtherSelected
                          ? Column(
                        key: const ValueKey(
                          'other_reason_input',
                        ),
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lý do khác',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                              FontWeight.w700,
                              color: Colors
                                  .grey.shade800,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors
                                  .grey.shade50,
                              borderRadius:
                              BorderRadius
                                  .circular(18),
                              border: Border.all(
                                color: Colors
                                    .red.shade100,
                              ),
                            ),
                            child: TextField(
                              controller:
                              _customReasonController,
                              maxLines: 4,
                              minLines: 3,
                              autofocus: true,
                              textInputAction:
                              TextInputAction
                                  .done,
                              onChanged: (_) {
                                setState(() {});
                              },
                              onTapOutside: (_) {
                                FocusScope.of(
                                  context,
                                ).unfocus();
                              },
                              decoration:
                              InputDecoration(
                                hintText:
                                'Ví dụ: Em chưa thể hỗ trợ khu vực này vào thời gian hiện tại...',
                                hintStyle:
                                TextStyle(
                                  color: Colors
                                      .grey.shade500,
                                  fontSize: 14,
                                ),
                                border:
                                InputBorder.none,
                                contentPadding:
                                const EdgeInsets
                                    .all(16),
                              ),
                            ),
                          ),

                          const SizedBox(
                              height: 24),
                        ],
                      )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 28),

                    /// BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                              Navigator.pop(
                                  context);
                            },
                            style:
                            OutlinedButton.styleFrom(
                              minimumSize:
                              const Size.fromHeight(
                                  54),
                              side: BorderSide(
                                color:
                                Colors.grey.shade300,
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    16),
                              ),
                            ),
                            child: const Text(
                              'Huỷ',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.w700,
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
                            !_isValid || _isLoading
                                ? null
                                : _handleConfirm,
                            style:
                            ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                              Colors.red.shade400,
                              disabledBackgroundColor:
                              Colors.grey.shade300,
                              foregroundColor:
                              Colors.white,
                              disabledForegroundColor:
                              Colors.grey.shade500,
                              minimumSize:
                              const Size.fromHeight(
                                  54),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color:
                                Colors.white,
                              ),
                            )
                                : const Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                              children: [
                                Icon(
                                  Icons
                                      .close_rounded,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Xác nhận từ chối',
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .w700,
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
            ),
          ),
        ),
      ),
    );
  }
}