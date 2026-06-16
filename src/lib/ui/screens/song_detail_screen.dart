import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/wakelock_helper.dart';
import '../../core/logger.dart';
import '../../core/ug_parser.dart';
import '../../core/models.dart';
import '../../core/sources/source.dart';
import '../../core/sources/ultimate_guitar_source.dart';
import '../../core/sources/cifraclub_source.dart';
import '../../core/sources/la_cuerda_source.dart';
import '../../core/sources/cifras_source.dart';
import '../../services/database.dart';
import '../../services/settings.dart';
import '../components/ug_song_view.dart';
import '../components/chord_detail_modal.dart';

enum ScrollSpeed { none, low, mid, high }

class SongDetailScreen extends StatefulWidget {
  final int? songId;
  final SongSearchResult? searchResult;
  final List<Source>? sources;

  const SongDetailScreen({
    super.key,
    this.songId,
    this.searchResult,
    this.sources,
  }) : assert(
         songId != null || searchResult != null,
         'Either songId or searchResult must be provided',
       );

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  SavedSong? _song;
  bool _loading = true;
  int _fontSize = 14;
  ScrollSpeed _scrollSpeed = ScrollSpeed.none;

  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _currentScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSongAndSettings();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        // Track the user manual scroll offset so that auto-scroll resumes correctly
        _currentScrollOffset = _scrollController.offset;
      }
    });
  }

  void _updateWakelock(bool enable) {
    if (enable) {
      WakelockHelper.enable();
    } else {
      WakelockHelper.disable();
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _updateWakelock(false);
    super.dispose();
  }

  Future<void> _openBrowser(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  Future<void> _loadSongAndSettings() async {
    try {
      final savedFontSize = await SettingsService.getFontSize();
      if (!mounted) return;
      setState(() {
        _fontSize = savedFontSize;
      });

      if (widget.songId != null) {
        final songData = await DatabaseService.getSongById(widget.songId!);
        if (!mounted) return;
        setState(() {
          _song = songData;
          _loading = false;
        });
      } else if (widget.searchResult != null) {
        final existingSong = await DatabaseService.getSongBySourceAndId(
          widget.searchResult!.source,
          widget.searchResult!.id,
        );
        if (existingSong != null) {
          if (!mounted) return;
          setState(() {
            _song = existingSong;
            _loading = false;
          });
          return;
        }

        final allSources =
            widget.sources ??
            [
              UltimateGuitarSource(),
              CifraclubSource(),
              LaCuerdaSource(),
              CifrasSource(),
            ];
        final source = allSources.firstWhere(
          (s) => s.name == widget.searchResult!.source,
          orElse: () => allSources[0],
        );
        final songContent = await source.getSong(widget.searchResult!.url);

        if (!mounted) return;

        final tempSong = SavedSong(
          id: null,
          sourceId: widget.searchResult!.id,
          title: songContent.title,
          artist: songContent.artist,
          lyrics: songContent.lyrics,
          chords: songContent.chords ?? '',
          source: songContent.source,
          url: songContent.url,
          createdAt: DateTime.now().toIso8601String(),
          instrument: widget.searchResult!.instrument ?? songContent.instrument,
          rating: widget.searchResult!.rating ?? songContent.rating,
          ratingCount:
              widget.searchResult!.ratingCount ?? songContent.ratingCount,
        );

        setState(() {
          _song = tempSong;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      logger.error('Failed to load song or settings: $e');
    }
  }

  Future<void> _toggleSaveCollection() async {
    final song = _song;
    if (song == null) return;

    setState(() {
      _loading = true;
    });

    try {
      if (song.id == null) {
        final savedSong = SavedSong(
          sourceId: song.sourceId,
          title: song.title,
          artist: song.artist,
          lyrics: song.lyrics,
          chords: song.chords,
          source: song.source,
          url: song.url,
          createdAt: DateTime.now().toIso8601String(),
          instrument: song.instrument,
          rating: song.rating,
          ratingCount: song.ratingCount,
        );
        final newId = await DatabaseService.saveSong(savedSong);
        final updatedSong = SavedSong(
          id: newId,
          sourceId: savedSong.sourceId,
          title: savedSong.title,
          artist: savedSong.artist,
          lyrics: savedSong.lyrics,
          chords: savedSong.chords,
          source: savedSong.source,
          url: savedSong.url,
          createdAt: savedSong.createdAt,
          instrument: savedSong.instrument,
          rating: savedSong.rating,
          ratingCount: savedSong.ratingCount,
        );
        if (!mounted) return;
        setState(() {
          _song = updatedSong;
          _loading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved to collection')));
      } else {
        await DatabaseService.deleteSong(song.id!);
        final updatedSong = SavedSong(
          id: null,
          sourceId: song.sourceId,
          title: song.title,
          artist: song.artist,
          lyrics: song.lyrics,
          chords: song.chords,
          source: song.source,
          url: song.url,
          createdAt: song.createdAt,
          instrument: song.instrument,
          rating: song.rating,
          ratingCount: song.ratingCount,
        );
        if (!mounted) return;
        setState(() {
          _song = updatedSong;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from collection')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      logger.error('Failed to toggle save collection: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _changeFontSize(int newSize) async {
    final clamped = newSize.clamp(8, 30);
    setState(() {
      _fontSize = clamped;
    });
    await SettingsService.saveFontSize(clamped);
  }

  void _toggleScrollSpeed() {
    setState(() {
      switch (_scrollSpeed) {
        case ScrollSpeed.none:
          _scrollSpeed = ScrollSpeed.low;
          _startAutoScroll(80);
          break;
        case ScrollSpeed.low:
          _scrollSpeed = ScrollSpeed.mid;
          _startAutoScroll(40);
          break;
        case ScrollSpeed.mid:
          _scrollSpeed = ScrollSpeed.high;
          _startAutoScroll(20);
          break;
        case ScrollSpeed.high:
          _scrollSpeed = ScrollSpeed.none;
          _stopAutoScroll();
          break;
      }
    });
  }

  void _startAutoScroll(int intervalMs) {
    _updateWakelock(true);
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      _currentScrollOffset += 1.0;
      if (_currentScrollOffset >= maxScroll) {
        _currentScrollOffset = maxScroll;
        _stopAutoScroll();
      }

      _scrollController.jumpTo(_currentScrollOffset);
    });
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _updateWakelock(false);
    setState(() {
      _scrollSpeed = ScrollSpeed.none;
    });
  }

  String? _getScrollLabel() {
    switch (_scrollSpeed) {
      case ScrollSpeed.low:
        return '1x';
      case ScrollSpeed.mid:
        return '2x';
      case ScrollSpeed.high:
        return '3x';
      default:
        return null;
    }
  }

  void _showChordDetail(String chordName) {
    showDialog(
      context: context,
      builder: (context) => ChordDetailModal(chordName: chordName),
    );
  }

  Widget _renderStandardContent(String text, ColorScheme colorScheme) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines.map((line) {
        final RegExp wordAndSpaceRegex = RegExp(r"(\s+|\S+)");
        final matches = wordAndSpaceRegex.allMatches(line);
        final chordRegex = RegExp(
          r"^[A-G][b#]?(maj|min|m|sus|dim|aug|add)?[0-9]?(sus[24])?(/[A-G][b#]?)?$",
        );

        final List<InlineSpan> spans = [];

        for (final match in matches) {
          final word = match.group(0) ?? '';
          final trimmed = word.trim();
          final isChord = trimmed.isNotEmpty && chordRegex.hasMatch(trimmed);

          if (isChord) {
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => _showChordDetail(trimmed),
                  child: Text(
                    word,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: _fontSize.toDouble(),
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ),
              ),
            );
          } else {
            spans.add(
              TextSpan(
                text: word,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: _fontSize.toDouble(),
                  fontFamily: 'SpaceMono',
                ),
              ),
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: RichText(
            text: TextSpan(
              children: spans.isEmpty ? [TextSpan(text: line)] : spans,
            ),
          ),
        );
      }).toList(),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          title: const Text('Loading...'),
        ),
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_song == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          title: const Text('Error'),
        ),
        body: Center(
          child: Text(
            'Song not found',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }

    final content = _song!.chords.isNotEmpty ? _song!.chords : _song!.lyrics;
    final isUG = isUGFormat(content);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          _song!.title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Auto scroll button
          OutlinedButton(
            onPressed: _toggleScrollSpeed,
            onLongPress: _stopAutoScroll,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: _scrollSpeed == ScrollSpeed.none
                ? Icon(Icons.play_arrow, size: 16, color: colorScheme.primary)
                : Text(
                    _getScrollLabel() ?? '',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Separator
          Container(
            width: 1,
            height: 18,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          // Font size icon
          Icon(Icons.format_size, size: 18, color: colorScheme.onSurface),
          // Font size decrement button
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () => _changeFontSize(_fontSize - 2),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          // Font size increment button
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => _changeFontSize(_fontSize + 2),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 12),
        ],
        elevation: 1,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _song!.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _song!.artist,
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_song!.rating != null) ...[
                  const SizedBox(height: 6),
                  _buildStars(_song!.rating, _song!.ratingCount),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _openBrowser(_song!.url),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SOURCE: ${_song!.source.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleSaveCollection,
                      icon: Icon(
                        _song!.id != null
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 16,
                      ),
                      label: Text(
                        _song!.id != null
                            ? 'Remove from collection'
                            : 'Save to collection',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _song!.id != null
                            ? colorScheme.errorContainer
                            : colorScheme.primaryContainer,
                        foregroundColor: _song!.id != null
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content card
            Card(
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: isUG
                    ? UGSongView(
                        content: content,
                        fontSize: _fontSize.toDouble(),
                      )
                    : _renderStandardContent(content, colorScheme),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
