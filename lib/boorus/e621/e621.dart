// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:boorusama/boorus/booru_builder.dart';
import 'package:boorusama/boorus/e621/configs/configs.dart';
import 'package:boorusama/boorus/providers.dart';
import 'package:boorusama/clients/e621/e621_client.dart';
import 'package:boorusama/core/autocompletes/autocompletes.dart';
import 'package:boorusama/core/configs/configs.dart';
import 'package:boorusama/core/configs/create/create.dart';
import 'package:boorusama/core/downloads/downloads.dart';
import 'package:boorusama/core/posts/posts.dart';
import 'package:boorusama/foundation/networking/networking.dart';
import 'artists/artists.dart';
import 'comments/comments.dart';
import 'favorites/favorites.dart';
import 'home/home.dart';
import 'posts/posts.dart';
import 'tags/tags.dart';

final e621ClientProvider =
    Provider.family<E621Client, BooruConfig>((ref, booruConfig) {
  final dio = newDio(ref.watch(dioArgsProvider(booruConfig)));

  return E621Client(
    baseUrl: booruConfig.url,
    dio: dio,
    login: booruConfig.login,
    apiKey: booruConfig.apiKey,
  );
});

final e621AutocompleteRepoProvider =
    Provider.family<AutocompleteRepository, BooruConfig>((ref, config) {
  final client = ref.watch(e621ClientProvider(config));

  return AutocompleteRepositoryBuilder(
    persistentStorageKey:
        '${Uri.encodeComponent(config.url)}_autocomplete_cache_v1',
    persistentStaleDuration: const Duration(days: 1),
    autocomplete: (query) async {
      final dtos = await client.getAutocomplete(query: query);

      return dtos
          .map((e) => AutocompleteData(
                type: AutocompleteData.tag,
                label: e.name?.replaceAll('_', ' ') ?? '',
                value: e.name ?? '',
                category: intToE621TagCategory(e.category).name,
                postCount: e.postCount,
                antecedent: e.antecedentName,
              ))
          .toList();
    },
  );
});

const kE621PostSamples = [
  {
    'id': '123456',
    'artist': 'artist_x_(abc) artist_2',
    'character': 'sonic_the_hedgehog classic_sonic',
    'copyright': 'sonic_the_hedgehog_(comics) sonic_the_hedgehog_(series)',
    'general': 'male solo',
    'meta': 'highres translated',
    'species': 'mammal hedgehog',
    'tags':
        'male solo sonic_the_hedgehog classic_sonic sonic_the_hedgehog_(comics) sonic_the_hedgehog_(series) highres translated mammal hedgehog',
    'extension': 'jpg',
    'md5': '9cf364e77f46183e2ebd75de757488e2',
    'width': '2232',
    'height': '1000',
    'aspect_ratio': '0.44776119402985076',
    'mpixels': '2.232356356345635',
    'source': 'https://example.com/filename.jpg',
    'rating': 'general',
    'index': '0',
  },
  {
    'id': '654321',
    'artist': 'artist_3',
    'character': 'classic_sonic',
    'copyright': 'sega',
    'general': 'male solo',
    'meta': 'highres translated',
    'species': 'mammal hedgehog',
    'tags': 'male solo classic_sonic sega highres translated mammal hedgehog',
    'extension': 'png',
    'md5': '2ebd75de757488e29cf364e77f46183e',
    'width': '1334',
    'height': '2232',
    'aspect_ratio': '0.598744769874477',
    'mpixels': '2.976527856856785678',
    'source': 'https://example.com/example_filename.jpg',
    'rating': 'general',
    'index': '1',
  }
];

class E621Builder
    with
        CharacterNotSupportedMixin,
        LegacyGranularRatingOptionsBuilderMixin,
        UnknownMetatagsMixin,
        DefaultMultiSelectionActionsBuilderMixin,
        DefaultHomeMixin,
        DefaultQuickFavoriteButtonBuilderMixin,
        DefaultThumbnailUrlMixin,
        DefaultPostGesturesHandlerMixin,
        DefaultPostStatisticsPageBuilderMixin,
        DefaultGranularRatingFiltererMixin,
        DefaultPostImageDetailsUrlMixin
    implements BooruBuilder {
  E621Builder();

  @override
  CreateConfigPageBuilder get createConfigPageBuilder => (
        context,
        id, {
        backgroundColor,
      }) =>
          CreateBooruConfigScope(
            id: id,
            config: BooruConfig.defaultConfig(
              booruType: id.booruType,
              url: id.url,
              customDownloadFileNameFormat:
                  kBoorusamaCustomDownloadFileNameFormat,
            ),
            child: CreateE621ConfigPage(
              backgroundColor: backgroundColor,
            ),
          );

  @override
  HomePageBuilder get homePageBuilder =>
      (context, config) => E621HomePage(config: config);

  @override
  UpdateConfigPageBuilder get updateConfigPageBuilder => (
        context,
        id, {
        backgroundColor,
        initialTab,
      }) =>
          UpdateBooruConfigScope(
            id: id,
            child: CreateE621ConfigPage(
              backgroundColor: backgroundColor,
              initialTab: initialTab,
            ),
          );

  @override
  SearchPageBuilder get searchPageBuilder =>
      (context, initialQuery) => E621SearchPage(initialQuery: initialQuery);

  @override
  PostDetailsPageBuilder get postDetailsPageBuilder =>
      (context, config, payload) {
        final posts = payload.posts.map((e) => e as E621Post).toList();

        return PostDetailsScope(
          initialIndex: payload.initialIndex,
          posts: posts,
          scrollController: payload.scrollController,
          child: const DefaultPostDetailsPage<E621Post>(),
        );
      };

  @override
  FavoritesPageBuilder? get favoritesPageBuilder =>
      (context, config) => const E621FavoritesPage();

  @override
  ArtistPageBuilder? get artistPageBuilder =>
      (context, artistName) => E621ArtistPage(artistName: artistName);

  @override
  CommentPageBuilder? get commentPageBuilder =>
      (context, useAppBar, postId) => E621CommentPage(
            postId: postId,
            useAppBar: useAppBar,
          );

  @override
  TagColorBuilder get tagColorBuilder =>
      (brightness, tagType) => switch (tagType) {
            'general' => const Color(0xffb4c7d8),
            'artist' => const Color(0xfff2ad04),
            'copyright' => const Color(0xffd60ad8),
            'character' => const Color(0xff05a903),
            'species' => const Color(0xffed5d1f),
            'invalid' => const Color(0xfffe3c3d),
            'meta' => const Color(0xfffefffe),
            'lore' => const Color(0xff218923),
            _ => const Color(0xffb4c7d8),
          };

  @override
  final DownloadFilenameGenerator downloadFilenameBuilder =
      DownloadFileNameBuilder<E621Post>(
    defaultFileNameFormat: kBoorusamaCustomDownloadFileNameFormat,
    defaultBulkDownloadFileNameFormat:
        kBoorusamaBulkDownloadCustomFileNameFormat,
    sampleData: kE621PostSamples,
    tokenHandlers: {
      'artist': (post, config) => post.artistTags.join(' '),
      'character': (post, config) => post.characterTags.join(' '),
      'copyright': (post, config) => post.copyrightTags.join(' '),
      'general': (post, config) => post.generalTags.join(' '),
      'meta': (post, config) => post.metaTags.join(' '),
      'species': (post, config) => post.speciesTags.join(' '),
      'width': (post, config) => post.width.toString(),
      'height': (post, config) => post.height.toString(),
      'mpixels': (post, config) => post.mpixels.toString(),
      'aspect_ratio': (post, config) => post.aspectRatio.toString(),
      'source': (post, config) => config.downloadUrl,
    },
  );

  @override
  final PostDetailsUIBuilder postDetailsUIBuilder = PostDetailsUIBuilder(
    preview: {
      DetailsPart.info: (context) =>
          const DefaultInheritedInformationSection<E621Post>(
            showSource: true,
          ),
      DetailsPart.toolbar: (context) =>
          const DefaultInheritedPostActionToolbar<E621Post>(),
    },
    full: {
      DetailsPart.info: (context) =>
          const DefaultInheritedInformationSection<E621Post>(
            showSource: true,
          ),
      DetailsPart.toolbar: (context) =>
          const DefaultInheritedPostActionToolbar<E621Post>(),
      DetailsPart.artistInfo: (context) => const E621ArtistSection(),
      DetailsPart.tags: (context) => const E621TagsTile(),
      DetailsPart.fileDetails: (context) =>
          const DefaultInheritedFileDetailsSection<E621Post>(),
      DetailsPart.artistPosts: (context) => const E621ArtistPostsSection(),
    },
  );
}
