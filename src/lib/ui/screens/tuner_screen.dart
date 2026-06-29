import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/wakelock_helper.dart';
import 'tuner/tuner_controller.dart';

class TunedString {
  final String note;
  final double freq;
  final String name;

  const TunedString({
    required this.note,
    required this.freq,
    required this.name,
  });
}

class Tuning {
  final String name;
  final String instrument;
  final List<TunedString> strings;

  const Tuning({
    required this.name,
    required this.instrument,
    required this.strings,
  });
}

const List<Tuning> tunings = [
  // GUITAR
  Tuning(
    name: 'Standard',
    instrument: 'Guitar',
    strings: [
      TunedString(note: 'E', freq: 82.41, name: '6th'),
      TunedString(note: 'A', freq: 110.00, name: '5th'),
      TunedString(note: 'D', freq: 146.83, name: '4th'),
      TunedString(note: 'G', freq: 196.00, name: '3rd'),
      TunedString(note: 'B', freq: 246.94, name: '2nd'),
      TunedString(note: 'E', freq: 329.63, name: '1st'),
    ],
  ),
  Tuning(
    name: 'Drop D',
    instrument: 'Guitar',
    strings: [
      TunedString(note: 'D', freq: 73.42, name: '6th'),
      TunedString(note: 'A', freq: 110.00, name: '5th'),
      TunedString(note: 'D', freq: 146.83, name: '4th'),
      TunedString(note: 'G', freq: 196.00, name: '3rd'),
      TunedString(note: 'B', freq: 246.94, name: '2nd'),
      TunedString(note: 'E', freq: 329.63, name: '1st'),
    ],
  ),
  Tuning(
    name: 'Half Step Down',
    instrument: 'Guitar',
    strings: [
      TunedString(note: 'Eb', freq: 77.78, name: '6th'),
      TunedString(note: 'Ab', freq: 103.83, name: '5th'),
      TunedString(note: 'Db', freq: 138.59, name: '4th'),
      TunedString(note: 'Gb', freq: 185.00, name: '3rd'),
      TunedString(note: 'Bb', freq: 233.08, name: '2nd'),
      TunedString(note: 'Eb', freq: 311.13, name: '1st'),
    ],
  ),
  // UKULELE
  Tuning(
    name: 'Standard (gCEA)',
    instrument: 'Ukulele',
    strings: [
      TunedString(note: 'G', freq: 392.00, name: '4th'),
      TunedString(note: 'C', freq: 261.63, name: '3rd'),
      TunedString(note: 'E', freq: 329.63, name: '2nd'),
      TunedString(note: 'A', freq: 440.00, name: '1st'),
    ],
  ),
  Tuning(
    name: 'D-Tuning (aDF#B)',
    instrument: 'Ukulele',
    strings: [
      TunedString(note: 'A', freq: 440.00, name: '4th'),
      TunedString(note: 'D', freq: 293.66, name: '3rd'),
      TunedString(note: 'F#', freq: 369.99, name: '2nd'),
      TunedString(note: 'B', freq: 493.88, name: '1st'),
    ],
  ),
  Tuning(
    name: 'Baritone (DGBE)',
    instrument: 'Ukulele',
    strings: [
      TunedString(note: 'D', freq: 146.83, name: '4th'),
      TunedString(note: 'G', freq: 196.00, name: '3rd'),
      TunedString(note: 'B', freq: 246.94, name: '2nd'),
      TunedString(note: 'E', freq: 329.63, name: '1st'),
    ],
  ),
  // BASS
  Tuning(
    name: 'Standard (EADG)',
    instrument: 'Bass',
    strings: [
      TunedString(note: 'E', freq: 41.20, name: '4th'),
      TunedString(note: 'A', freq: 55.00, name: '3rd'),
      TunedString(note: 'D', freq: 73.42, name: '2nd'),
      TunedString(note: 'G', freq: 98.00, name: '1st'),
    ],
  ),
  Tuning(
    name: '5-String (BEADG)',
    instrument: 'Bass',
    strings: [
      TunedString(note: 'B', freq: 30.87, name: '5th'),
      TunedString(note: 'E', freq: 41.20, name: '4th'),
      TunedString(note: 'A', freq: 55.00, name: '3rd'),
      TunedString(note: 'D', freq: 73.42, name: '2nd'),
      TunedString(note: 'G', freq: 98.00, name: '1st'),
    ],
  ),
  Tuning(
    name: 'Drop D (DADG)',
    instrument: 'Bass',
    strings: [
      TunedString(note: 'D', freq: 36.71, name: '4th'),
      TunedString(note: 'A', freq: 55.00, name: '3rd'),
      TunedString(note: 'D', freq: 73.42, name: '2nd'),
      TunedString(note: 'G', freq: 98.00, name: '1st'),
    ],
  ),
];

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  late final TunerController _tunerController;
  int _selectedTuningIndex = 0;
  bool _isListening = false;
  double? _pitch;
  TunedString? _closestString;
  double _centsOff = 0;
  String? _error;

  Tuning get _currentTuning => tunings[_selectedTuningIndex];

  @override
  void initState() {
    super.initState();
    _tunerController = TunerController();
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
    _tunerController.stop();
    _updateWakelock(false);
    super.dispose();
  }

  void _startTuning() {
    setState(() {
      _error = null;
      _pitch = null;
      _closestString = null;
      _centsOff = 0;
    });

    _tunerController.start(
      onPitch: (pitch) {
        if (!mounted) return;
        setState(() {
          if (_pitch == null) {
            _pitch = pitch;
          } else {
            // Apply exponential moving average to smooth pitch fluctuations
            const double smoothingFactor = 0.25;
            _pitch =
                (_pitch! * (1.0 - smoothingFactor)) + (pitch * smoothingFactor);
          }

          // Find the closest string in the selected tuning
          double minDiff = double.infinity;
          TunedString closest = _currentTuning.strings[0];

          for (final s in _currentTuning.strings) {
            final diff = (_pitch! - s.freq).abs();
            if (diff < minDiff) {
              minDiff = diff;
              closest = s;
            }
          }

          _closestString = closest;

          // Calculate cents off: 1200 * log2(pitch / freq)
          _centsOff = 1200 * math.log(_pitch! / closest.freq) / math.ln2;
        });
      },
      onError: (err) {
        if (!mounted) return;
        _updateWakelock(false);
        setState(() {
          _error = err;
          _isListening = false;
        });
      },
    );

    _updateWakelock(true);
    setState(() {
      _isListening = true;
    });
  }

  void _stopTuning() {
    _tunerController.stop();
    _updateWakelock(false);
    setState(() {
      _isListening = false;
      _pitch = null;
      _closestString = null;
      _centsOff = 0;
    });
  }

  void _toggleTuning() {
    if (_isListening) {
      _stopTuning();
    } else {
      _startTuning();
    }
  }

  Color _getMeterColor() {
    if (_centsOff.abs() < 5) return Colors.green;
    if (_centsOff.abs() < 15) return Colors.amber;
    return Colors.red;
  }

  void _showTuningSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // Group tunings by instrument
        final Map<String, List<MapEntry<int, Tuning>>> grouped = {};
        for (int i = 0; i < tunings.length; i++) {
          final tuning = tunings[i];
          grouped
              .putIfAbsent(tuning.instrument, () => [])
              .add(MapEntry(i, tuning));
        }

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Select Tuning',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: grouped.entries.map((entry) {
                  final instrument = entry.key;
                  final list = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        margin: const EdgeInsets.only(top: 15, bottom: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              instrument == 'Guitar'
                                  ? Icons.music_note
                                  : instrument == 'Ukulele'
                                  ? Icons.music_video
                                  : Icons.graphic_eq,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              instrument.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...list.map((item) {
                        final idx = item.key;
                        final tuning = item.value;
                        final isSelected = _selectedTuningIndex == idx;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTuningIndex = idx;
                              _closestString = null;
                              _centsOff = 0;
                              _pitch = null;
                            });
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 10,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tuning.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tuner Display
            Expanded(
              child: Center(
                child: _closestString != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large Note Text
                          Text(
                            _closestString!.note,
                            style: TextStyle(
                              fontSize: 96,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SpaceMono',
                              color: _getMeterColor(),
                            ),
                          ),
                          if (_pitch != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              '${_pitch!.toStringAsFixed(1)} Hz',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant,
                                fontFamily: 'SpaceMono',
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Subtitle and Change button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${_closestString!.name} String (${_currentTuning.name})',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: _showTuningSelection,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: colorScheme.primary),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Change',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // Cents Meter
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Column(
                              children: [
                                // Meter Bar with Needle
                                Container(
                                  height: 10,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: colorScheme.outlineVariant,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Center Mark
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: -5,
                                        child: Center(
                                          child: Container(
                                            width: 2,
                                            height: 20,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                      // Needle pointer
                                      Align(
                                        alignment: Alignment(
                                          (_centsOff / 50.0).clamp(-1.0, 1.0),
                                          0.0,
                                        ),
                                        child: FractionallySizedBox(
                                          child: Container(
                                            width: 4,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: _getMeterColor(),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 25),
                                // Meter Labels
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Flat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      _centsOff.abs() < 5
                                          ? 'In Tune'
                                          : '${_centsOff > 0 ? '+' : ''}${_centsOff.round()} cents',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getMeterColor(),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Sharp',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic,
                            size: 72,
                            color: _isListening
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isListening
                                    ? 'Play a string (${_currentTuning.name})...'
                                    : 'Tap to start tuning',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: _showTuningSelection,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: colorScheme.primary),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Change',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),

            // Error Display
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            // Control Button
            ElevatedButton.icon(
              onPressed: _toggleTuning,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening
                    ? Colors.red
                    : colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 40,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(
                _isListening ? 'Stop Tuning' : 'Start Tuning',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Instrument Strings Info Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_currentTuning.name} Tuning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _currentTuning.strings.map((s) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              s.note,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
