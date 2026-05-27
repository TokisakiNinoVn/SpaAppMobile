import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/services/realtime_service.dart';

class ListTechnicianApply extends StatefulWidget {
  final Map<String, dynamic> data;

  const ListTechnicianApply({
    super.key,
    required this.data,
  });

  @override
  State<ListTechnicianApply> createState() => _ListTechnicianApplyState();
}

class _ListTechnicianApplyState extends State<ListTechnicianApply> {

  late Map<String, dynamic> _order;

  List<Map<String, dynamic>> _technicians = [];

  bool _isLoading = true;
  String? _error;
  late Function(dynamic) _listener;


  @override
  @override
  void initState() {
    super.initState();
    _order = widget.data;

    // Đảm bảo RealtimeService được kết nối (nếu chưa)
    RealtimeService.instance.init(context: context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadListTechnicianApply();
    });

    _listener = (dynamic dataApply) {
      if (!mounted) return;

      try {
        final apply = Map<String, dynamic>.from(dataApply);

        // ✅ LỌC THEO ORDER ID – chỉ nhận ứng viên của đơn này
        final applyOrderId = apply['orderId']?.toString();
        if (applyOrderId != _order['_id']?.toString()) return;

        final applyId = apply["applyId"];
        final existed = _technicians.any(
              (e) => e["applyId"] == applyId || e["_id"] == applyId,
        );
        if (existed) return;

        setState(() {
          _technicians.insert(0, apply);
        });
      } catch (e) {
        appLog("Realtime technician_apply error: $e");
      }
    };

    RealtimeService.instance
        .onNewTechnicianApplyOrderListeners
        .add(_listener);
  }

  // void _listenRealtime() {
  //   appLog("REGISTER technician_apply listener");
  //
  //   RealtimeService.instance.onNewTechnicianApplyOrder =
  //       (dynamic dataApply) {
  //
  //     appLog("Data technician apply: $dataApply");
  //
  //     try {
  //       if (!mounted) return;
  //
  //       final apply = Map<String, dynamic>.from(dataApply);
  //
  //       final applyId = apply["applyId"];
  //
  //       final existed = _technicians.any(
  //             (e) => e["applyId"] == applyId,
  //       );
  //
  //       appLog("EXISTED: $existed");
  //
  //       if (existed) return;
  //
  //       setState(() {
  //         _technicians.insert(0, apply);
  //       });
  //
  //       appLog("UPDATED TECHNICIANS: ${_technicians.length}");
  //
  //     } catch (e) {
  //       appLog("Realtime technician_apply error: $e");
  //     }
  //   };
  // }

  @override
  void dispose() {
    // RealtimeService.instance.onNewTechnicianApplyOrder = null;

    RealtimeService.instance
        .onNewTechnicianApplyOrderListeners
        .remove(_listener);
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

          // appLog("List technician: $_technicians");
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
    // final tech = applyData["technician"] as Map<String, dynamic>;
    final tech = Map<String, dynamic>.from(
      applyData["technician"] ?? {},
    );

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
        child: RefreshIndicator(
          onRefresh: _loadListTechnicianApply,
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
          
              final tech = Map<String, dynamic>.from(
                apply["technician"] ?? {},
              );
          
              return _buildTechnicianCard(
                tech,
                apply,
              );
            },
          ),
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
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: tech["avatar"] != null
                    ? Image.network(
                  FormatHelper.formatNetworkImageUrl(
                    tech["avatar"],
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, size: 50),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.person, size: 50),
                ),
              ),
            ),

            // 👤 INFO - căn giữa hoàn toàn
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tech["fullName"] ?? "Không tên",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      tech["phone"] ?? "Chưa có số",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorConfig.textBlack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}