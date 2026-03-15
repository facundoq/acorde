import React, { useEffect, useState } from 'react';
import { StyleSheet, ScrollView, TouchableOpacity, useColorScheme, ActivityIndicator } from 'react-native';
import { useLocalSearchParams, Stack, useRouter } from 'expo-router';
import { Text, View } from '@/components/Themed';
import { getSongById, SavedSong } from '@/services/database';
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
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];
  const router = useRouter();

  useEffect(() => {
    const loadSong = async () => {
      try {
        const data = await getSongById(Number(id));
        setSong(data);
      } catch (error) {
        console.error('Failed to load song:', error);
      } finally {
        setLoading(false);
      }
    };

    loadSong();
  }, [id]);

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
        }} 
      />
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: 'transparent' }}>
            <View style={{ flex: 1, backgroundColor: 'transparent' }}>
              <Text style={[styles.title, { color: theme.text }]}>{song.title}</Text>
              <Text style={[styles.artist, { color: theme.subtext }]}>{song.artist}</Text>
            </View>
            <View style={styles.fontControls}>
              <TouchableOpacity 
                style={[styles.fontButton, { borderColor: theme.border }]} 
                onPress={() => setFontSize(Math.max(8, fontSize - 2))}
              >
                <Text style={{ color: theme.text, fontSize: 18 }}>-</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.fontButton, { borderColor: theme.border, marginLeft: 10 }]} 
                onPress={() => setFontSize(Math.min(30, fontSize + 2))}
              >
                <Text style={{ color: theme.text, fontSize: 18 }}>+</Text>
              </TouchableOpacity>
            </View>
          </View>
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
  fontControls: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'transparent',
  },
  fontButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    borderWidth: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'transparent',
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
