import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';

class PromoCard extends StatefulWidget {
  final String image;
  final String title;
  final String subtitle;
  final String? oldPrice;
  final String newPrice;
  final String discount;
  final String expiresAt;
  final bool showCountdown;
  final VoidCallback? onTap;

  const PromoCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    this.oldPrice,
    required this.newPrice,
    required this.discount,
    required this.expiresAt,
    this.showCountdown = false,
    this.onTap,
  });

  @override
  State<PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<PromoCard> {
  late Timer _timer;
  Duration remaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    _updateRemaining();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final expireTime = DateTime.parse(widget.expiresAt);
    final diff = expireTime.difference(DateTime.now());

    if (mounted) {
      setState(() {
        remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  String _switchFormat(String typeTime) {
    switch (typeTime) {
      case "Ngày":
        return "D";
      case "Giờ":
        return "H";
      case "Phút":
        return "M";
      case "Giây":
        return "S";
      default:
        return "";
    }
  }
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xC7FFFFFF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],

      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0, left: 0, top: 0, right: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(),
                    const SizedBox(width: 10),
                    Expanded(child: _buildContent()),
                  ],
                ),

                const SizedBox(height: 0),

                if (widget.showCountdown)
                  _buildCountdownFancy(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownFancy() {
    if (remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_off_rounded,
              color: Colors.red.shade600,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              "Ưu đãi đã kết thúc",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final days = remaining.inDays;
    final hours =
    (remaining.inHours % 24).toString().padLeft(2, '0');
    final minutes =
    (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
    (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(
              Icons.access_time_filled_rounded,
              size: 15,
              color: ColorConfig.primary,
            ),

            const SizedBox(width: 6),

            Text(
              "Kết thúc sau",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 10),

            _timeBox(days.toString(), "Ngày"),
            _dot(),
            _timeBox(hours, "Giờ"),
            _dot(),
            _timeBox(minutes, "Phút"),
            _dot(),
            _timeBox(seconds, "Giây"),
          ],
        ),
      ),
    );
  }

  Widget _timeBox(String value, String label) {
    return Column(
      children: [
        Container(
          width: 30,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: ColorConfig.primary,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
           "${value}${_switchFormat(label)}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ":",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: ColorConfig.primary,
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Image.network(
            widget.image,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: ColorConfig.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.discount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),

        Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          widget.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.oldPrice != null)
                    Text(
                      widget.oldPrice!,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                  const SizedBox(height: 2),

                  Text(
                    widget.newPrice,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      ColorConfig.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConfig.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.flash_on_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 2),
                    Text(
                      "Đặt ngay",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),

          ],
        ),
      ],
    );
  }
}