import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          // Avatar
          GestureDetector(onTap: onTap, child: _buildAvatar()),
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

  Widget _buildAvatar() {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        gradient: NexoraGradients.primaryButton,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: (request.avatar != null && request.avatar!.isNotEmpty)
            ? Image.network(
                request.avatar!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildAvatarPlaceholder(),
              )
            : _buildAvatarPlaceholder(),
      ),
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
