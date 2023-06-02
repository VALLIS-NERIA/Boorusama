// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/pools.dart';
import 'package:boorusama/boorus/danbooru/ui/pool/pool_grid_item.dart';
import 'pool_options_header.dart';
import 'pool_search_button.dart';

class PoolPage extends StatelessWidget {
  const PoolPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('pool.pool_gallery').tr(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          PoolSearchButton(),
        ],
      ),
      body: const SafeArea(
        bottom: false,
        child: _PostList(),
      ),
    );
  }
}

class _PostList extends ConsumerWidget {
  const _PostList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PoolOptionsHeader(),
        ),
        RiverPagedBuilder.autoDispose(
          firstPageProgressIndicatorBuilder: (context, controller) =>
              const CircularProgressIndicator.adaptive(),
          pullToRefresh: false,
          firstPageKey: const PoolKey(page: 1),
          provider: danbooruPoolsProvider,
          itemBuilder: (context, pool, index) => PoolGridItem(pool: pool),
          pagedBuilder: (controller, builder) => PagedSliverGrid(
            pagingController: controller,
            builderDelegate: builder,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}
