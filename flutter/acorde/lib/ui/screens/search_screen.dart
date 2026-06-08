import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/sources/source.dart';
import '../../core/sources/ultimate_guitar_source.dart';
import '../../core/sources/cifraclub_source.dart';
import '../../core/sources/la_cuerda_source.dart';
import '../../core/sources/cifras_source.dart';
import '../../core/logger.dart';
import '../../services/database.dart';
import '../../services/settings.dart';
import 'song_detail_screen.dart';

class SearchHistoryItem {
  final String query;
  final List<SongSearchResult> results;

  SearchHistoryItem({required this.query, required this.results});
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedSong> _songs = [];
  String _query = '';
  int _totalCount = 0;

  // Configuration states
  Map<String, bool> _selectedSources = {
    'ultimateguitar': true,
    'cifraclub': false,
    'lacuerda': false,
    'cifras': false,
  };
  bool _debugMode = false;
  List<String> _debugLogs = [];
  void Function()? _unsubscribeLogger;

  // Online search states
  List<SongSearchResult> _onlineResults = [];
  bool _searchingOnline = false;
  String? _status;
  String? _onlineError;
  bool _savingModalVisible = false;
  bool _isSaveCancelled = false;

  final Map<String, Map<String, dynamic>> _sourceStatus = {};
  final List<SearchHistoryItem> _searchHistory = [];

  late final List<Source> _allSources;

  @override
  void initState() {
    super.initState();
    _allSources = [
      UltimateGuitarSource(),
      CifraclubSource(),
      LaCuerdaSource(),
      CifrasSource(),
    ];
    _loadSettings();
    _loadSongs();
    _searchController.addListener(_onSearchTextChanged);

    // Subscribe to logger
    _unsubscribeLogger = logger.subscribe((msg) {
      if (!mounted) return;
      setState(() {
        final timeStr = DateTime.now()
            .toLocal()
            .toString()
            .split(' ')
            .last
            .substring(0, 8);
        _debugLogs.add('$timeStr: $msg');
        if (_debugLogs.length > 50) {
          _debugLogs.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _unsubscribeLogger?.call();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final config = await SettingsService.getSourcesConfig();
    setState(() {
      _selectedSources = Map<String, bool>.from(config);
    });
  }

  Future<void> _saveSettings() async {
    await SettingsService.saveSourcesConfig(_selectedSources);
  }

  Future<void> _loadSongs() async {
    final all = await DatabaseService.getSongs();
    if (!mounted) return;
    setState(() {
      _totalCount = all.length;
      if (_query.isEmpty) {
        _songs = all;
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
      _loadSongs();
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

  List<Source> get _activeSources {
    return _allSources.where((s) => _selectedSources[s.name] == true).toList();
  }

  Future<void> _handleOnlineSearch({String? overrideQuery}) async {
    final searchQuery = overrideQuery ?? _query;
    if (searchQuery.trim().isEmpty) return;
    final trimmedQuery = searchQuery.trim();

    if (_activeSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enable at least one search source in settings.',
          ),
        ),
      );
      return;
    }

    // Push to history if we already have online results
    if (_onlineResults.isNotEmpty) {
      _searchHistory.add(
        SearchHistoryItem(query: _query, results: List.from(_onlineResults)),
      );
    }

    if (overrideQuery != null) {
      _searchController.text = overrideQuery;
    }

    setState(() {
      _searchingOnline = true;
      _onlineResults = [];
      _onlineError = null;
      _status = 'Searching online for "$trimmedQuery"...';
      _sourceStatus.clear();
      for (final src in _activeSources) {
        _sourceStatus[src.name] = {'state': 'searching', 'count': 0};
      }
    });

    logger.log(
      'Starting search for "$trimmedQuery" on ${_activeSources.length} sources...',
    );

    try {
      final List<Future<List<SongSearchResult>>>
      searchFutures = _activeSources.map((source) async {
        try {
          logger.log('Searching ${source.name}...');
          final results = await source.search(trimmedQuery);
          logger.log(
            'Search done for ${source.name}: ${results.length} results found.',
          );
          if (mounted) {
            setState(() {
              _sourceStatus[source.name] = {
                'state': 'done',
                'count': results.length,
              };
            });
          }
          return results;
        } catch (e) {
          logger.log('Search error for ${source.name}: $e');
          if (mounted) {
            setState(() {
              _sourceStatus[source.name] = {'state': 'error', 'count': 0};
            });
          }
          return <SongSearchResult>[];
        }
      }).toList();

      final List<List<SongSearchResult>> allResultsArrays = await Future.wait(
        searchFutures,
      );
      final List<SongSearchResult> combinedResults = [];
      for (final list in allResultsArrays) {
        combinedResults.addAll(list);
      }

      if (!mounted) return;
      setState(() {
        _onlineResults = combinedResults;
        if (combinedResults.isEmpty) {
          _status = 'No online results found for "$trimmedQuery".';
        } else {
          _status = null;
        }
      });
    } catch (e) {
      logger.log('Critical search error: $e');
      if (!mounted) return;
      setState(() {
        _onlineError = 'A critical error occurred: $e';
        _status = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _searchingOnline = false;
        });
      }
    }
  }

  Future<void> _handleSaveOnline(SongSearchResult item) async {
    setState(() {
      _savingModalVisible = true;
      _isSaveCancelled = false;
      _status = 'Downloading from ${item.source}...';
      _onlineError = null;
    });

    try {
      final source = _allSources.firstWhere(
        (s) => s.name == item.source,
        orElse: () => _allSources[0],
      );
      final songContent = await source.getSong(item.url);

      if (_isSaveCancelled || !mounted) return;

      final savedSong = SavedSong(
        sourceId: item.id,
        title: songContent.title,
        artist: songContent.artist,
        lyrics: songContent.lyrics,
        chords: songContent.chords ?? '',
        source: songContent.source,
        url: songContent.url,
        createdAt: DateTime.now().toIso8601String(),
        instrument: item.instrument ?? songContent.instrument,
        rating: item.rating ?? songContent.rating,
      );

      final songId = await DatabaseService.saveSong(savedSong);

      if (_isSaveCancelled || !mounted) return;

      setState(() {
        _savingModalVisible = false;
        _onlineResults = [];
        _searchController.clear();
      });

      _loadSongs();

      if (!mounted) return;
      // Navigate to detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongDetailScreen(songId: songId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _onlineError = 'Failed to save song ($e)';
        _savingModalVisible = false;
        _status = null;
      });
    }
  }

  void _handleCancelSave() {
    setState(() {
      _isSaveCancelled = true;
      _savingModalVisible = false;
      _status = null;
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
          'Are you sure you want to delete "${song.title}" from your Tabs?',
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
      _loadSongs();
    }
  }

  IconData _getInstrumentIcon(String? instrument) {
    final name = instrument?.toLowerCase() ?? '';
    if (name.contains('chord')) return Icons.music_note_outlined;
    if (name.contains('tab')) return Icons.menu;
    if (name.contains('bass')) return Icons.music_note;
    return Icons.music_note;
  }

  Widget _buildStars(double? rating) {
    if (rating == null) return const SizedBox.shrink();
    final fullStars = rating.floor();
    final hasHalfStar = (rating % 1) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          IconData icon;
          if (index < fullStars) {
            icon = Icons.star;
          } else if (index == fullStars && hasHalfStar) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(icon, size: 14, color: Colors.amber);
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Text(
                'Search Sources',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._allSources.map((source) {
                    final isChecked = _selectedSources[source.name] == true;

                    return CheckboxListTile(
                      title: Text(
                        source.name[0].toUpperCase() + source.name.substring(1),
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      value: isChecked,
                      activeColor: colorScheme.primary,
                      onChanged: (val) {
                        setModalState(() {
                          _selectedSources[source.name] = val ?? false;
                        });
                        setState(() {
                          _selectedSources[source.name] = val ?? false;
                        });
                        _saveSettings();
                      },
                    );
                  }),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Debug Mode'),
                    subtitle: const Text('Show errors and logs in UI'),
                    value: _debugMode,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      setModalState(() {
                        _debugMode = val;
                      });
                      setState(() {
                        _debugMode = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSourceProgress() {
    if (!_searchingOnline && _sourceStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: _activeSources.map((source) {
          final status =
              _sourceStatus[source.name] ?? {'state': 'idle', 'count': 0};
          IconData icon = Icons.more_horiz;
          Color color = colorScheme.onSurfaceVariant;

          if (status['state'] == 'searching') {
            icon = Icons.search;
            color = colorScheme.primary;
          } else if (status['state'] == 'done') {
            icon = Icons.check_circle;
            color = (status['count'] as int) > 0 ? Colors.green : Colors.amber;
          } else if (status['state'] == 'error') {
            icon = Icons.cancel;
            color = Colors.red;
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                source.name[0].toUpperCase() + source.name.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOnlineResults() {
    if (_onlineResults.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Online Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _onlineResults = [];
                    _searchHistory.clear();
                    _searchController.clear();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _onlineResults.length,
          itemBuilder: (context, index) {
            final item = _onlineResults[index];
            final isArtist = item.type == 'artist';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              elevation: 0,
              child: ListTile(
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.artist,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.instrument != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            _getInstrumentIcon(item.instrument),
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.instrument!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.source.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStars(item.rating),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () {
                        if (isArtist) {
                          _handleOnlineSearch(overrideQuery: item.url);
                        } else {
                          _handleSaveOnline(item);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isArtist
                            ? colorScheme.primary
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        minimumSize: const Size(60, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        isArtist ? 'View' : 'Add',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: _onlineResults.isEmpty && !_searchingOnline,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_onlineResults.isNotEmpty || _searchingOnline) {
          if (_searchHistory.isNotEmpty) {
            final prev = _searchHistory.removeLast();
            setState(() {
              _searchController.text = prev.query;
              _onlineResults = prev.results;
            });
          } else {
            setState(() {
              _onlineResults = [];
              _searchController.clear();
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            children: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _showConfigDialog,
            ),
          ],
          elevation: 1,
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Header
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search your Tabs...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 15,
                            ),
                          ),
                        ),
                      ),
                      if (_query.length > 2) ...[
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _searchingOnline
                              ? null
                              : () => _handleOnlineSearch(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _searchingOnline
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Add Online',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Content List
                  Expanded(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // Local songs list (only visible if we are NOT viewing online results)
                        if (_onlineResults.isEmpty) ...[
                          if (_songs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 50.0,
                              ),
                              child: Text(
                                _query.isNotEmpty
                                    ? 'No matching local songs.'
                                    : 'Your Tabs list is empty.',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _songs.length,
                              itemBuilder: (context, index) {
                                final song = _songs[index];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  color: colorScheme.surfaceContainerLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: colorScheme.outlineVariant
                                          .withOpacity(0.5),
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
                                                SongDetailScreen(
                                                  songId: song.id!,
                                                ),
                                          ),
                                        );
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
                                              color:
                                                  colorScheme.onSurfaceVariant,
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
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            _buildStars(song.rating),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                song.source,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
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
                        ],

                        // Search Progress / Loading
                        if (_status != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_searchingOnline) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Flexible(
                                  child: Text(
                                    _status!,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        _buildSourceProgress(),

                        if (_onlineError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Text(
                              _onlineError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Online Results List
                        _buildOnlineResults(),

                        // Debug Logs Box
                        if (_debugMode && _debugLogs.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 25),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.4),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'DEBUG LOGS',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _debugLogs.clear()),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ..._debugLogs.map(
                                  (log) => Text(
                                    log,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 10,
                                      fontFamily: 'SpaceMono',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Saving / Downloading Overlay Dialog
            if (_savingModalVisible)
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Card(
                  margin: const EdgeInsets.all(30),
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 20),
                        Text(
                          'Saving Tab',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _status ?? 'Downloading...',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: _handleCancelSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
