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
        return InteractiveChord(
          chordName: part.content,
          fontSize: fontSize + 1,
          onTap: () => _showChordDetail(context, part.content),
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
            final textContent = segment.text;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chord
                if (segment.chord != null)
                  InteractiveChord(
                    chordName: segment.chord!,
                    fontSize: fontSize + 1,
                    onTap: () => _showChordDetail(context, segment.chord!),
                  )
                else
                  const SizedBox(
                    height:
                        22, // Keep spacing consistent with the height of InteractiveChord
                    child: Text(' ', style: TextStyle(fontFamily: 'SpaceMono')),
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
            return WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: InteractiveChord(
                chordName: segment.chord!,
                fontSize: fontSize + 1,
                onTap: () => _showChordDetail(context, segment.chord!),
              ),
            );
          }
          return TextSpan(text: segment.text);
        }).toList(),
      ),
    );
  }
}

class InteractiveChord extends StatefulWidget {
  final String chordName;
  final double fontSize;
  final VoidCallback onTap;

  const InteractiveChord({
    super.key,
    required this.chordName,
    required this.fontSize,
    required this.onTap,
  });

  @override
  State<InteractiveChord> createState() => _InteractiveChordState();
}

class _InteractiveChordState extends State<InteractiveChord> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shape = getChordShape(widget.chordName);
    final textColor = shape != null
        ? colorScheme.primary
        : const Color(0xFFFFD700);

    final baseColor = shape != null
        ? colorScheme.primary
        : const Color(0xFFFFD700);
    final backgroundColor = _isHovered
        ? baseColor.withOpacity(0.24)
        : baseColor.withOpacity(0.08);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.chordName,
            style: TextStyle(
              color: textColor,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceMono',
            ),
          ),
        ),
      ),
    );
  }
}
