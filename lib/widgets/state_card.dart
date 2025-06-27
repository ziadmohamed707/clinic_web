import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're in mobile, tablet, or desktop mode
        final isDesktop = constraints.maxWidth > 600;
        final isTablet = constraints.maxWidth > 400 && constraints.maxWidth <= 600;
        final isMobile = constraints.maxWidth <= 400;

        // Calculate responsive values
        final cardPadding = _getCardPadding(isDesktop, isTablet);
        final cardMargin = _getCardMargin(isDesktop);
        final iconSize = _getIconSize(isDesktop, isTablet);
        final verticalSpacing = _getVerticalSpacing(isDesktop, isTablet);
        
        return Card(
          margin: cardMargin,
          color: color.withOpacity(0.1),
          elevation: isDesktop ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
          ),
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
                SizedBox(height: verticalSpacing.small),
                Flexible(
                  child: Text(
                    title,
                    style: _getTitleStyle(context, isDesktop, isTablet),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: verticalSpacing.medium),
                Flexible(
                  child: Text(
                    value,
                    style: _getValueStyle(context, isDesktop, isTablet),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _getCardPadding(bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(8.0);
    }
  }

  EdgeInsets _getCardMargin(bool isDesktop) {
    return isDesktop 
        ? const EdgeInsets.all(8.0) 
        : const EdgeInsets.all(4.0);
  }

  double _getIconSize(bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return 32.0;
    } else if (isTablet) {
      return 24.0;
    } else {
      return 20.0;
    }
  }

  ({double small, double medium}) _getVerticalSpacing(bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return (small: 12.0, medium: 8.0);
    } else if (isTablet) {
      return (small: 8.0, medium: 4.0);
    } else {
      return (small: 4.0, medium: 2.0);
    }
  }

  TextStyle? _getTitleStyle(BuildContext context, bool isDesktop, bool isTablet) {
    final theme = Theme.of(context);
    
    if (isDesktop) {
      return theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: color,
      );
    } else if (isTablet) {
      return theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: color,
      );
    } else {
      return theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: color,
      );
    }
  }

  TextStyle? _getValueStyle(BuildContext context, bool isDesktop, bool isTablet) {
    final theme = Theme.of(context);
    
    if (isDesktop) {
      return theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: color,
      );
    } else if (isTablet) {
      return theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: color,
      );
    } else {
      return theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: color,
      );
    }
  }
}
