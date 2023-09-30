// Package imports:
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';

// Project imports:
import 'package:boorusama/boorus/booru_builder.dart';
import 'package:boorusama/boorus/providers.dart';
import 'package:boorusama/clients/gelbooru/gelbooru_client.dart';
import 'package:boorusama/clients/gelbooru/gelbooru_v1_client.dart';
import 'package:boorusama/core/feats/autocompletes/autocomplete.dart';
import 'package:boorusama/core/feats/boorus/boorus.dart';
import 'package:boorusama/core/feats/posts/posts.dart';
import 'package:boorusama/core/pages/boorus/create_anon_config_page.dart';
import 'package:boorusama/core/scaffolds/search_page_scaffold.dart';
import 'package:boorusama/foundation/networking/networking.dart';
import 'package:boorusama/functional.dart';
import 'package:boorusama/widgets/info_container.dart';

part 'providers.dart';

class GelbooruV1Builder
    with
        FavoriteNotSupportedMixin,
        PostCountNotSupportedMixin,
        ArtistNotSupportedMixin,
        DefaultBooruUIMixin
    implements BooruBuilder {
  const GelbooruV1Builder({
    required this.postRepo,
    required this.client,
  });

  final PostRepository postRepo;
  final GelbooruClient client;

  @override
  AutocompleteFetcher get autocompleteFetcher =>
      (tags) => client.autocomplete(term: tags).then((value) => value
          .map((e) => AutocompleteData(
                label: e.label ?? '<Unknown>',
                value: e.value ?? '<Unknown>',
              ))
          .toList());

  @override
  CreateConfigPageBuilder get createConfigPageBuilder => (
        context,
        url,
        booruType, {
        backgroundColor,
      }) =>
          CreateAnonConfigPage(
            url: url,
            booruType: booruType,
            backgroundColor: backgroundColor,
          );

  @override
  SearchPageBuilder get searchPageBuilder => (context, initialQuery) =>
      BooruProvider(
        builder: (booruBuilder) => SearchPageScaffold(
          noticeBuilder: (context) => InfoContainer(
            contentBuilder: (context) => Html(
                data: 'The app will use <b>Gelbooru</b> for tag completion.'),
          ),
          initialQuery: initialQuery,
          fetcher: (page, tags) =>
              booruBuilder?.postFetcher.call(page, tags) ??
              TaskEither.of(<Post>[]),
        ),
      );

  @override
  PostFetcher get postFetcher => (page, tags) => TaskEither.Do(($) async {
        final posts = await $(postRepo.getPosts(tags, page));

        return posts;
      });
}
