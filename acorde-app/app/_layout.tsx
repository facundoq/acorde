import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, useColorScheme } from 'react-native';
import 'react-native-reanimated';

import { initDatabase } from '@/services/database';
import { initSettings } from '@/services/settings';
import { Text, View } from '@/components/Themed';
import { Typography } from '@/constants/Typography';
import Colors from '@/constants/Colors';

export {
  // Catch any errors thrown by the Layout component.
  ErrorBoundary,
} from 'expo-router';

export const unstable_settings = {
  initialRouteName: '(tabs)',
};

// Prevent the splash screen from auto-hiding before asset loading is complete.
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const systemColorScheme = useColorScheme();
  const [loaded, error] = useFonts({
    RecursiveMono: require('../assets/fonts/Recursive.ttf'),
  });
  const [dbLoaded, setDbLoaded] = useState(false);
  const [loadingTask, setLoadingTask] = useState('Starting up...');
  
  const colorScheme = systemColorScheme ?? 'light';
  const theme = Colors[colorScheme];

  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (!loaded) {
      setLoadingTask('Loading system fonts...');
    } else if (!dbLoaded) {
      setLoadingTask('Preparing your local database...');
    }
  }, [loaded, dbLoaded]);

  useEffect(() => {
    const bootstrap = async () => {
      try {
        console.log('Starting bootstrap...');
        await Promise.all([initDatabase(), initSettings()]);
        console.log('Database and settings initialized.');
      } catch (err) {
        console.error('Failed to init database:', err);
      } finally {
        setDbLoaded(true);
      }
    };

    bootstrap();
  }, []);

  useEffect(() => {
    if (loaded && dbLoaded) {
      console.log('Fonts and DB loaded, hiding splash screen.');
      setLoadingTask('Ready!');
      SplashScreen.hideAsync().catch(() => {});
    }
  }, [loaded, dbLoaded]);

  if (!loaded || !dbLoaded) {
    return (
      <View style={[styles.loadingContainer, { backgroundColor: '#000' }]}>
        <Text style={[styles.loadingText, { color: '#fff' }]}>Acorde</Text>
        <ActivityIndicator size="large" color="#fff" />
        <Text style={[styles.subText, { color: '#aaa' }]}>{loadingTask}</Text>
      </View>
    );
  }

  return <RootLayoutNav />;
}

function RootLayoutNav() {
  const colorScheme = useColorScheme();

  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <Stack>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      </Stack>
    </ThemeProvider>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    fontSize: 32,
    fontWeight: 'bold',
    ...Typography.mono as any,
    marginBottom: 20,
  },
  subText: {
    marginTop: 20,
    fontSize: 14,
  },
});
