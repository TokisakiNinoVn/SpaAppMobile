import 'package:flutter/material.dart';
import 'package:spa_app/services/user_service.dart';
// import 'package:spa_app/helper/format_helper.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});
  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final UserService userService = UserService();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  String searchQuery = '';
  String selectedRole = 'ktv';
  String selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final response = await userService.getAllUserService();
    if (response['success']) {
      final allUsers = List<Map<String, dynamic>>.from(response['data']);
      setState(() {
        users = allUsers;
        _applyFilters();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredUsers = users.where((user) {
        final roleMatch = user['roles'] == selectedRole;
        final statusMatch = user['status'] == selectedStatus;
        final searchMatch = user['phone'].toString().contains(searchQuery) ||
            user['fullname'].toString().toLowerCase().contains(searchQuery.toLowerCase());
        return roleMatch && statusMatch && searchMatch;
      }).toList();
    });
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Thông tin chi tiết", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Họ tên: ${user['fullname']}"),
            Text("SĐT: ${user['phone']}"),
            Text("Trạng thái: ${user['status']}"),
            Text("Role: ${user['roles']}"),
            Text("KTV: ${user['technicians'].isNotEmpty ? user['technicians'][0]['fullName'] : 'Không có'}"),
            // Có thể thêm ảnh, địa chỉ, v.v tại đây
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final technicianName = user['technicians'].isNotEmpty ? user['technicians'][0]['fullName'] : 'Không có';
    final avatarUrl = user['technicians'].isNotEmpty && user['technicians'][0]['avatar'] != null
        ? user['technicians'][0]['avatar']['url'] ?? ''
        : '';


    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: avatarUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(user['phone']),
        subtitle: Text("Trạng thái: ${user['status']} | KTV: $technicianName"),
        onTap: () => _showUserDetails(user),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                // TODO: mở màn sửa
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // TODO: xác nhận và xoá
              },
            ),
            IconButton(
              icon: Icon(
                user['isActive'] ? Icons.lock_outline : Icons.lock_open,
                color: Colors.grey,
              ),
              onPressed: () {
                // TODO: khoá/mở khoá tài khoản
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tìm kiếm và lọc
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Ô tìm kiếm
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tìm theo số điện thoại hoặc tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Bộ lọc roles
              DropdownButton<String>(
                value: selectedRole,
                items: ['admin', 'ktv']
                    .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                ))
                    .toList(),
                onChanged: (value) {
                  selectedRole = value!;
                  _applyFilters();
                },
              ),
              const SizedBox(width: 8),
              // Bộ lọc status
              DropdownButton<String>(
                value: selectedStatus,
                items: ['active', 'inactive']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  selectedStatus = value!;
                  _applyFilters();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredUsers.isEmpty
              ? const Center(child: Text('Không tìm thấy người dùng nào.'))
              : ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              return _buildUserItem(filteredUsers[index]);
            },
          ),
        ),
      ],
    );
  }
}
