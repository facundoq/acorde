class SongSearchResult {
  final String id;
  final String title;
  final String artist;
  final String source;
  final String url;
  final String? instrument;
  final double? rating;
  final int? ratingCount;
  final String? type; // 'song' or 'artist'

  SongSearchResult({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    required this.url,
    this.instrument,
    this.rating,
    this.ratingCount,
    this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'source': source,
      'url': url,
      'instrument': instrument,
      'rating': rating,
      'rating_count': ratingCount,
      'type': type,
    };
  }

  factory SongSearchResult.fromJson(Map<String, dynamic> json) {
    return SongSearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      source: json['source'] as String,
      url: json['url'] as String,
      instrument: json['instrument'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int?,
      type: json['type'] as String?,
    );
  }
}

class SongContent {
  final String title;
  final String artist;
  final String lyrics;
  final String? chords;
  final String url;
  final String source;
  final String? instrument;
  final double? rating;
  final int? ratingCount;

  SongContent({
    required this.title,
    required this.artist,
    required this.lyrics,
    this.chords,
    required this.url,
    required this.source,
    this.instrument,
    this.rating,
    this.ratingCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'lyrics': lyrics,
      'chords': chords,
      'url': url,
      'source': source,
      'instrument': instrument,
      'rating': rating,
      'rating_count': ratingCount,
    };
  }

  factory SongContent.fromJson(Map<String, dynamic> json) {
    return SongContent(
      title: json['title'] as String,
      artist: json['artist'] as String,
      lyrics: json['lyrics'] as String,
      chords: json['chords'] as String?,
      url: json['url'] as String,
      source: json['source'] as String,
      instrument: json['instrument'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int?,
    );
  }
}

String detectInstrument(String? url, String? title, String? lyrics) {
  final cleanUrl = (url ?? '').toLowerCase();
  final cleanTitle = (title ?? '').toLowerCase();
  final cleanLyrics = (lyrics ?? '').toLowerCase();

  if (cleanUrl.contains('ukulele') ||
      cleanTitle.contains('ukulele') ||
      cleanTitle.contains('ukelele')) {
    return 'Ukulele';
  }
  if (cleanUrl.contains('bass') ||
      cleanUrl.contains('bajo') ||
      cleanTitle.contains('bass') ||
      cleanTitle.contains('bajo')) {
    return 'Bass';
  }
  if (cleanUrl.contains('harmonica') ||
      cleanUrl.contains('armonica') ||
      cleanTitle.contains('harmonica') ||
      cleanTitle.contains('armonica') ||
      cleanLyrics.contains('harmonica') ||
      cleanLyrics.contains('armonica')) {
    return 'Harmonica';
  }
  if (cleanUrl.contains('piano') ||
      cleanUrl.contains('teclado') ||
      cleanTitle.contains('piano') ||
      cleanTitle.contains('teclado') ||
      cleanUrl.contains('keyboard') ||
      cleanTitle.contains('keyboard')) {
    return 'Piano';
  }
  return 'Chords';
}
