import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/information_provider.dart'; // điều chỉnh đường dẫn theo project

class ManagementPlatformFee extends StatefulWidget {
  const ManagementPlatformFee({super.key});

  @override
  State<ManagementPlatformFee> createState() => _ManagementPlatformFeeState();
}

class _ManagementPlatformFeeState extends State<ManagementPlatformFee> {
  // Map lưu TextEditingController cho từng item theo id
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Gọi API lấy danh sách ngay khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InformationProvider>();
      provider.list();
    });
  }

  @override
  void dispose() {
    // Giải phóng các controller
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Cập nhật hoặc tạo controller cho mỗi item khi dữ liệu thay đổi
  void _updateControllers(List platformFees) {
    for (var fee in platformFees) {
      final id = fee['_id'] as String;
      if (!_controllers.containsKey(id)) {
        _controllers[id] = TextEditingController(
          text: (fee['percentage'] ?? 0).toString(),
        );
      }
    }
  }

  Future<void> _updateFee(
    BuildContext context,
    InformationProvider provider,
    String id,
    double percentage,
  ) async {
    final success = await provider.update(id, {'percentage': percentage});
    if (!context.mounted) return;

    if (success) {
      SnackBarHelper.showSuccess(context, 'Cập nhật thành công');
    } else {
      SnackBarHelper.showSuccess(context, 'Cập nhật thất bại: ${provider.errorMessage ?? ''}');
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       automaticallyImplyLeading: false,
  //       backgroundColor: Colors.white,
  //       elevation: 0,
  //       title: Row(
  //         children: [
  //           InkWell(
  //             onTap: () => context.pop(),
  //             borderRadius: BorderRadius.circular(40),
  //             child: Container(
  //               width: 40,
  //               height: 40,
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFFF5F5F5),
  //                 borderRadius: BorderRadius.circular(40),
  //               ),
  //               child: const Icon(
  //                 Icons.arrow_back_ios_new_rounded,
  //                 size: 18,
  //                 color: Color(0xFF1A1A1A),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           const Text("Cài đặt thu phí nền tảng"),
  //         ],
  //       ),
  //     ),
  //     body: Consumer<InformationProvider>(
  //       builder: (context, provider, child) {
  //         if (provider.isLoadingList) {
  //           return const Center(child: CircularProgressIndicator());
  //         }
  //
  //         if (provider.errorMessage != null) {
  //           return Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Text('Lỗi: ${provider.errorMessage}'),
  //                 const SizedBox(height: 16),
  //                 ElevatedButton(
  //                   onPressed: () => provider.list(),
  //                   child: const Text('Thử lại'),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }
  //
  //         final fees = provider.platformFees;
  //         if (fees.isEmpty) {
  //           return const Center(child: Text('Không có dữ liệu phí nền tảng'));
  //         }
  //
  //         // Cập nhật controller khi dữ liệu thay đổi
  //         _updateControllers(fees);
  //
  //         return ListView.builder(
  //           padding: const EdgeInsets.all(16),
  //           itemCount: fees.length,
  //           itemBuilder: (context, index) {
  //             final fee = fees[index];
  //             final id = fee['_id'] as String;
  //             final name = fee['name'] as String;
  //             final controller = _controllers[id]!;
  //             final isUpdating = provider.updatingId == id;
  //
  //             return Card(
  //               margin: const EdgeInsets.only(bottom: 16),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(16),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       name,
  //                       style: const TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 12),
  //                     Row(
  //                       children: [
  //                         Expanded(
  //                           child: TextField(
  //                             controller: controller,
  //                             keyboardType:
  //                             const TextInputType.numberWithOptions(decimal: true),
  //                             decoration: const InputDecoration(
  //                               labelText: 'Phần trăm (%)',
  //                               border: OutlineInputBorder(),
  //                               suffixText: '%',
  //                             ),
  //                           ),
  //                         ),
  //                         const SizedBox(width: 12),
  //                         ElevatedButton(
  //                           onPressed: isUpdating
  //                               ? null
  //                               : () async {
  //                             double? percentage;
  //
  //                             try {
  //                               percentage = double.parse(controller.text.trim());
  //                             } catch (_) {
  //                               ScaffoldMessenger.of(context).showSnackBar(
  //                                 const SnackBar(
  //                                   content: Text('Vui lòng nhập số hợp lệ'),
  //                                   backgroundColor: Colors.orange,
  //                                 ),
  //                               );
  //                               return;
  //                             }
  //
  //                             await _updateFee(
  //                               context,
  //                               provider,
  //                               id,
  //                               percentage,
  //                             );
  //                           },
  //                           child: isUpdating
  //                               ? const SizedBox(
  //                             width: 20,
  //                             height: 20,
  //                             child: CircularProgressIndicator(
  //                               strokeWidth: 2,
  //                             ),
  //                           )
  //                               : const Text('Cập nhật'),
  //                         )
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thu phí các dịch vụ",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  // SizedBox(height: 2),
                  // Text(
                  //   "Quản lý phần trăm phí cho từng dịch vụ",
                  //   style: TextStyle(
                  //     fontSize: 13,
                  //     color: Color(0xFF6B7280),
                  //     fontWeight: FontWeight.w400,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer<InformationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingList) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Có lỗi xảy ra',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => provider.list(),
                      child: const Text("Thử lại"),
                    )
                  ],
                ),
              ),
            );
          }

          final fees = provider.platformFees;

          if (fees.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.list(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text(
                      "Không có dữ liệu",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          _updateControllers(fees);

          return RefreshIndicator(
            onRefresh: () async {
              await provider.list();
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: fees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final fee = fees[index];

                final id = fee['_id'] as String;
                final name = fee['name'] as String;

                final controller = _controllers[id]!;

                final isUpdating = provider.updatingId == id;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                // const SizedBox(height: 4),
                                // const Text(
                                //   "Thiết lập mức phí nền tảng",
                                //   style: TextStyle(
                                //     fontSize: 13,
                                //     color: Color(0xFF6B7280),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                hintText: 'Nhập phần trăm',
                                suffixText: '%',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ColorConfig.primary,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: isUpdating
                                  ? null
                                  : () async {
                                double? percentage;

                                try {
                                  percentage = double.parse(
                                    controller.text.trim(),
                                  );
                                } catch (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng nhập số hợp lệ',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                if (percentage <= 0 || percentage >= 100) {
                                  SnackBarHelper.showError(context, 'Phần trăm phải lớn hơn 0 và nhỏ hơn 100');
                                  return;
                                }

                                await _updateFee(
                                  context,
                                  provider,
                                  id,
                                  percentage,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: ColorConfig.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 1
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: isUpdating
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                "Cập nhật",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}