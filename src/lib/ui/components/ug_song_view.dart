import 'package:flutter/material.dart';
import '../../core/ug_parser.dart';
import '../../core/chord_shapes.dart';
import 'chord_detail_modal.dart';
import 'tablature_view.dart';

class UGSongView extends StatelessWidget {
  final String content;
  final double fontSize;

  const UGSongView({super.key, required this.content, this.fontSize = 14});

  void _showChordDetail(BuildContext context, String chordName) {
    showDialog(
      context: context,
      builder: (context) => ChordDetailModal(chordName: chordName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parts = parseUGTabs(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) => _buildPart(part, context)).toList(),
    );
  }

  Widget _buildPart(UGPart part, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (part.type) {
      case UGPartType.chord:
        final shape = getChordShape(part.content);
        final color = shape != null
            ? colorScheme.primary
            : const Color(0xFFFFD700);

        return GestureDetector(
          onTap: () => _showChordDetail(context, part.content),
          child: Text(
            part.content,
            style: TextStyle(
              color: color,
              fontSize: fontSize + 1,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceMono',
            ),
          ),
        );

      case UGPartType.header:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            part.content,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceMono',
            ),
          ),
        );

      case UGPartType.tab:
        final alignedLines = parseAlignedSegments(part.content);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: alignedLines
                .map((line) => _buildAlignedLine(line, context))
                .toList(),
          ),
        );

      case UGPartType.tablature:
        return TablatureView(content: part.content, fontSize: fontSize);

      case UGPartType.text:
        return Text(
          part.content,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: fontSize,
            fontFamily: 'SpaceMono',
          ),
        );
    }
  }

  Widget _buildAlignedLine(AlignedLine line, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (line.type == AlignedLineType.paired) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 0,
          runSpacing: 4,
          children: line.segments.map((segment) {
            final shape = segment.chord != null
                ? getChordShape(segment.chord!)
                : null;
            final color = segment.chord != null
                ? (shape != null
                      ? colorScheme.primary
                      : const Color(0xFFFFD700))
                : Colors.transparent;

            final textContent = segment.text;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chord
                if (segment.chord != null)
                  GestureDetector(
                    onTap: () => _showChordDetail(context, segment.chord!),
                    child: Text(
                      segment.chord!,
                      style: TextStyle(
                        color: color,
                        fontSize: fontSize + 1,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  )
                else
                  Text(
                    ' ',
                    style: TextStyle(
                      color: Colors.transparent,
                      fontSize: fontSize + 1,
                      fontFamily: 'SpaceMono',
                    ),
                  ),

                // Text
                Text(
                  textContent.isNotEmpty
                      ? textContent
                      : (segment.chord != null ? ' ' : ''),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: fontSize,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    // Single line
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: fontSize,
          fontFamily: 'SpaceMono',
        ),
        children: line.segments.map((segment) {
          if (segment.chord != null) {
            final shape = getChordShape(segment.chord!);
            final color = shape != null
                ? colorScheme.primary
                : const Color(0xFFFFD700);

            return WidgetSpan(
              child: GestureDetector(
                onTap: () => _showChordDetail(context, segment.chord!),
                child: Text(
                  segment.chord!,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize + 1,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ),
            );
          }
          return TextSpan(text: segment.text);
        }).toList(),
      ),
    );
  }
}
