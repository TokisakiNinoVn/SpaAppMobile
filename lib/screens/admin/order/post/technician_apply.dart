import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/extensions/login_type_role_extension.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/order_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/order_provider.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/screens/components/chip_custom.dart';
import 'package:spa_app/screens/components/copyable_text.dart';
import 'package:spa_app/screens/components/dashed_divider_component.dart';
import 'package:spa_app/services/realtime_service.dart';

class ListTechnicianApply extends StatefulWidget {
  final Map<String, dynamic> data;

  const ListTechnicianApply({super.key, required this.data});

  @override
  State<ListTechnicianApply> createState() => _ListTechnicianApplyState();
}

class _ListTechnicianApplyState extends State<ListTechnicianApply> {
  late Map<String, dynamic> _order;

  List<Map<String, dynamic>> _technicians = [];
  Set<String> _selectedApplyIds = {}; // Lưu applyId của các KTV được chọn

  bool _isLoading = true;
  bool _isAssigning = false;
  String? _error;
  late Function(dynamic) _listener;

  @override
  void initState() {
    super.initState();
    _order = widget.data;

    RealtimeService.instance.init(context: context);

    appLog("data widget: ${widget.data}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadListTechnicianApply();
    });

    _listener = (dynamic dataApply) {
      if (!mounted) return;

      try {
        final apply = Map<String, dynamic>.from(dataApply);
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

    RealtimeService.instance.onNewTechnicianApplyOrderListeners.add(_listener);
  }

  @override
  void dispose() {
    RealtimeService.instance.onNewTechnicianApplyOrderListeners.remove(
      _listener,
    );
    super.dispose();
  }

  Future<void> _loadListTechnicianApply() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedApplyIds.clear();
    });

    try {
      final provider = context.read<OrderProvider>();

      final success = await provider.technicianApplyOrderAdmin(_order["_id"]);

      if (success && mounted) {
        setState(() {
          _technicians = List<Map<String, dynamic>>.from(
            provider.listTechnicianApplyPost,
          );

          // appLog("DS các KTV apply: $_technicians");
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

  void _toggleSelection(String applyId) {
    setState(() {
      if (_selectedApplyIds.contains(applyId)) {
        _selectedApplyIds.remove(applyId);
      } else {
        _selectedApplyIds.add(applyId);
      }
    });
  }

  Future<void> _handleAssign() async {
    if (_selectedApplyIds.isEmpty || _isAssigning) return;

    setState(() => _isAssigning = true);

    String errorMessage;
    try {
      final orderId = _order["_id"];
      final selectedList = _selectedApplyIds.toList();

      final provider = context.read<OrderProvider>();
      final success = await provider.entrustOrderAdmin(orderId, {
        "selectedList": selectedList,
      });
      if (success && mounted) {
        await _loadListTechnicianApply();
        SnackBarHelper.showSuccess(context, "Giao việc cho KTV thành công");
      }
    } catch (e) {
      // Show error message from API response
      final message = e.toString();
      if (message.startsWith('Exception: ')) {
        errorMessage = message.replaceFirst('Exception: ', '');
      } else {
        errorMessage = message;
      }
      if (mounted) {
        SnackBarHelper.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _selectedApplyIds.clear();
        });
      }
    }
  }

  void _showTechnicianDetails(Map<String, dynamic> applyData) {
    final tech = Map<String, dynamic>.from(applyData["technician"] ?? {});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      child:
                          tech["avatar"] != null
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
                        Text(tech["phone"] ?? "Chưa có số điện thoại"),
                        if (tech["email"] != null) Text(tech["email"]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    "Giới tính",
                    tech["gender"] == "female" ? "Nữ" : "Nam",
                  ),
                  _buildDetailRow("Kinh nghiệm", tech["experience"] ?? ""),
                  _buildDetailRow("Tỉnh/TP", tech["province"] ?? ""),
                  _buildDetailRow(
                    "Quận/Huyện",
                    (tech["districts"] as List?)?.join(", ") ?? "",
                  ),
                  _buildDetailRow("Địa chỉ", tech["address"] ?? ""),
                  _buildDetailRow("Đánh giá", "${tech["rate"] ?? 0}"),
                  _buildDetailRow(
                    "Trạng thái",
                    tech["isActive"] == true
                        ? "Đang hoạt động"
                        : "Không hoạt động",
                  ),
                  _buildDetailRow(
                    "Đang làm việc",
                    tech["isWoking"] == true ? "Có" : "Không",
                  ),
                  if (tech["bio"] != null && tech["bio"].toString().isNotEmpty)
                    _buildDetailRow("Giới thiệu", tech["bio"]),
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
                        itemCount: (tech["images"] as List).length,
                        itemBuilder: (_, index) {
                          final img = tech["images"][index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                FormatHelper.formatNetworkImageUrl(img["url"]),
                                width: 110,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: 110,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
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
      child: const Icon(Icons.person, size: 50),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
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
          Expanded(child: Text(value.isEmpty ? "Chưa cập nhật" : value)),
        ],
      ),
    );
  }

  // ================== UI ORDER CARD ==================
  Widget _buildOrderInfoCard() {
    final order = _order;
    bool isPrioritize = order['pricing']?['extraAmount'] > 0 ? true : false;

    return Column(
      children: [
        // ====== CARD NGƯỜI TẠO (RIÊNG) ======
        _buildCreatorCard(),

        const SizedBox(height: 12),

        // ====== CARD THÔNG TIN ORDER ======
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: ColorConfig.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TRẠNG THÁI & ƯU TIÊN
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: OrderHelper.statusColor(order["status"]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        OrderHelper.displayStatusOrder(order["status"]),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isPrioritize)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Ưu tiên",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // nút Xem chi tiết (có icon và text)
                    InkWell(
                      onTap: () {
                        final orderId = order['_id']?.toString();
                        if (orderId == null) return;
                        context.push(
                          "${AdminRouterConfig.detailOrderAdmin}/$orderId",
                          extra: {'isEntrust': false, 'isNewOrder': true},
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConfig.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Xem chi tiết",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const DashedDivider(),
                const SizedBox(height: 5),

                // TÊN DỊCH VỤ & THỜI GIAN
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order['nameService'] ?? "Dịch vụ Spa",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${order['serviceTimePriceDetails']['duration'] ?? 0} phút",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 5),
                const DashedDivider(),
                const SizedBox(height: 8),

                // KHÁCH HÀNG
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      "${order["genderCustomer"] == "female" ? "Khách nữ" : "Khách nam"}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    CopyableText(
                      text: order["phoneCustomer"] ?? "",
                      icon: Icons.call,
                      successMessage:
                          "Đã sao chép số điện thoại ${order["phoneCustomer"] ?? ""}",
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ĐỊA CHỈ
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order["address"] ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // THỜI GIAN LÀM & LOẠI ĐƠN
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      order["workingHours"] ?? "",
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    const Spacer(),
                    Text(
                      "${order['subTypeOrder'] == 'now' ? 'Đơn làm ngay' : 'Đơn hẹn giờ'}",
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // TIỀN TIP
                Row(
                  children: [
                    Text(
                      "Tiền tip: ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    if (order["isPrioritize"] == true)
                      Row(
                        children: [
                          Text(
                            "${FormatHelper.formatPrice(order["moneyPrioritize"] ?? 0)}đ",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                const DashedDivider(),
                const SizedBox(height: 5),

                // TIỀN KTV NHẬN & TỔNG TIỀN
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "KTV Nhận",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${FormatHelper.formatPrice(order['pricing']?['technicianReceiveAmount'] ?? 0)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Tổng tiền khách phải trả",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${FormatHelper.formatPrice(order['pricing']?['finalAmount'] ?? 0)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ====== CARD NGƯỜI TẠO (RIÊNG BIỆT) ======
  Widget _buildCreatorCard() {
    final createByUser = _order['createByUser'] ?? {};
    if (createByUser.isEmpty) return const SizedBox.shrink();
    final displayRoles =
        LoginTypeRoleExtension.fromValue(
          createByUser['rolesActive'],
        ).displayName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: ColorConfig.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Người đăng đơn",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${createByUser['fullname'] ?? ''}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "${displayRoles}",
                    style: TextStyle(fontSize: 13, color: Colors.black),
                  ),
                ],
              ),
            ),
            CopyableText(
              text: createByUser["phone"] ?? "",
              successMessage:
                  "Đã sao chép số điện thoại ${createByUser["phone"] ?? ""}",
            ),
          ],
        ),
      ),
    );
  }

  // ================== ITEM KTV (có checkbox) ==================
  Widget _buildTechnicianItem(
    Map<String, dynamic> apply,
    Map<String, dynamic> tech,
  ) {
    final applyId = apply["applyId"].toString();
    final isSelected = _selectedApplyIds.contains(applyId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showTechnicianDetails(apply),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          tech["avatar"] != null
                              ? Image.network(
                                FormatHelper.formatNetworkImageUrl(
                                  tech["avatar"],
                                ),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.person, size: 40),
                                  );
                                },
                              )
                              : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 40),
                              ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tech["fullName"] ?? "Không tên",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Text(
                          //   tech["phone"] ?? "Chưa có số",
                          //   style: const TextStyle(
                          //     fontSize: 13,
                          //     color: Colors.grey,
                          //   ),
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          // ),
                          CopyableText(
                            text: tech["phone"] ?? "",
                            successMessage:
                                "Đã sao chép số điện thoại ${tech["phone"] ?? ""}",
                          ),
                          Row(
                            children: [
                              // Text(
                              //   apply["isEntrust"] == true
                              //       ? "Đã giao đơn"
                              //       : "Chưa giao đơn",
                              //   style: const TextStyle(
                              //     fontSize: 13,
                              //     color: Colors.grey,
                              //   ),
                              //   maxLines: 1,
                              //   overflow: TextOverflow.ellipsis,
                              // ),
                            if (apply["isEntrust"] && apply["isEntrust"] != null) ...[
                              StatusChip(
                                label:
                                    apply["isEntrust"] == true
                                        ? "Đã giao đơn"
                                        : "Chưa giao đơn",
                                textColor:
                                    apply["isEntrust"] == true
                                        ? Colors.green
                                        : Colors.orange,
                                backgroundColor:
                                    apply["isEntrust"] == true
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                              ),
                            ],
                              if (apply["isEntrust"] && apply["isEntrust"] != null) ...[
                                const SizedBox(width: 5),
                                // Text(
                                //   OrderHelper.displayStatusOrder(
                                //     apply["statusEntrust"],
                                //   ),
                                //   style: const TextStyle(
                                //     fontSize: 13,
                                //     color: Colors.grey,
                                //   ),
                                //   maxLines: 1,
                                //   overflow: TextOverflow.ellipsis,
                                // ),
                                StatusChip(
                                  label: OrderHelper.displayStatusOrder(
                                    apply["statusEntrust"],
                                  ),
                                  textColor: Colors.white,
                                  backgroundColor: Color(0xFFE39352),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          if (apply["isEntrust"] != true) ...[
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelection(applyId),
              activeColor: ColorConfig.primary,
            ),
          ],
        ],
      ),
    );
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorConfig.primaryBackground,
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
                  borderRadius: BorderRadius.circular(40),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadListTechnicianApply,
                      child: const Text("Thử lại"),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // ✅ Phần nội dung có thể scroll (chiếm toàn bộ không gian còn lại)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card thông tin đơn việc
                          _buildOrderInfoCard(),

                          const SizedBox(height: 10),

                          // Phần danh sách ứng viên
                          if (_technicians.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  "Chưa có KTV nào ứng tuyển",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    8,
                                  ),
                                  child: Text(
                                    "Ứng viên (${_technicians.length})",
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                RefreshIndicator(
                                  onRefresh: _loadListTechnicianApply,
                                  child: ListView.builder(
                                    shrinkWrap:
                                        true, // ✅ Quan trọng: cho phép ListView co lại theo nội dung
                                    physics:
                                        const NeverScrollableScrollPhysics(), // ✅ Tắt scroll của ListView
                                    itemCount: _technicians.length,
                                    itemBuilder: (_, index) {
                                      final apply = _technicians[index];
                                      final tech = Map<String, dynamic>.from(
                                        apply["technician"] ?? {},
                                      );
                                      return _buildTechnicianItem(apply, tech);
                                    },
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  // ✅ Nút Giao việc - luôn cố định ở dưới cùng
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_selectedApplyIds.isEmpty || _isAssigning)
                                ? null
                                : _handleAssign,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConfig.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isAssigning
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  "Giao việc (${_selectedApplyIds.length})",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
