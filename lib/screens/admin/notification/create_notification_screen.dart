import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../services/notification_service.dart';
import '../../../../helper/snackbar_helper.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({
    super.key,
  });

  @override
  State<CreateNotificationScreen> createState() =>
      _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _repeatIntervalController = TextEditingController();
  final TextEditingController _specificDateTimeController = TextEditingController();

  // Selected values
  String? _selectedRecipientType;
  String? _selectedModeValue; // Store the value (1,2,3,4,5)
  String? _selectedModeType; // Store the mode type (once, daily_time, interval)
  bool _isSendNow = false;

  // For daily_time mode with days of week
  List<int> _selectedDaysOfWeek = [];
  TimeOfDay? _selectedTimeOfDay;
  DateTime? _selectedSpecificDate;

  // For interval mode
  int? _repeatIntervalMinutes;

  final List<Map<String, String>> typeOfRecipient = [
    {"name": "Khách hàng", "value": "customer"},
    {"name": "Kỹ thuật viên", "value": "ktv"}
  ];

  final List<Map<String, String>> modes = [
    {"name": "Gửi một lần (gửi ngay)", "mode": "once", "value": "1", "isSendNow": "true"},
    {"name": "Gửi một lần (hẹn giờ)", "mode": "once", "value": "2", "isSendNow": "false"},
    {"name": "Lặp theo ngày", "mode": "daily_time", "value": "3", "isSendNow": "false"},
    {"name": "Lặp theo tuần", "mode": "daily_time", "value": "4", "isSendNow": "false"},
    {"name": "Lặp sau mỗi N phút", "mode": "interval", "value": "5", "isSendNow": "false"}
  ];

  final Map<int, String> daysOfWeekMap = {
    0: 'Thứ 2',
    1: 'Thứ 3',
    2: 'Thứ 4',
    3: 'Thứ 5',
    4: 'Thứ 6',
    5: 'Thứ 7',
    6: 'Chủ nhật',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _repeatIntervalController.dispose();
    _specificDateTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOfDay ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTimeOfDay = picked;
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedSpecificDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: _selectedTimeOfDay ?? TimeOfDay.now(),
      );
      if (timePicked != null) {
        setState(() {
          _selectedSpecificDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
          _selectedTimeOfDay = timePicked;
        });
        _specificDateTimeController.text = DateFormat('dd/MM/yyyy HH:mm')
            .format(_selectedSpecificDate!);
      }
    }
  }

  Map<String, dynamic> _buildRequestData() {
    // Get the selected mode config
    String scheduleMode = "";
    bool sendNow = false;

    // If have selected mode, get its config
    if (_selectedModeValue != null) {
      final selectedModeConfig = modes.firstWhere(
            (mode) => mode['value'] == _selectedModeValue,
        orElse: () => {"mode": "", "value": "", "isSendNow": "false"},
      );
      scheduleMode = selectedModeConfig['mode'] ?? "";
      sendNow = selectedModeConfig['isSendNow'] == "true";
    }

    Map<String, dynamic> request = {
      "title": _titleController.text.trim(),
      "content": _contentController.text.trim(),
      "typeOfRecipient": _selectedRecipientType,
      "isSendNow": sendNow,
      "schedule": {
        "mode": scheduleMode // Always include schedule with mode from selected mode
      }
    };

    // If send now is true, return with schedule mode only (no additional fields)
    if (sendNow) {
      return request;
    }

    // If no mode selected, return with empty schedule mode
    if (_selectedModeValue == null) {
      return request;
    }

    // Find the selected mode config for additional fields
    final selectedModeConfig = modes.firstWhere(
          (mode) => mode['value'] == _selectedModeValue,
      orElse: () => {"mode": "", "value": "", "isSendNow": "false"},
    );

    final modeType = selectedModeConfig['mode'] ?? '';
    final modeValue = selectedModeConfig['value'];

    // Build schedule with additional fields based on mode type
    Map<String, dynamic> schedule = {
      "mode": modeType
    };

    switch (modeType) {
      case 'once':
      // Check if it's "Gửi một lần (hẹn giờ)" - value = "2"
        if (modeValue == '2' && _selectedSpecificDate != null) {
          schedule["sendAt"] = _selectedSpecificDate!.toUtc().toIso8601String();
        }
        break;

      case 'daily_time':
        if (_selectedTimeOfDay != null) {
          final timeString =
              '${_selectedTimeOfDay!.hour.toString().padLeft(2, '0')}:${_selectedTimeOfDay!.minute.toString().padLeft(2, '0')}';
          schedule["timeOfDay"] = timeString;

          // Add daysOfWeek for weekly mode (value = "4")
          if (modeValue == '4' && _selectedDaysOfWeek.isNotEmpty) {
            schedule["daysOfWeek"] = _selectedDaysOfWeek;
          }
        }
        break;

      case 'interval':
        if (_repeatIntervalMinutes != null && _repeatIntervalMinutes! > 0) {
          schedule["repeatInterval"] = _repeatIntervalMinutes! * 60 * 1000; // Convert to milliseconds
        }
        break;
    }

    request["schedule"] = schedule;
    return request;
  }

  Future<void> _createNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate based on selected mode
    if (_selectedModeValue == null) {
      SnackBarHelper.showError(context, 'Vui lòng chọn hình thức gửi');
      return;
    }

    final selectedModeConfig = modes.firstWhere(
          (mode) => mode['value'] == _selectedModeValue,
    );
    final modeType = selectedModeConfig['mode'];
    final modeValue = selectedModeConfig['value'];
    final isSendNow = selectedModeConfig['isSendNow'] == "true";

    // Validate for scheduled modes (not send now)
    if (!isSendNow) {
      switch (modeType) {
        case 'once':
          if (modeValue == '2') { // Hẹn giờ
            if (_selectedSpecificDate == null) {
              SnackBarHelper.showError(
                  context, 'Vui lòng chọn thời gian gửi cụ thể');
              return;
            }
            if (_selectedSpecificDate!.isBefore(DateTime.now())) {
              SnackBarHelper.showError(context, 'Thời gian gửi phải trong tương lai');
              return;
            }
          }
          break;

        case 'daily_time':
          if (_selectedTimeOfDay == null) {
            SnackBarHelper.showError(context, 'Vui lòng chọn thời gian gửi');
            return;
          }
          if (modeValue == '4' && _selectedDaysOfWeek.isEmpty) { // Lặp theo tuần
            SnackBarHelper.showError(context, 'Vui lòng chọn ít nhất một ngày trong tuần');
            return;
          }
          break;

        case 'interval':
          if (_repeatIntervalMinutes == null || _repeatIntervalMinutes! <= 0) {
            SnackBarHelper.showError(context, 'Vui lòng nhập khoảng thời gian lặp hợp lệ');
            return;
          }
          if (_repeatIntervalMinutes! < 10) {
            SnackBarHelper.showError(context, 'Khoảng thời gian lặp tối thiểu là 10 phút');
            return;
          }
          break;
      }
    }

    if (_selectedRecipientType == null) {
      SnackBarHelper.showError(context, 'Vui lòng chọn đối tượng nhận');
      return;
    }

    final requestData = _buildRequestData();

    // Log request for debugging
    print('Creating notification with data: $requestData');

    try {
      final response = await _notificationService.createNotificationService(requestData);

      if (response['success'] == true) {
        SnackBarHelper.showSuccess(context, 'Tạo thông báo thành công');
        Navigator.pop(context, true); // Return true to refresh list
      } else {
        throw Exception(response['message'] ?? 'Không thể tạo thông báo');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi khi tạo thông báo: $e');
    }
  }

  Widget _buildRecipientTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đối tượng nhận *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: typeOfRecipient.map((type) {
            bool isSelected = _selectedRecipientType == type['value'];
            return ChoiceChip(
              label: Text(type['name']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedRecipientType = selected ? type['value'] : null;
                });
              },
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSendModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình thức gửi *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: modes.map((mode) {
            bool isSelected = _selectedModeValue == mode['value'];

            return FilterChip(
              label: Text(mode['name']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedModeValue = mode['value'];
                    _selectedModeType = mode['mode'];

                    // Reset previous data when switching modes
                    _selectedSpecificDate = null;
                    _selectedTimeOfDay = null;
                    _selectedDaysOfWeek = [];
                    _repeatIntervalMinutes = null;
                    _specificDateTimeController.clear();
                    _repeatIntervalController.clear();
                  } else {
                    _selectedModeValue = null;
                    _selectedModeType = null;
                  }
                });
              },
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleConfig() {
    if (_selectedModeValue == null) {
      return const SizedBox();
    }

    final selectedModeConfig = modes.firstWhere(
          (mode) => mode['value'] == _selectedModeValue,
    );
    final modeType = selectedModeConfig['mode'];
    final modeValue = selectedModeConfig['value'];
    final isSendNow = selectedModeConfig['isSendNow'] == "true";

    // Don't show config for send now mode
    if (isSendNow) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.send, color: Colors.green.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Thông báo sẽ được gửi ngay sau khi tạo',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    switch (modeType) {
      case 'once':
        if (modeValue == '2') { // Hẹn giờ
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thời gian gửi *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _specificDateTimeController.text.isEmpty
                              ? 'Chọn thời gian gửi'
                              : _specificDateTimeController.text,
                          style: TextStyle(
                            color: _specificDateTimeController.text.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thông báo sẽ được gửi một lần vào thời gian đã chọn',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          );
        }
        return const SizedBox();

      case 'daily_time':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời gian gửi *',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedTimeOfDay == null
                            ? 'Chọn giờ gửi'
                            : '${_selectedTimeOfDay!.hour.toString().padLeft(2, '0')}:${_selectedTimeOfDay!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (modeValue == '4') ...[ // Lặp theo tuần
              const Text(
                'Ngày gửi trong tuần *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: daysOfWeekMap.entries.map((entry) {
                  bool isSelected = _selectedDaysOfWeek.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDaysOfWeek.add(entry.key);
                        } else {
                          _selectedDaysOfWeek.remove(entry.key);
                        }
                      });
                    },
                    selectedColor: Colors.blue.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Thông báo sẽ được gửi vào các ngày đã chọn lúc ${_selectedTimeOfDay != null ? '${_selectedTimeOfDay!.hour.toString().padLeft(2, '0')}:${_selectedTimeOfDay!.minute.toString().padLeft(2, '0')}' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ] else ...[
              Text(
                'Thông báo sẽ được gửi vào ${_selectedTimeOfDay != null ? '${_selectedTimeOfDay!.hour.toString().padLeft(2, '0')}:${_selectedTimeOfDay!.minute.toString().padLeft(2, '0')}' : ''} hàng ngày',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        );

      case 'interval':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khoảng thời gian lặp *',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _repeatIntervalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập số phút (tối thiểu 10 phút)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'phút',
                suffixStyle: TextStyle(color: Colors.grey.shade600),
                errorText: _repeatIntervalMinutes != null && _repeatIntervalMinutes! < 10
                    ? 'Khoảng thời gian phải >= 10 phút'
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isNotEmpty) {
                    _repeatIntervalMinutes = int.tryParse(value);
                  } else {
                    _repeatIntervalMinutes = null;
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập khoảng thời gian lặp';
                }
                final minutes = int.tryParse(value);
                if (minutes == null) {
                  return 'Vui lòng nhập số hợp lệ';
                }
                if (minutes < 10) {
                  return 'Khoảng thời gian lặp tối thiểu là 10 phút';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Thông báo sẽ được lặp lại mỗi ${_repeatIntervalMinutes ?? 0} phút',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              '⚠️ Lưu ý: Khoảng thời gian lặp tối thiểu là 10 phút',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 12),
            const Text("Tạo thông báo"),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  hintText: 'Nhập tiêu đề thông báo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Content field
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung *',
                  hintText: 'Nhập nội dung thông báo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập nội dung';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Recipient type selector
              _buildRecipientTypeSelector(),
              const SizedBox(height: 24),

              // Send mode selector
              _buildSendModeSelector(),
              const SizedBox(height: 24),

              // Schedule configuration
              if (_selectedModeValue != null) ...[
                _buildScheduleConfig(),
                const SizedBox(height: 24),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tạo thông báo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}