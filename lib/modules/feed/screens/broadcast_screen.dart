import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../repositories/feed_repo.dart';
import '../model/feed_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../chat/repositories/chat_repository.dart';
import '../../chat/models/chat_model.dart';
import '../../chat/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/feed_providers.dart';

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  // Removed _fabAnimationController since FAB will always be visible.
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  // Removed _isFabVisible since FAB will always be visible.
  // Reactive user profile from AuthRepository
  UserModel? get _currentUser => AuthRepository.instance.currentUserProfile;
  String get _userName => _currentUser?.displayName ?? 'Guest';
  String get _userAvatar => _currentUser?.avatar ?? '';
  String get _userId => _currentUser?.id ?? '';

  List<PostModel> _getFilteredPosts(List<PostModel> posts) {
    if (_searchQuery.isEmpty) return posts;
    return posts.where((post) {
      final content = post.content.toLowerCase();
      final user = post.user.toLowerCase();
      final username = post.username.toLowerCase();
      final hashtags = post.hashtags.join(' ').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return content.contains(query) ||
          user.contains(query) ||
          username.contains(query) ||
          hashtags.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  Future<void> _loadPosts() async {
    // This is now handled by Riverpod's postsStreamProvider
    ref.invalidate(postsStreamProvider);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _createPost() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreatePostSheet(
        userName: _userName,
        userAvatar: _userAvatar,
        onPostCreated: (newPost) async {
          await PostRepository.instance.createPost(newPost);
        },
      ),
    );
  }

  void _toggleLike(PostModel post) {
    PostRepository.instance.toggleLike(post.id, _userId);
    // The stream will handle the UI update automatically
    HapticFeedback.lightImpact();
  }

  void _toggleSave(PostModel post) {
    PostRepository.instance.toggleSave(post.id, _userId);
    // The stream will handle the UI update automatically
    HapticFeedback.lightImpact();
  }

  void _showPostOptions(PostModel post) {
    final isOwnPost = post.userId == _userId || post.displayName == _userName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NexoraColors.midnightPurple.withOpacity(0.98),
              NexoraColors.midnightDark.withOpacity(0.98),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.3),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              if (isOwnPost) ...[
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Post',
                  color: NexoraColors.accentCyan,
                  onTap: () {
                    Navigator.of(context).pop();
                    _editPost(post);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete Post',
                  color: NexoraColors.error,
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmDeletePost(post);
                  },
                ),
              ],
              if (!isOwnPost) ...[
                _buildOptionTile(
                  icon: Icons.person_add_outlined,
                  label: 'Follow ${post.displayName}',
                  color: NexoraColors.primaryPurple,
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'You are now following ${post.displayName}',
                        ),
                        backgroundColor: NexoraColors.success.withOpacity(0.9),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(16.r),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                  },
                ),
                _buildOptionTile(
                  icon: Icons.notifications_off_outlined,
                  label: 'Mute this user',
                  color: NexoraColors.warning,
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "You won't see posts from ${post.displayName}",
                        ),
                        backgroundColor: NexoraColors.warning.withOpacity(0.9),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(16.r),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                  },
                ),
                _buildOptionTile(
                  icon: Icons.report_outlined,
                  label: 'Report Post',
                  color: NexoraColors.error,
                  onTap: () {
                    Navigator.of(context).pop();
                    _reportPost(post);
                  },
                ),
              ],
              _buildOptionTile(
                icon: Icons.copy_outlined,
                label: 'Copy Text',
                color: NexoraColors.textSecondary,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: post.content));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          const Text('Post text copied successfully'),
                        ],
                      ),
                      backgroundColor: NexoraColors.success.withOpacity(0.9),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16.r),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 22.r),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: NexoraColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _editPost(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreatePostSheet(
        userName: _userName,
        userAvatar: _userAvatar,
        initialContent: post.content,
        isEditing: true,
        onPostCreated: (editedPost) async {
          await PostRepository.instance.updatePost(
            post.copyWith(
              content: editedPost.content,
              hashtags: editedPost.hashtags,
            ),
          );
        },
      ),
    );
  }

  void _confirmDeletePost(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GlassContainer(
          borderRadius: 24.r,
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: NexoraColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: NexoraColors.error,
                  size: 48.r,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Delete Post?',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'This action cannot be undone. Your post will be permanently removed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NexoraColors.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: NexoraColors.textMuted,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.error,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await PostRepository.instance.deletePost(post.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.white),
                                SizedBox(width: 8),
                                const Text('Your post has been removed'),
                              ],
                            ),
                            backgroundColor: NexoraColors.error.withOpacity(
                              0.9,
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(16.r),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        );
                      },
                      child: Text('Delete', style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportPost(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GlassContainer(
          borderRadius: 24.r,
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: NexoraColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag_outlined,
                  color: NexoraColors.error,
                  size: 48.r,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Report Post',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              ...[
                'Spam',
                'Harassment',
                'Inappropriate Content',
                'False Information',
              ].map(
                (reason) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Report Submitted: $reason'),
                          backgroundColor: NexoraColors.success.withOpacity(
                            0.9,
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16.r),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: NexoraColors.textPrimary,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: NexoraColors.textMuted,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComments(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommentsSheet(
        post: post,
        userName: _userName,
        userAvatar: _userAvatar,
        onCommentAdded: (comment) async {
          await PostRepository.instance.addComment(post.id, comment);
        },
      ),
    );
  }

  void _openUserProfile(PostModel post) async {
    HapticFeedback.lightImpact();

    // Show loading or just navigate if we assume fast fetch
    final userProfile = await AuthRepository.instance.getUserProfile(
      post.userId,
    );

    if (userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileViewScreen(
            profile: ProfileModel.fromUserData(userProfile),
          ),
        ),
      );
    } else {
      // Fallback to minimal profile if user not found in DB (unlikely)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileViewScreen(
            profile: ProfileModel(
              id: post.userId,
              name: post.user,
              email: '',
              avatar: post.avatar,
            ),
          ),
        ),
      );
    }
  }

  void _openImageViewer(List<String> images, int initialIndex, PostModel post) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          images: images,
          initialIndex: initialIndex,
          post: post,
        ),
      ),
    );
  }

  Future<void> _refreshFeed() async {
    _refreshController.forward();
    await _loadPosts();
    _refreshController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsStreamProvider);

    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Main Content
            postsAsync.when(
              data: (posts) {
                final visiblePosts = _getFilteredPosts(posts);
                return RefreshIndicator(
                  onRefresh: _refreshFeed,
                  color: NexoraColors.primaryPurple,
                  backgroundColor: NexoraColors.midnightDark,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 140.h,
                        floating: true,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: _buildSearchBar(),
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                        title: Text(
                          'Feed',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = NexoraGradients.logoGradient
                                  .createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                  ),
                          ),
                        ),
                      ),
                      if (visiblePosts.isEmpty && _searchQuery.isNotEmpty)
                        SliverFillRemaining(child: _buildEmptySearch())
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final post = visiblePosts[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 20.h),
                                child: TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: Duration(
                                    milliseconds: 500 + (index * 100),
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, double value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 30.h * (1 - value)),
                                        child: _buildPostCard(post),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }, childCount: visiblePosts.length),
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: NexoraColors.primaryPurple,
                ),
              ),
              error: (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: NexoraColors.error,
                      size: 64.r,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error loading feed: $e',
                      style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(postsStreamProvider),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: GestureDetector(
          onTap: _createPost,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: NexoraGradients.primaryButton,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: NexoraColors.primaryPurple.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: NexoraColors.primaryPurple.withOpacity(0.2),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  'Create Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: NexoraColors.glassBackground,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: NexoraColors.primaryPurple.withOpacity(0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: NexoraColors.primaryPurple.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: NexoraColors.primaryPurple, size: 22.r),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 15.sp,
              ),
              decoration: InputDecoration(
                hintText: 'Search posts, users, hashtags...',
                hintStyle: TextStyle(
                  color: NexoraColors.textMuted,
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: NexoraColors.textMuted.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: NexoraColors.textMuted,
                  size: 16.r,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64.r,
                color: NexoraColors.textMuted.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No posts found',
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try searching with different keywords',
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 14.sp),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: NexoraColors.primaryPurple,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http');
  }

  String _getTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (duration.inDays >= 1) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildAvatarPlaceholder(String name, {double size = 20}) {
    String initial = '?';
    if (name.isNotEmpty) {
      String cleanName = name.startsWith('@') ? name.substring(1) : name;
      if (cleanName.isNotEmpty) {
        initial = cleanName[0].toUpperCase();
      }
    }
    return Text(
      initial,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: size.sp,
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return GestureDetector(
      onDoubleTap: () => _toggleLike(post),
      child: GlassContainer(
        borderRadius: 24.r,
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header with Dynamic Profile Loading
            FutureBuilder<UserModel?>(
              future: AuthRepository.instance.getUserProfile(post.userId),
              builder: (context, snapshot) {
                final author = snapshot.data;
                final displayName = (author?.displayName?.isNotEmpty == true)
                    ? author!.displayName
                    : post.displayName;
                final avatar = (author?.avatar?.isNotEmpty == true)
                    ? author!.avatar!
                    : post.avatar;

                return Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openUserProfile(post),
                      child: Stack(
                        children: [
                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              gradient: NexoraGradients.primaryButton,
                              borderRadius: BorderRadius.circular(15.r),
                              boxShadow: [
                                BoxShadow(
                                  color: NexoraColors.primaryPurple.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8.r,
                                  spreadRadius: 1.r,
                                ),
                              ],
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.r),
                                child: _isValidUrl(avatar)
                                    ? Image.network(
                                        avatar,
                                        width: 50.w,
                                        height: 50.w,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildAvatarPlaceholder(
                                                  displayName,
                                                ),
                                      )
                                    : _buildAvatarPlaceholder(displayName),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2.h,
                            right: 2.w,
                            child: Container(
                              width: 12.w,
                              height: 12.w,
                              decoration: BoxDecoration(
                                color: (author?.isOnline ?? false)
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: NexoraColors.midnightDark,
                                  width: 2.w,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openUserProfile(post),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: NexoraColors.textPrimary,
                                      fontSize: 16.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (post.feeling != null) ...[
                                  SizedBox(width: 4.w),
                                  Text(
                                    "is feeling ${post.feeling}",
                                    style: TextStyle(
                                      color: NexoraColors.textSecondary,
                                      fontSize: 12.sp,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Icon(
                                  post.visibility == 'Public'
                                      ? Icons.public
                                      : post.visibility == 'Campus'
                                      ? Icons.school
                                      : Icons.lock,
                                  color: NexoraColors.accentCyan,
                                  size: 12.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  post.visibility,
                                  style: TextStyle(
                                    color: NexoraColors.accentCyan,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '  •  ',
                                  style: TextStyle(
                                    color: NexoraColors.textMuted,
                                    fontSize: 10.sp,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time,
                                  color: NexoraColors.textMuted,
                                  size: 11.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  _getTimeAgo(post.createdAt),
                                  style: TextStyle(
                                    color: NexoraColors.textMuted,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: NexoraColors.glassBackground,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.more_vert),
                        color: NexoraColors.textMuted,
                        iconSize: 20.r,
                        onPressed: () => _showPostOptions(post),
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 16.h),

            // Content with improved styling
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                post.content,
                style: TextStyle(
                  color: NexoraColors.textPrimary,
                  fontSize: 15.sp,
                  height: 1.4,
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Poll Widget
            if (post.poll != null) ...[
              _buildPollWidget(post),
              SizedBox(height: 12.h),
            ],

            // Image Grid
            if (post.images.isNotEmpty) ...[
              _buildImageGrid(post.images, post),
              SizedBox(height: 12.h),
            ],

            SizedBox(height: 12.h),

            // Enhanced Hashtags
            if (post.hashtags.isNotEmpty)
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: post.hashtags.map<Widget>((tag) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchQuery = tag.toString().replaceAll('#', '');
                        _searchController.text = _searchQuery;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: NexoraColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(
                          color: NexoraColors.primaryPurple.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        tag.toString(),
                        style: TextStyle(
                          color: NexoraColors.primaryPurple,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            SizedBox(height: 16.h),

            // Stats row with improved design
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatIcon(
                      post.isLikedBy(_userId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      post.isLikedBy(_userId)
                          ? NexoraColors.romanticPink
                          : NexoraColors.textMuted,
                      post.likes.toString(),
                      () => _toggleLike(post),
                    ),
                    SizedBox(width: 20.w),
                    _buildStatIcon(
                      Icons.chat_bubble_outline,
                      NexoraColors.textMuted,
                      post.comments.toString(),
                      () => _showComments(post),
                    ),
                    SizedBox(width: 20.w),
                    _buildStatIcon(
                      Icons.share_outlined,
                      NexoraColors.textMuted,
                      post.shares.toString(),
                      () => _showShareSheet(post),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _toggleSave(post),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: post.isSavedBy(_userId)
                          ? NexoraColors.accentCyan.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      post.isSavedBy(_userId)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: post.isSavedBy(_userId)
                          ? NexoraColors.accentCyan
                          : NexoraColors.textMuted,
                      size: 22.r,
                    ),
                  ),
                ),
              ],
            ),

            // Comments preview with improved styling
            if (post.commentsList.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Divider(color: NexoraColors.glassBorder, height: 1.h),
              SizedBox(height: 12.h),
              ...List.generate(post.commentsList.length.clamp(0, 2), (
                commentIndex,
              ) {
                final comment = post.commentsList[commentIndex];
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          gradient: NexoraGradients.primaryButton,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _isValidUrl(comment.avatar)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14.w),
                                  child: Image.network(
                                    comment.avatar,
                                    width: 28.w,
                                    height: 28.w,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildAvatarPlaceholder(
                                              comment.displayName,
                                              size: 11,
                                            ),
                                  ),
                                )
                              : _buildAvatarPlaceholder(
                                  comment.displayName,
                                  size: 11,
                                ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: comment.displayName,
                                    style: TextStyle(
                                      color: NexoraColors.textPrimary,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  •  ',
                                    style: TextStyle(
                                      color: NexoraColors.textMuted,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                  TextSpan(
                                    text: comment.time,
                                    style: TextStyle(
                                      color: NexoraColors.textMuted,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              comment.comment,
                              style: TextStyle(
                                color: NexoraColors.textSecondary,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (post.commentsList.length > 2)
                GestureDetector(
                  onTap: () => _showComments(post),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      children: [
                        Text(
                          "View all ${post.comments} comments",
                          style: TextStyle(
                            color: NexoraColors.primaryPurple,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward,
                          color: NexoraColors.primaryPurple,
                          size: 14.r,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(
    IconData icon,
    Color color,
    String count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.r),
          SizedBox(width: 6.w),
          Text(
            count,
            style: TextStyle(
              color: NexoraColors.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollWidget(PostModel post) {
    final poll = post.poll!;
    int totalVotes = poll.votes.fold(0, (sum, v) => sum + v);
    final userVote = poll.userVote(_userId);

    return GlassContainer(
      borderRadius: 16,
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.poll_outlined,
                color: NexoraColors.primaryPurple,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  poll.question,
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...List.generate(poll.options.length, (i) {
            double percentage = totalVotes == 0
                ? 0
                : poll.votes[i] / totalVotes;
            final bool isSelected = userVote == i;

            return GestureDetector(
              onTap: () =>
                  PostRepository.instance.voteInPoll(post.id, i, _userId),
              child: Container(
                margin: EdgeInsets.only(bottom: 8.h),
                child: Stack(
                  children: [
                    Container(
                      height: 38.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: isSelected
                            ? Border.all(
                                color: NexoraColors.primaryPurple,
                                width: 1.w,
                              )
                            : null,
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage > 0 ? percentage : 0.01,
                      child: Container(
                        height: 38.h,
                        decoration: BoxDecoration(
                          gradient: NexoraGradients.primaryButton.withOpacity(
                            isSelected ? 0.5 : 0.2,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    Container(
                      height: 38.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  poll.options[i],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isSelected) ...[
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.check_circle,
                                    color: NexoraColors.primaryPurple,
                                    size: 14.r,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '${(percentage * 100).toInt()}%',
                            style: TextStyle(
                              color: isSelected
                                  ? NexoraColors.textPrimary
                                  : NexoraColors.textMuted,
                              fontSize: 11.sp,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 4.h),
          Text(
            '$totalVotes votes',
            style: TextStyle(color: NexoraColors.textMuted, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> images, PostModel post) {
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(images, 0, post),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              Image.network(
                images[0],
                height: 220.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_out_map, color: Colors.white, size: 16.r),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(images, 0, post),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  images[0],
                  height: 150.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(images, 1, post),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  images[1],
                  height: 150.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          GestureDetector(
            onTap: () => _openImageViewer(images, 0, post),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                images[0],
                height: 150.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImageViewer(images, 1, post),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      images[1],
                      height: 100.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImageViewer(images, 2, post),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          images[2],
                          height: 100.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (images.length > 3)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: Colors.black.withOpacity(0.6),
                            ),
                            child: Center(
                              child: Text(
                                "+${images.length - 3}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  void _showShareSheet(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.3),
          ),
        ),
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: NexoraColors.glassBorder,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Center(
              child: Text(
                "Share Post",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  Icons.send,
                  "Direct",
                  NexoraColors.primaryPurple,
                  () {
                    Navigator.of(context).pop();
                    _shareToDirect(post);
                  },
                ),
                _buildShareOption(
                  Icons.group,
                  "Campus",
                  NexoraColors.romanticPink,
                  () {
                    Navigator.of(context).pop();
                    _shareToCampus(post);
                  },
                ),
                _buildShareOption(
                  Icons.copy,
                  "Copy",
                  NexoraColors.accentCyan,
                  () {
                    Navigator.of(context).pop();
                    _copyToClipboard(post);
                  },
                ),
                _buildShareOption(
                  Icons.more_horiz,
                  "More",
                  NexoraColors.textMuted,
                  () {
                    Navigator.of(context).pop();
                    _shareMore(post);
                  },
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share to',
                style: TextStyle(
                  color: NexoraColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 100.h,
              child: StreamBuilder<List<ChatModel>>(
                stream: ChatRepository.instance.getConversations(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No recent chats',
                        style: TextStyle(
                          color: NexoraColors.textMuted,
                          fontSize: 13.sp,
                        ),
                      ),
                    );
                  }

                  final conversations = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: conversations.length + 1, // +1 for "More"
                    itemBuilder: (context, index) {
                      if (index == conversations.length) {
                        return Padding(
                          padding: EdgeInsets.only(right: 20.w),
                          child: _buildShareOption(
                            Icons.more_horiz,
                            "More",
                            NexoraColors.textMuted,
                            () => _shareMore(post),
                          ),
                        );
                      }

                      final chat = conversations[index];
                      final otherUserId = chat.participantIds.firstWhere(
                        (id) => id != _userId,
                        orElse: () => '',
                      );

                      if (otherUserId.isEmpty) return const SizedBox.shrink();

                      return FutureBuilder<UserModel?>(
                        future: AuthRepository.instance.getUserProfile(
                          otherUserId,
                        ),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData)
                            return const SizedBox.shrink();
                          final user = userSnapshot.data!;
                          return _buildShareContact(user, post);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  void _shareToDirect(PostModel post) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Select a contact to share with'),
        backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
      ),
    );
  }

  void _shareToCampus(PostModel post) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your post is now visible to the campus community'),
        backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
      ),
    );
  }

  void _copyToClipboard(PostModel post) {
    Clipboard.setData(ClipboardData(text: post.content));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post content copied to clipboard'),
        backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
      ),
    );
  }

  void _shareMore(PostModel post) async {
    HapticFeedback.lightImpact();
    await Share.share(
      'Check out this post on Nexora: ${post.content}',
      subject: 'Shared Post from Nexora',
    );
  }

  Widget _buildShareContact(UserModel user, PostModel post) {
    final color = NexoraColors.primaryPurple;
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();
        HapticFeedback.lightImpact();

        // Find or create chat
        String? chatId = await ChatRepository.instance.findExistingChat(
          user.id,
        );
        if (chatId == null) {
          chatId = await ChatRepository.instance.createChat(user.id);
        }

        // Send message
        await ChatRepository.instance.sendMessage(
          type: MessageType.text,
          content: 'Shared a post: ${post.content}',
          chatId: chatId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post shared with ${user.name}'),
            backgroundColor: color.withOpacity(0.9),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 20.w),
        child: Column(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8.r,
                    spreadRadius: 1.r,
                  ),
                ],
              ),
              child: Center(
                child: ClipOval(
                  child: user.avatar != null && user.avatar!.isNotEmpty
                      ? Image.network(
                          user.avatar!,
                          width: 56.w,
                          height: 56.w,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp,
                            ),
                          ),
                        )
                      : Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              user.name,
              style: TextStyle(
                color: NexoraColors.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5.w),
            ),
            child: Icon(icon, color: color, size: 28.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: NexoraColors.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Create Post Sheet (Enhanced)
class CreatePostSheet extends ConsumerStatefulWidget {
  final Function(PostModel)? onPostCreated;
  final String? userName;
  final String? userAvatar;
  final String? initialContent;
  final bool isEditing;

  const CreatePostSheet({
    this.onPostCreated,
    this.userName,
    this.userAvatar,
    this.initialContent,
    this.isEditing = false,
    super.key,
  });

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _postController;
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  String _visibility = 'Public';
  bool _isPosting = false;
  final List<String> _availableHashtags = [
    '#campuslife',
    '#study',
    '#college',
    '#friends',
    '#weekend',
    '#food',
    '#coffee',
    '#library',
    '#exam',
    '#fun',
  ];

  // New features state
  final List<String> _selectedImages = [];
  String? _pollQuestion;
  final List<String> _pollOptions = [];
  String? _selectedFeeling;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _postController = TextEditingController(text: widget.initialContent ?? '');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusNode.requestFocus();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => img.path));
          if (_selectedImages.length > 4) {
            _selectedImages.removeRange(4, _selectedImages.length);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can select up to 4 images')),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick images')));
    }
  }

  void _showPollEditor() {
    final TextEditingController questionController = TextEditingController(
      text: _pollQuestion,
    );
    final List<TextEditingController> optionControllers = _pollOptions.isEmpty
        ? [TextEditingController(), TextEditingController()]
        : _pollOptions.map((opt) => TextEditingController(text: opt)).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: GlassContainer(
              borderRadius: 24.r,
              padding: EdgeInsets.all(20.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Poll',
                    style: NexoraTextStyles.headline2.copyWith(fontSize: 20.sp),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: questionController,
                    decoration: NexoraTheme.glassInputDecoration(
                      'Poll Question',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 12.h),
                  ...List.generate(optionControllers.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: optionControllers[index],
                              decoration: NexoraTheme.glassInputDecoration(
                                'Option ${index + 1}',
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (optionControllers.length > 2)
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  optionControllers.removeAt(index);
                                });
                              },
                              icon: const Icon(
                                Icons.remove_circle,
                                color: NexoraColors.error,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (optionControllers.length < 4)
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          optionControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(
                        Icons.add_circle,
                        color: NexoraColors.accentCyan,
                      ),
                      label: Text(
                        'Add Option',
                        style: TextStyle(color: NexoraColors.accentCyan),
                      ),
                    ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: NexoraColors.textMuted),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexoraColors.primaryPurple,
                        ),
                        onPressed: () {
                          if (questionController.text.trim().isEmpty ||
                              optionControllers.any(
                                (c) => c.text.trim().isEmpty,
                              )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all poll fields'),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _pollQuestion = questionController.text.trim();
                            _pollOptions.clear();
                            _pollOptions.addAll(
                              optionControllers.map((c) => c.text.trim()),
                            );
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFeelingPicker() {
    final Map<String, String> feelings = {
      'Happy': '😊',
      'Excited': '🤩',
      'Blessed': '😇',
      'Loved': '🥰',
      'Cool': '😎',
      'Thinking': '🤔',
      'Tired': '😴',
      'Focusing': '🧠',
      'Celebrating': '🥳',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 30.r,
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: NexoraTextStyles.headline2.copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: feelings.entries
                  .map(
                    (f) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFeeling = '${f.value} ${f.key}';
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFeeling?.contains(f.key) == true
                              ? NexoraColors.primaryPurple.withOpacity(0.3)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          '${f.value} ${f.key}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _addHashtag(String hashtag) {
    final currentText = _postController.text;
    if (!currentText.contains(hashtag)) {
      _postController.text = '$currentText $hashtag';
      _postController.selection = TextSelection.fromPosition(
        TextPosition(offset: _postController.text.length),
      );
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    }
    setState(() {});
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        for (String imagePath in _selectedImages) {
          final file = File(imagePath);
          final ref = FirebaseStorage.instance
              .ref()
              .child('posts')
              .child(
                '${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}',
              );
          await ref.putFile(file);
          imageUrls.add(await ref.getDownloadURL());
        }
      }

      final content = _postController.text.trim();
      final hashtagRegex = RegExp(r'#\w+');
      final hashtags = hashtagRegex
          .allMatches(content)
          .map((m) => m.group(0)!)
          .toList();

      final username = widget.userName?.startsWith('@') == true
          ? widget.userName!
          : '@${(widget.userName ?? 'You').toLowerCase().replaceAll(' ', '.')}';

      final postModel = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: fb.FirebaseAuth.instance.currentUser?.uid ?? '',
        user: widget.userName ?? 'You',
        username: username,
        avatar: widget.userAvatar?.startsWith('http') == true
            ? widget.userAvatar!
            : 'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.userName ?? 'User'}',
        time:
            'Just now', // Keep for compatibility if needed, but we'll use createdAt
        content: content,
        hashtags: hashtags,
        images: imageUrls,
        likes: 0,
        comments: 0,
        shares: 0,
        likedBy: const [],
        savedBy: const [],
        commentsList: <CommentModel>[],
        createdAt: DateTime.now(),
        poll: _pollQuestion != null
            ? PollModel(
                question: _pollQuestion!,
                options: _pollOptions,
                votes: List.filled(_pollOptions.length, 0),
              )
            : null,
        feeling: _selectedFeeling,
        visibility: _visibility,
      );

      if (widget.onPostCreated != null) {
        await widget.onPostCreated!(postModel);
      }

      Navigator.of(context).pop();
      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Post Updated!' : 'Post Created!'),
          backgroundColor: NexoraColors.success.withOpacity(0.9),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        gradient: NexoraGradients.mainBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        border: Border.all(color: NexoraColors.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: NexoraColors.glassBackground,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.close,
                          color: NexoraColors.textMuted,
                          size: 20.r,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.isEditing ? "Edit Post" : "Create Post",
                      style: TextStyle(
                        color: NexoraColors.textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1 + (_animationController.value * 0.1),
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap:
                            (_postController.text.trim().isNotEmpty ||
                                    _pollQuestion != null) &&
                                !_isPosting
                            ? _createPost
                            : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                (_postController.text.trim().isNotEmpty ||
                                    _pollOptions.isNotEmpty)
                                ? NexoraGradients.primaryButton
                                : null,
                            color:
                                (_postController.text.trim().isEmpty &&
                                    _pollOptions.isEmpty)
                                ? NexoraColors.textMuted.withOpacity(0.3)
                                : null,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow:
                                (_postController.text.trim().isNotEmpty ||
                                    _pollOptions.isNotEmpty)
                                ? [
                                    BoxShadow(
                                      color: NexoraColors.primaryPurple
                                          .withOpacity(0.3),
                                      blurRadius: 8.r,
                                      spreadRadius: 1.r,
                                    ),
                                  ]
                                : null,
                          ),
                          child: _isPosting
                              ? SizedBox(
                                  width: 16.r,
                                  height: 16.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.isEditing ? "Save" : "Post",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // User info with enhanced visibility picker
                  Consumer(
                    builder: (context, ref, child) {
                      final profile = ref.watch(currentUserProvider);
                      final displayName =
                          profile?.displayName ?? widget.userName ?? 'You';
                      final avatar = profile?.avatar;

                      String getInitial(String name) {
                        if (name.isEmpty) return 'U';
                        return name.startsWith('@')
                            ? name[1].toUpperCase()
                            : name[0].toUpperCase();
                      }

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            Container(
                              width: 52.w,
                              height: 52.w,
                              decoration: BoxDecoration(
                                gradient: NexoraGradients.primaryButton,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: NexoraColors.primaryPurple
                                        .withOpacity(0.3),
                                    blurRadius: 8.r,
                                    spreadRadius: 1.r,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: ClipOval(
                                  child: (avatar != null && avatar.isNotEmpty)
                                      ? Image.network(
                                          avatar,
                                          width: 52.w,
                                          height: 52.w,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Center(
                                                    child: Text(
                                                      getInitial(displayName),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 22.sp,
                                                      ),
                                                    ),
                                                  ),
                                        )
                                      : Center(
                                          child: Text(
                                            getInitial(displayName),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22.sp,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      color: NexoraColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  GestureDetector(
                                    onTap: _showVisibilityPicker,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: NexoraColors.glassBackground,
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: NexoraColors.primaryPurple
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _visibility == 'Public'
                                                ? Icons.public
                                                : _visibility == 'Campus'
                                                ? Icons.school
                                                : Icons.lock,
                                            size: 14.r,
                                            color: NexoraColors.accentCyan,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            _visibility,
                                            style: TextStyle(
                                              color: NexoraColors.textSecondary,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 16.r,
                                            color: NexoraColors.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: GlassContainer(
                      borderRadius: 20.r,
                      padding: EdgeInsets.all(16.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _postController,
                            focusNode: _focusNode,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              color: NexoraColors.textPrimary,
                              fontSize: 16.sp,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  "What's on your mind? Share with the campus community...",
                              hintStyle: TextStyle(
                                color: NexoraColors.textMuted,
                                fontSize: 15.sp,
                              ),
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Add hashtags to reach more people',
                                style: TextStyle(
                                  color: NexoraColors.textMuted,
                                  fontSize: 11.sp,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _postController.text.length > 500
                                      ? NexoraColors.error.withOpacity(0.1)
                                      : NexoraColors.glassBackground,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  '${_postController.text.length}/500',
                                  style: TextStyle(
                                    color: _postController.text.length > 500
                                        ? NexoraColors.error
                                        : NexoraColors.textMuted,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected Images Preview
                  if (_selectedImages.isNotEmpty)
                    Container(
                      height: 120.h,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 12.w, top: 8.h),
                                width: 100.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  image: DecorationImage(
                                    image: FileImage(
                                      File(_selectedImages[index]),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                    color: NexoraColors.primaryPurple
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 4.w,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: const BoxDecoration(
                                      color: NexoraColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14.r,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  // Poll Preview
                  if (_pollQuestion != null)
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: GlassContainer(
                        borderRadius: 16.r,
                        padding: EdgeInsets.all(12.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.poll_outlined,
                                  color: NexoraColors.primaryPurple,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _pollQuestion!,
                                    style: TextStyle(
                                      color: NexoraColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _pollQuestion = null;
                                      _pollOptions.clear();
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    color: NexoraColors.textMuted,
                                    size: 18.r,
                                  ),
                                ),
                              ],
                            ),
                            ..._pollOptions.map(
                              (opt) => Container(
                                margin: EdgeInsets.only(top: 8.h),
                                padding: EdgeInsets.all(10.r),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    color: NexoraColors.textSecondary,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Quick hashtags with improved design
                  Container(
                    height: 45.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableHashtags.length,
                      itemBuilder: (context, index) {
                        final hashtag = _availableHashtags[index];
                        final isSelected = _postController.text.contains(
                          hashtag,
                        );
                        return GestureDetector(
                          onTap: () => _addHashtag(hashtag),
                          child: Container(
                            margin: EdgeInsets.only(right: 8.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? NexoraGradients.primaryButton
                                  : null,
                              color: isSelected
                                  ? null
                                  : NexoraColors.glassBackground,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected
                                    ? NexoraColors.primaryPurple.withOpacity(
                                        0.3,
                                      )
                                    : NexoraColors.glassBorder,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: NexoraColors.primaryPurple
                                            .withOpacity(0.2),
                                        blurRadius: 8.r,
                                        spreadRadius: 1.r,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              hashtag,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : NexoraColors.textSecondary,
                                fontSize: 13.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Enhanced bottom action bar
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: NexoraColors.midnightDark.withOpacity(0.95),
              border: Border(
                top: BorderSide(
                  color: NexoraColors.primaryPurple.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    Icons.image_outlined,
                    'Photo',
                    NexoraColors.accentCyan,
                  ),

                  _buildActionButton(
                    Icons.poll_outlined,
                    'Poll',
                    NexoraColors.primaryPurple,
                  ),

                  _buildActionButton(
                    Icons.emoji_emotions_outlined,
                    'Feeling',
                    NexoraColors.warning,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (label == 'Photo') {
          _pickImages();
        } else if (label == 'Poll') {
          _showPollEditor();
        } else if (label == 'Feeling') {
          _showFeelingPicker();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('The $label feature is under development'),
              backgroundColor: color.withOpacity(0.9),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22.r),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showVisibilityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: NexoraColors.glassBorder,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Who can see this post?',
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            _buildVisibilityOption(
              Icons.public,
              'Public',
              'Anyone can see this post',
              _visibility == 'Public',
              () {
                setState(() => _visibility = 'Public');
                Navigator.of(context).pop();
              },
            ),
            _buildVisibilityOption(
              Icons.school,
              'Campus Only',
              'Only people from your campus',
              _visibility == 'Campus',
              () {
                setState(() => _visibility = 'Campus');
                Navigator.of(context).pop();
              },
            ),
            _buildVisibilityOption(
              Icons.lock,
              'Private',
              'Only your friends',
              _visibility == 'Friends',
              () {
                setState(() => _visibility = 'Friends');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption(
    IconData icon,
    String label,
    String description,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? NexoraGradients.primaryButton : null,
          color: isSelected ? null : NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? NexoraColors.primaryPurple.withOpacity(0.3)
                : NexoraColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? NexoraColors.primaryPurple.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? NexoraColors.primaryPurple
                    : NexoraColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? NexoraColors.primaryPurple
                          : NexoraColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: NexoraColors.primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

// Comments Sheet (Enhanced)
class CommentsSheet extends StatefulWidget {
  final PostModel post;
  final String userName;
  final String? userAvatar;
  final Function(CommentModel)? onCommentAdded;

  const CommentsSheet({
    required this.post,
    required this.userName,
    this.userAvatar,
    this.onCommentAdded,
    super.key,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommentModel> _comments = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _comments = List<CommentModel>.from(widget.post.commentsList);
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: fb.FirebaseAuth.instance.currentUser?.uid ?? '',
      user: widget.userName,
      username: widget.userName.startsWith('@') ? widget.userName : '',
      avatar: widget.userAvatar ?? '',
      comment: _commentController.text.trim(),
      time: 'Just now',
      createdAt: DateTime.now(),
    );

    // If onCommentAdded is provided, it's expected to handle the actual persistence
    // and potentially update the parent widget's state, which would then rebuild
    // this CommentsSheet with the updated post.commentsList.
    // So, we don't optimistically add to _comments here if a callback is provided.
    if (widget.onCommentAdded != null) {
      widget.onCommentAdded!(newComment);
    } else {
      // If no callback, we update locally.
      _comments.insert(0, newComment);
    }

    setState(() {
      _isSubmitting = false;
    });

    _commentController.clear();
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your comment was posted successfully'),
        backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _toggleCommentLike(CommentModel comment) {
    HapticFeedback.lightImpact();
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    PostRepository.instance.toggleCommentLike(
      widget.post.id,
      comment.id,
      currentUserId,
    );
    // UI updates via stream in parent
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        gradient: NexoraGradients.mainBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        border: Border.all(color: NexoraColors.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Enhanced Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NexoraColors.primaryPurple.withOpacity(0.2),
                            NexoraColors.primaryPurple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: NexoraColors.primaryPurple,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      "Comments (${widget.post.comments})",
                      style: TextStyle(
                        color: NexoraColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: NexoraColors.glassBackground,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.close,
                          color: NexoraColors.textMuted,
                          size: 20.r,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feed')
                  .doc(widget.post.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        NexoraColors.primaryPurple,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return Center(
                    child: Text(
                      'Post no longer available',
                      style: TextStyle(color: NexoraColors.textMuted),
                    ),
                  );
                }

                final post = PostModel.fromFirestore(snapshot.data!);
                final comments = post.commentsList;

                if (comments.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: NexoraColors.glassBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 64.r,
                              color: NexoraColors.textMuted.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              color: NexoraColors.textPrimary,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Be the first to start the conversation!',
                            style: TextStyle(
                              color: NexoraColors.textMuted,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _buildCommentItem(comment),
                    );
                  },
                );
              },
            ),
          ),

          // Enhanced comment input
          Container(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 12.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12.h,
            ),
            decoration: BoxDecoration(
              color: NexoraColors.midnightDark.withOpacity(0.95),
              border: Border(
                top: BorderSide(
                  color: NexoraColors.primaryPurple.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      gradient: NexoraGradients.primaryButton,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: NexoraColors.primaryPurple.withOpacity(0.3),
                          blurRadius: 5.r,
                        ),
                      ],
                    ),
                    child: Center(
                      child:
                          (widget.userAvatar != null &&
                              widget.userAvatar!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                widget.userAvatar!.startsWith('http')
                                    ? widget.userAvatar!
                                    : 'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(widget.userName)}&backgroundColor=transparent&size=200',
                                width: 40.w,
                                height: 40.w,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: NexoraColors.glassBackground,
                        borderRadius: BorderRadius.circular(25.r),
                        border: Border.all(
                          color: NexoraColors.primaryPurple.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          color: NexoraColors.textPrimary,
                          fontSize: 14.sp,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          hintStyle: TextStyle(
                            color: NexoraColors.textMuted.withOpacity(0.8),
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                          suffixIcon: _commentController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _commentController.clear();
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: NexoraColors.textMuted.withOpacity(
                                        0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: NexoraColors.textMuted,
                                      size: 16.r,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _submitComment(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap:
                        _isSubmitting || _commentController.text.trim().isEmpty
                        ? null
                        : _submitComment,
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        gradient: _commentController.text.trim().isEmpty
                            ? LinearGradient(
                                colors: [
                                  NexoraColors.textMuted.withOpacity(0.3),
                                  NexoraColors.textMuted.withOpacity(0.2),
                                ],
                              )
                            : NexoraGradients.primaryButton,
                        shape: BoxShape.circle,
                        boxShadow: _commentController.text.trim().isEmpty
                            ? null
                            : [
                                BoxShadow(
                                  color: NexoraColors.primaryPurple.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8.r,
                                ),
                              ],
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: _commentController.text.trim().isEmpty
                                    ? NexoraColors.textMuted.withOpacity(0.5)
                                    : Colors.white,
                                size: 20.r,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            gradient: NexoraGradients.primaryButton,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.w),
              child: Image.network(
                comment.avatar.startsWith('http')
                    ? comment.avatar
                    : 'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(comment.displayName)}&backgroundColor=transparent&size=200',
                width: 40.w,
                height: 40.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  comment.displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.displayName,
                          style: TextStyle(
                            color: NexoraColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          comment.time,
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      comment.comment,
                      style: TextStyle(
                        color: NexoraColors.textSecondary,
                        fontSize: 14.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleCommentLike(comment),
                      child: Row(
                        children: [
                          Icon(
                            comment.likedBy.contains(
                                  fb.FirebaseAuth.instance.currentUser?.uid,
                                )
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14.r,
                            color:
                                comment.likedBy.contains(
                                  fb.FirebaseAuth.instance.currentUser?.uid,
                                )
                                ? NexoraColors.romanticPink
                                : NexoraColors.textMuted,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            comment.likes > 0
                                ? '${comment.likes} Like${comment.likes > 1 ? 's' : ''}'
                                : 'Like',
                            style: TextStyle(
                              color:
                                  comment.likedBy.contains(
                                    fb.FirebaseAuth.instance.currentUser?.uid,
                                  )
                                  ? NexoraColors.romanticPink
                                  : NexoraColors.textMuted,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    GestureDetector(
                      onTap: () {
                        _focusNode.requestFocus();
                        _commentController.text = '${comment.displayName} ';
                        _commentController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: _commentController.text.length),
                        );
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: NexoraColors.textMuted,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Image Viewer Screen (Enhanced)
class ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final PostModel post;

  const ImageViewerScreen({
    required this.images,
    required this.post,
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  double _scale = 1.0;
  double _previousScale = 1.0;
  late AnimationController _likeAnimationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _doubleTapLike() {
    PostRepository.instance.likePost(
      widget.post.id,
      ChatRepository.instance.currentUserId!,
    );
    _likeAnimationController.forward().then(
      (_) => _likeAnimationController.reverse(),
    );
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, color: Colors.white, size: 22.r),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.more_vert, color: Colors.white, size: 22.r),
            ),
            onPressed: () => _showImageOptions(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image PageView with double tap like
          GestureDetector(
            onDoubleTap: _doubleTapLike,
            onScaleStart: (details) {
              _previousScale = _scale;
            },
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
              });
            },
            onScaleEnd: (details) {
              if (_scale < 1.2) {
                setState(() {
                  _scale = 1.0;
                });
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _scale = 1.0;
                });
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Transform.scale(
                    scale: _scale,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation(
                              NexoraColors.primaryPurple,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: NexoraColors.glassBackground,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: NexoraColors.textMuted,
                              size: 64.r,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Double tap like animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _likeAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _likeAnimationController.value,
                  child: Transform.scale(
                    scale: 0.5 + (_likeAnimationController.value * 1.0),
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Icon(
                          Icons.favorite,
                          color: NexoraColors.romanticPink.withOpacity(0.8),
                          size: 100.r * (1 + _likeAnimationController.value),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Enhanced page indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: 120.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: _currentIndex == index ? 30.w : 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      gradient: _currentIndex == index
                          ? const LinearGradient(
                              colors: [
                                NexoraColors.primaryPurple,
                                NexoraColors.romanticPink,
                              ],
                            )
                          : null,
                      color: _currentIndex == index
                          ? null
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: _currentIndex == index
                          ? [
                              BoxShadow(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.5,
                                ),
                                blurRadius: 8.r,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

          // Enhanced image counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 70.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: NexoraColors.primaryPurple.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Enhanced bottom actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(
                      Icons.download_outlined,
                      'Save',
                      onTap: () {
                        PostRepository.instance.toggleSave(
                          widget.post.id,
                          ChatRepository.instance.currentUserId!,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Post saved successfully'),
                            backgroundColor: NexoraColors.success.withOpacity(
                              0.9,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildBottomAction(
                      Icons.share_outlined,
                      'Share',
                      onTap: () {
                        // Implement sharing logic
                        Clipboard.setData(
                          ClipboardData(text: widget.images[_currentIndex]),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Link copied to clipboard'),
                            backgroundColor: NexoraColors.primaryPurple
                                .withOpacity(0.9),
                          ),
                        );
                      },
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('feed')
                          .doc(widget.post.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final isLiked =
                            snapshot.hasData &&
                            ((snapshot.data!.data()
                                        as Map<String, dynamic>)['likedBy'] ??
                                    [])
                                .contains(
                                  ChatRepository.instance.currentUserId!,
                                );
                        return _buildBottomAction(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          'Like',
                          color: isLiked ? NexoraColors.romanticPink : null,
                          onTap: () {
                            PostRepository.instance.toggleLike(
                              widget.post.id,
                              ChatRepository.instance.currentUserId!,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 24.r),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: NexoraColors.glassBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              _buildOptionItem(
                Icons.download_outlined,
                'Save to device',
                NexoraColors.accentCyan,
                () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Image saved to your device'),
                      backgroundColor: NexoraColors.success.withOpacity(0.9),
                    ),
                  );
                },
              ),
              _buildOptionItem(
                Icons.share_outlined,
                'Share image',
                NexoraColors.primaryPurple,
                () {
                  Navigator.of(context).pop();
                },
              ),
              _buildOptionItem(
                Icons.copy_outlined,
                'Copy image link',
                NexoraColors.romanticPink,
                () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Image link copied to clipboard'),
                      backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
                    ),
                  );
                },
              ),
              _buildOptionItem(
                Icons.flag_outlined,
                'Report image',
                NexoraColors.error,
                () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: color, size: 22.r),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: NexoraColors.textPrimary,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
