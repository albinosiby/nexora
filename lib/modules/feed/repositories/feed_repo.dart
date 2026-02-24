// lib/data/repositories/post_repository.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/feed_model.dart';

abstract class IPostRepository {
  Future<List<PostModel>> getPosts({int page = 1, int limit = 10});
  Future<PostModel> getPostById(String id);
  Future<List<PostModel>> searchPosts(String query);
  Future<PostModel> createPost(PostModel post);
  Future<PostModel> updatePost(PostModel post);
  Future<void> deletePost(String id);
  Future<PostModel> toggleLike(String postId, String userId);
  Future<PostModel> toggleSave(String postId, String userId);
  Future<CommentModel> addComment(String postId, CommentModel comment);
  Future<void> deleteComment(String postId, String commentId);
  Future<List<PostModel>> getPostsByUser(String userId);
  Future<List<String>> getTrendingHashtags();
}

class PostRepository extends GetxService implements IPostRepository {
  static PostRepository get instance => Get.find<PostRepository>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _postsCollection;

  @override
  void onInit() {
    super.onInit();
    _postsCollection = _firestore.collection('feed');
  }

  @override
  Future<List<PostModel>> getPosts({int page = 1, int limit = 10}) async {
    try {
      final querySnapshot = await _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit * page) // Simple pagination for now
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  @override
  Future<PostModel> getPostById(String id) async {
    final doc = await _postsCollection.doc(id).get();
    if (!doc.exists) throw Exception('Post not found');
    return PostModel.fromFirestore(doc);
  }

  @override
  Future<List<PostModel>> searchPosts(String query) async {
    // Firestore doesn't support full-text search directly without third-party services.
    // However, we can do a simple prefix search or client-side filtering.
    // For now, let's fetch recent posts and filter client-side as a fallback.
    final posts = await getPosts(limit: 50);
    final lowercaseQuery = query.toLowerCase();

    return posts.where((post) {
      return post.content.toLowerCase().contains(lowercaseQuery) ||
          post.user.toLowerCase().contains(lowercaseQuery) ||
          post.username.toLowerCase().contains(lowercaseQuery) ||
          post.hashtags.any(
            (tag) => tag.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  @override
  Future<PostModel> createPost(PostModel post) async {
    final docRef = await _postsCollection.add(post.toJson());
    final doc = await docRef.get();
    return PostModel.fromFirestore(doc);
  }

  @override
  Future<PostModel> updatePost(PostModel post) async {
    await _postsCollection.doc(post.id).update(post.toJson());
    return post;
  }

  @override
  Future<void> deletePost(String id) async {
    await _postsCollection.doc(id).delete();
  }

  @override
  Future<PostModel> toggleLike(String postId, String userId) async {
    // Optimization: In a real app, likes should be in a subcollection or use a separate tracking field.
    // For this simple implementation, we'll fetch, update, and return.
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) throw Exception('Post not found');

    final post = PostModel.fromFirestore(doc);
    final wasLiked = post.liked;

    final updatedPost = post.copyWith(
      liked: !wasLiked,
      likes: wasLiked ? post.likes - 1 : post.likes + 1,
    );

    await _postsCollection.doc(postId).update({
      'liked': updatedPost.liked,
      'likes': updatedPost.likes,
    });

    return updatedPost;
  }

  @override
  Future<PostModel> toggleSave(String postId, String userId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) throw Exception('Post not found');

    final post = PostModel.fromFirestore(doc);
    final updatedPost = post.copyWith(saved: !post.saved);

    await _postsCollection.doc(postId).update({'saved': updatedPost.saved});

    return updatedPost;
  }

  @override
  Future<CommentModel> addComment(String postId, CommentModel comment) async {
    final newComment = comment.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );

    await _postsCollection.doc(postId).update({
      'comments_list': FieldValue.arrayUnion([newComment.toJson()]),
      'comments': FieldValue.increment(1),
    });

    return newComment;
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) return;

    final post = PostModel.fromFirestore(doc);
    final updatedComments = post.commentsList
        .where((c) => c.id != commentId)
        .toList();

    await _postsCollection.doc(postId).update({
      'comments_list': updatedComments.map((c) => c.toJson()).toList(),
      'comments': FieldValue.increment(-1),
    });
  }

  @override
  Future<List<PostModel>> getPostsByUser(String userId) async {
    final querySnapshot = await _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<String>> getTrendingHashtags() async {
    // This would typically be a cloud function or separate aggregation.
    // For now, client-side aggregation on the latest 50 posts.
    final posts = await getPosts(limit: 50);
    final hashtagCount = <String, int>{};

    for (final post in posts) {
      for (final hashtag in post.hashtags) {
        hashtagCount[hashtag] = (hashtagCount[hashtag] ?? 0) + 1;
      }
    }

    final sortedHashtags = hashtagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedHashtags.take(10).map((e) => e.key).toList();
  }
}
