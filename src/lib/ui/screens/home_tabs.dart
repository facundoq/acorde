import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'diagrams_screen.dart';
import 'tuner_screen.dart';
import 'collection_screen.dart';

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _currentIndex = 0; // Collection is now at index 0 as default tab

  final GlobalKey<SearchScreenState> _searchKey =
      GlobalKey<SearchScreenState>();
  final GlobalKey<CollectionScreenState> _collectionKey =
      GlobalKey<CollectionScreenState>();
  final GlobalKey<CollectionScreenState> _favoritesKey =
      GlobalKey<CollectionScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CollectionScreen(key: _collectionKey, onSearchOnline: _onSearchOnline),
      CollectionScreen(
        key: _favoritesKey,
        onSearchOnline: _onSearchOnline,
        showOnlyFavorites: true,
      ),
      SearchScreen(key: _searchKey),
      const DiagramsScreen(),
      const TunerScreen(),
    ];
  }

  void _onSearchOnline(String query) {
    setState(() {
      _currentIndex = 2; // Search index is now 2
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchKey.currentState?.triggerOnlineSearch(query);
    });
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      _collectionKey.currentState?.loadSongs();
    } else if (index == 1) {
      _favoritesKey.currentState?.loadSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Collection',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_on_outlined),
            selectedIcon: Icon(Icons.grid_on),
            label: 'Diagrams',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Tuner',
          ),
        ],
      ),
    );
  }
}
