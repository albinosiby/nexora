import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/nexora_theme.dart';
import '../repositories/connection_service.dart';

class ConnectionUserCard extends StatelessWidget {
  final ConnectionRequest request;
  final List<Widget> actions;
  final VoidCallback? onTap;

  const ConnectionUserCard({
    super.key,
    required this.request,
    required this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: NexoraColors.glassBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: NexoraColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar — fetches live from Firestore
          GestureDetector(onTap: onTap, child: _buildLiveAvatar()),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.name,
                    style: TextStyle(
                      color: NexoraColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    request.major ?? 'Student',
                    style: TextStyle(
                      color: NexoraColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTimeAgo(request.timestamp),
                    style: TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Actions
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            Row(children: actions),
          ],
        ],
      ),
    );
  }

  /// Fetches the latest avatar URL from Firestore in real-time
  Widget _buildLiveAvatar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(request.userId)
          .snapshots(),
      builder: (context, snapshot) {
        String? liveAvatar;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          liveAvatar = data?['avatar'] as String?;
        }
        // Fall back to cached avatar from connection request
        final avatarUrl = (liveAvatar != null && liveAvatar.isNotEmpty)
            ? liveAvatar
            : request.avatar;

        final hasAvatar =
            avatarUrl != null &&
            avatarUrl.isNotEmpty &&
            avatarUrl.startsWith('http');

        return Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            gradient: NexoraGradients.primaryButton,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: hasAvatar
                ? Image.network(
                    avatarUrl,
                    width: 56.w,
                    height: 56.w,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildAvatarPlaceholder();
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        request.name.isNotEmpty ? request.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 22.sp,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
