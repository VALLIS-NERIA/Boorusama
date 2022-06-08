// Package imports:
import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/accounts/i_account_repository.dart';
import 'package:boorusama/boorus/danbooru/domain/favorites/i_favorite_post_repository.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/i_post_repository.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/post.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/post_dto.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/time_scale.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/i_api.dart';
import 'package:boorusama/core/infrastructure/http_parser.dart';

List<Post> parsePost(HttpResponse<dynamic> value) => parse(
      value: value,
      converter: (item) => PostDto.fromJson(item),
    ).map((dto) => dto.toEntity()).toList();

class PostRepository implements IPostRepository {
  PostRepository(
    IApi api,
    IAccountRepository accountRepository,
    IFavoritePostRepository favoritePostRepository,
  )   : _api = api,
        _accountRepository = accountRepository;

  final IAccountRepository _accountRepository;
  final IApi _api;

  static const int _limit = 60;

  @override
  Future<List<Post>> getCuratedPosts(
    DateTime date,
    int page,
    TimeScale scale,
  ) async =>
      _accountRepository
          .get()
          .then(
            (account) => _api.getCuratedPosts(
              account.username,
              account.apiKey,
              "${date.year}-${date.month}-${date.day}",
              scale.toString().split(".").last,
              page,
              _limit,
            ),
          )
          .then(parsePost)
          .catchError((Object obj) {
        switch (obj.runtimeType) {
          case DioError:
            final response = (obj as DioError).response;
            if (response == null) {
              throw Exception("Failed to get popular posts for $date");
            }
            if (response.statusCode == 500) {
              throw DatabaseTimeOut(
                  "Your search took too long to execute and was cancelled.");
            } else {
              throw Exception("Failed to get popular posts for $date");
            }
          default:
        }
        return <Post>[];
      });

  @override
  Future<List<Post>> getMostViewedPosts(
    DateTime date,
  ) async =>
      _accountRepository
          .get()
          .then(
            (account) => _api.getMostViewedPosts(
              account.username,
              account.apiKey,
              "${date.year}-${date.month}-${date.day}",
            ),
          )
          .then(parsePost)
          .catchError((Object obj) {
        switch (obj.runtimeType) {
          case DioError:
            final response = (obj as DioError).response;
            if (response == null) {
              throw Exception("Failed to get popular posts for $date");
            }
            if (response.statusCode == 500) {
              throw DatabaseTimeOut(
                  "Your search took too long to execute and was cancelled.");
            } else {
              throw Exception("Failed to get popular posts for $date");
            }
          default:
        }
        return <Post>[];
      });

  @override
  Future<List<Post>> getPopularPosts(
    DateTime date,
    int page,
    TimeScale scale,
  ) async =>
      _accountRepository
          .get()
          .then(
            (account) => _api.getPopularPosts(
              account.username,
              account.apiKey,
              "${date.year}-${date.month}-${date.day}",
              scale.toString().split(".").last,
              page,
              _limit,
            ),
          )
          .then(parsePost)
          .catchError((Object obj) {
        switch (obj.runtimeType) {
          case DioError:
            final response = (obj as DioError).response;
            if (response == null) {
              throw Exception("Failed to get popular posts for $date");
            }
            if (response.statusCode == 500) {
              throw DatabaseTimeOut(
                  "Your search took too long to execute and was cancelled.");
            } else {
              throw Exception("Failed to get popular posts for $date");
            }
          default:
        }
        return <Post>[];
      });

  @override
  Future<List<Post>> getPosts(
    String tagString,
    int page, {
    int limit = 50,
    CancelToken? cancelToken,
    bool skipFavoriteCheck = false,
  }) async {
    try {
      return _accountRepository
          .get()
          .then(
            (account) => _api.getPosts(
              account.username,
              account.apiKey,
              page,
              tagString,
              limit,
              cancelToken: cancelToken,
            ),
          )
          .then(parsePost);
    } on DioError catch (e) {
      if (e.type == DioErrorType.cancel) {
        // Cancel token triggered, skip this request
        return [];
      } else if (e.response == null) {
        throw Exception("Failed to get posts for $tagString");
      } else if (e.response!.statusCode == 422) {
        throw CannotSearchMoreThanTwoTags(
            "${e.response!.data['message']} Upgrade your account to search for more tags at once.");
      } else if (e.response!.statusCode == 500) {
        throw DatabaseTimeOut(
            "Your search took too long to execute and was cancelled.");
      } else {
        throw Exception("Failed to get posts for $tagString");
      }
    }
  }
}

class CannotSearchMoreThanTwoTags implements BooruException {
  CannotSearchMoreThanTwoTags(this.message);

  @override
  final String message;
}

class DatabaseTimeOut implements BooruException {
  DatabaseTimeOut(this.message);

  @override
  final String message;
}

class BooruException implements Exception {
  BooruException(this.message);

  final String message;
}
