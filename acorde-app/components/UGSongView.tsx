import React, { useState } from 'react';
import { StyleSheet, TouchableOpacity, Modal, ScrollView, useColorScheme, View as DefaultView } from 'react-native';
import { Text, View } from '@/components/Themed';
import { parseUGTabs, UGPart } from '@/core/ug-parser';
import Colors from '@/constants/Colors';
import { getChordShape, ChordShape } from '@/constants/ChordShapes';

interface UGSongViewProps {
  content: string;
}

export default function UGSongView({ content }: UGSongViewProps) {
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
            style={[styles.chordText, { color }]}
          >
            {part.content}
          </Text>
        );
      }
      case 'header':
        return (
          <Text key={index} style={[styles.headerText, { color: theme.tint }]}>
            {part.content}
          </Text>
        );
      case 'tab':
        // Recursively parse content inside [tab] tags to handle nested [ch] tags
        const nestedParts = parseUGTabs(part.content);
        return (
          <Text key={index} style={[styles.tabText, { color: theme.subtext }]}>
            {nestedParts.map((nestedPart, i) => renderPart(nestedPart, i))}
          </Text>
        );
      case 'text':
      default:
        return (
          <Text key={index} style={[styles.regularText, { color: theme.text }]}>
            {part.content}
          </Text>
        );
    }
  };

  const parts = parseUGTabs(content);

  return (
    <View style={styles.container}>
      <Text style={styles.contentWrapper}>
        {parts.map((part, index) => renderPart(part, index))}
      </Text>

      <Modal
        visible={!!selectedChord}
        transparent={true}
        animationType="fade"
        onRequestClose={() => setSelectedChord(null)}
      >
        <TouchableOpacity 
          style={styles.modalOverlay} 
          activeOpacity={1} 
          onPress={() => setSelectedChord(null)}
        >
          <View style={[styles.modalContent, { backgroundColor: theme.card, borderColor: theme.border }]}>
            {selectedChord && (
              <>
                <Text style={[styles.modalTitle, { color: theme.text }]}>{selectedChord}</Text>
                <ChordDiagram chordName={selectedChord} theme={theme} />
                <TouchableOpacity 
                  onPress={() => setSelectedChord(null)}
                  style={[styles.closeButton, { backgroundColor: theme.tint }]}
                >
                  <Text style={styles.closeButtonText}>Close</Text>
                </TouchableOpacity>
              </>
            )}
          </View>
        </TouchableOpacity>
      </Modal>
    </View>
  );
}

function ChordDiagram({ chordName, theme }: { chordName: string, theme: any }) {
  const shape = getChordShape(chordName);
  
  if (!shape) {
    return (
      <View style={styles.noShapeContainer}>
        <Text style={{ color: theme.text }}>No diagram available for {chordName}</Text>
      </View>
    );
  }

  // Basic representation of a guitar neck
  // 6 strings, 5 frets
  const strings = [0, 1, 2, 3, 4, 5]; // E, A, D, G, B, e
  const frets = [1, 2, 3, 4, 5];

  return (
    <DefaultView style={styles.diagramContainer}>
      <DefaultView style={{ flexDirection: 'row', alignItems: 'flex-start' }}>
        {/* Fret Numbers Column */}
        <DefaultView style={styles.fretNumbersColumn}>
          {frets.map(f => (
            <Text key={f} style={[styles.fretNumber, { top: (f - 0.5) * 30 + 5, color: theme.subtext }]}>
              {f}
            </Text>
          ))}
        </DefaultView>

        <DefaultView style={[styles.fretboard, { borderColor: theme.text }]}>
          {/* Nut or first fret line */}
          <DefaultView style={[styles.nut, { backgroundColor: theme.text }]} />
          
          {/* Frets */}
          {frets.map(f => (
            <DefaultView key={f} style={[styles.fret, { top: f * 30, backgroundColor: theme.text, opacity: 0.7 }]} />
          ))}

          {/* Barre Line */}
          {shape.barre && (
            <DefaultView style={[
              styles.barreLine, 
              { 
                top: (shape.barre - 0.5) * 30 - 4, 
                backgroundColor: theme.tint,
                opacity: 0.8
              }
            ]} />
          )}

          {/* Strings and fingers */}
          <DefaultView style={styles.stringsLayer}>
            {strings.map(s => {
              const fret = shape.frets[s];
              const finger = shape.fingers ? shape.fingers[s] : null;
              
              return (
                <DefaultView key={s} style={styles.stringContainer}>
                  {/* String line */}
                  <DefaultView style={[styles.stringLine, { backgroundColor: theme.text, opacity: 0.5 }]} />
                  
                  {/* Marker for muted or open */}
                  {fret === -1 && <Text style={[styles.marker, { color: 'red' }]}>X</Text>}
                  {fret === 0 && <Text style={[styles.marker, { color: theme.text }]}>O</Text>}
                  
                  {/* Finger position */}
                  {fret > 0 && (
                    <DefaultView style={[
                      styles.finger, 
                      { 
                        top: (fret - 0.5) * 30 + 5, 
                        backgroundColor: theme.tint 
                      }
                    ]}>
                      {finger && <Text style={styles.fingerText}>{finger}</Text>}
                    </DefaultView>
                  )}
                </DefaultView>
              );
            })}
          </DefaultView>
        </DefaultView>
      </DefaultView>
      
      {/* Barre indicator (simplified) */}
      {shape.barre && (
        <Text style={[styles.barreText, { color: theme.subtext, marginTop: 15 }]}>Barre on fret {shape.barre}</Text>
      )}
    </DefaultView>
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
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    width: 280,
    padding: 20,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
  },
  modalTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  closeButton: {
    marginTop: 20,
    paddingVertical: 10,
    paddingHorizontal: 30,
    borderRadius: 8,
  },
  closeButtonText: {
    color: 'white',
    fontWeight: 'bold',
  },
  noShapeContainer: {
    height: 150,
    justifyContent: 'center',
  },
  diagramContainer: {
    alignItems: 'center',
  },
  fretNumbersColumn: {
    width: 25,
    height: 160,
    marginRight: 5,
    position: 'relative',
  },
  fretNumber: {
    position: 'absolute',
    right: 5,
    fontSize: 12,
    fontWeight: 'bold',
  },
  fretboard: {
    width: 180,
    height: 160,
    borderLeftWidth: 1,
    borderRightWidth: 1,
    borderTopWidth: 1,
    position: 'relative',
  },
  barreLine: {
    position: 'absolute',
    left: 10,
    right: 10,
    height: 18,
    borderRadius: 9,
    zIndex: 1,
  },
  nut: {
    height: 5,
    width: '100%',
  },
  fret: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: 2,
  },
  stringsLayer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 10,
    height: '100%',
  },
  stringContainer: {
    width: 20,
    height: '100%',
    alignItems: 'center',
    position: 'relative',
  },
  stringLine: {
    width: 0.8,
    height: '100%',
    position: 'absolute',
  },
  marker: {
    position: 'absolute',
    top: -20,
    fontSize: 12,
    fontWeight: 'bold',
  },
  finger: {
    position: 'absolute',
    width: 18,
    height: 18,
    borderRadius: 9,
    justifyContent: 'center',
    alignItems: 'center',
  },
  fingerText: {
    color: 'white',
    fontSize: 10,
    fontWeight: 'bold',
  },
  barreText: {
    marginTop: 10,
    fontSize: 12,
    fontStyle: 'italic',
  }
});
