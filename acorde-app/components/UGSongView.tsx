import React, { useState } from 'react';
import { StyleSheet, useColorScheme, View as DefaultView } from 'react-native';
import { Text, View } from '@/components/Themed';
import { parseUGTabs, UGPart, parseAlignedSegments, AlignedLine } from '@/core/ug-parser';
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

  const renderAlignedLine = (line: AlignedLine, lineIndex: number) => {
    // 1. Paired line: Chords specifically aligned over lyrics
    if (line.type === 'paired') {
      return (
        <View key={lineIndex} style={styles.alignedLine}>
          {line.segments.map((segment, segIndex) => {
            const shape = segment.chord ? getChordShape(segment.chord) : null;
            const color = segment.chord ? (shape ? theme.tint : '#FFD700') : 'transparent';
            
            return (
              <View key={segIndex} style={styles.segment}>
                <Text 
                  onPress={segment.chord ? () => setSelectedChord(segment.chord) : undefined}
                  style={[styles.chordText, { color, fontSize: fontSize + 1, minHeight: fontSize + 5 }]}
                >
                  {segment.chord || ' '}
                </Text>
                <Text style={[styles.regularText, { color: theme.text, fontSize, minHeight: fontSize + 2 }]}>
                  {segment.text || (segment.chord ? ' ' : '')}
                </Text>
              </View>
            );
          })}
        </View>
      );
    }

    // 2. Single line: Chords only, or plain text
    return (
      <Text key={lineIndex} style={[styles.regularText, { color: theme.text, fontSize, marginBottom: 5 }]}>
        {line.segments.map((segment, segIndex) => {
          if (segment.chord) {
            const shape = getChordShape(segment.chord);
            const color = shape ? theme.tint : '#FFD700';
            return (
              <Text 
                key={segIndex}
                onPress={() => setSelectedChord(segment.chord!)}
                style={[styles.chordText, { color, fontSize: fontSize + 1 }]}
              >
                {segment.chord}
              </Text>
            );
          }
          return <Text key={segIndex}>{segment.text}</Text>;
        })}
      </Text>
    );
  };

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
        const alignedLines = parseAlignedSegments(part.content);
        return (
          <View key={index} style={styles.tabContainer}>
            {alignedLines.map((line, i) => renderAlignedLine(line, i))}
          </View>
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
      <View style={{ backgroundColor: 'transparent' }}>
        {parts.map((part, index) => renderPart(part, index))}
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
    backgroundColor: 'transparent',
  },
  chordText: {
    fontFamily: 'SpaceMono',
    fontWeight: 'bold',
  },
  headerText: {
    fontFamily: 'SpaceMono',
    fontWeight: 'bold',
    marginTop: 10,
    marginBottom: 5,
  },
  tabContainer: {
    backgroundColor: 'transparent',
    marginVertical: 5,
  },
  alignedLine: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    backgroundColor: 'transparent',
    marginBottom: 5,
  },
  segment: {
    flexDirection: 'column',
    alignItems: 'flex-start',
    backgroundColor: 'transparent',
  },
  regularText: {
    fontFamily: 'SpaceMono',
  }
});
