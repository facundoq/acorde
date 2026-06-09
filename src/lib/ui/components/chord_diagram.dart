import 'package:flutter/material.dart';
import '../../core/chord_shapes.dart';

class ChordDiagram extends StatelessWidget {
  final ChordShape shape;

  const ChordDiagram({super.key, required this.shape});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final onSurfaceColor = colorScheme.onSurface;
    final primaryColor = colorScheme.primary;
    final subtextColor = colorScheme.onSurfaceVariant;

    final strings = List.generate(6, (i) => i);
    final frets = [1, 2, 3, 4, 5];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fret Numbers Column
            SizedBox(
              width: 25,
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: frets.map((f) {
                  return Positioned(
                    top: (f - 0.5) * 30 + 5,
                    right: 5,
                    child: Text(
                      '$f',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subtextColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Fretboard Container
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: onSurfaceColor, width: 1),
                  right: BorderSide(color: onSurfaceColor, width: 1),
                  top: BorderSide(color: onSurfaceColor, width: 1),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Nut (thick top line)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(height: 5, color: onSurfaceColor),
                  ),

                  // Frets (horizontal lines)
                  ...frets.map((f) {
                    return Positioned(
                      top: f * 30.0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: onSurfaceColor.withOpacity(0.7),
                      ),
                    );
                  }),

                  // Barre Line
                  if (shape.barre != null)
                    Positioned(
                      top: (shape.barre! - 0.5) * 30 - 4,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),

                  // Strings and fingers Layer
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: strings.map((s) {
                          final fret = shape.frets[s];
                          final finger =
                              shape.fingers != null && s < shape.fingers!.length
                              ? shape.fingers![s]
                              : null;

                          final isBarreFret =
                              shape.barre != null && shape.barre == fret;
                          final isBarredFinger = isBarreFret && finger == 1;

                          return SizedBox(
                            width: 20,
                            height: double.infinity,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              clipBehavior: Clip.none,
                              children: [
                                // Vertical String Line
                                Center(
                                  child: Container(
                                    width: 1,
                                    height: double.infinity,
                                    color: onSurfaceColor.withOpacity(0.5),
                                  ),
                                ),

                                // Marker for muted or open strings
                                if (fret == -1)
                                  Positioned(
                                    top: -20,
                                    child: const Text(
                                      'X',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (fret == 0)
                                  Positioned(
                                    top: -20,
                                    child: Text(
                                      'O',
                                      style: TextStyle(
                                        color: onSurfaceColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                // Finger Circle
                                if (fret > 0 && !isBarredFinger)
                                  Positioned(
                                    top: (fret - 0.5) * 30 + 5,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: finger != null && finger > 0
                                          ? Text(
                                              '$finger',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Barre indicator text
        if (shape.barre != null)
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Text(
              'Barre on fret ${shape.barre}',
              style: TextStyle(
                color: subtextColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
