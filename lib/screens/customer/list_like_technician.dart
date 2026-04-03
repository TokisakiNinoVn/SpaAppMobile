import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/like_service.dart';

class ListLikeTechnicianScreen extends StatefulWidget {
  const ListLikeTechnicianScreen({super.key});

  @override
  State<ListLikeTechnicianScreen> createState() =>
      _ListLikeTechnicianScreenState();
}

class _ListLikeTechnicianScreenState extends State<ListLikeTechnicianScreen> {
  final LikeService _likeService = LikeService();
  final TextEditingController _searchController =
  TextEditingController();

  bool _isLoading = true;

  List<dynamic> _allLikes = [];
  List<dynamic> _filteredLikes = [];

  @override
  void initState() {
    super.initState();
    _loadListLikeTechnician();

    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListLikeTechnician() async {
    try {
      setState(() => _isLoading = true);

      final res = await _likeService.listBaseLikeService();
      final data = res['data'] ?? [];

      setState(() {
        _allLikes = data;
        _filteredLikes = data;
      });
    } catch (e) {
      debugPrint('Load like error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final keyword = _searchController.text.toLowerCase().trim();

    setState(() {
      if (keyword.isEmpty) {
        _filteredLikes = _allLikes;
      } else {
        _filteredLikes = _allLikes.where((item) {
          final name =
          (item['fullName'] ?? '').toString().toLowerCase();
          return name.contains(keyword);
        }).toList();
      }
    });
  }

  Future<void> _deleteLikeTechnician(String techId) async {
    try {
      var response = await _likeService.deleteLikeService(techId);

      setState(() {
        _allLikes.removeWhere((item) => item['_id'] == techId);
        _filteredLikes
            .removeWhere((item) => item['_id'] == techId);
      });

      final String message = response['message'] ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: ColorConfig.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Delete like error: $e');
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm theo tên kỹ thuật viên...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(dynamic tech) {
    return InkWell(
      onTap: () {
        context.push('/technician-detail/${tech['_id']}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xffeeeeee)),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(
                tech['avatar']?['url'] ??
                    'https://via.placeholder.com/150',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tech['fullName'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tech['province'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star,
                    size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  tech['rate']?.toString() ?? '0',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _deleteLikeTechnician(tech['_id']),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                child:
                const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Danh sách yêu thích',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _filteredLikes.isEmpty
                ? const Center(
              child: Text(
                'Không tìm thấy kỹ thuật viên phù hợp.',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _filteredLikes.length,
              itemBuilder: (context, index) {
                return _buildItem(
                    _filteredLikes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
