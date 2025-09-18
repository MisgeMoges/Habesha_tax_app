import 'package:flutter/material.dart';
import '../../../core/utils/ios_scroll_physics.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: getPlatformScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('About Our Church'),
              background: Image.asset(
                'assets/images/church1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Our Faith',
                    'The Ethiopian Orthodox Tewahedo Church is one of the oldest Christian communities in the world, tracing its roots to the apostolic era. Our faith is centered on the Holy Trinity, the teachings of the Bible, and the rich traditions handed down from the early Church Fathers.',
                    Icons.auto_awesome,
                    Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Our Mission',
                    'To glorify God through worship, prayer, and service; to preserve and teach the ancient faith; and to foster love, unity, and compassion among all people.',
                    Icons.flag,
                    Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Our History',
                    "Christianity was introduced to Ethiopia in the 4th century by St. Frumentius (Abba Selama). The Ethiopian Orthodox Church has played a vital role in the nation's spiritual, cultural, and social life for over 1,600 years.",
                    Icons.history_edu,
                    Colors.green,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Our Values',
                    '• Deep reverence for the Holy Trinity\n• Observance of ancient liturgical traditions\n• Fasting, prayer, and charity\n• Respect for elders and community\n• Preservation of Ethiopian Christian heritage',
                    Icons.star,
                    Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Worship & Liturgy',
                    "Our worship is rich in ancient hymns, chants (Zema), and the use of Ge'ez, the classical liturgical language. The Divine Liturgy (Qidase) is celebrated with deep reverence, incense, and processions.",
                    Icons.church,
                    Colors.red,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Leadership',
                    'The Church is shepherded by Patriarchs, Bishops, Priests, and Deacons, with the laity playing a vital role in parish life. Our clergy are dedicated to spiritual guidance, teaching, and service.',
                    Icons.people,
                    Colors.purple,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Unique Traditions',
                    '• Timket (Epiphany) and Meskel (Finding of the True Cross)\n• Fasting seasons and holy days\n• Veneration of saints and angels\n• Iconography and church art\n• Traditional church music and dance',
                    Icons.cake,
                    Colors.teal,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Join Our Community',
                    'We warmly welcome you to worship, learn, and grow with us. Whether you are a lifelong Orthodox Christian or new to the faith, you have a place in our spiritual family.',
                    Icons.group_add,
                    Colors.indigo,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
