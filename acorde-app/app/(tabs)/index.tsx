import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { StyleSheet, FlatList, TouchableOpacity, TextInput, Alert, ActivityIndicator, Modal, useColorScheme, Switch, Platform, ScrollView, Linking } from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Text, View } from '@/components/Themed';
import { getSongs, searchLocalSongs, SavedSong, deleteSong, saveSong } from '@/services/database';
import { CifraclubSource } from '../../core/sources/CifraclubSource';
import { LaCuerdaSource } from '../../core/sources/LaCuerdaSource';
import { UltimateGuitarSource } from '../../core/sources/UltimateGuitarSource';
import { CifrasSource } from '../../core/sources/CifrasSource';
import { SongSearchResult } from '../../core/types';
import { Source } from '../../core/sources/Source';
import Colors from '@/constants/Colors';

const SOURCES_CONFIG_KEY = 'acorde_sources_config';

export default function TabsScreen() {
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];
  
  const [songs, setSongs] = useState<SavedSong[]>([]);
  const [query, setQuery] = useState('');
  const [totalCount, setTotalCount] = useState(0);
  
  // Configuration states
  const [selectedSources, setSelectedSources] = useState<Record<string, boolean>>({
    'ultimateguitar': true,
    'cifraclub': false,
    'lacuerda': false,
    'cifras': false,
  });
  const [showConfigModal, setShowConfigModal] = useState(false);

  // Online search states
  const [onlineResults, setOnlineResults] = useState<SongSearchResult[]>([]);
  const [searchingOnline, setSearchingOnline] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const [onlineError, setOnlineError] = useState<string | null>(null);
  
  const router = useRouter();

  const allSources: Source[] = useMemo(() => [
    new UltimateGuitarSource(),
    new CifraclubSource(),
    new LaCuerdaSource(),
    new CifrasSource(),
  ], []);

  const activeSources = useMemo(() => 
    allSources.filter(s => selectedSources[s.name]),
    [selectedSources, allSources]
  );

  // Load config on mount
  useEffect(() => {
    if (Platform.OS === 'web') {
      const saved = window.localStorage.getItem(SOURCES_CONFIG_KEY);
      if (saved) {
        try {
          setSelectedSources(JSON.parse(saved));
        } catch (e) {}
      }
    }
  }, []);

  // Save config when changed
  const toggleSource = (name: string, value: boolean) => {
    const newConfig = { ...selectedSources, [name]: value };
    setSelectedSources(newConfig);
    if (Platform.OS === 'web') {
      window.localStorage.setItem(SOURCES_CONFIG_KEY, JSON.stringify(newConfig));
    }
  };

  const loadSongs = useCallback(async () => {
    const all = await getSongs();
    setTotalCount(all.length);
    const results = query ? await searchLocalSongs(query) : all;
    setSongs(results);
  }, [query]);

  useFocusEffect(
    useCallback(() => {
      loadSongs();
    }, [loadSongs])
  );

  const handleOnlineSearch = async () => {
    if (!query.trim()) return;
    if (activeSources.length === 0) {
      alert('Please enable at least one search source in settings (gear icon).');
      return;
    }

    setSearchingOnline(true);
    setOnlineResults([]);
    setOnlineError(null);
    setStatus(`Searching online for "${query}"...`);
    
    let allResults: SongSearchResult[] = [];
    let lastError = null;
    
    try {
      console.log(`Starting online search for: ${query}`);
      for (const source of activeSources) {
        try {
          console.log(`Searching source: ${source.name}`);
          const results = await source.search(query);
          console.log(`Results from ${source.name}: ${results.length}`);
          allResults = [...allResults, ...results];
        } catch (err: any) {
          console.error(`Search error for ${source.name}:`, err);
          lastError = err.message;
        }
      }

      setOnlineResults(allResults);
      if (allResults.length === 0) {
        if (lastError) {
          setOnlineError(`No online results found (${lastError})`);
          setStatus(null);
        } else {
          setStatus(`No online results found for "${query}".`);
        }
      } else {
        setStatus(null);
      }
    } catch (err: any) {
      console.error("Critical search error:", err);
      setOnlineError(`A critical error occurred: ${err.message}`);
      setStatus(null);
    } finally {
      setSearchingOnline(false);
    }
  };

  const handleSaveOnline = async (item: SongSearchResult) => {
    try {
      setStatus(`Downloading from ${item.source}...`);
      setOnlineError(null);
      const source = allSources.find(s => s.name === item.source) || allSources[0];
      const songContent = await source.getSong(item.url);
      const songId = await saveSong({
        source_id: item.id,
        title: songContent.title,
        artist: songContent.artist,
        lyrics: songContent.lyrics,
        chords: songContent.chords || '',
        source: songContent.source,
        url: songContent.url,
        instrument: item.instrument || songContent.instrument,
        rating: item.rating || songContent.rating,
      });
      loadSongs();
      setOnlineResults([]);
      setStatus(null);
      // Redirect to the newly saved song
      router.push({ pathname: '/song/[id]', params: { id: songId } });
    } catch (error: any) {
      console.error('Save error:', error);
      setOnlineError(`Failed to save song (${error.message})`);
    } finally {
      setStatus(null);
    }
  };

  const handleDelete = (id: number, title: string) => {
    Alert.alert(
      'Delete Song',
      `Are you sure you want to delete "${title}" from your Tabs?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Delete', style: 'destructive', onPress: async () => { await deleteSong(id); loadSongs(); } },
      ]
    );
  };

  const getInstrumentIcon = (instrument?: string) => {
    const name = instrument?.toLowerCase() || '';
    if (name.includes('chord')) return 'musical-notes-outline';
    if (name.includes('tab')) return 'reorder-four-outline';
    if (name.includes('bass')) return 'musical-note';
    return 'musical-note-outline';
  };

  const renderStars = (rating?: number) => {
    if (!rating) return null;
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 >= 0.5;
    
    return (
      <View style={styles.starsContainer}>
        {[...Array(5)].map((_, i) => {
          let name: any = 'star-outline';
          if (i < fullStars) name = 'star';
          else if (i === fullStars && hasHalfStar) name = 'star-half';
          return <Ionicons key={i} name={name} size={12} color="#FFB300" />;
        })}
        <Text style={[styles.ratingText, { marginLeft: 4 }]}>{rating.toFixed(1)}</Text>
      </View>
    );
  };

  const renderOnlineResults = () => {
    if (onlineResults.length === 0) return null;
    return (
      <View style={styles.onlineSection}>
        <View style={[styles.sectionHeader, { borderBottomColor: theme.border }]}>
          <Text style={[styles.sectionTitle, { color: theme.text }]}>Online Results</Text>
          <TouchableOpacity onPress={() => setOnlineResults([])}>
            <Text style={{ color: theme.tint, fontWeight: 'bold' }}>Clear</Text>
          </TouchableOpacity>
        </View>
        {onlineResults.map((item, index) => (
          <View key={`${item.source}-${item.id}-${index}`} style={[styles.resultItem, { borderBottomColor: theme.border, backgroundColor: 'transparent' }]}>
            <View style={[styles.resultInfo, { backgroundColor: 'transparent' }]}>
              <Text style={[styles.title, { color: theme.text }]}>{item.title}</Text>
              <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: 'transparent', flexWrap: 'wrap' }}>
                <Text style={[styles.artist, { color: theme.subtext }]}>{item.artist}</Text>
                {item.instrument && (
                  <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: 'transparent', marginLeft: 8 }}>
                    <Ionicons name={getInstrumentIcon(item.instrument)} size={14} color={theme.tint} />
                    <Text style={[styles.instrumentTag, { color: theme.tint, marginLeft: 2 }]}>{item.instrument}</Text>
                  </View>
                )}
              </View>
              <Text style={[styles.resultSource, { color: theme.tint }]}>{item.source}</Text>
            </View>
            <View style={{ alignItems: 'flex-end', backgroundColor: 'transparent' }}>
              {renderStars(item.rating)}
              <TouchableOpacity style={[styles.saveButton, { backgroundColor: '#4CAF50', marginTop: 5 }]} onPress={() => handleSaveOnline(item)}>
                <Text style={styles.saveButtonText}>Add</Text>
              </TouchableOpacity>
            </View>
          </View>
        ))}
      </View>
    );
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top, backgroundColor: theme.background }]}>
      {/* Title Bar */}
      <View style={[styles.titleBar, { borderBottomColor: theme.border, backgroundColor: '#000' }]}>
        <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: 'transparent' }}>
          <Text style={[styles.appName, { color: '#fff' }]}>Acorde</Text>
          <View style={[styles.badge, { backgroundColor: theme.tint, marginLeft: 10 }]}>
            <Text style={styles.badgeText}>{totalCount} Tabs</Text>
          </View>
        </View>
        <TouchableOpacity onPress={() => setShowConfigModal(true)} style={styles.configButton}>
          <Ionicons name="settings-outline" size={24} color="#fff" />
        </TouchableOpacity>
      </View>

      <View style={styles.content}>
        <View style={styles.searchHeader}>
          <TextInput
            style={[styles.searchInput, { borderColor: theme.border, color: theme.text, backgroundColor: theme.card }]}
            placeholder="Search your Tabs..."
            placeholderTextColor={theme.subtext}
            value={query}
            onChangeText={setQuery}
            onSubmitEditing={handleOnlineSearch}
          />
          {query.length > 2 && (
            <TouchableOpacity 
              style={[styles.onlineSearchButton, { backgroundColor: theme.tint }]} 
              onPress={handleOnlineSearch}
              disabled={searchingOnline}
            >
              {searchingOnline ? <ActivityIndicator size="small" color="#fff" /> : <Text style={styles.onlineSearchButtonText}>Add Online</Text>}
            </TouchableOpacity>
          )}
        </View>

        <FlatList
          data={songs}
          keyExtractor={(item) => item.id.toString()}
          renderItem={({ item }) => (
            <TouchableOpacity 
              style={[styles.songItem, { borderBottomColor: theme.border }]} 
              onPress={() => router.push({ pathname: '/song/[id]', params: { id: item.id } })}
              onLongPress={() => handleDelete(item.id, item.title)}
            >
              <View style={styles.songInfo}>
                <Text style={[styles.title, { color: theme.text }]}>{item.title}</Text>
                <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: 'transparent' }}>
                  <Text style={[styles.artist, { color: theme.subtext }]}>{item.artist}</Text>
                  {item.instrument && (
                    <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: 'transparent', marginLeft: 8 }}>
                      <Ionicons name={getInstrumentIcon(item.instrument)} size={14} color={theme.tint} />
                      <Text style={[styles.instrumentTag, { color: theme.tint, marginLeft: 2 }]}>{item.instrument}</Text>
                    </View>
                  )}
                </View>
              </View>
              <View style={{ alignItems: 'flex-end', backgroundColor: 'transparent' }}>
                {renderStars(item.rating)}
                <Text style={[styles.sourceTag, { backgroundColor: theme.card, color: theme.subtext, marginTop: 4 }]}>{item.source}</Text>
              </View>
            </TouchableOpacity>
          )}
          ListEmptyComponent={<Text style={[styles.emptyText, { color: theme.subtext }]}>{query ? 'No matching local songs.' : 'Your Tabs list is empty.'}</Text>}
          ListFooterComponent={
            <View style={{ backgroundColor: 'transparent', paddingBottom: 40 }}>
              {status && (
                <View style={styles.statusContainer}>
                  <ActivityIndicator size="small" color={theme.tint} style={{ marginRight: 10 }} />
                  <Text style={[styles.statusText, { color: theme.tint }]}>{status}</Text>
                </View>
              )}
              {onlineError && <Text style={[styles.statusText, { color: '#f44336', marginTop: 20, fontWeight: 'bold', textAlign: 'center' }]}>{onlineError}</Text>}
              {renderOnlineResults()}
            </View>
          }
        />
      </View>

      {/* Configuration Modal */}
      <Modal visible={showConfigModal} animationType="fade" transparent>
        <View style={styles.modalOverlay}>
          <View style={[styles.configCard, { backgroundColor: theme.card }]}>
            <Text style={[styles.modalTitle, { color: theme.text, marginBottom: 20 }]}>Search Sources</Text>
            {allSources.map(source => (
              <View key={source.name} style={[styles.configRow, { backgroundColor: 'transparent' }]}>
                <Text style={{ color: theme.text, textTransform: 'capitalize' }}>{source.name}</Text>
                <Switch
                  value={selectedSources[source.name]}
                  onValueChange={(val) => toggleSource(source.name, val)}
                  trackColor={{ false: '#767577', true: theme.tint }}
                />
              </View>
            ))}

            <View style={[styles.separator, { backgroundColor: theme.border, marginVertical: 20 }]} />
            
            <Text style={[styles.modalTitle, { color: theme.text, fontSize: 16, marginBottom: 10 }]}>Native Android App</Text>
            <Text style={{ color: theme.subtext, fontSize: 12, marginBottom: 15 }}>
              Download the APK to bypass CORS and search restricted sites directly.
            </Text>
            <TouchableOpacity 
              style={[styles.doneButton, { backgroundColor: '#4CAF50', flexDirection: 'row' }]} 
              onPress={() => {
                if (Platform.OS === 'web') {
                  Linking.openURL('/acorde.apk');
                } else {
                  Alert.alert('Download', 'This feature is only available on the web version.');
                }
              }}
            >
              <Ionicons name="logo-android" size={20} color="#fff" style={{ marginRight: 10 }} />
              <Text style={styles.saveButtonText}>Download APK</Text>
            </TouchableOpacity>

            <TouchableOpacity style={[styles.doneButton, { marginTop: 15, backgroundColor: theme.tint }]} onPress={() => setShowConfigModal(false)}>
              <Text style={styles.saveButtonText}>Done</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { flex: 1, padding: 15, backgroundColor: 'transparent' },
  titleBar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, paddingVertical: 15 },
  appName: { fontSize: 22, fontWeight: 'bold', fontFamily: 'SpaceMono' },
  badge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12 },
  badgeText: { color: '#fff', fontSize: 12, fontWeight: 'bold' },
  searchHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 10, backgroundColor: 'transparent' },
  searchInput: { flex: 1, height: 45, borderWidth: 1, borderRadius: 8, paddingHorizontal: 15, fontSize: 16 },
  onlineSearchButton: { paddingHorizontal: 12, height: 45, justifyContent: 'center', borderRadius: 8, marginLeft: 10 },
  onlineSearchButtonText: { color: '#fff', fontWeight: 'bold', fontSize: 12 },
  statusText: { fontStyle: 'italic', backgroundColor: 'transparent' },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 20,
    backgroundColor: 'transparent',
  },
  songItem: { flexDirection: 'row', paddingVertical: 15, borderBottomWidth: 1, alignItems: 'center', backgroundColor: 'transparent' },
  songInfo: { flex: 1, backgroundColor: 'transparent' },
  title: { fontSize: 16, fontWeight: 'bold' },
  artist: { fontSize: 14 },
  instrumentTag: { fontSize: 12, fontWeight: '600' },
  starsContainer: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'transparent' },
  ratingText: { fontSize: 12, fontWeight: 'bold', color: '#FFB300' },
  sourceTag: { fontSize: 10, paddingHorizontal: 6, paddingVertical: 2, borderRadius: 4, overflow: 'hidden' },
  emptyText: { textAlign: 'center', marginTop: 50, paddingHorizontal: 20, backgroundColor: 'transparent' },
  // Online section styles
  onlineSection: { marginTop: 20, backgroundColor: 'transparent' },
  sectionHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingBottom: 10, borderBottomWidth: 1, marginBottom: 10, backgroundColor: 'transparent' },
  sectionTitle: { fontSize: 18, fontWeight: 'bold' },
  resultItem: { flexDirection: 'row', paddingVertical: 15, borderBottomWidth: 1, alignItems: 'center', backgroundColor: 'transparent' },
  resultInfo: { flex: 1, backgroundColor: 'transparent' },
  resultSource: { fontSize: 10, marginTop: 2, textTransform: 'uppercase', fontWeight: 'bold', backgroundColor: 'transparent' },
  saveButton: { paddingVertical: 8, paddingHorizontal: 15, borderRadius: 5 },
  doneButton: { paddingVertical: 12, paddingHorizontal: 20, borderRadius: 8, alignItems: 'center' },
  saveButtonText: { color: '#fff', fontWeight: 'bold' },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center' },
  separator: { height: 1, width: '100%' },
  configCard: { width: '80%', padding: 20, borderRadius: 12 },
  configRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 10 },
  configButton: { padding: 5, backgroundColor: 'transparent' }
});
