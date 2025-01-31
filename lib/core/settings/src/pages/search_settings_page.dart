// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';

// Project imports:
import '../../../configs/redirect.dart';
import '../providers/settings_notifier.dart';
import '../providers/settings_provider.dart';
import '../types/types.dart';
import '../widgets/settings_page_scaffold.dart';

class SearchSettingsPage extends ConsumerStatefulWidget {
  const SearchSettingsPage({
    super.key,
  });

  @override
  ConsumerState<SearchSettingsPage> createState() => _SearchSettingsPageState();
}

class _SearchSettingsPageState extends ConsumerState<SearchSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifer = ref.watch(settingsNotifierProvider.notifier);

    return SettingsPageScaffold(
      title: const Text('settings.search.search').tr(),
      children: [
        ListTile(
          title: const Text('settings.search.auto_focus_search_bar').tr(),
          trailing: Switch(
            value: settings.autoFocusSearchBar,
            onChanged: (value) {
              notifer.updateSettings(
                settings.copyWith(
                  autoFocusSearchBar: value,
                ),
              );
            },
          ),
        ),
        ListTile(
          title: const Text('Persistent search bar').tr(),
          subtitle:
              const Text('Keep the search bar visible while scrolling.').tr(),
          trailing: Switch(
            value: settings.persistSearchBar,
            onChanged: (value) {
              notifer.updateSettings(
                settings.copyWith(
                  searchBarScrollBehavior: value
                      ? SearchBarScrollBehavior.persistent
                      : SearchBarScrollBehavior.autoHide,
                ),
              );
            },
          ),
        ),
        ListTile(
          title: const Text(
            'settings.search.hide_bookmarked_posts_from_search_results',
          ).tr(),
          trailing: Switch(
            activeColor: Theme.of(context).colorScheme.primary,
            value: settings.shouldFilterBookmarks,
            onChanged: (value) {
              notifer.updateSettings(
                settings.copyWith(
                  bookmarkFilterType: value
                      ? BookmarkFilterType.hideAll
                      : BookmarkFilterType.none,
                ),
              );
            },
          ),
        ),
        const BooruConfigMoreSettingsRedirectCard.search(),
      ],
    );
  }
}
