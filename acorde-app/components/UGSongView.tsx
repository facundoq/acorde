import React, { useState } from 'react';
import { StyleSheet, useColorScheme, View as DefaultView, Pressable } from 'react-native';
import { Text, View } from '@/components/Themed';
import { parseUGTabs, UGPart, parseAlignedSegments, AlignedLine } from '@/core/ug-parser';
import Colors from '@/constants/Colors';
import { getChordShape } from '@/constants/ChordShapes';
import { Typography } from '@/constants/Typography';
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
                {segment.chord ? (
                  <Pressable 
                    onPress={() => setSelectedChord(segment.chord!)}
                    style={({ hovered, pressed }) => [
                      styles.chordPressable,
                      (hovered || pressed) && { backgroundColor: theme.tabIconDefault + '44', borderRadius: 2 }
                    ]}
                  >
                    <Text style={[styles.chordText, { color, fontSize: fontSize + 1, minHeight: fontSize + 5 }]}>
                      {segment.chord}
                    </Text>
                  </Pressable>
                ) : (
                  <Text style={[styles.chordText, { color: 'transparent', fontSize: fontSize + 1, minHeight: fontSize + 5 }]}>
                    {' '}
                  </Text>
                )}
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
      <Text key={lineIndex} style={[styles.regularText, { color: theme.text, fontSize }]}>
        {line.segments.map((segment, segIndex) => {
          if (segment.chord) {
            const shape = getChordShape(segment.chord);
            const color = shape ? theme.tint : '#FFD700';
            return (
              <Pressable 
                key={segIndex}
                onPress={() => setSelectedChord(segment.chord!)}
                style={({ hovered, pressed }) => [
                  styles.inlineChordPressable,
                  (hovered || pressed) && { backgroundColor: theme.tabIconDefault + '44', borderRadius: 2 }
                ]}
              >
                <Text style={[styles.chordText, { color, fontSize: fontSize + 1 }]}>
                  {segment.chord}
                </Text>
              </Pressable>
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
          <Pressable 
            key={index}
            onPress={() => setSelectedChord(part.content)}
            style={({ hovered, pressed }) => [
              styles.inlineChordPressable,
              (hovered || pressed) && { backgroundColor: theme.tabIconDefault + '44', borderRadius: 2 }
            ]}
          >
            <Text style={[styles.chordText, { color, fontSize: fontSize + 1 }]}>
              {part.content}
            </Text>
          </Pressable>
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
    ...Typography.mono as any,
    fontWeight: 'bold',
  },
  chordPressable: {
    backgroundColor: 'transparent',
  },
  inlineChordPressable: {
    backgroundColor: 'transparent',
    display: 'inline-flex',
  },
  headerText: {
    ...Typography.mono as any,
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
  },
  segment: {
    flexDirection: 'column',
    alignItems: 'flex-start',
    backgroundColor: 'transparent',
  },
  regularText: {
    ...Typography.mono as any,
  }
});
