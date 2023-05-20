// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:boorusama/api/moebooru.dart';
import 'package:boorusama/boorus/moebooru/application/downloads/download_provider.dart';
import 'package:boorusama/boorus/moebooru/domain/posts/moebooru_popular_repository.dart';
import 'package:boorusama/boorus/moebooru/infra/autocompletes/moebooru_autocomplete_repository.dart';
import 'package:boorusama/boorus/moebooru/infra/posts.dart';
import 'package:boorusama/boorus/moebooru/infra/posts/moebooru_post_repository_api.dart';
import 'package:boorusama/boorus/moebooru/infra/tags.dart';
import 'package:boorusama/core/application/blacklists.dart';
import 'package:boorusama/core/application/boorus.dart';
import 'package:boorusama/core/application/downloads.dart';
import 'package:boorusama/core/domain/autocompletes.dart';
import 'package:boorusama/core/domain/boorus.dart';
import 'package:boorusama/core/domain/posts.dart';
import 'package:boorusama/core/domain/settings.dart';
import 'package:boorusama/core/provider.dart';

class MoebooruProvider extends StatelessWidget {
  const MoebooruProvider({
    super.key,
    required this.postRepository,
    required this.builder,
    required this.autocompleteRepository,
    required this.moebooruPopularRepository,
  });

  factory MoebooruProvider.create(
    BuildContext context, {
    required WidgetRef ref,
    required Widget Function(BuildContext context) builder,
    Key? key,
  }) {
    final booruConfig = ref.read(currentBooruConfigProvider);
    final dio = ref.read(dioProvider(booruConfig.url));

    final api = MoebooruApi(dio);

    final settingsRepo = context.read<SettingsRepository>();
    final globalBlacklistedTagRepo = ref.read(globalBlacklistedTagRepoProvider);
    final currentBooruConfigRepository =
        context.read<CurrentBooruConfigRepository>();
    final tagSummaryRepository = MoebooruTagSummaryRepository(api);
    final autocompleteRepo = MoebooruAutocompleteRepository(
        tagSummaryRepository: tagSummaryRepository);

    final postRepo = MoebooruPostRepositoryApi(
      api,
      globalBlacklistedTagRepo,
      currentBooruConfigRepository,
      settingsRepo,
    );
    final popularRepository = MoebooruPopularRepositoryApi(
      api,
      globalBlacklistedTagRepo,
      currentBooruConfigRepository,
    );

    return MoebooruProvider(
      key: key,
      postRepository: postRepo,
      builder: builder,
      autocompleteRepository: autocompleteRepo,
      moebooruPopularRepository: popularRepository,
    );
  }

  factory MoebooruProvider.of(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
    Key? key,
  }) {
    final postRepo = context.read<PostRepository>();
    final autocompleteRepo = context.read<AutocompleteRepository>();
    final popularRepository = context.read<MoebooruPopularRepository>();

    return MoebooruProvider(
      key: key,
      postRepository: postRepo,
      moebooruPopularRepository: popularRepository,
      builder: builder,
      autocompleteRepository: autocompleteRepo,
    );
  }

  final PostRepository postRepository;
  final AutocompleteRepository autocompleteRepository;
  final MoebooruPopularRepository moebooruPopularRepository;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: postRepository),
        RepositoryProvider.value(value: moebooruPopularRepository),
        RepositoryProvider.value(value: autocompleteRepository),
      ],
      child: ProviderScope(
        overrides: [
          autocompleteRepoProvider.overrideWithValue(autocompleteRepository),
          downloadFileNameGeneratorProvider.overrideWith(
              (ref) => ref.watch(moebooruDownloadFileNameGeneratorProvider)),
        ],
        child: Builder(
          builder: builder,
        ),
      ),
    );
  }
}
