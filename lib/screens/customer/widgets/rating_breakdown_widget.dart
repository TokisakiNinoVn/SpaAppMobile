import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/rate_service.dart';

class RatingBreakdownWidget extends StatefulWidget {
  final String technicianId;

  const RatingBreakdownWidget({
    super.key,
    required this.technicianId,
  });

  @override
  State<RatingBreakdownWidget> createState() =>
      _RatingBreakdownWidgetState();
}

class _RatingBreakdownWidgetState
    extends State<RatingBreakdownWidget> {
  final RateService _rateService = RateService();

  bool _isLoading = true;

  double averageRating = 0.0;
  int totalReviews = 0;

  List<dynamic> reviews = [];
  List<dynamic> filteredReviews = [];

  int selectedRatingFilter = 0;

  Map<int, int> ratingCounts = {
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0,
  };

  static const String defaultAvatar =
      "https://i.pinimg.com/736x/20/ef/6b/20ef6b554ea249790281e6677abc4160.jpg";

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      final response = await _rateService
          .getByTechnicianId(widget.technicianId);

      if (response["success"] == true) {
        final List data = response["data"] ?? [];

        final Map<int, int> counts = {
          5: 0,
          4: 0,
          3: 0,
          2: 0,
          1: 0,
        };

        for (final item in data) {
          final int score = item["score"] ?? 0;

          if (counts.containsKey(score)) {
            counts[score] = counts[score]! + 1;
          }
        }

        setState(() {
          averageRating =
              (response["averageScore"] ?? 0).toDouble();

          totalReviews = response["total"] ?? 0;

          ratingCounts = counts;

          reviews = data;
          filteredReviews = data;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Rating error: $e");

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterReviews(int rating) {
    setState(() {
      selectedRatingFilter = rating;

      if (rating == 0) {
        filteredReviews = reviews;
      } else {
        filteredReviews = reviews.where((item) {
          return item["score"] == rating;
        }).toList();
      }
    });
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return "Khách hàng";
    }

    if (phone.length <= 4) {
      return phone;
    }

    return "${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}";
  }

  String _formatDate(dynamic createdAt) {
    try {
      final date = createdAt != null
          ? DateTime.parse(createdAt.toString())
          : DateTime.now();

      return DateFormat("dd/MM/yyyy HH:mm").format(date);
    } catch (_) {
      return DateFormat("dd/MM/yyyy HH:mm")
          .format(DateTime.now());
    }
  }

  Widget _buildStarRow(double rating, {double size = 18}) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : (index < rating
              ? Icons.star_half
              : Icons.star_border),
          size: size,
          color: ColorConfig.yellow,
        );
      }),
    );
  }

  Widget _buildProgressItem(int starLevel) {
    final count = ratingCounts[starLevel] ?? 0;

    final percent =
    totalReviews > 0 ? count / totalReviews : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Text(
                  "$starLevel",
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    ColorConfig.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.star,
                  size: 14,
                  color: ColorConfig.yellow,
                ),
              ],
            ),
          ),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey.shade200,
                color: ColorConfig.primary,
                minHeight: 6,
              ),
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: 35,
            child: Text(
              "$count",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                ColorConfig.black.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(dynamic review) {
    final customer = review["customerId"];

    final String phone =
    _maskPhone(customer?["phone"]);

    final String avatar =
    customer?["avatar"] != null
        ? customer["avatar"]
        : defaultAvatar;

    final double score =
    (review["score"] ?? 0).toDouble();

    final String comment =
        review["comment"] ?? "";

    final String createdAt =
    _formatDate(review["createdAt"]);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(avatar),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.black,
                      ),
                    ),

                    const SizedBox(height: 4),

                    _buildStarRow(score, size: 16),
                  ],
                ),
              ),

              Text(
                createdAt,
                style: TextStyle(
                  fontSize: 11,
                  color:
                  ColorConfig.black.withOpacity(0.5),
                ),
              ),
            ],
          ),

          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                comment,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                  ColorConfig.black.withOpacity(0.85),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedRatingFilter,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: TextStyle(
            color: ColorConfig.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: [
            DropdownMenuItem(
              value: 0,
              child: Text(
                "Tất cả ($totalReviews)",
              ),
            ),

            ...List.generate(5, (index) {
              final star = 5 - index;
              final count = ratingCounts[star] ?? 0;

              return DropdownMenuItem(
                value: star,
                child: Row(
                  children: [
                    Text("$star sao"),

                    const SizedBox(width: 6),

                    Icon(
                      Icons.star,
                      size: 16,
                      color: ColorConfig.yellow,
                    ),

                    const SizedBox(width: 6),

                    Text("($count)"),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) {
            if (value != null) {
              _filterReviews(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            Text(
              "Không có đánh giá phù hợp",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            "Đánh giá",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConfig.black,
            ),
          ),

          const SizedBox(height: 16),

          /// HEADER
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: ColorConfig.black,
                ),
              ),

              const SizedBox(width: 16),

              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _buildStarRow(averageRating),

                  const SizedBox(height: 4),

                  Text(
                    "$totalReviews đánh giá",
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorConfig.black
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// BREAKDOWN
          Column(
            children: List.generate(
              5,
                  (index) =>
                  _buildProgressItem(5 - index),
            ),
          ),

          const SizedBox(height: 20),

          Divider(color: Colors.grey.shade200),

          const SizedBox(height: 10),

          /// REVIEW LIST
          // ...reviews.map(_buildReviewItem),
          /// FILTER HEADER
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Danh sách đánh giá",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorConfig.black,
                ),
              ),

              _buildFilterDropdown(),
            ],
          ),

          const SizedBox(height: 14),

          /// REVIEW LIST
          if (filteredReviews.isEmpty)
            _buildEmptyReviews()
          else
            ...filteredReviews.map(_buildReviewItem),
        ],
      ),
    );
  }
}