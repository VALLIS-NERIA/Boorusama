// Package imports:
import 'package:booru_clients/danbooru.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/danbooru_provider.dart';
import 'package:boorusama/core/cache/providers.dart';
import 'package:boorusama/core/configs/config.dart';
import 'package:boorusama/core/http/providers.dart';
import 'package:boorusama/core/tags/configs/providers.dart';
import 'user.dart';
import 'user_repository.dart';

final danbooruUserRepoProvider =
    Provider.family<UserRepository, BooruConfigAuth>((ref, config) {
  return UserRepositoryApi(
    ref.watch(danbooruClientProvider(config)),
    ref.watch(tagInfoProvider).defaultBlacklistedTags,
  );
});

const _kCurrentUserIdKey = '_current_uid';

final danbooruCurrentUserProvider =
    FutureProvider.family<UserSelf?, BooruConfigAuth>((ref, config) async {
  if (!config.hasLoginDetails()) return null;

  // First, we try to get the user id from the cache
  final miscData = ref.watch(miscDataBoxProvider);
  final key =
      '${_kCurrentUserIdKey}_${Uri.encodeComponent(config.url)}_${config.login}';
  final cached = miscData.get(key);
  var id = cached != null ? int.tryParse(cached) : null;

  // If the cached id is null, we need to fetch it from the api
  if (id == null) {
    final dio = ref.watch(dioProvider(config));

    final data = await DanbooruClient(
            dio: dio,
            baseUrl: config.url,
            apiKey: config.apiKey,
            login: config.login)
        .getProfile()
        .then((value) => value.data['id']);

    id = switch (data) {
      final int i => i,
      _ => null,
    };

    // If the id is not null, we cache it
    if (id != null) {
      miscData.put(key, id.toString());
    }
  }

  // If the id is still null, we can't do anything else here
  if (id == null) return null;

  return ref.watch(danbooruUserRepoProvider(config)).getUserSelfById(id);
});
