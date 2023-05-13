// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/danbooru_provider.dart';
import 'package:boorusama/boorus/danbooru/domain/posts.dart';
import 'package:boorusama/core/application/posts/details.dart';
import 'package:boorusama/core/domain/posts.dart';

final danbooruPostDetailsArtistProvider = NotifierProvider.autoDispose
    .family<PostDetailsArtistNotifier, List<Recommend<DanbooruPost>>, int>(
  PostDetailsArtistNotifier.new,
  dependencies: [
    danbooruArtistCharacterPostRepoProvider,
  ],
);

class PostDetailsArtistNotifier
    extends AutoDisposeFamilyNotifier<List<Recommend<DanbooruPost>>, int>
    with DanbooruPostRepositoryMixin, PostDetailsTagsX<DanbooruPost> {
  @override
  DanbooruPostRepository get postRepository =>
      ref.read(danbooruArtistCharacterPostRepoProvider);

  @override
  Future<List<DanbooruPost>> Function(String tag, int page) get fetcher =>
      (tags, page) => getPostsOrEmpty(tags, page);

  @override
  List<Recommend<DanbooruPost>> build(int arg) => [];

  Future<void> load(DanbooruPost post) => fetchPosts(
        post.artistTags,
        RecommendType.artist,
        limit: 30,
      );
}
