import 'package:flutter/material.dart';

import 'package:spa_app/screens/admin/widgets/city_detail_screen.dart';

class ListCity extends StatelessWidget {
  const ListCity({super.key});

  @override
  Widget build(BuildContext context) {
    final cities = [
      {
        "id": 1,
        'name': 'Hà Nội',
        'value': 'Hà Nội',
        'image': 'lib/assets/images/ha_noi.jpg',
      },
      {
        "id": 2,
        'name': 'Hải Phòng',
        'value': 'Hải Phòng',
        'image': 'lib/assets/images/hai_phong.jpg',
      },
      {
        "id": 3,
        'name': 'Đà Nẵng',
        'value': 'Đà Nẵng',
        'image': 'lib/assets/images/da_nang.jpg',
      },
      {
        "id": 4,
        'name': 'Thành phố Hồ Chí Minh',
        'value': 'TP. Hồ Chí Minh',
        'image': 'lib/assets/images/tphcm.jpg',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Chọn KTV các khu vực chính',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final city = cities[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CityDetailScreen(
                          cityName: city['name'] as String,
                          cityId: index + 1,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 150,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            city['image'] as String,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black26,
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Text(
                            city['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
