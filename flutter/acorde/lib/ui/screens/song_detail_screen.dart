import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/logger.dart';
import '../../core/ug_parser.dart';
import '../../services/database.dart';
import '../../services/settings.dart';
import '../components/ug_song_view.dart';
import '../components/chord_detail_modal.dart';

enum ScrollSpeed { none, low, mid, high }

class SongDetailScreen extends StatefulWidget {
  final int songId;

  const SongDetailScreen({super.key, required this.songId});

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

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSongAndSettings() async {
    try {
      final songData = await DatabaseService.getSongById(widget.songId);
      final savedFontSize = await SettingsService.getFontSize();
      if (!mounted) return;
      setState(() {
        _song = songData;
        _fontSize = savedFontSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      logger.error('Failed to load song or settings: $e');
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
          const SizedBox(width: 8),
          // Font size decrement button
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _changeFontSize(_fontSize - 2),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Font size increment button
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _changeFontSize(_fontSize + 2),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 10),
                Container(
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
          ],
        ),
      ),
    );
  }
}
