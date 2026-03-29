import React, { useState, useEffect, useRef } from 'react';
import { StyleSheet, TouchableOpacity, useColorScheme, Platform, ActivityIndicator, Modal, ScrollView } from 'react-native';
import { Stack } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { AudioModule, useAudioRecorder, RecordingOptionsPresets } from 'expo-audio';
import { Text, View } from '@/components/Themed';
import Colors from '@/constants/Colors';

// Tunings Database
const TUNINGS = [
  // GUITAR
  { 
    name: 'Standard', instrument: 'Guitar',
    strings: [
      { note: 'E', freq: 82.41, name: '6th' },
      { note: 'A', freq: 110.00, name: '5th' },
      { note: 'D', freq: 146.83, name: '4th' },
      { note: 'G', freq: 196.00, name: '3rd' },
      { note: 'B', freq: 246.94, name: '2nd' },
      { note: 'E', freq: 329.63, name: '1st' },
    ]
  },
  { 
    name: 'Drop D', instrument: 'Guitar',
    strings: [
      { note: 'D', freq: 73.42, name: '6th' },
      { note: 'A', freq: 110.00, name: '5th' },
      { note: 'D', freq: 146.83, name: '4th' },
      { note: 'G', freq: 196.00, name: '3rd' },
      { note: 'B', freq: 246.94, name: '2nd' },
      { note: 'E', freq: 329.63, name: '1st' },
    ]
  },
  { 
    name: 'Half Step Down', instrument: 'Guitar',
    strings: [
      { note: 'Eb', freq: 77.78, name: '6th' },
      { note: 'Ab', freq: 103.83, name: '5th' },
      { note: 'Db', freq: 138.59, name: '4th' },
      { note: 'Gb', freq: 185.00, name: '3rd' },
      { note: 'Bb', freq: 233.08, name: '2nd' },
      { note: 'Eb', freq: 311.13, name: '1st' },
    ]
  },
  
  // UKULELE
  { 
    name: 'Standard (gCEA)', instrument: 'Ukulele',
    strings: [
      { note: 'G', freq: 392.00, name: '4th' },
      { note: 'C', freq: 261.63, name: '3rd' },
      { note: 'E', freq: 329.63, name: '2nd' },
      { note: 'A', freq: 440.00, name: '1st' },
    ]
  },
  { 
    name: 'D-Tuning (aDF#B)', instrument: 'Ukulele',
    strings: [
      { note: 'A', freq: 440.00, name: '4th' },
      { note: 'D', freq: 293.66, name: '3rd' },
      { note: 'F#', freq: 369.99, name: '2nd' },
      { note: 'B', freq: 493.88, name: '1st' },
    ]
  },
  { 
    name: 'Baritone (DGBE)', instrument: 'Ukulele',
    strings: [
      { note: 'D', freq: 146.83, name: '4th' },
      { note: 'G', freq: 196.00, name: '3rd' },
      { note: 'B', freq: 246.94, name: '2nd' },
      { note: 'E', freq: 329.63, name: '1st' },
    ]
  },

  // BASS
  { 
    name: 'Standard (EADG)', instrument: 'Bass',
    strings: [
      { note: 'E', freq: 41.20, name: '4th' },
      { note: 'A', freq: 55.00, name: '3rd' },
      { note: 'D', freq: 73.42, name: '2nd' },
      { note: 'G', freq: 98.00, name: '1st' },
    ]
  },
  { 
    name: '5-String (BEADG)', instrument: 'Bass',
    strings: [
      { note: 'B', freq: 30.87, name: '5th' },
      { note: 'E', freq: 41.20, name: '4th' },
      { note: 'A', freq: 55.00, name: '3rd' },
      { note: 'D', freq: 73.42, name: '2nd' },
      { note: 'G', freq: 98.00, name: '1st' },
    ]
  },
  { 
    name: 'Drop D (DADG)', instrument: 'Bass',
    strings: [
      { note: 'D', freq: 36.71, name: '4th' },
      { note: 'A', freq: 55.00, name: '3rd' },
      { note: 'D', freq: 73.42, name: '2nd' },
      { note: 'G', freq: 98.00, name: '1st' },
    ]
  },
];

export default function TunerScreen() {
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];
  
  const [selectedTuningIndex, setSelectedTuningIndex] = useState(0);
  const [isListening, setIsListening] = useState(false);
  const [pitch, setPitch] = useState<number | null>(null);
  const [closestString, setString] = useState<typeof TUNINGS[0]['strings'][0] | null>(null);
  const [centsOff, setCentsOff] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [showTuningModal, setShowTuningModal] = useState(false);

  const currentTuning = TUNINGS[selectedTuningIndex];

  const audioCtx = useRef<AudioContext | null>(null);
  const analyser = useRef<AnalyserNode | null>(null);
  const microphone = useRef<MediaStreamAudioSourceNode | null>(null);
  const animationFrame = useRef<number | null>(null);
  const currentTuningRef = useRef(currentTuning);

  // Sync ref for the animation loop
  useEffect(() => {
    currentTuningRef.current = currentTuning;
  }, [currentTuning]);

  const recorder = useAudioRecorder(RecordingOptionsPresets.LOW_QUALITY);

  const startListening = async () => {
    if (Platform.OS === 'web') {
      await startListeningWeb();
    } else {
      await startListeningNative();
    }
  };

  const stopListening = () => {
    if (Platform.OS === 'web') {
      stopListeningWeb();
    } else {
      stopListeningNative();
    }
  };

  const startListeningWeb = async () => {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      setError("Microphone access is not supported by your browser or requires a secure (HTTPS) connection.");
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      audioCtx.current = new (window.AudioContext || (window as any).webkitAudioContext)();
      analyser.current = audioCtx.current.createAnalyser();
      analyser.current.fftSize = 2048;
      
      microphone.current = audioCtx.current.createMediaStreamSource(stream);
      microphone.current.connect(analyser.current);
      
      setIsListening(true);
      setError(null);
      updatePitch();
    } catch (err: any) {
      setError("Microphone access denied or not available.");
      console.error(err);
    }
  };

  const stopListeningWeb = () => {
    if (animationFrame.current) cancelAnimationFrame(animationFrame.current);
    if (microphone.current) microphone.current.disconnect();
    if (audioCtx.current) audioCtx.current.close();
    setIsListening(false);
    setPitch(null);
    setString(null);
  };

  const startListeningNative = async () => {
    try {
      const { status } = await AudioModule.requestPermissionsAsync();
      if (status !== 'granted') {
        setError('Microphone permission not granted');
        return;
      }

      await AudioModule.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      await recorder.prepareAsync();
      await recorder.recordAsync();
      setIsListening(true);
      setError(null);
      
      // Real-time pitch detection on Native usually requires a specialized 
      // native module like react-native-pitch-detector or processing raw buffers.
      // With expo-audio, we can simulate the UI state.
      setError("Native real-time detection requires specialized native modules. Web version is recommended for full accuracy.");
    } catch (err) {
      console.error('Failed to start recording', err);
      setError('Failed to access microphone');
    }
  };

  const stopListeningNative = async () => {
    try {
      if (recorder.isRecording) {
        await recorder.stopAsync();
      }
      setIsListening(false);
      setPitch(null);
      setString(null);
    } catch (err) {
      console.error('Failed to stop recording', err);
    }
  };

  const updatePitch = () => {
    if (!analyser.current) return;
    
    const buffer = new Float32Array(analyser.current.fftSize);
    analyser.current.getFloatTimeDomainData(buffer);
    
    const detectedPitch = autoCorrelate(buffer, audioCtx.current!.sampleRate);
    
    if (detectedPitch !== -1) {
      setPitch(detectedPitch);
      
      // Find closest string in the current selected tuning
      let minDiff = Infinity;
      let closest = currentTuningRef.current.strings[0];
      
      currentTuningRef.current.strings.forEach(s => {
        const diff = Math.abs(detectedPitch - s.freq);
        if (diff < minDiff) {
          minDiff = diff;
          closest = s;
        }
      });
      
      setString(closest);
      
      // Calculate cents off
      const cents = 1200 * Math.log2(detectedPitch / closest.freq);
      setCentsOff(cents);
    }
    
    animationFrame.current = requestAnimationFrame(updatePitch);
  };

  // Simple Autocorrelation algorithm for pitch detection
  const autoCorrelate = (buffer: Float32Array, sampleRate: number) => {
    const SIZE = buffer.length;
    let rms = 0;

    for (let i = 0; i < SIZE; i++) {
      rms += buffer[i] * buffer[i];
    }
    rms = Math.sqrt(rms / SIZE);
    if (rms < 0.01) return -1; // signal too weak

    let r1 = 0, r2 = SIZE - 1, thres = 0.2;
    for (let i = 0; i < SIZE / 2; i++) {
      if (Math.abs(buffer[i]) < thres) {
        r1 = i;
        break;
      }
    }
    for (let i = 1; i < SIZE / 2; i++) {
      if (Math.abs(buffer[SIZE - i]) < thres) {
        r2 = SIZE - i;
        break;
      }
    }

    const subBuffer = buffer.slice(r1, r2);
    const subSize = subBuffer.length;

    const c = new Float32Array(subSize);
    for (let i = 0; i < subSize; i++) {
      for (let j = 0; j < subSize - i; j++) {
        c[i] = c[i] + subBuffer[j] * subBuffer[j + i];
      }
    }

    let d = 0;
    while (c[d] > c[d + 1]) d++;
    let maxval = -1, maxpos = -1;
    for (let i = d; i < subSize; i++) {
      if (c[i] > maxval) {
        maxval = c[i];
        maxpos = i;
      }
    }
    let T0 = maxpos;

    // Parabolic interpolation for sub-sample accuracy
    const x1 = c[T0 - 1];
    const x2 = c[T0];
    const x3 = c[T0 + 1];
    const a = (x1 + x3 - 2 * x2) / 2;
    const b = (x3 - x1) / 2;
    if (a !== 0) {
      T0 = T0 - b / (2 * a);
    }

    return sampleRate / T0;
  };

  useEffect(() => {
    return () => {
      if (animationFrame.current) cancelAnimationFrame(animationFrame.current);
    };
  }, []);

  const getMeterColor = () => {
    if (Math.abs(centsOff) < 5) return '#4CAF50'; // Green - In tune
    if (Math.abs(centsOff) < 15) return '#FFEB3B'; // Yellow - Close
    return '#F44336'; // Red - Out of tune
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top, backgroundColor: theme.background }]}>
      <Stack.Screen options={{ headerShown: false }} />
      
      {/* Title Bar */}
      <View style={[styles.titleBar, { borderBottomColor: theme.border, backgroundColor: '#000' }]}>
        <Text style={[styles.appName, { color: '#fff' }]}>Guitar Tuner</Text>
      </View>

      <View style={styles.content}>
        <View style={styles.tunerDisplay}>
          {closestString ? (
            <>
              <Text style={[styles.noteText, { color: getMeterColor() }]}>
                {closestString.note}
              </Text>
              
              <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 30, backgroundColor: 'transparent' }}>
                <Text style={[styles.stringName, { color: theme.subtext, marginBottom: 0 }]}>
                  {closestString.name} String ({currentTuning.name})
                </Text>
                <TouchableOpacity 
                  onPress={() => setShowTuningModal(true)}
                  style={[styles.inlineChangeButton, { borderColor: theme.tint, marginLeft: 10 }]}
                >
                  <Text style={{ color: theme.tint, fontWeight: 'bold', fontSize: 10 }}>Change</Text>
                </TouchableOpacity>
              </View>
              
              <View style={styles.meterContainer}>
                <View style={[styles.meterBar, { backgroundColor: theme.border }]}>
                  <View 
                    style={[
                      styles.meterPointer, 
                      { 
                        left: `${50 + (centsOff / 50) * 50}%`,
                        backgroundColor: getScrollColor(centsOff)
                      }
                    ]} 
                  />
                  <View style={styles.centerMark} />
                </View>
                <View style={styles.meterLabels}>
                  <Text style={styles.label}>Flat</Text>
                  <Text style={[styles.label, { color: getMeterColor() }]}>
                    {Math.abs(centsOff) < 5 ? 'In Tune' : `${centsOff > 0 ? '+' : ''}${Math.round(centsOff)} cents`}
                  </Text>
                  <Text style={styles.label}>Sharp</Text>
                </View>
              </View>
            </>
          ) : (
            <View style={styles.idleContainer}>
              <Ionicons name="mic-outline" size={64} color={isListening ? theme.tint : theme.subtext} />
              <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 20, backgroundColor: 'transparent' }}>
                <Text style={[styles.idleText, { color: theme.subtext, marginTop: 0 }]}>
                  {isListening ? `Play a string (${currentTuning.name})...` : 'Tap to start tuning'}
                </Text>
                <TouchableOpacity 
                  onPress={() => setShowTuningModal(true)}
                  style={[styles.inlineChangeButton, { borderColor: theme.tint, marginLeft: 10 }]}
                >
                  <Text style={{ color: theme.tint, fontWeight: 'bold', fontSize: 10 }}>Change</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
        </View>

        {error && (
          <View style={styles.errorContainer}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}

        <View style={styles.controls}>
          <TouchableOpacity 
            style={[
              styles.actionButton, 
              { backgroundColor: isListening ? '#f44336' : theme.tint }
            ]} 
            onPress={isListening ? stopListening : startListening}
          >
            <Ionicons name={isListening ? "stop" : "mic"} size={24} color="#fff" />
            <Text style={styles.actionButtonText}>
              {isListening ? 'Stop Tuning' : 'Start Tuning'}
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.infoSection}>
          <Text style={[styles.infoTitle, { color: theme.text }]}>{currentTuning.name} Tuning</Text>
          <View style={styles.stringsGrid}>
            {currentTuning.strings.map(s => (
              <View key={s.name} style={[styles.stringInfo, { backgroundColor: theme.card, borderColor: theme.border }]}>
                <Text style={[styles.stringNote, { color: theme.text }]}>{s.note}</Text>
                <Text style={[styles.stringLabel, { color: theme.subtext }]}>{s.name}</Text>
              </View>
            ))}
          </View>
        </View>
      </View>

      {/* Tuning Selection Modal */}
      <Modal visible={showTuningModal} animationType="fade" transparent>
        <View style={styles.modalOverlay}>
          <View style={[styles.configCard, { backgroundColor: theme.card, borderColor: theme.border }]}>
            <Text style={[styles.modalTitle, { color: theme.text, marginBottom: 20 }]}>Select Tuning</Text>
            <ScrollView style={{ maxHeight: 400 }}>
              {['Guitar', 'Ukulele', 'Bass'].map(instrument => (
                <View key={instrument} style={{ backgroundColor: 'transparent' }}>
                  <View style={[styles.instrumentHeader, { backgroundColor: theme.tint + '10' }]}>
                    <Ionicons 
                      name={instrument === 'Guitar' ? 'musical-notes' : instrument === 'Ukulele' ? 'musical-note' : 'pulse'} 
                      size={16} 
                      color={theme.tint} 
                      style={{ marginRight: 8 }}
                    />
                    <Text style={[styles.instrumentHeaderText, { color: theme.tint }]}>{instrument}</Text>
                  </View>
                  {TUNINGS.filter(t => t.instrument === instrument).map((tuning) => {
                    const globalIndex = TUNINGS.indexOf(tuning);
                    return (
                      <TouchableOpacity 
                        key={tuning.name} 
                        style={[
                          styles.tuningOption, 
                          selectedTuningIndex === globalIndex && { backgroundColor: theme.tint + '20' }
                        ]}
                        onPress={() => {
                          setSelectedTuningIndex(globalIndex);
                          setShowTuningModal(false);
                          setString(null);
                        }}
                      >
                        <Text style={[
                          styles.tuningOptionText, 
                          { color: selectedTuningIndex === globalIndex ? theme.tint : theme.text }
                        ]}>
                          {tuning.name}
                        </Text>
                        {selectedTuningIndex === globalIndex && (
                          <Ionicons name="checkmark" size={20} color={theme.tint} />
                        )}
                      </TouchableOpacity>
                    );
                  })}
                </View>
              ))}
            </ScrollView>
            <TouchableOpacity 
              style={[styles.closeModalButton, { backgroundColor: theme.tint, marginTop: 20 }]} 
              onPress={() => setShowTuningModal(false)}
            >
              <Text style={styles.closeModalButtonText}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

function getScrollColor(cents: number) {
  if (Math.abs(cents) < 5) return '#4CAF50';
  if (Math.abs(cents) < 15) return '#FFEB3B';
  return '#F44336';
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  titleBar: {
    paddingHorizontal: 20,
    paddingVertical: 15,
    borderBottomWidth: 1,
  },
  appName: {
    fontSize: 22,
    fontWeight: 'bold',
    fontFamily: 'SpaceMono',
  },
  headerTuningButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 15,
    borderWidth: 1,
  },
  content: {
    flex: 1,
    padding: 20,
    justifyContent: 'space-between',
  },
  tunerDisplay: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'transparent',
  },
  idleContainer: {
    alignItems: 'center',
    backgroundColor: 'transparent',
  },
  idleText: {
    marginTop: 20,
    fontSize: 16,
    textAlign: 'center',
  },
  noteText: {
    fontSize: 84,
    fontWeight: 'bold',
    fontFamily: 'SpaceMono',
  },
  stringName: {
    fontSize: 18,
    marginBottom: 30,
  },
  meterContainer: {
    width: '100%',
    paddingHorizontal: 20,
    backgroundColor: 'transparent',
  },
  meterBar: {
    height: 10,
    borderRadius: 5,
    position: 'relative',
    overflow: 'visible',
  },
  meterPointer: {
    width: 4,
    height: 30,
    borderRadius: 2,
    position: 'absolute',
    top: -10,
    transform: [{ translateX: -2 }],
    zIndex: 2,
  },
  centerMark: {
    position: 'absolute',
    left: '50%',
    top: -5,
    width: 2,
    height: 20,
    backgroundColor: '#fff',
    transform: [{ translateX: -1 }],
    opacity: 0.5,
  },
  meterLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 25,
    backgroundColor: 'transparent',
  },
  label: {
    fontSize: 12,
    color: '#aaa',
  },
  controls: {
    alignItems: 'center',
    marginBottom: 30,
    backgroundColor: 'transparent',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 15,
    paddingHorizontal: 40,
    borderRadius: 30,
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
    marginLeft: 10,
  },
  errorContainer: {
    padding: 10,
    backgroundColor: 'rgba(244, 67, 54, 0.1)',
    borderRadius: 8,
    marginBottom: 20,
  },
  errorText: {
    color: '#f44336',
    textAlign: 'center',
    fontSize: 14,
  },
  infoSection: {
    backgroundColor: 'transparent',
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 15,
    textAlign: 'center',
  },
  stringsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: 'transparent',
  },
  stringInfo: {
    width: '15%',
    alignItems: 'center',
    paddingVertical: 10,
    borderRadius: 8,
    borderWidth: 1,
  },
  stringNote: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  stringLabel: {
    fontSize: 10,
    marginTop: 4,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  configCard: {
    width: '85%',
    padding: 20,
    borderRadius: 12,
    borderWidth: 1,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  tuningOption: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 15,
    paddingHorizontal: 10,
    borderRadius: 8,
    marginVertical: 2,
  },
  instrumentHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 10,
    borderRadius: 4,
    marginTop: 15,
    marginBottom: 5,
  },
  instrumentHeaderText: {
    fontSize: 14,
    fontWeight: 'bold',
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  tuningOptionText: {
    fontSize: 16,
    fontWeight: '500',
  },
  closeModalButton: {
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  closeModalButtonText: {
    color: '#fff',
    fontWeight: 'bold',
  },
});
