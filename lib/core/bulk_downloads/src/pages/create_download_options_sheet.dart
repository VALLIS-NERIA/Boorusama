// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';

// Project imports:
import '../../../downloads/l10n.dart' as d;
import '../../../downloads/widgets/download_folder_selector_section.dart';
import '../../../foundation/toast.dart';
import '../../../info/device_info.dart';
import '../../../settings/providers.dart';
import '../../../settings/settings.dart';
import '../../../settings/widgets.dart';
import '../../../theme.dart';
import '../../../widgets/drag_line.dart';
import '../providers/bulk_download_notifier.dart';
import '../providers/create_download_options_notifier.dart';
import '../routes/route_utils.dart';
import '../routes/routes.dart';
import '../types/bulk_download_error.dart';
import '../types/download_options.dart';
import '../types/l10n.dart';
import '../widgets/bulk_download_tag_list.dart';

class CreateDownloadOptionsSheet extends ConsumerWidget {
  const CreateDownloadOptionsSheet({
    required this.initialValue,
    super.key,
    this.prevRouteName,
  });

  final List<String>? initialValue;
  final String? prevRouteName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    void showSnackBar(String message) {
      if (prevRouteName != kBulkdownload) {
        showSimpleSnackBar(
          context: context,
          content: Text(message),
          action: SnackBarAction(
            label: 'generic.view'.tr(),
            textColor: colorScheme.surface,
            onPressed: () {
              goToBulkDownloadManagerPage(context);
            },
          ),
        );
      }
    }

    final notifier = ref.watch(bulkDownloadProvider.notifier);
    final quality =
        ref.watch(settingsProvider.select((e) => e.downloadQuality));
    final initial = DownloadOptions.initial(
      quality: quality.name,
      tags: initialValue,
    );
    final options = ref.watch(createDownloadOptionsProvider(initial));
    final androidSdkInt = ref.watch(
      deviceInfoProvider
          .select((value) => value.androidDeviceInfo?.version.sdkInt),
    );
    final validOptions = options.valid(androidSdkInt: androidSdkInt);

    return CreateDownloadOptionsRawSheet(
      initial: initial,
      actions: Row(
        spacing: 16,
        children: [
          Expanded(
            child: ElevatedButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: validOptions
                      ? BorderSide(
                          color: colorScheme.outline,
                        )
                      : BorderSide.none,
                ),
              ),
              onPressed: validOptions
                  ? () {
                      notifier.queueDownloadLater(options);
                      showSnackBar('Created');

                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text(
                DownloadTranslations.addToQueue,
              ).tr(),
            ),
          ),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              onPressed: validOptions
                  ? () {
                      try {
                        notifier.downloadFromOptions(options);
                        showSnackBar('Download started');

                        Navigator.of(context).pop();
                      } on BulkDownloadOptionsError catch (e) {
                        showErrorToast(context, e.message);
                      }
                    }
                  : null,
              child: const Text(
                DownloadTranslations.download,
              ).tr(),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateDownloadOptionsRawSheet extends ConsumerStatefulWidget {
  const CreateDownloadOptionsRawSheet({
    required this.initial,
    required this.actions,
    super.key,
    this.advancedToggle = true,
  });

  final DownloadOptions initial;
  final Widget actions;
  final bool advancedToggle;

  @override
  ConsumerState<CreateDownloadOptionsRawSheet> createState() =>
      _CreateDownloadOptionsRawSheetState();
}

class _CreateDownloadOptionsRawSheetState
    extends ConsumerState<CreateDownloadOptionsRawSheet> {
  var advancedOptions = false;

  @override
  Widget build(BuildContext context) {
    final params = widget.initial;
    final notifier = ref.watch(createDownloadOptionsProvider(params).notifier);
    final options = ref.watch(createDownloadOptionsProvider(params));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final showAll = switch (widget.advancedToggle) {
      true => advancedOptions,
      false => true,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DragLine(),
                  ],
                ),
              ),
              BulkDownloadTagList(
                tags: options.tags,
                onSubmit: notifier.addTag,
                onRemove: notifier.removeTag,
                onHistoryTap: notifier.addFromSearchHistory,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: DownloadFolderSelectorSection(
                  title: Text(
                    DownloadTranslations.saveToFolder.tr().toUpperCase(),
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.hintColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  storagePath: options.path,
                  deviceInfo: ref.watch(deviceInfoProvider),
                  onPathChanged: (path) {
                    notifier.setPath(path);
                  },
                  hint: DownloadTranslations.selectFolder.tr(),
                ),
              ),
              if (widget.advancedToggle)
                SwitchListTile(
                  title: const Text(
                    DownloadTranslations.showAdvancedOptions,
                  ).tr(),
                  value: advancedOptions,
                  onChanged: (value) {
                    setState(() {
                      advancedOptions = value;
                    });
                  },
                ),
              if (showAll || advancedOptions) ...[
                SwitchListTile(
                  title: const Text(
                    DownloadTranslations.enableNotifications,
                  ).tr(),
                  value: options.notifications,
                  onChanged: (value) {
                    notifier.setNotifications(value);
                  },
                ),
                SwitchListTile(
                  title: const Text(d.DownloadTranslations.skipDownloadIfExists)
                      .tr(),
                  value: options.skipIfExists,
                  onChanged: (value) {
                    notifier.setSkipIfExists(value);
                  },
                ),
                SettingsTile(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('settings.download.quality').tr(),
                  selectedOption:
                      options.quality ?? DownloadQuality.original.name,
                  items: DownloadQuality.values.map((e) => e.name).toList(),
                  onChanged: (value) {
                    notifier.setQuality(value);
                  },
                  optionBuilder: (value) =>
                      Text('settings.download.qualities.$value').tr(),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: widget.actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
