import React, { useEffect, useState } from 'react';
import { StyleSheet, ScrollView, TouchableOpacity, useColorScheme, ActivityIndicator } from 'react-native';
import { useLocalSearchParams, Stack, useRouter } from 'expo-router';
import { Text, View } from '@/components/Themed';
import { getSongById, SavedSong } from '@/services/database';
import Colors from '@/constants/Colors';

export default function SongDetailScreen() {
  const { id } = useLocalSearchParams();
  const [song, setSong] = useState<SavedSong | null>(null);
  const [loading, setLoading] = useState(true);
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
          <Text style={[styles.title, { color: theme.text }]}>{song.title}</Text>
          <Text style={[styles.artist, { color: theme.subtext }]}>{song.artist}</Text>
          <View style={[styles.sourceContainer, { backgroundColor: theme.card }]}>
            <Text style={[styles.sourceText, { color: theme.subtext }]}>Source: {song.source}</Text>
          </View>
        </View>

        <View style={[styles.contentCard, { backgroundColor: theme.card, borderColor: theme.border }]}>
          <Text style={[styles.lyricsChords, { color: theme.text }]}>
            {song.chords || song.lyrics}
          </Text>
        </View>
      </ScrollView>
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
