import 'package:flutter/material.dart';
import '../../core/chord_shapes.dart';
import '../components/chord_diagram.dart';

class DiagramsScreen extends StatefulWidget {
  const DiagramsScreen({super.key});

  @override
  State<DiagramsScreen> createState() => _DiagramsScreenState();
}

class _DiagramsScreenState extends State<DiagramsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allChords = [];
  List<String> _filteredChords = [];

  @override
  void initState() {
    super.initState();
    _allChords = chordShapes.keys.toList()..sort();
    _filteredChords = _allChords;
    _searchController.addListener(_filterChords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChords() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChords = _allChords;
      } else {
        _filteredChords = _allChords
            .where((chord) => chord.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/icon.png', width: 24, height: 24),
            const SizedBox(width: 8),
            const Text(
              'Acorde',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceMono',
              ),
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // Search Box
            TextField(
              controller: _searchController,
              autocorrect: false,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search chords (e.g. C, G#m7, Bb)...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 15,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Chords List
            Expanded(
              child: _filteredChords.isNotEmpty
                  ? ListView.builder(
                      itemCount: _filteredChords.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        final chord = _filteredChords[index];
                        final shapes = getChordShapes(chord);
                        final shapeCount = shapes.length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                          elevation: 0,
                          child: Theme(
                            data: theme.copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              title: Text(
                                chord,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                              subtitle: Text(
                                '$shapeCount ${shapeCount == 1 ? 'shape' : 'shapes'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              children: [
                                if (shapes.isNotEmpty)
                                  Container(
                                    height: 250,
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      itemCount: shapes.length,
                                      itemBuilder: (context, shapeIndex) {
                                        final shape = shapes[shapeIndex];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 20.0,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 180,
                                                height: 180,
                                                child: ChordDiagram(
                                                  shape: shape,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Shape ${shapeIndex + 1}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontFamily: 'SpaceMono',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Text(
                                      'No diagram available for $chord',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Chord "${_searchController.text}" not found.',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
