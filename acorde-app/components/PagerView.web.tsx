import React from 'react';
import { ScrollView, View, StyleSheet, NativeSyntheticEvent, NativeScrollEvent } from 'react-native';

interface PagerViewProps {
  style?: any;
  initialPage?: number;
  onPageSelected?: (e: any) => void;
  children: React.ReactNode;
}

export default function PagerViewWeb({ style, children, onPageSelected }: PagerViewProps) {
  const handleScroll = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    if (!onPageSelected) return;
    
    const { contentOffset, layoutMeasurement } = event.nativeEvent;
    const page = Math.round(contentOffset.x / layoutMeasurement.width);
    
    onPageSelected({
      nativeEvent: { position: page }
    });
  };

  return (
    <ScrollView
      horizontal
      pagingEnabled
      showsHorizontalScrollIndicator={false}
      onMomentumScrollEnd={handleScroll}
      style={[style, styles.container]}
      contentContainerStyle={styles.content}
    >
      {React.Children.map(children, (child) => (
        <View style={styles.page}>
          {child}
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flexGrow: 1,
  },
  page: {
    width: 240, // Match the width from the styles in UGSongView/ChordDetailModal
    justifyContent: 'center',
    alignItems: 'center',
  },
});
