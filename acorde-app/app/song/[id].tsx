import React, { useEffect, useState, useRef } from 'react';
import { StyleSheet, ScrollView, TouchableOpacity, useColorScheme, ActivityIndicator, Platform } from 'react-native';
import { useLocalSearchParams, Stack, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Text, View } from '@/components/Themed';
import { getSongById, SavedSong } from '@/services/database';
import { getFontSize, saveFontSize } from '@/services/settings';
import Colors from '@/constants/Colors';
import UGSongView from '@/components/UGSongView';
import ChordDetailModal from '@/components/ChordDetailModal';
import { isUGFormat } from '@/core/ug-parser';

export default function SongDetailScreen() {
  const { id } = useLocalSearchParams();
  const [song, setSong] = useState<SavedSong | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedChord, setSelectedChord] = useState<string | null>(null);
  const [fontSize, setFontSize] = useState(14);
  const [scrollSpeed, setScrollSpeed] = useState<'none' | 'low' | 'mid' | 'high'>('none');
  const scrollRef = useRef<ScrollView>(null);
  const scrollInterval = useRef<any>(null);
  const currentY = useRef(0);
  
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];
  const router = useRouter();

  // Load font size and handle scroll reset
  useEffect(() => {
    const loadData = async () => {
      try {
        const [songData, savedFontSize] = await Promise.all([
          getSongById(Number(id)),
          getFontSize()
        ]);
        setSong(songData);
        setFontSize(savedFontSize);
      } catch (error) {
        console.error('Failed to load song or settings:', error);
      } finally {
        setLoading(false);
      }
    };

    loadData();
    currentY.current = 0; // Reset scroll position tracker
  }, [id]);

  const changeFontSize = async (newSize: number) => {
    const clampedSize = Math.max(8, Math.min(30, newSize));
    setFontSize(clampedSize);
    await saveFontSize(clampedSize);
  };

  // Auto-scroll logic
  useEffect(() => {
    if (scrollInterval.current) {
      clearInterval(scrollInterval.current);
      scrollInterval.current = null;
    }

    if (scrollSpeed !== 'none') {
      const intervalMs = scrollSpeed === 'low' ? 80 : scrollSpeed === 'mid' ? 40 : 20;
      
      scrollInterval.current = setInterval(() => {
        currentY.current += 1;
        scrollRef.current?.scrollTo({ y: currentY.current, animated: false });
      }, intervalMs);
    }

    return () => {
      if (scrollInterval.current) clearInterval(scrollInterval.current);
    };
  }, [scrollSpeed]);

  const handleManualScroll = (event: any) => {
    // Update tracking position even during auto-scroll to handle user manual "nudges"
    currentY.current = event.nativeEvent.contentOffset.y;
  };

  const toggleScrollSpeed = () => {
    const speeds: ('none' | 'low' | 'mid' | 'high')[] = ['none', 'low', 'mid', 'high'];
    const currentIndex = speeds.indexOf(scrollSpeed);
    const nextIndex = (currentIndex + 1) % speeds.length;
    setScrollSpeed(speeds[nextIndex]);
  };

  const getScrollIcon = () => {
    switch (scrollSpeed) {
      case 'low': return "chevron-down-outline";
      case 'mid': return "chevron-down";
      case 'high': return "play-forward-outline";
      default: return "arrow-down-circle-outline";
    }
  };

  const getScrollColor = () => {
    return scrollSpeed === 'none' ? theme.text : theme.tint;
  };

  if (loading) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background, justifyContent: 'center' }]}>
        <ActivityIndicator size="large" color={theme.tint} />
      </View>
    );
  }

  if (!song) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background, justifyContent: 'center' }]}>
        <Text style={{ color: theme.text, textAlign: 'center' }}>Song not found</Text>
      </View>
    );
  }

  const content = song.chords || song.lyrics || '';
  const isUG = isUGFormat(content);

  // Simple heuristic to make chords clickable in regular text
  // This looks for words that are likely chords (uppercase letters and numbers)
  const renderStandardContent = (text: string) => {
    const lines = text.split('\n');
    return lines.map((line, lineIdx) => {
      // If a line is mostly chords (regex heuristic)
      const words = line.split(/(\s+)/);
      return (
        <Text key={lineIdx} style={[styles.lyricsChords, { color: theme.text, fontSize, lineHeight: fontSize * 1.4 }]}>
          {words.map((word, wordIdx) => {
            const trimmed = word.trim();
            // Basic regex for common chord patterns: [A-G][b#]?[maj|min|m|sus|dim|aug]?[0-9]?
            const isChord = /^[A-G][b#]?(maj|min|m|sus|dim|aug|add)?[0-9]?(sus[24])?(\/[A-G][b#]?)?$/.test(trimmed);
            
            if (isChord) {
              return (
                <Text 
                  key={wordIdx} 
                  style={{ color: theme.tint, fontWeight: 'bold', fontFamily: 'SpaceMono', fontSize }}
                  onPress={() => setSelectedChord(trimmed)}
                >
                  {word}
                </Text>
              );
            }
            return <Text key={wordIdx} style={{ fontFamily: 'SpaceMono', fontSize }}>{word}</Text>;
          })}
          {'\n'}
        </Text>
      );
    });
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <Stack.Screen 
        options={{ 
          title: song.title,
          headerBackTitle: 'Tabs',
          headerStyle: { backgroundColor: theme.background },
          headerTintColor: theme.tint,
          headerRight: () => (
            <View style={styles.headerControls}>
              <TouchableOpacity 
                style={[styles.headerButton, { borderColor: getScrollColor() }]} 
                onPress={toggleScrollSpeed}
              >
                <Ionicons 
                  name={getScrollIcon() as any} 
                  size={20} 
                  color={getScrollColor()} 
                />
              </TouchableOpacity>

              <View style={[styles.separator, { backgroundColor: theme.border, height: 20, marginHorizontal: 8 }]} />

              <TouchableOpacity 
                style={[styles.headerButton, { borderColor: theme.border }]} 
                onPress={() => changeFontSize(fontSize - 2)}
              >
                <Ionicons name="remove" size={18} color={theme.text} />
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.headerButton, { borderColor: theme.border, marginLeft: 8 }]} 
                onPress={() => changeFontSize(fontSize + 2)}
              >
                <Ionicons name="add" size={18} color={theme.text} />
              </TouchableOpacity>
            </View>
          )
        }} 
      />
      <ScrollView 
        ref={scrollRef}
        contentContainerStyle={styles.scrollContent}
        onScroll={handleManualScroll}
        scrollEventThrottle={16}
      >
        <View style={styles.header}>
          <Text style={[styles.title, { color: theme.text }]}>{song.title}</Text>
          <Text style={[styles.artist, { color: theme.subtext }]}>{song.artist}</Text>
          <View style={[styles.sourceContainer, { backgroundColor: theme.card }]}>
            <Text style={[styles.sourceText, { color: theme.subtext }]}>Source: {song.source}</Text>
          </View>
        </View>

        <View style={[styles.contentCard, { backgroundColor: theme.card, borderColor: theme.border }]}>
          {isUG ? (
            <UGSongView content={content} fontSize={fontSize} />
          ) : (
            <View style={{ backgroundColor: 'transparent' }}>
              {renderStandardContent(content)}
            </View>
          )}
        </View>
      </ScrollView>

      <ChordDetailModal 
        chordName={selectedChord} 
        onClose={() => setSelectedChord(null)} 
        theme={theme} 
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
  },
  header: {
    marginBottom: 20,
    backgroundColor: 'transparent',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  artist: {
    fontSize: 18,
    marginTop: 4,
  },
  headerControls: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'transparent',
    paddingRight: 10,
  },
  headerButton: {
    width: 34,
    height: 34,
    borderRadius: 17,
    borderWidth: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'transparent',
  },
  separator: {
    width: 1,
  },
  sourceContainer: {
    marginTop: 10,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
    alignSelf: 'flex-start',
  },
  sourceText: {
    fontSize: 12,
    textTransform: 'uppercase',
  },
  contentCard: {
    padding: 15,
    borderRadius: 8,
    borderWidth: 1,
  },
  lyricsChords: {
    fontFamily: 'SpaceMono', 
    fontSize: 14,
    lineHeight: 20,
  },
});
