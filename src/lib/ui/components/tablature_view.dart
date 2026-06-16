import 'package:flutter/material.dart';

class TablatureView extends StatelessWidget {
  final String content;
  final double fontSize;

  const TablatureView({
    super.key,
    required this.content,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Split the content into individual string lines
    final rawLines = content.split('\n').where((l) => l.isNotEmpty).toList();
    if (rawLines.isEmpty) return const SizedBox.shrink();

    // 1. For each line, extract the tuning prefix (everything up to the first '|') and the tab content.
    final List<String> prefixes = [];
    final List<String> tabContents = [];
    int maxPrefixLen = 0;
    int maxTabContentLen = 0;

    for (final line in rawLines) {
      final pipeIndex = line.indexOf('|');
      if (pipeIndex != -1) {
        final prefix = line.substring(0, pipeIndex + 1);
        final tabContent = line.substring(pipeIndex + 1);
        prefixes.add(prefix);
        tabContents.add(tabContent);
        if (prefix.length > maxPrefixLen) {
          maxPrefixLen = prefix.length;
        }
        if (tabContent.length > maxTabContentLen) {
          maxTabContentLen = tabContent.length;
        }
      } else {
        prefixes.add('');
        tabContents.add(line);
        if (line.length > maxTabContentLen) {
          maxTabContentLen = line.length;
        }
      }
    }

    // 2. Pad prefixes and tab contents so everything is perfectly aligned
    final List<String> alignedPrefixes = [];
    final List<String> alignedTabContents = [];

    for (int i = 0; i < rawLines.length; i++) {
      final prefix = prefixes[i];
      final tabContent = tabContents[i];

      // Pad prefix to the left so that the first '|' character aligns
      final paddedPrefix = prefix.padLeft(maxPrefixLen);
      alignedPrefixes.add(paddedPrefix);

      // Pad tab contents with spaces to the max length
      final paddedTabContent = tabContent.padRight(maxTabContentLen);
      alignedTabContents.add(paddedTabContent);
    }

    // We render using a LayoutBuilder to dynamically measure character width and wrap
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure the width of a single character in SpaceMono font
        final textPainter = TextPainter(
          text: TextSpan(
            text: '-',
            style: TextStyle(fontSize: fontSize, fontFamily: 'SpaceMono'),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final charWidth = textPainter.width;

        // Account for horizontal padding and borders in the container
        const double paddingWidth = 24.0;
        final double availableWidth = constraints.maxWidth - paddingWidth;

        // Calculate max characters per line
        int maxChars = (availableWidth / charWidth).floor();
        if (maxChars < 15) maxChars = 15; // fallback minimum

        // The number of characters available for the tab content itself
        final int contentMaxChars = maxChars - maxPrefixLen;
        if (contentMaxChars <= 0) {
          // Fallback if the prefix itself is wider than available space
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(rawLines.length, (i) {
                return Text(
                  alignedPrefixes[i] + alignedTabContents[i],
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: fontSize,
                    fontFamily: 'SpaceMono',
                  ),
                );
              }),
            ),
          );
        }

        // 3. Slice the tab content into multiple blocks
        final List<Widget> slices = [];
        int start = 0;

        while (start < maxTabContentLen) {
          final int end = (start + contentMaxChars < maxTabContentLen)
              ? start + contentMaxChars
              : maxTabContentLen;

          slices.add(
            Padding(
              padding: EdgeInsets.only(
                bottom: start + contentMaxChars < maxTabContentLen ? 12.0 : 0.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(rawLines.length, (i) {
                  final sliceContent = alignedTabContents[i].substring(
                    start,
                    end,
                  );
                  return Text(
                    alignedPrefixes[i] + sliceContent,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: fontSize,
                      fontFamily: 'SpaceMono',
                    ),
                  );
                }),
              ),
            ),
          );

          start += contentMaxChars;
        }

        // Return a beautiful container with a subtle border and background to show it was recognized as a tab
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices,
          ),
        );
      },
    );
  }
}
