import React, { useState } from 'react';
import { StyleSheet, useColorScheme } from 'react-native';
import { Text, View } from '@/components/Themed';
import { parseUGTabs, UGPart } from '@/core/ug-parser';
import Colors from '@/constants/Colors';
import { getChordShape } from '@/constants/ChordShapes';
import ChordDetailModal from './ChordDetailModal';

interface UGSongViewProps {
  content: string;
  fontSize?: number;
}

export default function UGSongView({ content, fontSize = 14 }: UGSongViewProps) {
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  const [selectedChord, setSelectedChord] = useState<string | null>(null);

  const renderPart = (part: UGPart, index: number): React.ReactNode => {
    switch (part.type) {
      case 'chord': {
        const shape = getChordShape(part.content);
        const color = shape ? theme.tint : '#FFD700'; // Yellowish for unknown
        return (
          <Text 
            key={index} 
            onPress={() => setSelectedChord(part.content)}
            style={[styles.chordText, { color, fontSize: fontSize + 1 }]}
          >
            {part.content}
          </Text>
        );
      }
      case 'header':
        return (
          <Text key={index} style={[styles.headerText, { color: theme.tint, fontSize }]}>
            {part.content}
          </Text>
        );
      case 'tab':
        // Recursively parse content inside [tab] tags to handle nested [ch] tags
        const nestedParts = parseUGTabs(part.content);
        return (
          <Text key={index} style={[styles.tabText, { color: theme.subtext, fontSize: fontSize - 1 }]}>
            {nestedParts.map((nestedPart, i) => renderPart(nestedPart, i))}
          </Text>
        );
      case 'text':
      default:
        return (
          <Text key={index} style={[styles.regularText, { color: theme.text, fontSize }]}>
            {part.content}
          </Text>
        );
    }
  };

  const parts = parseUGTabs(content);

  return (
    <View style={styles.container}>
      <Text style={[styles.contentWrapper, { fontSize, lineHeight: fontSize * 1.4 }]}>
        {parts.map((part, index) => renderPart(part, index))}
      </Text>

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
    backgroundColor: 'transparent',
  },
  contentWrapper: {
    fontFamily: 'SpaceMono',
    fontSize: 14,
    lineHeight: 20,
  },
  chordText: {
    fontFamily: 'SpaceMono',
    fontWeight: 'bold',
    fontSize: 15,
  },
  headerText: {
    fontFamily: 'SpaceMono',
    fontWeight: 'bold',
    fontSize: 14,
    marginTop: 10,
    marginBottom: 5,
  },
  tabText: {
    fontFamily: 'SpaceMono',
    fontSize: 13,
  },
  regularText: {
    fontFamily: 'SpaceMono',
    fontSize: 14,
  }
});
