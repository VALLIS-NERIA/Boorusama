// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../blacklists/routes.dart';
import '../bookmarks/routes.dart';
import '../configs/widgets.dart';
import '../downloads/routes.dart';
import '../settings/providers.dart';
import '../settings/routes.dart';
import '../settings/settings.dart';
import '../tags/favorites/routes.dart';
import 'side_menu_tile.dart';

class SideBarMenu extends ConsumerWidget {
  const SideBarMenu({
    super.key,
    this.width,
    this.popOnSelect = false,
    this.initialContent,
    this.content,
    this.padding,
  });

  final double? width;
  final EdgeInsets? padding;
  final bool popOnSelect;
  final List<Widget>? initialContent;
  final List<Widget>? content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(
      settingsProvider.select((value) => value.booruConfigSelectorPosition),
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navigator = Navigator.of(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Container(
      color: colorScheme.surfaceContainerLow,
      constraints: BoxConstraints.expand(
        width: min(MediaQuery.sizeOf(context).width * 0.85, 400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (position == BooruConfigSelectorPosition.side)
            ColoredBox(
              color: colorScheme.surface,
              child: const SafeArea(
                bottom: false,
                child: BooruSelector(),
              ),
            ),
          VerticalDivider(
            color: colorScheme.outlineVariant,
            thickness: 0.25,
            width: 1,
          ),
          Expanded(
            child: ColoredBox(
              color: colorScheme.surfaceContainerLow,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (initialContent != null)
                      SizedBox(
                        height: viewPadding.top,
                      )
                    else
                      const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CurrentBooruTile(),
                    ),
                    if (initialContent != null)
                      ...initialContent!.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: e,
                        ),
                      ),
                    if (initialContent != null)
                      const Divider(
                        thickness: 0.75,
                      ),
                    if (content != null) ...[
                      ...content!.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: e,
                        ),
                      ),
                    ] else
                      ...[
                        SideMenuTile(
                          icon: const Icon(Symbols.favorite),
                          title: const Text('sideMenu.your_bookmarks').tr(),
                          onTap: () {
                            if (popOnSelect) navigator.pop();
                            goToBookmarkPage(context);
                          },
                        ),
                        SideMenuTile(
                          icon: const Icon(Symbols.list),
                          title: const Text('sideMenu.your_blacklist').tr(),
                          onTap: () {
                            if (popOnSelect) navigator.pop();
                            goToGlobalBlacklistedTagsPage(context);
                          },
                        ),
                        SideMenuTile(
                          icon: const Icon(Symbols.tag),
                          title: const Text('favorite_tags.favorite_tags').tr(),
                          onTap: () {
                            if (popOnSelect) navigator.pop();
                            goToFavoriteTagsPage(context);
                          },
                        ),
                        SideMenuTile(
                          icon: const Icon(Symbols.sim_card_download),
                          title: const Text('sideMenu.bulk_download').tr(),
                          onTap: () {
                            if (popOnSelect) navigator.pop();
                            goToBulkDownloadPage(
                              context,
                              null,
                              ref: ref,
                            );
                          },
                        ),
                        SideMenuTile(
                          icon: const Icon(Symbols.download),
                          title: const Text('Download manager'),
                          onTap: () {
                            if (popOnSelect) navigator.pop();
                            goToDownloadManagerPage(context);
                          },
                        ),
                        const Divider(
                          key: ValueKey('divider'),
                          thickness: 0.75,
                        ),
                        SideMenuTile(
                          icon: const Icon(
                            Symbols.question_mark,
                            fill: 1,
                          ),
                          title: const Text('sideMenu.get_support').tr(),
                          onTap: () {
                            if (popOnSelect) navigator.pop();
                            goToSettingsPage(context, scrollTo: 'support');
                          },
                        ),
                        SideMenuTile(
                          icon: const Icon(
                            Symbols.settings,
                            fill: 1,
                          ),
                          title: Text('sideMenu.settings'.tr()),
                          onTap: () {
                            if (popOnSelect) navigator.pop();
                            goToSettingsPage(context);
                          },
                        ),
                      ].map(
                        (e) => Padding(
                          padding: e.key != const ValueKey('divider')
                              ? const EdgeInsets.symmetric(horizontal: 8)
                              : EdgeInsets.zero,
                          child: e,
                        ),
                      ),
                    SizedBox(
                      height: viewPadding.bottom + 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
