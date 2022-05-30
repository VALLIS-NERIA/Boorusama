// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:dio/dio.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/authentication/authentication_state_notifier.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/repositories/accounts/account_repository.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/repositories/favorites/favorite_post_repository.dart';
import 'package:boorusama/boorus/danbooru/presentation/features/comment/comment_page.dart';

final _isFavedProvider =
    FutureProvider.autoDispose.family<bool, int>((ref, postId) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final repo = ref.watch(favoriteProvider);
  final account = await ref.watch(accountProvider).get();
  final isFaved = repo.checkIfFavoritedByUser(account.id, postId);

  ref.maintainState = true;
  return isFaved;
});

class PostActionToolbar extends HookWidget {
  const PostActionToolbar({
    Key? key,
    required this.post,
  }) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    // final comments = useProvider(_commentsProvider(post.id));
    final isLoggedIn = useProvider(isLoggedInProvider);

    bool displayNoticeIfNotLoggedIn() {
      if (!isLoggedIn) {
        final snackbar = SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 6.0,
          content: Text(
            'You need to log in to perform this action',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
        return false;
      }
      return true;
    }

    final isFaved = useProvider(_isFavedProvider(post.id));
    final favCount = useState(post.favCount);

    final buttons = <Widget>[
      // TextButton.icon(
      //     onPressed: () {},
      //     icon: FaIcon(FontAwesomeIcons.thumbsUp, color: Colors.white),
      //     label: Text(
      //       post.upScore.toString(),
      //       style: TextStyle(color: Colors.white),
      //     )),
      // TextButton.icon(
      //     onPressed: () {},
      //     icon: FaIcon(
      //       FontAwesomeIcons.thumbsDown,
      //       color: Colors.white,
      //     ),
      //     label: Text(
      //       post.downScore.toString(),
      //       style: TextStyle(color: Colors.white),
      //     )),
      IconButton(
        onPressed: () => showBarModalBottomSheet(
          expand: false,
          context: context,
          builder: (context) => CommentPage(
            postId: post.id,
          ),
        ),
        icon: FaIcon(
          FontAwesomeIcons.comment,
          color: Colors.white,
        ),
      ),
    ];
    if (isLoggedIn) {
      final button = isFaved.when(
          data: (value) {
            final button = TextButton.icon(
                onPressed: () {
                  isFaved.whenData((value) async {
                    final result = value
                        ? context
                            .read(favoriteProvider)
                            .removeFromFavorites(post.id)
                        : context
                            .read(favoriteProvider)
                            .addToFavorites(post.id);

                    await result;
                    context.refresh(_isFavedProvider(post.id));
                  });
                },
                icon: value
                    ? FaIcon(FontAwesomeIcons.solidHeart, color: Colors.red)
                    : FaIcon(
                        FontAwesomeIcons.heart,
                        color: Colors.white,
                      ),
                label: Text(
                  favCount.value.toString(),
                  style: TextStyle(color: Colors.white),
                ));
            return button;
          },
          loading: () => Center(
                child: TextButton.icon(
                    onPressed: null,
                    icon: FaIcon(
                      FontAwesomeIcons.spinner,
                      color: Colors.white,
                    ),
                    label: Text(
                      post.favCount.toString(),
                      style: TextStyle(color: Colors.white),
                    )),
              ),
          error: (e, m) => SizedBox.shrink());
      buttons.add(button);
    }

    return ButtonBar(
        alignment: MainAxisAlignment.spaceEvenly, children: buttons);
  }
}
