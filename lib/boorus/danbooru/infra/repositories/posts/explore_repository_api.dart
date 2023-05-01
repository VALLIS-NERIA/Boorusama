// Project imports:
import 'package:boorusama/api/danbooru.dart';
import 'package:boorusama/boorus/danbooru/domain/posts.dart';
import 'package:boorusama/boorus/danbooru/infra/dtos/dtos.dart';
import 'package:boorusama/boorus/danbooru/infra/repositories/posts/common.dart';
import 'package:boorusama/core/domain/boorus.dart';
import 'package:boorusama/core/domain/posts/post_image_source_composer.dart';
import 'package:boorusama/functional.dart';

class ExploreRepositoryApi implements ExploreRepository {
  const ExploreRepositoryApi({
    required this.api,
    required this.currentBooruConfigRepository,
    required this.postRepository,
    required this.urlComposer,
  });

  final CurrentBooruConfigRepository currentBooruConfigRepository;
  final DanbooruPostRepository postRepository;
  final DanbooruApi api;
  final ImageSourceComposer<PostDto> urlComposer;

  static const int _limit = 60;

  @override
  DanbooruPostsOrError getHotPosts(
    int page, {
    int? limit,
  }) =>
      postRepository.getPosts(
        'order:rank',
        page,
        limit: limit,
      );

  @override
  DanbooruPostsOrError getMostViewedPosts(
    DateTime date,
  ) =>
      getBooruConfigFrom(currentBooruConfigRepository)
          .flatMap((booruConfig) => getData(
                fetcher: () => api.getMostViewedPosts(
                  booruConfig.login,
                  booruConfig.apiKey,
                  '${date.year}-${date.month}-${date.day}',
                ),
              ))
          .flatMap((response) =>
              TaskEither.fromEither(parseData(response, urlComposer)));

  @override
  DanbooruPostsOrError getPopularPosts(
    DateTime date,
    int page,
    TimeScale scale, {
    int? limit,
  }) =>
      getBooruConfigFrom(currentBooruConfigRepository)
          .flatMap((booruConfig) => getData(
                fetcher: () => api.getPopularPosts(
                  booruConfig.login,
                  booruConfig.apiKey,
                  '${date.year}-${date.month}-${date.day}',
                  scale.toString().split('.').last,
                  page,
                  limit ?? _limit,
                ),
              ))
          .flatMap((response) =>
              TaskEither.fromEither(parseData(response, urlComposer)));
}
