// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../core/blacklists/providers.dart';
import '../../../core/configs/config.dart';
import '../../../core/foundation/caching.dart';
import '../../../core/posts/post/post.dart';
import '../../../core/posts/post/providers.dart';
import '../posts/posts.dart';

final gelbooruArtistPostRepo =
    Provider.family<PostRepository<GelbooruPost>, BooruConfigSearch>(
        (ref, config) {
  return PostRepositoryCacher(
    keyBuilder: (tags, page, {limit}) =>
        '${tags.split(' ').join('-')}_${page}_$limit',
    repository: ref.watch(gelbooruPostRepoProvider(config)),
    cache: LruCacher(capacity: 100),
  );
});

final gelbooruArtistPostsProvider = FutureProvider.autoDispose.family<
    List<GelbooruPost>,
    (BooruConfigFilter, BooruConfigSearch, String?)>((ref, params) async {
  final (filter, search, artistName) = params;

  return ref.watch(gelbooruArtistPostRepo(search)).getPostsFromTagWithBlacklist(
        tag: artistName,
        blacklist: ref.watch(blacklistTagsProvider(filter).future),
      );
});
