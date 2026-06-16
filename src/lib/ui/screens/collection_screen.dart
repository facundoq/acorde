import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/database.dart';
import 'song_detail_screen.dart';

class CollectionScreen extends StatefulWidget {
  final VoidCallback? onSettingsPressed;
  final void Function(String query)? onSearchOnline;

  const CollectionScreen({
    super.key,
    this.onSettingsPressed,
    this.onSearchOnline,
  });

  @override
  State<CollectionScreen> createState() => CollectionScreenState();
}

class CollectionScreenState extends State<CollectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedSong> _songs = [];
  String _query = '';
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    loadSongs();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadSongs() async {
    final all = await DatabaseService.getSongs();
    if (!mounted) return;
    setState(() {
      _totalCount = all.length;
      if (_query.isEmpty) {
        _songs = all;
      } else {
        _searchLocal(_query);
      }
    });
  }

  void _onSearchTextChanged() {
    final text = _searchController.text.trim();
    if (text == _query) return;
    setState(() {
      _query = text;
    });

    if (text.isEmpty) {
      loadSongs();
    } else {
      _searchLocal(text);
    }
  }

  Future<void> _searchLocal(String query) async {
    final results = await DatabaseService.searchLocalSongs(query);
    if (!mounted) return;
    setState(() {
      _songs = results;
    });
  }

  Future<void> _confirmDelete(SavedSong song) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('Delete Song'),
        content: Text(
          'Are you sure you want to delete "${song.title}" from your Collection?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && song.id != null) {
      await DatabaseService.deleteSong(song.id!);
      loadSongs();
    }
  }

  IconData _getInstrumentIcon(String? instrument) {
    final name = instrument?.toLowerCase() ?? '';
    if (name.contains('chord')) return Icons.music_note_outlined;
    if (name.contains('tab')) return Icons.menu;
    if (name.contains('bass')) return Icons.music_note;
    return Icons.music_note;
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
          children: [
            SvgPicture.asset('assets/images/icon.svg', width: 24, height: 24),
            const SizedBox(width: 8),
            const Text(
              'Acorde',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceMono',
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_totalCount Tabs',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onSettingsPressed != null)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: widget.onSettingsPressed,
            ),
        ],
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search field
            TextField(
              controller: _searchController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search your Collection...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.library_music_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
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

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadSongs,
                child: _songs.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                            child: ListTile(
                              onTap: () {
                                if (song.id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SongDetailScreen(songId: song.id!),
                                    ),
                                  ).then((_) => loadSongs());
                                }
                              },
                              onLongPress: () => _confirmDelete(song),
                              title: Text(
                                song.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      song.artist,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (song.instrument != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      _getInstrumentIcon(song.instrument),
                                      size: 14,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      song.instrument!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(
                                        4,
                                      ),
                                    ),
                                    child: Text(
                                      song.source,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _confirmDelete(song),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    if (_query.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No matching local songs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Would you like to search online for "$_query"?',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onSearchOnline != null
                    ? () => widget.onSearchOnline!(_query)
                    : null,
                icon: const Icon(Icons.public, color: Colors.white),
                label: Text('Search online for "$_query"'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Collection list is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontFamily: 'SpaceMono',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search online and save tabs to see them here!',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onSearchOnline != null
                  ? () => widget.onSearchOnline!('')
                  : null,
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text('Discover Songs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
