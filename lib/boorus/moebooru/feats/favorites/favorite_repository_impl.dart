// Package imports:
import 'package:booru_clients/Moebooru.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../../core/configs/config.dart';
import '../../../../core/posts/favorites/providers.dart';
import '../../moebooru.dart';
import '../posts/moebooru_post.dart';
import 'moebooru_favorites_provider.dart';

class MoebooruFavoriteRepository extends FavoriteRepository<MoebooruPost> {
  MoebooruFavoriteRepository(this.ref, this.config);

  final Ref ref;
  final BooruConfigAuth config;

  MoebooruClient get client => ref.read(moebooruClientProvider(config));

  @override
  bool canFavorite() => config.hasLoginDetails();

  @override
  Future<AddFavoriteStatus> addToFavorites(int postId) async =>
      client.favoritePost(postId: postId).then(
            (_) => AddFavoriteStatus.success,
            onError: (_) => AddFavoriteStatus.failure,
          );

  @override
  Future<bool> removeFromFavorites(int postId) async =>
      client.unfavoritePost(postId: postId).then(
            (_) => true,
            onError: (_) => false,
          );

  @override
  bool isPostFavorited(MoebooruPost post) =>
      ref.watch(moebooruFavoritesProvider(post.id))?.contains(config.login) ??
      false;
}
