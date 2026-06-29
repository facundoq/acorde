import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../../core/models.dart';
import '../../core/sources/source.dart';
import '../../core/sources/ultimate_guitar_source.dart';
import '../../core/sources/cifraclub_source.dart';
import '../../core/sources/la_cuerda_source.dart';
import '../../core/sources/cifras_source.dart';
import '../../core/logger.dart';
import '../../services/settings.dart';
import 'song_detail_screen.dart';

class SearchHistoryItem {
  final String query;
  final List<SongSearchResult> results;

  SearchHistoryItem({required this.query, required this.results});
}

class SearchScreen extends StatefulWidget {
  /// Optionally inject a custom list of sources (used by tests).
  /// If null, the real sources are used.
  final List<Source>? sources;

  const SearchScreen({super.key, this.sources});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

  final Map<String, Map<String, dynamic>> _sourceStatus = {};
  final List<SearchHistoryItem> _searchHistory = [];

  late final List<Source> _allSources;

  @override
  void initState() {
    super.initState();
    _allSources =
        widget.sources ??
        [
          UltimateGuitarSource(),
          CifraclubSource(),
          LaCuerdaSource(),
          CifrasSource(),
        ];
    _loadSettings();
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

  void _onSearchTextChanged() {
    final text = _searchController.text.trim();
    if (text == _query) return;
    setState(() {
      _query = text;
    });
  }

  void triggerOnlineSearch(String query) {
    if (query.trim().isEmpty) return;
    _searchController.text = query;
    _query = query;
    _handleOnlineSearch(overrideQuery: query);
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

      final googleKey =
          const String.fromEnvironment('GOOGLE_API_KEY').isNotEmpty
          ? const String.fromEnvironment('GOOGLE_API_KEY')
          : await SettingsService.getGoogleApiKey();
      final googleCx = const String.fromEnvironment('GOOGLE_CX').isNotEmpty
          ? const String.fromEnvironment('GOOGLE_CX')
          : await SettingsService.getGoogleCx();

      if (combinedResults.isEmpty &&
          googleKey != null &&
          googleKey.isNotEmpty &&
          googleCx != null &&
          googleCx.isNotEmpty) {
        if (mounted) {
          setState(() {
            _status = 'Querying Google Custom Search fallback...';
          });
        }
        logger.log('Triggering Google Custom Search API fallback...');
        final googleResults = await _searchGoogleProgrammableSearch(
          trimmedQuery,
          googleKey,
          googleCx,
        );
        combinedResults.addAll(googleResults);
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

  Future<List<SongSearchResult>> _searchGoogleProgrammableSearch(
    String query,
    String apiKey,
    String cx,
  ) async {
    final url =
        'https://customsearch.googleapis.com/customsearch/v1?key=$apiKey&cx=$cx&q=${Uri.encodeComponent(query)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'];
        if (items is List) {
          final List<SongSearchResult> results = [];
          for (final item in items) {
            final title = item['title'] as String? ?? '';
            final link = item['link'] as String? ?? '';
            final parsed = parseGoogleSearchResult(title, link);
            if (parsed != null) {
              results.add(parsed);
            }
          }
          return results;
        }
      }
    } catch (e) {
      logger.log('Google Custom Search error: $e');
    }
    return [];
  }

  SongSearchResult? parseGoogleSearchResult(String title, String url) {
    final cleanUrl = url.toLowerCase();
    String source = '';

    if (cleanUrl.contains('ultimate-guitar.com')) {
      source = 'ultimateguitar';
    } else if (cleanUrl.contains('cifraclub.com.br')) {
      source = 'cifraclub';
    } else if (cleanUrl.contains('lacuerda.net')) {
      source = 'lacuerda';
    } else if (cleanUrl.contains('cifras.com.br')) {
      source = 'cifras';
    } else {
      return null;
    }

    String parsedTitle = title;
    String parsedArtist = 'Unknown';

    if (source == 'ultimateguitar') {
      final parts = title.split(RegExp(r'\s+by\s+', caseSensitive: false));
      if (parts.length == 2) {
        parsedTitle = parts[0]
            .replaceAll(
              RegExp(r'\s+(chords|tab|bass|ukulele)\s*$', caseSensitive: false),
              '',
            )
            .trim();
        final artistParts = parts[1].split(' @ ');
        parsedArtist = artistParts[0].trim();
      }
    } else if (source == 'cifraclub') {
      final parts = title.split(' - ');
      if (parts.length >= 2) {
        parsedTitle = parts[0].trim();
        parsedArtist = parts[1].trim();
      }
    } else if (source == 'lacuerda') {
      final parts = title.split(':');
      final mainPart = parts[0];
      final subparts = mainPart.split(',');
      if (subparts.length >= 2) {
        parsedTitle = subparts[0].trim();
        parsedArtist = subparts[1].trim();
      }
    } else if (source == 'cifras') {
      final parts = title.split(' - ');
      if (parts.length >= 2) {
        parsedTitle = parts[0].trim();
        parsedArtist = parts[1].trim();
      }
    }

    if (parsedTitle.contains(' - ')) {
      final split = parsedTitle.split(' - ');
      parsedTitle = split[0].trim();
      if (split.length > 1) {
        parsedArtist = split[1].trim();
      }
    }

    parsedTitle = parsedTitle
        .replaceAll(
          RegExp(
            r'\s*(-\s*Cifra Club|-\s*Cifras|@\s*Ultimate-Guitar.Com|:\s*Acordes\s*-\s*LaCuerda)$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    parsedArtist = parsedArtist
        .replaceAll(
          RegExp(
            r'\s*(-\s*Cifra Club|-\s*Cifras|@\s*Ultimate-Guitar.Com|:\s*Acordes\s*-\s*LaCuerda)$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    String id = url;
    if (source == 'ultimateguitar') {
      final prefix = 'https://tabs.ultimate-guitar.com/tab/';
      if (url.startsWith(prefix)) {
        id = url.substring(prefix.length);
      }
    } else if (source == 'lacuerda') {
      final uri = Uri.parse(url);
      id = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    } else if (source == 'cifraclub') {
      final prefix = 'https://www.cifraclub.com.br/';
      if (url.startsWith(prefix)) {
        id = url.substring(prefix.length);
      }
    } else if (source == 'cifras') {
      final prefix = 'https://www.cifras.com.br/cifra/';
      if (url.startsWith(prefix)) {
        id = url.substring(prefix.length);
      }
    }

    return SongSearchResult(
      id: id,
      title: parsedTitle,
      artist: parsedArtist,
      source: source,
      url: url,
      type: 'song',
      instrument: detectInstrument(url, parsedTitle, ''),
    );
  }

  IconData _getInstrumentIcon(String? instrument) {
    final name = instrument?.toLowerCase() ?? '';
    if (name.contains('chord')) return Icons.music_note_outlined;
    if (name.contains('tab')) return Icons.menu;
    if (name.contains('bass')) return Icons.music_note;
    return Icons.music_note;
  }

  Widget _buildStars(double? rating, int? ratingCount) {
    if (rating == null) return const SizedBox.shrink();
    final fullStars = rating.floor();
    final hasHalfStar = (rating % 1) >= 0.5;
    final reviewsText = ratingCount != null ? ' ($ratingCount reviews)' : '';

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
          reviewsText,
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
    final apiKeyController = TextEditingController();
    final cxController = TextEditingController();

    SettingsService.getGoogleApiKey().then(
      (val) => apiKeyController.text = val ?? '',
    );
    SettingsService.getGoogleCx().then((val) => cxController.text = val ?? '');

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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._allSources.map((source) {
                      final isChecked = _selectedSources[source.name] == true;

                      return CheckboxListTile(
                        title: Text(
                          source.name[0].toUpperCase() +
                              source.name.substring(1),
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
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Google Fallback Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: apiKeyController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Google API Key',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        SettingsService.saveGoogleApiKey(val.trim());
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cxController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Search Engine ID (CX)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        SettingsService.saveGoogleCx(val.trim());
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    apiKeyController.dispose();
                    cxController.dispose();
                    Navigator.of(context).pop();
                  },
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

          final providerName =
              source.name[0].toUpperCase() + source.name.substring(1);
          final displayText = status['state'] == 'done'
              ? '$providerName (${status['count']})'
              : providerName;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                displayText,
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
                onTap: () {
                  if (isArtist) {
                    _handleOnlineSearch(overrideQuery: item.url);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongDetailScreen(
                          searchResult: item,
                          sources: _allSources,
                        ),
                      ),
                    );
                  }
                },
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
                    _buildStars(item.rating, item.ratingCount),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () {
                        if (isArtist) {
                          _handleOnlineSearch(overrideQuery: item.url);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SongDetailScreen(
                                searchResult: item,
                                sources: _allSources,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
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
                      child: const Text(
                        'View',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
            mainAxisSize: MainAxisSize.min,
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
                          textInputAction: TextInputAction.search,
                          onSubmitted: (val) => _handleOnlineSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search chords & tabs online...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
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
                              horizontal: 16,
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
                                  'Search',
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
                        // Empty Onboarding State
                        if (_onlineResults.isEmpty && _status == null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 80.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.public,
                                    size: 80,
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Search Chords & Tabs Online',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                      fontFamily: 'SpaceMono',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Find songs from Ultimate Guitar, Cifra Club, and more',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: _debugLogs.join('\n'),
                                              ),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Copied logs to clipboard',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Copy',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        TextButton(
                                          onPressed: () => setState(
                                            () => _debugLogs.clear(),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Clear',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ..._debugLogs.map(
                                  (log) => SelectableText(
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
          ],
        ),
      ),
    );
  }
}
