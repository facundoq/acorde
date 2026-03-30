import React, { useState, useMemo } from 'react';
import { StyleSheet, FlatList, TouchableOpacity, TextInput, useColorScheme, View as DefaultView } from 'react-native';
import { Stack } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Text, View } from '@/components/Themed';
import { Typography } from '@/constants/Typography';
import Colors from '@/constants/Colors';
import { CHORD_SHAPES } from '@/constants/ChordShapes';
import ChordDetailModal from '@/components/ChordDetailModal';

export default function DiagramsScreen() {
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];
  
  const [query, setQuery] = useState('');
  const [selectedChord, setSelectedChord] = useState<string | null>(null);

  const allChords = useMemo(() => Object.keys(CHORD_SHAPES).sort(), []);

  const filteredChords = useMemo(() => {
    if (!query.trim()) return allChords;
    const q = query.toLowerCase();
    return allChords.filter(chord => chord.toLowerCase().includes(q));
  }, [query, allChords]);

  const renderChordItem = ({ item }: { item: string }) => (
    <TouchableOpacity 
      style={[styles.chordItem, { backgroundColor: theme.card, borderColor: theme.border }]}
      onPress={() => setSelectedChord(item)}
    >
      <Text style={[styles.chordName, { color: theme.text }]}>{item}</Text>
      <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: 'transparent' }}>
        <Text style={[styles.variantCount, { color: theme.subtext }]}>
          {CHORD_SHAPES[item].length} {CHORD_SHAPES[item].length === 1 ? 'shape' : 'shapes'}
        </Text>
        <Ionicons name="chevron-forward" size={18} color={theme.border} />
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top, backgroundColor: theme.background }]}>
      <Stack.Screen options={{ headerShown: false }} />
      
      {/* Title Bar */}
      <View style={[styles.titleBar, { borderBottomColor: theme.border, backgroundColor: '#000' }]}>
        <Text style={[styles.appName, { color: '#fff' }]}>Chord Diagrams</Text>
      </View>

      <View style={styles.content}>
        <View style={styles.searchHeader}>
          <TextInput
            style={[styles.searchInput, { borderColor: theme.border, color: theme.text, backgroundColor: theme.card }]}
            placeholder="Search chords (e.g. C, G#m7, Bb)..."
            placeholderTextColor={theme.subtext}
            value={query}
            onChangeText={setQuery}
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>

        <FlatList
          data={filteredChords}
          keyExtractor={(item) => item}
          renderItem={renderChordItem}
          contentContainerStyle={{ paddingBottom: 20 }}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="help-circle-outline" size={48} color={theme.subtext} />
              <Text style={[styles.emptyText, { color: theme.subtext }]}>
                Chord "{query}" not found in our database yet.
              </Text>
            </View>
          }
        />
      </View>

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
  titleBar: {
    paddingHorizontal: 20,
    paddingVertical: 15,
    borderBottomWidth: 1,
  },
  appName: {
    fontSize: 22,
    fontWeight: 'bold',
    ...Typography.mono as any,
  },
  content: {
    flex: 1,
    padding: 15,
    backgroundColor: 'transparent',
  },
  searchHeader: {
    marginBottom: 15,
    backgroundColor: 'transparent',
  },
  searchInput: {
    height: 45,
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 15,
    fontSize: 16,
  },
  chordItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 15,
    paddingHorizontal: 15,
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 10,
  },
  chordName: {
    fontSize: 18,
    fontWeight: 'bold',
    ...Typography.mono as any,
  },
  variantCount: {
    fontSize: 14,
    marginRight: 5,
  },
  emptyContainer: {
    alignItems: 'center',
    marginTop: 50,
    backgroundColor: 'transparent',
  },
  emptyText: {
    marginTop: 10,
    fontSize: 16,
    textAlign: 'center',
    paddingHorizontal: 40,
  },
});
