import 'package:flutter/material.dart';
import '../../core/chord_shapes.dart';
import 'chord_diagram.dart';

class ChordDetailModal extends StatefulWidget {
  final String chordName;

  const ChordDetailModal({super.key, required this.chordName});

  @override
  State<ChordDetailModal> createState() => _ChordDetailModalState();
}

class _ChordDetailModalState extends State<ChordDetailModal> {
  int _currentShapeIndex = 0;
  late List<ChordShape> _availableShapes;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _availableShapes = getChordShapes(widget.chordName);
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(ChordDetailModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chordName != widget.chordName) {
      setState(() {
        _availableShapes = getChordShapes(widget.chordName);
        _currentShapeIndex = 0;
      });
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.chordName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            if (_availableShapes.isNotEmpty) ...[
              SizedBox(
                width: 240,
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _availableShapes.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentShapeIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: ChordDiagram(shape: _availableShapes[index]),
                    );
                  },
                ),
              ),
              if (_availableShapes.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_availableShapes.length, (index) {
                      final isSelected = index == _currentShapeIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8,
                        width: isSelected ? 12 : 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ] else
              SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'No diagram available for ${widget.chordName}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 30,
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
