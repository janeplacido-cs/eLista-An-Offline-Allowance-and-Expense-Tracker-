import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = AppTextStyles.of(context);

    return Padding(
      padding: AppLayout.headerPadding,
      child: SizedBox(
        height: AppLayout.headerRowHeight,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyles.screenTitle,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppLayout.headerTrailingSpacing),
              SizedBox(
                width: AppLayout.headerTrailingSize,
                height: AppLayout.headerTrailingSize,
                child: Material(
                  color: colors.surfaceContainerLow,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: trailing,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
