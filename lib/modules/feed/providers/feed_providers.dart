import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/feed_repo.dart';
import '../model/feed_model.dart';

final postsStreamProvider = StreamProvider<List<PostModel>>((ref) {
  return PostRepository.instance.getPostsStream();
});
