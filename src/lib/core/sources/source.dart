import '../models.dart';

abstract class Source {
  String get name;
  Future<List<SongSearchResult>> search(String query);
  Future<SongContent> getSong(String url);
}
