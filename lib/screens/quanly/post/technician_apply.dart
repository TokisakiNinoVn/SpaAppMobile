import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/services/realtime_service.dart';
import 'package:spa_app/services/user_discount_service.dart';

class ListTechnicianApplyManager extends StatefulWidget {
  final Map<String, dynamic> data;

  const ListTechnicianApplyManager({
    super.key,
    required this.data,
  });

  @override
  State<ListTechnicianApplyManager> createState() => _ListTechnicianApplyState();
}

class _ListTechnicianApplyState extends State<ListTechnicianApplyManager> {
  final UserDiscountService _userDiscountService = UserDiscountService();

  late Map<String, dynamic> _order;

  List<Map<String, dynamic>> _technicians = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _order = widget.data;

    // appLog("ID order: ${_order["_id"]}");

    _listenRealtime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadListTechnicianApply();
    });
  }

  void _listenRealtime() {
    RealtimeService.instance.onNewTechnicianApplyOrder = (dynamic dataApply) {
      try {
        if (!mounted) return;

        final apply = Map<String, dynamic>.from(dataApply);

        final applyId = apply["applyId"];

        // tránh duplicate
        final existed = _technicians.any(
              (e) => e["applyId"] == applyId,
        );

        if (existed) return;

        setState(() {
          _technicians.insert(0, apply);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${apply["technician"]?["fullName"] ?? "KTV"} vừa ứng tuyển",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        appLog("Realtime technician_apply error: $e");
      }
    };
  }

  @override
  void dispose() {
    RealtimeService.instance.onNewTechnicianApplyOrder = null;
    super.dispose();
  }

  Future<void> _loadListTechnicianApply() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<OrderProvider>();

      final success = await provider.technicianApplyOrderAdmin(
        _order["_id"],
      );

      if (success && mounted) {
        setState(() {
          _technicians = List<Map<String, dynamic>>.from(
            provider.listTechnicianApplyPost,
          );
        });
      } else if (mounted) {
        setState(() {
          _error = "Không thể tải danh sách KTV";
        });
      }
    } catch (e) {
      appLog('Lỗi load danh sách KTV: $e');

      if (mounted) {
        setState(() {
          _error = "Đã xảy ra lỗi khi tải dữ liệu";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showTechnicianDetails(Map<String, dynamic> applyData) {
    final tech = applyData["technician"] as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: ClipOval(
                      child: tech["avatar"] != null
                          ? Image.network(
                        FormatHelper.formatNetworkImageUrl(
                          tech["avatar"],
                        ),
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _avatarPlaceholder();
                        },
                      )
                          : _avatarPlaceholder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      tech["fullName"] ?? "Không có tên",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          tech["phone"] ?? "Chưa có số điện thoại",
                        ),
                        if (tech["email"] != null)
                          Text(tech["email"]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildDetailRow(
                    "Giới tính",
                    tech["gender"] == "female"
                        ? "Nữ"
                        : "Nam",
                  ),

                  _buildDetailRow(
                    "Kinh nghiệm",
                    tech["experience"] ?? "",
                  ),

                  _buildDetailRow(
                    "Tỉnh/TP",
                    tech["province"] ?? "",
                  ),

                  _buildDetailRow(
                    "Quận/Huyện",
                    (tech["districts"] as List?)
                        ?.join(", ") ??
                        "",
                  ),

                  _buildDetailRow(
                    "Địa chỉ",
                    tech["address"] ?? "",
                  ),

                  _buildDetailRow(
                    "Đánh giá",
                    "${tech["rate"] ?? 0}",
                  ),

                  _buildDetailRow(
                    "Trạng thái",
                    tech["isActive"] == true
                        ? "Đang hoạt động"
                        : "Không hoạt động",
                  ),

                  _buildDetailRow(
                    "Đang làm việc",
                    tech["isWoking"] == true
                        ? "Có"
                        : "Không",
                  ),

                  _buildDetailRow(
                    "Số dư",
                    FormatHelper.formatPrice(
                      tech["balance"] ?? 0,
                    ),
                  ),

                  if (tech["bio"] != null &&
                      tech["bio"].toString().isNotEmpty)
                    _buildDetailRow(
                      "Giới thiệu",
                      tech["bio"],
                    ),

                  const SizedBox(height: 18),

                  if (tech["images"] != null &&
                      (tech["images"] as List).isNotEmpty) ...[
                    const Text(
                      "Hình ảnh khác",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                        (tech["images"] as List).length,
                        itemBuilder: (_, index) {
                          final img =
                          tech["images"][index];

                          return Padding(
                            padding:
                            const EdgeInsets.only(
                              right: 10,
                            ),
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(
                                14,
                              ),
                              child: Image.network(
                                FormatHelper
                                    .formatNetworkImageUrl(
                                  img["url"],
                                ),
                                width: 110,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) {
                                  return Container(
                                    width: 110,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 110,
      height: 110,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.person,
        size: 50,
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty
                  ? "Chưa cập nhật"
                  : value,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,

        title: Row(
          children: [
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius:
                  BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),

            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Các KTV ứng việc",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Text(_error!),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed:
              _loadListTechnicianApply,
              child: const Text(
                "Thử lại",
              ),
            ),
          ],
        ),
      )
          : _technicians.isEmpty
          ? const Center(
        child: Text(
          "Chưa có KTV nào ứng tuyển",
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _technicians.length,

          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),

          itemBuilder: (_, index) {
            final apply = _technicians[index];

            final tech =
            apply["technician"]
            as Map<String, dynamic>;

            return _buildTechnicianCard(
              tech,
              apply,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTechnicianCard(
      Map<String, dynamic> tech,
      Map<String, dynamic> applyData,
      ) {
    return GestureDetector(
      onTap: () {
        _showTechnicianDetails(applyData);
      },

      child: Card(
        elevation: 2,
        color: Colors.white,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: tech["avatar"] != null
                    ? Image.network(
                  FormatHelper
                      .formatNetworkImageUrl(
                    tech["avatar"],
                  ),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 50,
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.person,
                    size: 50,
                  ),
                ),
              ),
            ),

            Center(
              child: Expanded(
                flex: 2,
                child: Padding(
                  padding:
                  const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Align(
                        child: Text(
                          tech["fullName"] ??
                              "Không tên",
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Align(
                        child: Text(
                          tech["phone"] ?? "Chưa có số",
                          style: TextStyle(
                            fontSize: 13,
                            color: ColorConfig.textBlack,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}