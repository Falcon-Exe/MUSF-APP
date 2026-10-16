// lib/features/home/presentation/widgets/glass_leader_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GlassLeaderCard extends StatelessWidget {
  final String name;
  final String role;
  final Color color;
  final IconData icon;
  final String? imageUrl;
  final String? backgroundImageUrl;
  final String? description;

  const GlassLeaderCard({
    super.key,
    required this.name,
    required this.role,
    required this.color,
    required this.icon,
    this.imageUrl,
    this.backgroundImageUrl,
    this.description,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get _hasBackgroundImage =>
      backgroundImageUrl != null && backgroundImageUrl!.trim().isNotEmpty;

  String get _description => description?.trim().isNotEmpty == true
      ? description!.trim()
      : "As a core member of the Union Leadership team, they are dedicated to enhancing student welfare, organizing key events, and bridging the gap between students and administration.";

  void _showLeaderProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: _leaderAvatar(46),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 0,
                  ),
                  child: Text(
                    "Close Profile",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBackground = _hasBackgroundImage;

    return GestureDetector(
      onTap: () => _showLeaderProfile(context),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 18, top: 10, bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              image: hasBackground
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                        backgroundImageUrl!.trim(),
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: LinearGradient(
                colors: [
                  hasBackground
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.95),
                  hasBackground
                      ? color.withValues(alpha: 0.72)
                      : color.withValues(alpha: 0.18),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: _leaderAvatar(38),
                ),
                const SizedBox(height: 12),
                Icon(icon, color: color.withValues(alpha: 0.7), size: 28),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: hasBackground
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _leaderAvatar(double radius) {
    if (!_hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          _initials(name),
          style: TextStyle(
            color: color,
            fontSize: radius * 0.42,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!.trim(),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: color.withValues(alpha: 0.12),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            _initials(name),
            style: TextStyle(
              color: color,
              fontSize: radius * 0.42,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}
