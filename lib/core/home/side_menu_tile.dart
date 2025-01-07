// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:boorusama/foundation/theme.dart';

class SideMenuTile extends StatelessWidget {
  const SideMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.popOnSelect = true,
  });

  final Widget icon;
  final Widget title;
  final VoidCallback onTap;
  final bool popOnSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        child: InkWell(
          onTap: () {
            onTap();
            if (popOnSelect) {
              Navigator.of(context).maybePop();
            }
          },
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: DefaultTextStyle(
            style: context.textTheme.titleSmall ?? const TextStyle(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 4,
              ),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 12),
                  title,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
