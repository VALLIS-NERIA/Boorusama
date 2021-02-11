// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_tags/flutter_tags.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/all.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/search/query_state_notifier.dart';
import 'package:boorusama/boorus/danbooru/application/search/search_state_notifier.dart';
import 'package:boorusama/boorus/danbooru/application/search/suggestions_state_notifier.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/domain/tags/tag.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/services/download_service.dart';
import 'package:boorusama/boorus/danbooru/presentation/shared/infinite_load_list.dart';
import 'package:boorusama/boorus/danbooru/presentation/shared/search_bar.dart';
import 'package:boorusama/boorus/danbooru/presentation/shared/sliver_post_grid_placeholder.dart';
import 'package:boorusama/core/application/list_item_status.dart';
import 'tag_suggestion_items.dart';

part 'search_page.freezed.dart';

final _searchDisplayProvider =
    StateProvider.autoDispose<SearchDisplayState>((ref) {
  final status = SearchDisplayState.suggestions();
  print("Display status: $status");
  return status;
});

final _itemStatus = Provider<ListItemStatus<Post>>(
    (ref) => ref.watch(searchStateNotifierProvider.state).posts.status);
final _postStatusProvider = Provider<ListItemStatus<Post>>((ref) {
  final status = ref.watch(_itemStatus);
  print("Search monitoring status: $status");
  return status;
});

final _posts = Provider.autoDispose<List<Post>>(
    (ref) => ref.watch(searchStateNotifierProvider.state).posts.items);
final _postProvider = Provider.autoDispose<List<Post>>((ref) {
  final posts = ref.watch(_posts);
  return posts;
});

final _query = Provider.autoDispose<String>(
    (ref) => ref.watch(queryStateNotifierProvider.state).query);
final _queryProvider = Provider.autoDispose<String>((ref) {
  final query = ref.watch(_query);
  print("Search query: $query");
  return query;
});

final _tags = Provider.autoDispose<List<Tag>>(
    (ref) => ref.watch(suggestionsStateNotifier.state).tags);
final _tagProvider = Provider.autoDispose<List<Tag>>((ref) {
  final tags = ref.watch(_tags);
  return tags;
});

final _suggestionsMonitoring = Provider.autoDispose<SuggestionsMonitoringState>(
    (ref) =>
        ref.watch(suggestionsStateNotifier.state).suggestionsMonitoringState);
final _suggestionsMonitoringStateProvider =
    Provider.autoDispose<SuggestionsMonitoringState>((ref) {
  final status = ref.watch(_suggestionsMonitoring);
  print("Tag suggestion monitoring status: $status");
  return status;
});

final _completedQueryItems = Provider.autoDispose<List<String>>((ref) {
  return ref.watch(queryStateNotifierProvider.state).completedQueryItems;
});
final _completedQueryItemsProvider = Provider.autoDispose<List<String>>((ref) {
  final completedQueryItems = ref.watch(_completedQueryItems);

  if (completedQueryItems.isEmpty) {
    final searchDisplay = ref.watch(_searchDisplayProvider);
    Future.delayed(Duration.zero, () {
      if (searchDisplay.mounted) {
        searchDisplay.state = SearchDisplayState.suggestions();
      }
    });
  }

  return completedQueryItems;
});

class SearchPage extends HookWidget {
  const SearchPage({Key key, this.initialQuery}) : super(key: key);

  final String initialQuery;

  void _onTagItemTapped(BuildContext context, String tag) =>
      context.read(queryStateNotifierProvider).add(tag);

  void _onClearQueryButtonPressed(BuildContext context,
      StateController<SearchDisplayState> searchDisplayState) {
    context.read(searchStateNotifierProvider).clear();
    context.read(suggestionsStateNotifier).clear();
    context.read(queryStateNotifierProvider).clear();
  }

  void _onBackIconPressed(BuildContext context) {
    context.read(searchStateNotifierProvider).clear();
    context.read(suggestionsStateNotifier).clear();
    context.read(queryStateNotifierProvider).clear();
    Navigator.of(context).pop();
  }

  void _onDownloadButtonPressed(List<Post> posts, BuildContext context) {
    return posts
        .forEach((post) => useProvider(downloadServiceProvider).download(post));
  }

  void _onQueryUpdated(BuildContext context, String value,
      StateController<SearchDisplayState> searchDisplayState) {
    if (searchDisplayState.state == SearchDisplayState.results()) {
      searchDisplayState.state = SearchDisplayState.suggestions();
    }
    context.read(queryStateNotifierProvider).update(value);
  }

  bool _onTagRemoveButtonTap(
      BuildContext context, List<String> completedQueryItems, int index) {
    context.read(queryStateNotifierProvider).remove(completedQueryItems[index]);
    context.read(searchStateNotifierProvider).search();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final queryEditingController = useTextEditingController();
    final refreshController = useState(RefreshController());

    final searchDisplayState = useProvider(_searchDisplayProvider);
    final postStatus = useProvider(_postStatusProvider);
    final posts = useProvider(_postProvider);
    final query = useProvider(_queryProvider);

    final gridKey = useState(GlobalKey());

    final suggestionsMonitoringState =
        useProvider(_suggestionsMonitoringStateProvider);
    final tags = useProvider(_tagProvider);

    final completedQueryItems = useProvider(_completedQueryItemsProvider);

    final scrollController = useState(AutoScrollController());
    useEffect(() {
      queryEditingController.text = query;
      queryEditingController.selection =
          TextSelection.fromPosition(TextPosition(offset: query.length));
      return () => {};
    }, [query]);

    useEffect(() {
      if (initialQuery.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          context.read(queryStateNotifierProvider).add(initialQuery);
        });
      }
      return null;
    }, []);

    useEffect(() {
      return () => scrollController.value.dispose;
    }, []);

    return SafeArea(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Scaffold(
          floatingActionButton: searchDisplayState.state.when(
            suggestions: () => FloatingActionButton(
              onPressed: () {
                if (completedQueryItems.isEmpty) {
                  context.read(queryStateNotifierProvider).add(query);
                }

                FocusScope.of(context).unfocus();
                searchDisplayState.state = SearchDisplayState.results();
                context.read(searchStateNotifierProvider).search();
              },
              heroTag: null,
              child: Icon(Icons.search),
            ),
            results: () => FloatingActionButton(
              onPressed: () => _onDownloadButtonPressed(posts, context),
              heroTag: null,
              child: Icon(Icons.download_sharp),
            ),
          ),
          appBar: AppBar(
            toolbarHeight: kToolbarHeight * 1.2,
            elevation: 0,
            shadowColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: SearchBar(
              autofocus: true,
              queryEditingController: queryEditingController,
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => _onBackIconPressed(context),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: () =>
                    _onClearQueryButtonPressed(context, searchDisplayState),
              ),
              onChanged: (value) =>
                  _onQueryUpdated(context, value, searchDisplayState),
            ),
          ),
          body: Column(
            children: [
              if (completedQueryItems.length > 0) ...[
                Tags(
                  horizontalScroll: true,
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  itemCount: completedQueryItems.length,
                  itemBuilder: (index) => ItemTags(
                    index: index,
                    title: completedQueryItems[index].replaceAll('_', ' '),
                    pressEnabled: false,
                    removeButton: ItemTagsRemoveButton(
                        onRemoved: () => _onTagRemoveButtonTap(
                            context, completedQueryItems, index)),
                  ),
                ),
                Divider(
                  height: 0,
                  thickness: 3,
                  indent: 10,
                  endIndent: 10,
                ),
              ],
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      child: searchDisplayState.state.when(
                        suggestions: () => suggestionsMonitoringState.when(
                          none: () => SizedBox.shrink(),
                          inProgress: () => Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: TagSuggestionItems(
                                tags: tags, onItemTap: (tag) {}),
                          ),
                          completed: () => Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: TagSuggestionItems(
                                tags: tags,
                                onItemTap: (tag) =>
                                    _onTagItemTapped(context, tag)),
                          ),
                          error: () =>
                              Center(child: Text("Something went wrong")),
                        ),
                        results: () => postStatus.maybeWhen(
                          orElse: () => postStatus.maybeWhen(
                            refreshing: () => CustomScrollView(
                              slivers: [
                                SliverPadding(
                                    padding: EdgeInsets.all(6.0),
                                    sliver: SliverPostGridPlaceHolder()),
                              ],
                            ),
                            orElse: () => ProviderListener(
                              provider: searchStateNotifierProvider,
                              onChange: (context, state) {
                                state.maybeWhen(
                                  fetched: () {
                                    refreshController.value.loadComplete();

                                    refreshController.value.refreshCompleted();
                                  },
                                  error: () => Scaffold.of(context)
                                      .showSnackBar(SnackBar(
                                          content:
                                              Text("Something went wrong"))),
                                  orElse: () {},
                                );
                              },
                              child: InfiniteLoadList(
                                onLoadMore: () => context
                                    .read(searchStateNotifierProvider)
                                    .getMoreResult(),
                                onItemChanged: (index) {
                                  if (index > posts.length * 0.8) {
                                    context
                                        .read(searchStateNotifierProvider)
                                        .getMoreResult();
                                  }
                                },
                                scrollController: scrollController.value,
                                gridKey: gridKey.value,
                                posts: posts,
                                refreshController: refreshController.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@freezed
abstract class SearchDisplayState with _$SearchDisplayState {
  const factory SearchDisplayState.results() = _Results;

  const factory SearchDisplayState.suggestions() = _Suggestions;
}
