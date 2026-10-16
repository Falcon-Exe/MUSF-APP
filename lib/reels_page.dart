import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 🟢 Keep Reels state alive

  late final Stream<List<Map<String, dynamic>>> _reelsStream;

  @override
  void initState() {
    super.initState();
    // 🟢 Real-time stream from Supabase committee_reels
    _reelsStream = Supabase.instance.client
        .from('committee_reels')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🟢 Required for KeepAlive
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      // 🟢 Real-time StreamBuilder fetches the photos
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _reelsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading feed: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white54,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No posts yet. Check back later!",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 🟢 Vertical PageView for that "Reels" swiping experience
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];

              String imageUrl = data['image_url'] ?? data['imageUrl'] ?? '';
              String committee = data['committee'] ?? 'Union';
              String caption = data['caption'] ?? '';

              final rawTs = data['timestamp'] ?? data['created_at'];
              String dateStr = '';
              if (rawTs != null) {
                final dt = DateTime.tryParse(rawTs.toString());
                if (dt != null) {
                  dateStr = DateFormat('dd MMM yyyy').format(dt);
                }
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. THE MAIN IMAGE FROM FIREBASE
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white38,
                        size: 50,
                      ),
                    ),
                  ),

                  // 2. GRADIENT OVERLAY (To make text readable over bright photos)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),

                  // 3. RIGHT SIDE BUTTONS (Interaction)
                  Positioned(
                    right: 15,
                    bottom: 100,
                    child: Column(
                      children: [
                        _buildIconButton(Icons.favorite, "Like"),
                        _buildIconButton(Icons.comment, "Comment"),
                        _buildIconButton(Icons.share, "Share"),
                        const SizedBox(height: 20),
                        // Committee Avatar Icon
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blueAccent,
                              width: 2,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.groups_rounded,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. BOTTOM TEXT INFO
                  Positioned(
                    left: 15,
                    bottom: 30,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Committee Name & Date
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blueAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "@$committee",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 2.0,
                                      color: Colors.black,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Caption Text
                        if (caption.isNotEmpty)
                          Text(
                            caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  blurRadius: 2.0,
                                  color: Colors.black,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 35),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
