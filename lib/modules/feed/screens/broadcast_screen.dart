import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/models/user_model.dart';
import '../repositories/feed_repo.dart';
import '../model/feed_model.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  // Removed _fabAnimationController since FAB will always be visible.
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  bool _isLoading = false;
  // Removed _isFabVisible since FAB will always be visible.
  // Reactive user profile from AuthRepository
  UserModel? get _currentUser => AuthRepository.instance.currentUserProfile;
  String get _userName => _currentUser?.name ?? 'Guest';
  String get _userAvatar => _currentUser?.avatar ?? '';
  String get _userId => _currentUser?.id ?? '';

  List<PostModel> _allPosts = [];

  List<PostModel> get filteredPosts {
    if (_searchQuery.isEmpty) return _allPosts;
    return _allPosts.where((post) {
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
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final posts = await PostRepository.instance.getPosts();
    setState(() {
      _allPosts = posts;
      _isLoading = false;
    });
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
          final createdPost = await PostRepository.instance.createPost(newPost);
          setState(() {
            _allPosts.insert(0, createdPost);
          });
        },
      ),
    );
  }

  void _toggleLike(int index) async {
    HapticFeedback.lightImpact();
    final post = filteredPosts[index];
    final actualIndex = _allPosts.indexWhere((p) => p.id == post.id);
    if (actualIndex == -1) return;

    // Optimistic update
    setState(() {
      final wasLiked = post.liked;
      _allPosts[actualIndex] = post.copyWith(
        liked: !wasLiked,
        likes: wasLiked ? post.likes - 1 : post.likes + 1,
      );
    });

    try {
      final updatedPost = await PostRepository.instance.toggleLike(
        post.id,
        _userId,
      );
      setState(() {
        _allPosts[actualIndex] = updatedPost;
      });
    } catch (e) {
      // Revert on error
      setState(() {
        _allPosts[actualIndex] = post;
      });
      Get.snackbar('Error', 'Failed to update like');
    }
  }

  void _toggleSave(int index) async {
    HapticFeedback.lightImpact();
    final post = filteredPosts[index];
    final actualIndex = _allPosts.indexWhere((p) => p.id == post.id);
    if (actualIndex == -1) return;

    // Optimistic update
    setState(() {
      _allPosts[actualIndex] = post.copyWith(saved: !post.saved);
    });

    try {
      final updatedPost = await PostRepository.instance.toggleSave(
        post.id,
        _userId,
      );
      setState(() {
        _allPosts[actualIndex] = updatedPost;
      });

      final isSaved = updatedPost.saved;
      Get.snackbar(
        isSaved ? 'Saved to collection' : 'Removed from collection',
        isSaved ? 'Post saved successfully' : 'Post removed successfully',
        backgroundColor:
            (isSaved ? NexoraColors.accentCyan : NexoraColors.textMuted)
                .withOpacity(0.95),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
        icon: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: Colors.white,
        ),
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _allPosts[actualIndex] = post;
      });
      Get.snackbar('Error', 'Failed to save post');
    }
  }

  void _showPostOptions(PostModel post, int index) {
    final isOwnPost = post.userId == _userId || post.user == _userName;

    Get.bottomSheet(
      Container(
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
                    Get.back();
                    _editPost(post, index);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete Post',
                  color: NexoraColors.error,
                  onTap: () {
                    Get.back();
                    _confirmDeletePost(index);
                  },
                ),
              ],
              if (!isOwnPost) ...[
                _buildOptionTile(
                  icon: Icons.person_add_outlined,
                  label: 'Follow ${post.user}',
                  color: NexoraColors.primaryPurple,
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Following',
                      'You are now following ${post.user}',
                      backgroundColor: NexoraColors.success.withOpacity(0.9),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                      margin: EdgeInsets.all(16.r),
                      borderRadius: 12.r,
                    );
                  },
                ),
                _buildOptionTile(
                  icon: Icons.notifications_off_outlined,
                  label: 'Mute this user',
                  color: NexoraColors.warning,
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Muted',
                      'You won\'t see posts from ${post.user}',
                      backgroundColor: NexoraColors.warning.withOpacity(0.9),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                      margin: EdgeInsets.all(16.r),
                      borderRadius: 12.r,
                    );
                  },
                ),
                _buildOptionTile(
                  icon: Icons.report_outlined,
                  label: 'Report Post',
                  color: NexoraColors.error,
                  onTap: () {
                    Get.back();
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
                  Get.back();
                  Get.snackbar(
                    'Copied to Clipboard',
                    'Post text copied successfully',
                    backgroundColor: NexoraColors.success.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    margin: EdgeInsets.all(16.r),
                    borderRadius: 12.r,
                    icon: const Icon(Icons.check, color: Colors.white),
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

  void _editPost(PostModel post, int index) {
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
          final actualIndex = _allPosts.indexWhere((p) => p.id == post.id);
          if (actualIndex == -1) return;

          final updatedPost = await PostRepository.instance.updatePost(
            post.copyWith(
              content: editedPost.content,
              hashtags: editedPost.hashtags,
            ),
          );

          setState(() {
            _allPosts[actualIndex] = updatedPost;
          });
        },
      ),
    );
  }

  void _confirmDeletePost(int index) {
    final post = filteredPosts[index];

    Get.dialog(
      AlertDialog(
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
                      onPressed: () => Get.back(),
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
                        Get.back();
                        await PostRepository.instance.deletePost(post.id);
                        setState(() {
                          _allPosts.removeWhere((p) => p.id == post.id);
                        });
                        Get.snackbar(
                          'Post Deleted',
                          'Your post has been removed',
                          backgroundColor: NexoraColors.error.withOpacity(0.9),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          margin: EdgeInsets.all(16.r),
                          borderRadius: 12.r,
                          icon: const Icon(Icons.delete, color: Colors.white),
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
    Get.dialog(
      AlertDialog(
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
                      Get.back();
                      Get.snackbar(
                        'Report Submitted',
                        'Thank you for helping keep our community safe',
                        backgroundColor: NexoraColors.success.withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                        margin: EdgeInsets.all(16.r),
                        borderRadius: 12.r,
                        duration: const Duration(seconds: 2),
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
                onPressed: () => Get.back(),
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
        onCommentAdded: (commentText) async {
          final comment = CommentModel(
            id: '',
            userId: _userId,
            user: _userName,
            comment: commentText
                .comment, // Assuming commentText is a CommentModel from UI
            time: 'Just now',
            createdAt: DateTime.now(),
          );

          final addedComment = await PostRepository.instance.addComment(
            post.id,
            comment,
          );

          setState(() {
            final postIndex = _allPosts.indexWhere((p) => p.id == post.id);
            if (postIndex != -1) {
              final updatedComments = List<CommentModel>.from(
                _allPosts[postIndex].commentsList,
              )..add(addedComment);
              _allPosts[postIndex] = _allPosts[postIndex].copyWith(
                commentsList: updatedComments,
                comments: _allPosts[postIndex].comments + 1,
              );
            }
          });
        },
      ),
    );
  }

  void _openUserProfile(PostModel post) {
    HapticFeedback.lightImpact();
    Get.to(
      () => ProfileViewScreen(
        profile: ProfileModel(
          id: post.id,
          name: post.user,
          email: '${post.user.toLowerCase().replaceAll(' ', '.')}@example.com',
          avatar: post.avatar,
          bio: 'Campus community member 💜',
          year: '3rd Year',
          major: 'Computer Science',
          interests: const ['Coding', 'Music', 'Gaming'],
          isOnline: true,
          spotifyTrackName: 'Espresso',
          spotifyArtist: 'Sabrina Carpenter',
        ),
      ),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _openImageViewer(List<String> images, int initialIndex) {
    HapticFeedback.lightImpact();
    Get.to(
      () => ImageViewerScreen(images: images, initialIndex: initialIndex),
      transition: Transition.zoom,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _refreshFeed() async {
    _refreshController.forward();
    await _loadPosts();
    _refreshController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshFeed,
            color: NexoraColors.primaryPurple,
            backgroundColor: NexoraColors.midnightPurple,
            displacement: 40.h,
            edgeOffset: 20.h,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Enhanced App Bar
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          NexoraColors.midnightDark.withOpacity(0.9),
                          NexoraColors.midnightDark.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  title: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        NexoraColors.primaryPurple,
                        NexoraColors.romanticPink,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Nexora',
                      style: NexoraTextStyles.headline1.copyWith(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.w,
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    // height must account for vertical padding (8 top + 16 bottom)
                    // plus the 50px search bar, so total 74 to avoid overflow.
                    preferredSize: Size.fromHeight(74.h),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                      child: _buildSearchBar(),
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 8.h)),

                // Trending Stories Section
                SliverToBoxAdapter(child: SizedBox(height: 8.h)),

                // Feed Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                NexoraColors.primaryPurple.withOpacity(0.3),
                                NexoraColors.primaryPurple.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            color: NexoraColors.primaryPurple,
                            size: 18.r,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Latest Updates',
                          style: TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredPosts.length} posts',
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                // Feed
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _refreshController,
                    builder: (context, _) => _buildFeed(),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 80.h)),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createPost,
          backgroundColor: NexoraColors.primaryPurple,
          elevation: 8.r,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Create Post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

  Widget _buildFeed() {
    final displayPosts = filteredPosts;

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.r),
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation(
              NexoraColors.primaryPurple,
            ),
          ),
        ),
      );
    }

    if (displayPosts.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearch();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: displayPosts.length,
      itemBuilder: (context, index) {
        final post = displayPosts[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30.h * (1 - value)),
                  child: _buildPostCard(post, index),
                ),
              );
            },
          ),
        );
      },
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

  Widget _buildPostCard(PostModel post, int index) {
    return GestureDetector(
      onDoubleTap: () => _toggleLike(index),
      child: GlassContainer(
        borderRadius: 24.r,
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header
            Row(
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
                          child: Text(
                            post.avatar.isNotEmpty ? post.avatar : post.user[0],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp,
                            ),
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
                            color: Colors.green,
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
                            Text(
                              post.user.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: NexoraColors.textPrimary,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.15,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                post.username.toString(),
                                style: TextStyle(
                                  color: NexoraColors.primaryPurple,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: NexoraColors.textMuted,
                              size: 12.r,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              post.time.toString(),
                              style: TextStyle(
                                color: NexoraColors.textMuted,
                                fontSize: 12.sp,
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
                    onPressed: () => _showPostOptions(post, index),
                  ),
                ),
              ],
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

            // Images
            if (post.images.isNotEmpty) _buildImageGrid(post.images),

            SizedBox(height: 16.h),

            // Stats row with improved design
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatIcon(
                      post.liked == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      post.liked == true
                          ? NexoraColors.romanticPink
                          : NexoraColors.textMuted,
                      post.likes.toString(),
                      () => _toggleLike(index),
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
                  onTap: () => _toggleSave(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: post.saved == true
                          ? NexoraColors.accentCyan.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      post.saved == true
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: post.saved == true
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
                          child: Text(
                            comment.user[0],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
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
                                    text: comment.user,
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

  Widget _buildImageGrid(List<String> images) {
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(images, 0),
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
              onTap: () => _openImageViewer(images, 0),
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
              onTap: () => _openImageViewer(images, 1),
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
            onTap: () => _openImageViewer(images, 0),
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
                  onTap: () => _openImageViewer(images, 1),
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
                  onTap: () => _openImageViewer(images, 2),
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
                    Get.back();
                    _shareToDirect(post);
                  },
                ),
                _buildShareOption(
                  Icons.group,
                  "Campus",
                  NexoraColors.romanticPink,
                  () {
                    Get.back();
                    _shareToCampus(post);
                  },
                ),
                _buildShareOption(
                  Icons.copy,
                  "Copy",
                  NexoraColors.accentCyan,
                  () {
                    Get.back();
                    _copyToClipboard(post);
                  },
                ),
                _buildShareOption(
                  Icons.more_horiz,
                  "More",
                  NexoraColors.textMuted,
                  () {
                    Get.back();
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
              height: 80.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildShareContact('Sarah', NexoraColors.romanticPink, post),
                  _buildShareContact('Mike', NexoraColors.primaryPurple, post),
                  _buildShareContact('Emma', NexoraColors.accentCyan, post),
                  _buildShareContact(
                    'Alex',
                    NexoraColors.primaryPurple.withOpacity(0.6),
                    post,
                  ),
                  _buildShareContact(
                    'Jordan',
                    NexoraColors.primaryPurple,
                    post,
                  ),
                ],
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
    Get.snackbar(
      'Share',
      'Select a contact to share with',
      backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
    );
  }

  void _shareToCampus(PostModel post) {
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Shared to Campus!',
      'Your post is now visible to the campus community',
      backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
    );
  }

  void _copyToClipboard(PostModel post) {
    Clipboard.setData(ClipboardData(text: post.content));
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Copied!',
      'Post content copied to clipboard',
      backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
    );
  }

  void _shareMore(PostModel post) {
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Share',
      'More sharing options coming soon!',
      backgroundColor: NexoraColors.textMuted.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
    );
  }

  Widget _buildShareContact(String name, Color color, PostModel post) {
    return GestureDetector(
      onTap: () {
        Get.back();
        HapticFeedback.lightImpact();
        Get.snackbar(
          'Shared!',
          'Post shared with $name',
          backgroundColor: color.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          margin: EdgeInsets.all(16.r),
          borderRadius: 12.r,
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
                child: Text(
                  name[0],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              name,
              style: TextStyle(
                color: NexoraColors.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
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
class CreatePostSheet extends StatefulWidget {
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
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet>
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

  void _createPost() {
    if (_postController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    final content = _postController.text.trim();
    final hashtagRegex = RegExp(r'#\w+');
    final hashtags = hashtagRegex
        .allMatches(content)
        .map((m) => m.group(0)!)
        .toList();

    final username =
        '@${(widget.userName ?? 'You').toLowerCase().replaceAll(' ', '.')}';

    final postModel = PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: fb.FirebaseAuth.instance.currentUser?.uid ?? '',
      user: widget.userName ?? 'You',
      username: username,
      avatar: widget.userAvatar ?? (widget.userName ?? 'U')[0],
      time: 'Just now',
      content: content,
      hashtags: hashtags,
      images: <String>[],
      likes: 0,
      comments: 0,
      shares: 0,
      liked: false,
      saved: false,
      commentsList: <CommentModel>[],
      createdAt: DateTime.now(),
    );

    if (widget.onPostCreated != null) {
      widget.onPostCreated!(postModel);
    }

    Get.back();
    HapticFeedback.mediumImpact();

    Get.snackbar(
      widget.isEditing ? 'Post Updated!' : 'Post Created!',
      widget.isEditing
          ? 'Your post has been updated successfully'
          : 'Your post is now live on the campus feed',
      backgroundColor: NexoraColors.success.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
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
      height: MediaQuery.of(context).size.height * 0.85,
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
                    IconButton(
                      onPressed: () => Get.back(),
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
                            _postController.text.trim().isNotEmpty &&
                                !_isPosting
                            ? _createPost
                            : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: _postController.text.trim().isNotEmpty
                                ? NexoraGradients.primaryButton
                                : null,
                            color: _postController.text.trim().isEmpty
                                ? NexoraColors.textMuted.withOpacity(0.3)
                                : null,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: _postController.text.trim().isNotEmpty
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

          // User info with enhanced visibility picker
          Padding(
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
                        color: NexoraColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 8.r,
                        spreadRadius: 1.r,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (widget.userName ?? 'U').isNotEmpty
                          ? (widget.userName ?? 'U')[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22.sp,
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
                        widget.userName ?? 'You',
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
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: NexoraColors.primaryPurple.withOpacity(
                                0.3,
                              ),
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
          ),

          // Post content with character count
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: GlassContainer(
                borderRadius: 20.r,
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
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
                final isSelected = _postController.text.contains(hashtag);
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
                          ? LinearGradient(
                              colors: [
                                NexoraColors.primaryPurple,
                                NexoraColors.deepPurple,
                              ],
                            )
                          : null,
                      color: isSelected ? null : NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : NexoraColors.glassBorder,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.3,
                                ),
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
          SizedBox(height: 12.h),

          // Enhanced bottom action bar
          Container(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 16.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    Icons.image_outlined,
                    'Photo',
                    NexoraColors.accentCyan,
                  ),
                  _buildActionButton(
                    Icons.videocam_outlined,
                    'Video',
                    NexoraColors.romanticPink,
                  ),
                  _buildActionButton(
                    Icons.poll_outlined,
                    'Poll',
                    NexoraColors.primaryPurple,
                  ),
                  _buildActionButton(
                    Icons.location_on_outlined,
                    'Location',
                    NexoraColors.success,
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
        Get.snackbar(
          'Coming Soon',
          'The $label feature is under development',
          backgroundColor: color.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          margin: EdgeInsets.all(16.r),
          borderRadius: 12.r,
        );
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
    Get.bottomSheet(
      Container(
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
                Get.back();
              },
            ),
            _buildVisibilityOption(
              Icons.school,
              'Campus Only',
              'Only people from your campus',
              _visibility == 'Campus',
              () {
                setState(() => _visibility = 'Campus');
                Get.back();
              },
            ),
            _buildVisibilityOption(
              Icons.lock,
              'Private',
              'Only your friends',
              _visibility == 'Friends',
              () {
                setState(() => _visibility = 'Friends');
                Get.back();
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
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    NexoraColors.primaryPurple.withOpacity(0.2),
                    NexoraColors.primaryPurple.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? NexoraColors.primaryPurple
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
      comment: _commentController.text.trim(),
      time: 'Just now',
      createdAt: DateTime.now(),
    );

    setState(() {
      _comments.insert(0, newComment);
      _isSubmitting = false;
    });

    if (widget.onCommentAdded != null) {
      widget.onCommentAdded!(newComment);
    }

    _commentController.clear();
    HapticFeedback.lightImpact();

    Get.snackbar(
      'Comment Added',
      'Your comment was posted successfully',
      backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
    );
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
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: _comments.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _buildCommentItem(comment),
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
                          widget.userAvatar != null &&
                              widget.userAvatar!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                widget.userAvatar!,
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
            child: Text(
              comment.user[0].toUpperCase(),
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
                          comment.user,
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
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 14.r,
                            color: NexoraColors.textMuted,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Like',
                            style: TextStyle(
                              color: NexoraColors.textMuted,
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
                        _commentController.text = '@${comment.user} ';
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

  const ImageViewerScreen({
    required this.images,
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
    _likeAnimationController.forward().then(
      (_) => _likeAnimationController.reverse(),
    );
    HapticFeedback.heavyImpact();
    Get.snackbar(
      'Liked',
      'Added to your likes',
      backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(milliseconds: 800),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
    );
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
          onPressed: () => Get.back(),
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
                  opacity: 1 - _likeAnimationController.value,
                  child: Transform.scale(
                    scale: 1 + (_likeAnimationController.value * 0.5),
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
                    _buildBottomAction(Icons.download_outlined, 'Save'),
                    _buildBottomAction(Icons.share_outlined, 'Share'),
                    _buildBottomAction(Icons.favorite_border, 'Like'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.snackbar(
          label,
          'Feature coming soon!',
          backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          margin: EdgeInsets.all(16.r),
          borderRadius: 12.r,
        );
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
            child: Icon(icon, color: Colors.white, size: 24.r),
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
    Get.bottomSheet(
      Container(
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
                  Get.back();
                  Get.snackbar(
                    'Saved',
                    'Image saved to your device',
                    backgroundColor: NexoraColors.success.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                },
              ),
              _buildOptionItem(
                Icons.share_outlined,
                'Share image',
                NexoraColors.primaryPurple,
                () {
                  Get.back();
                },
              ),
              _buildOptionItem(
                Icons.copy_outlined,
                'Copy image link',
                NexoraColors.romanticPink,
                () {
                  Get.back();
                  Clipboard.setData(
                    ClipboardData(text: widget.images[_currentIndex]),
                  );
                  Get.snackbar(
                    'Copied',
                    'Image link copied to clipboard',
                    backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    margin: EdgeInsets.all(16.r),
                    borderRadius: 12.r,
                  );
                },
              ),
              _buildOptionItem(
                Icons.flag_outlined,
                'Report image',
                NexoraColors.error,
                () {
                  Get.back();
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
