import React from 'react';
import { StyleSheet, View as DefaultView } from 'react-native';
import { Text } from '@/components/Themed';
import { ChordShape } from '@/constants/ChordShapes';

interface ChordDiagramProps {
  shape: ChordShape;
  theme: any;
}

export default function ChordDiagram({ shape, theme }: ChordDiagramProps) {
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
                  {fret > 0 && !(shape.barre === fret && finger === 1) && (
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
  diagramContainer: {
    alignItems: 'center',
  },
  fretNumbersColumn: {
    width: 25,
    height: 180,
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
    height: 180,
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
