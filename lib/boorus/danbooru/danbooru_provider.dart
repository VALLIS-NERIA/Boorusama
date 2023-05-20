// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:boorusama/api/danbooru.dart';
import 'package:boorusama/boorus/danbooru/application/downloads/download_provider.dart';
import 'package:boorusama/boorus/danbooru/application/pools.dart';
import 'package:boorusama/boorus/danbooru/application/saved_searches.dart';
import 'package:boorusama/boorus/danbooru/application/tags.dart';
import 'package:boorusama/boorus/danbooru/domain/pools.dart';
import 'package:boorusama/boorus/danbooru/domain/posts.dart';
import 'package:boorusama/boorus/danbooru/domain/saved_searches.dart';
import 'package:boorusama/boorus/danbooru/domain/tags.dart';
import 'package:boorusama/boorus/danbooru/domain/users.dart';
import 'package:boorusama/boorus/danbooru/infra/repositories/pool/pool_cacher.dart';
import 'package:boorusama/boorus/danbooru/infra/repositories/posts/danbooru_artist_character_post_repository.dart';
import 'package:boorusama/boorus/danbooru/infra/repositories/repositories.dart';
import 'package:boorusama/boorus/danbooru/infra/repositories/saved_searches/save_search_repository_api.dart';
import 'package:boorusama/boorus/danbooru/infra/repositories/tags/related_tag_repository_empty.dart';
import 'package:boorusama/core/application/blacklists.dart';
import 'package:boorusama/core/application/boorus.dart';
import 'package:boorusama/core/application/downloads.dart';
import 'package:boorusama/core/application/tags.dart';
import 'package:boorusama/core/domain/autocompletes.dart';
import 'package:boorusama/core/infra/caching/lru_cacher.dart';
import 'package:boorusama/core/infra/services/tag_info_service.dart';
import 'package:boorusama/core/provider.dart';

class DanbooruProvider extends StatelessWidget {
  const DanbooruProvider({
    super.key,
    required this.builder,
    required this.postRepo,
    required this.poolRepo,
    required this.userRepo,
    required this.relatedTagRepo,
    required this.poolDescriptionRepo,
    required this.savedSearchRepo,
    required this.tagInfo,
    required this.poolOverviewBloc,
    required this.savedSearchBloc,
    required this.danbooruArtistCharacterPostRepository,
  });

  factory DanbooruProvider.create(
    BuildContext context, {
    required WidgetRef ref,
    required Widget Function(BuildContext context) builder,
  }) {
    final booruConfig = ref.read(currentBooruConfigProvider);
    final dio = ref.read(dioProvider(booruConfig.url));
    final tagInfo = context.read<TagInfo>();
    final api = DanbooruApi(dio);
    ref.read(trendingTagsProvider.notifier).fetch();

    final settingRepository = ref.read(settingsRepoProvider);
    final currentBooruConfigRepo = ref.read(currentBooruConfigRepoProvider);

    final postRepo = PostRepositoryApi(
      api,
      currentBooruConfigRepo,
      settingRepository,
      ref.read(globalBlacklistedTagRepoProvider),
    );

    final userRepo = UserRepositoryApi(
      api,
      currentBooruConfigRepo,
      tagInfo.defaultBlacklistedTags,
    );

    final poolRepo = PoolCacher(PoolRepositoryApi(api, currentBooruConfigRepo));

    final relatedTagRepo = RelatedTagRepositoryEmpty();

    final poolDescriptionRepo = PoolDescriptionRepositoryApi(
      dio: dio,
      endpoint: booruConfig.url,
    );

    final savedSearchRepo =
        SavedSearchRepositoryApi(api, currentBooruConfigRepo);

    final poolOverviewBloc = PoolOverviewBloc()
      ..add(const PoolOverviewChanged(
        category: PoolCategory.series,
        order: PoolOrder.latest,
      ));

    final savedSearchBloc = SavedSearchBloc(
      savedSearchRepository: savedSearchRepo,
    );

    final artistCharacterPostRepository = DanbooruArtistCharacterPostRepository(
      repository: postRepo,
      cache: LruCacher(),
    );

    return DanbooruProvider(
      builder: builder,
      poolDescriptionRepo: poolDescriptionRepo,
      poolRepo: poolRepo,
      postRepo: postRepo,
      relatedTagRepo: relatedTagRepo,
      savedSearchRepo: savedSearchRepo,
      userRepo: userRepo,
      tagInfo: tagInfo,
      poolOverviewBloc: poolOverviewBloc,
      savedSearchBloc: savedSearchBloc,
      danbooruArtistCharacterPostRepository: artistCharacterPostRepository,
    );
  }

  factory DanbooruProvider.of(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
  }) {
    final postRepo = context.read<DanbooruPostRepository>();
    final userRepo = context.read<UserRepository>();
    final poolRepo = context.read<PoolRepository>();
    final relatedTagRepo = context.read<RelatedTagRepository>();
    final poolDescriptionRepo = context.read<PoolDescriptionRepository>();
    final savedSearchRepo = context.read<SavedSearchRepository>();

    final tagInfo = context.read<TagInfo>();

    final poolOverviewBloc = context.read<PoolOverviewBloc>();
    final savedSearchBloc = context.read<SavedSearchBloc>();
    final artistCharacterPostRepository =
        context.read<DanbooruArtistCharacterPostRepository>();

    return DanbooruProvider(
      builder: builder,
      poolDescriptionRepo: poolDescriptionRepo,
      poolRepo: poolRepo,
      postRepo: postRepo,
      relatedTagRepo: relatedTagRepo,
      savedSearchRepo: savedSearchRepo,
      userRepo: userRepo,
      tagInfo: tagInfo,
      poolOverviewBloc: poolOverviewBloc,
      savedSearchBloc: savedSearchBloc,
      danbooruArtistCharacterPostRepository: artistCharacterPostRepository,
    );
  }

  final Widget Function(BuildContext context) builder;

  final DanbooruPostRepository postRepo;
  final DanbooruArtistCharacterPostRepository
      danbooruArtistCharacterPostRepository;
  final PoolRepository poolRepo;
  final UserRepository userRepo;
  final RelatedTagRepository relatedTagRepo;
  final PoolDescriptionRepository poolDescriptionRepo;
  final SavedSearchRepository savedSearchRepo;

  final PoolOverviewBloc poolOverviewBloc;
  final SavedSearchBloc savedSearchBloc;

  final TagInfo tagInfo;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: postRepo),
        RepositoryProvider.value(value: danbooruArtistCharacterPostRepository),
        RepositoryProvider.value(value: poolRepo),
        RepositoryProvider.value(value: userRepo),
        RepositoryProvider.value(value: relatedTagRepo),
        RepositoryProvider.value(value: poolDescriptionRepo),
        RepositoryProvider.value(value: savedSearchRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: poolOverviewBloc),
          BlocProvider.value(value: savedSearchBloc),
        ],
        child: ProviderScope(
          overrides: [
            poolRepoProvider.overrideWithValue(poolRepo),
            danbooruArtistCharacterPostRepoProvider
                .overrideWithValue(danbooruArtistCharacterPostRepository),
            poolDescriptionRepoProvider.overrideWithValue(poolDescriptionRepo),
            tagRepoProvider
                .overrideWith((ref) => ref.watch(danbooruTagRepoProvider)),
            downloadFileNameGeneratorProvider.overrideWith(
                (ref) => ref.watch(danbooruDownloadFileNameGeneratorProvider)),
            autocompleteRepoProvider.overrideWith(
                (ref) => ref.watch(danbooruAutocompleteRepoProvider))
          ],
          child: Builder(builder: builder),
        ),
      ),
    );
  }
}

final danbooruApiProvider = Provider<DanbooruApi>((ref) {
  final booruConfig = ref.watch(currentBooruConfigProvider);
  final dio = ref.watch(dioProvider(booruConfig.url));

  return DanbooruApi(dio);
});

final poolRepoProvider =
    Provider<PoolRepository>((ref) => throw UnimplementedError());

final danbooruPostRepoProvider = Provider<DanbooruPostRepository>((ref) {
  final api = ref.watch(danbooruApiProvider);
  final booruConfigRepo = ref.watch(currentBooruConfigRepoProvider);
  final settingsRepo = ref.watch(settingsRepoProvider);
  final globalBlacklistedTagRepo = ref.watch(globalBlacklistedTagRepoProvider);

  return PostRepositoryApi(
      api, booruConfigRepo, settingsRepo, globalBlacklistedTagRepo);
});

final danbooruArtistCharacterPostRepoProvider =
    Provider<DanbooruPostRepository>((ref) => throw UnimplementedError());

final poolDescriptionRepoProvider =
    Provider<PoolDescriptionRepository>((ref) => throw UnimplementedError());

final danbooruAutocompleteRepoProvider =
    Provider<AutocompleteRepository>((ref) {
  final api = ref.watch(danbooruApiProvider);
  final currentBooruConfigRepository =
      ref.watch(currentBooruConfigRepoProvider);

  return AutocompleteRepositoryApi(
    api: api,
    currentBooruConfigRepository: currentBooruConfigRepository,
  );
});
