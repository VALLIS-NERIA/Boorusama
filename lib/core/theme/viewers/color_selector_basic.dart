// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';

// Project imports:
import '../../foundation/platform.dart';
import '../colors.dart';
import 'theme_previewer_notifier.dart';
import 'theme_widgets.dart';

class BasicColorSelector extends ConsumerWidget {
  const BasicColorSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(themePreviewerProvider.notifier);
    final currentColors = ref.watch(themePreviewerColorsProvider);
    final enableDynamicColoring = currentColors.enableDynamicColoring;
    final dynamicColorSupported = ref.watch(dynamicColorSupportProvider);
    final basicColors = ref.watch(
      themePreviewerProvider.select(
        (value) => value.basicColors,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 8,
            children: [
              ...basicColors.map((colors) {
                final selected = colors.name == currentColors.name;
                final colorScheme = notifier.getSchemeFromColorSettings(colors);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: PreviewColorContainer(
                    followSystem: colors.followSystemDarkMode == true,
                    primary: colorScheme?.primary ?? Colors.transparent,
                    onSurface: colorScheme?.onSurface ?? Colors.transparent,
                    onTap: () {
                      notifier.updateColors(
                        colors.copyWith(
                          enableDynamicColoring: enableDynamicColoring,
                        ),
                      );
                    },
                    selected: selected,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('settings.theme.dynamic_color').tr(),
            subtitle: dynamicColorSupported
                ? !isDesktopPlatform()
                    ? const Text(
                        'settings.theme.dynamic_color_mobile_description',
                      ).tr()
                    : const Text(
                        'settings.theme.dynamic_color_desktop_description',
                      ).tr()
                : Text(
                    '${!isDesktopPlatform() ? 'settings.theme.dynamic_color_mobile_description'.tr() : 'settings.theme.dynamic_color_desktop_description'.tr()}. ${'settings.theme.dynamic_color_unsupported_description'.tr()}',
                  ),
            value: enableDynamicColoring,
            onChanged: dynamicColorSupported
                ? (value) => notifier.updateColors(
                      currentColors.copyWith(
                        enableDynamicColoring: value,
                      ),
                    )
                : null,
          ),
        ],
      ),
    );
  }
}
