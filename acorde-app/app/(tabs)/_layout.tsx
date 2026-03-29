import React from 'react';
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useColorScheme } from 'react-native';
import Colors from '@/constants/Colors';

export default function TabLayout() {
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  return (
    <Tabs screenOptions={{ 
      headerShown: false,
      tabBarActiveTintColor: theme.tint,
      tabBarStyle: {
        backgroundColor: theme.background,
        borderTopColor: theme.border,
      }
    }}>
      <Tabs.Screen 
        name="index" 
        options={{
          title: 'My Tabs',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="musical-notes" size={size} color={color} />
          ),
        }} 
      />
      <Tabs.Screen 
        name="diagrams" 
        options={{
          title: 'Diagrams',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="grid" size={size} color={color} />
          ),
        }} 
      />
      <Tabs.Screen 
        name="tuner" 
        options={{
          title: 'Tuner',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="mic" size={size} color={color} />
          ),
        }} 
      />
    </Tabs>
  );
}
