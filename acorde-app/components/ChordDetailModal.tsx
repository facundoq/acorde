import React, { useState, useEffect } from 'react';
import { StyleSheet, TouchableOpacity, Modal, View as DefaultView } from 'react-native';
import PagerView from './PagerView';
import { Text, View } from '@/components/Themed';
import { getChordShapes } from '@/constants/ChordShapes';
import ChordDiagram from './ChordDiagram';

interface ChordDetailModalProps {
  chordName: string | null;
  onClose: () => void;
  theme: any;
}

export default function ChordDetailModal({ chordName, onClose, theme }: ChordDetailModalProps) {
  const [currentShapeIndex, setCurrentShapeIndex] = useState(0);
  const availableShapes = chordName ? getChordShapes(chordName) : [];

  useEffect(() => {
    if (chordName) {
      setCurrentShapeIndex(0);
    }
  }, [chordName]);

  if (!chordName) return null;

  return (
    <Modal
      visible={!!chordName}
      transparent={true}
      animationType="fade"
      onRequestClose={onClose}
    >
      <TouchableOpacity 
        style={styles.modalOverlay} 
        activeOpacity={1} 
        onPress={onClose}
      >
        <View style={[styles.modalContent, { backgroundColor: theme.card, borderColor: theme.border }]}>
          <Text style={[styles.modalTitle, { color: theme.text }]}>{chordName}</Text>
          
          {availableShapes.length > 0 ? (
            <>
              <PagerView 
                style={styles.pagerView} 
                initialPage={0}
                onPageSelected={(e) => setCurrentShapeIndex(e.nativeEvent.position)}
              >
                {availableShapes.map((shape, idx) => (
                  <DefaultView key={idx} style={{ backgroundColor: 'transparent' }}>
                    <ChordDiagram shape={shape} theme={theme} />
                  </DefaultView>
                ))}
              </PagerView>

              {availableShapes.length > 1 && (
                <View style={styles.pagerIndicator}>
                  {availableShapes.map((_, idx) => (
                    <View 
                      key={idx} 
                      style={[
                        styles.indicatorDot, 
                        { 
                          backgroundColor: idx === currentShapeIndex ? theme.tint : theme.border,
                          width: idx === currentShapeIndex ? 12 : 8
                        }
                      ]} 
                    />
                  ))}
                </View>
              )}
            </>
          ) : (
            <View style={styles.noShapeContainer}>
              <Text style={{ color: theme.text }}>No diagram available for {chordName}</Text>
            </View>
          )}

          <TouchableOpacity 
            onPress={onClose}
            style={[styles.closeButton, { backgroundColor: theme.tint }]}
          >
            <Text style={styles.closeButtonText}>Close</Text>
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    </Modal>
  );
}

const styles = StyleSheet.create({
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    padding: 20,
    paddingTop: 30,
    paddingBottom: 20,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
    minWidth: 280,
  },
  modalTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  pagerView: {
    width: 240,
    height: 220,
  },
  pagerIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 20,
    marginTop: 10,
  },
  indicatorDot: {
    height: 8,
    borderRadius: 4,
    marginHorizontal: 4,
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
});
