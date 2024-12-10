// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../core/configs/ref.dart';
import '../../../core/home/home_navigation_tile.dart';
import '../../../core/home/home_page_scaffold.dart';
import '../../../core/home/side_menu_tile.dart';
import '../../../core/router.dart';
import '../../../core/widgets/widgets.dart';
import 'moebooru_popular_page.dart';
import 'moebooru_popular_recent_page.dart';

class MoebooruHomePage extends ConsumerStatefulWidget {
  const MoebooruHomePage({
    super.key,
  });

  @override
  ConsumerState<MoebooruHomePage> createState() => _MoebooruHomePageState();
}

class _MoebooruHomePageState extends ConsumerState<MoebooruHomePage> {
  @override
  Widget build(BuildContext context) {
    final config = ref.watchConfigAuth;

    return HomePageScaffold(
      mobileMenu: [
        SideMenuTile(
          icon: const Icon(
            Symbols.explore,
            fill: 1,
          ),
          title: const Text('Popular'),
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const Text('Popular'),
                ),
                body: const CustomContextMenuOverlay(
                  child: MoebooruPopularPage(),
                ),
              ),
            ),
          ),
        ),
        SideMenuTile(
          icon: const Icon(
            Symbols.local_fire_department,
            fill: 1,
          ),
          title: const Text('Hot'),
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const Text('Hot'),
                ),
                body: const CustomContextMenuOverlay(
                  child: MoebooruPopularRecentPage(),
                ),
              ),
            ),
          ),
        ),
        if (config.hasLoginDetails()) ...[
          SideMenuTile(
            icon: const Icon(
              Symbols.favorite,
              fill: 1,
            ),
            title: Text('profile.favorites'.tr()),
            onTap: () {
              goToFavoritesPage(context);
            },
          ),
        ],
      ],
      desktopMenuBuilder: (context, controller, constraints) => [
        HomeNavigationTile(
          value: 1,
          controller: controller,
          constraints: constraints,
          selectedIcon: Symbols.explore,
          icon: Symbols.explore,
          title: 'Popular',
        ),
        HomeNavigationTile(
          value: 2,
          controller: controller,
          constraints: constraints,
          selectedIcon: Symbols.local_fire_department,
          icon: Symbols.local_fire_department,
          title: 'Hot',
        ),
      ],
      desktopViews: const [
        MoebooruPopularPage(),
        MoebooruPopularRecentPage(),
      ],
    );
  }
}
