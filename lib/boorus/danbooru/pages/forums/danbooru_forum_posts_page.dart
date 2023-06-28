// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

// Project imports:
import 'package:boorusama/boorus/core/feats/boorus/providers.dart';
import 'package:boorusama/boorus/core/feats/dtext/html_converter.dart';
import 'package:boorusama/boorus/core/utils.dart';
import 'package:boorusama/boorus/danbooru/feats/forums/forums.dart';
import 'package:boorusama/boorus/danbooru/pages/forums/forum_post_header.dart';
import 'package:boorusama/boorus/danbooru/router.dart';
import 'danbooru_forum_vote_chip.dart';

class DanbooruForumPostsPage extends ConsumerWidget {
  const DanbooruForumPostsPage({
    super.key,
    required this.topicId,
    required this.originalPostId,
  });

  final int topicId;
  final int originalPostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booru = ref.watch(currentBooruProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Posts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RiverPagedBuilder.autoDispose(
        firstPageProgressIndicatorBuilder: (context, controller) =>
            const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        pullToRefresh: false,
        firstPageKey: originalPostId,
        provider: danbooruForumPostsProvider(topicId),
        itemBuilder: (context, post, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ForumPostHeader(
                authorName: post.creator.name,
                createdAt: post.createdAt,
                authorLevel: post.creator.level,
                onTap: () =>
                    goToUserDetailsPage(ref, context, uid: post.creator.id),
              ),
              Html(
                onLinkTap: (url, context, attributes, element) =>
                    url != null ? launchExternalUrlString(url) : null,
                style: {
                  'body': Style(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                  'blockquote': Style(
                    padding: const EdgeInsets.only(left: 8),
                    margin: const EdgeInsets.only(left: 4, bottom: 16),
                    border: const Border(
                        left: BorderSide(color: Colors.grey, width: 3)),
                  )
                },
                data: dtext(post.body, booru: booru),
              ),
              const SizedBox(height: 8),
              if (post.votes.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: post.votes
                      .map((e) => ForumVoteChip(
                            icon: switch (e.type) {
                              DanbooruForumPostVoteType.upvote => Icon(
                                  Icons.arrow_upward,
                                  color: _iconColor(e.type),
                                ),
                              DanbooruForumPostVoteType.downvote => Icon(
                                  Icons.arrow_downward,
                                  color: _iconColor(e.type),
                                ),
                              DanbooruForumPostVoteType.unsure => Container(
                                  margin: const EdgeInsets.all(4),
                                  child: FaIcon(
                                    FontAwesomeIcons.faceMeh,
                                    size: 16,
                                    color: _iconColor(e.type),
                                  ),
                                ),
                            },
                            color: _color(e.type),
                            borderColor: _borderColor(e.type),
                            label: Text(e.creatorId.toString()),
                          ))
                      .toList(),
                )
            ],
          ),
        ),
        pagedBuilder: (controller, builder) => PagedListView(
          pagingController: controller,
          builderDelegate: builder,
        ),
      ),
    );
  }
}

Color _color(DanbooruForumPostVoteType type) => switch (type) {
      DanbooruForumPostVoteType.upvote => const Color(0xff01370a),
      DanbooruForumPostVoteType.downvote => const Color(0xff5c1212),
      DanbooruForumPostVoteType.unsure => const Color(0xff382c00),
    };

Color _borderColor(DanbooruForumPostVoteType type) => switch (type) {
      DanbooruForumPostVoteType.upvote => const Color(0xff016f19),
      DanbooruForumPostVoteType.downvote => const Color(0xffc10105),
      DanbooruForumPostVoteType.unsure => const Color(0xff675403),
    };

Color _iconColor(DanbooruForumPostVoteType type) => switch (type) {
      DanbooruForumPostVoteType.upvote => const Color(0xff01aa2d),
      DanbooruForumPostVoteType.downvote => const Color(0xffff5b5a),
      DanbooruForumPostVoteType.unsure => const Color(0xffdac278),
    };
