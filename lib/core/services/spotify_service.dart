import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String albumArt;
  final String spotifyUrl;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.albumArt,
    required this.spotifyUrl,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'],
      name: json['name'],
      artist: (json['artists'] as List).map((a) => a['name']).join(', '),
      albumArt: json['album']['images'].isNotEmpty
          ? json['album']['images'][0]['url']
          : 'https://api.dicebear.com/7.x/shapes/png?seed=spotify',
      spotifyUrl: json['external_urls']['spotify'],
    );
  }
}

class SpotifyService extends GetxService {
  static SpotifyService get to => Get.find();

  // IMPORTANT: User should provide these from Spotify Developer Dashboard
  final String _clientId = 'YOUR_CLIENT_ID';
  final String _clientSecret = 'YOUR_CLIENT_SECRET';

  String? _accessToken;
  DateTime? _tokenExpiry;

  bool get hasCredentials =>
      _clientId != 'YOUR_CLIENT_ID' && _clientSecret != 'YOUR_CLIENT_SECRET';

  Future<bool> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return true;
    }

    if (!hasCredentials) return false;

    try {
      final authStr = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $authStr',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in']),
        );
        return true;
      }
    } catch (e) {
      print('Spotify Auth Error: $e');
    }
    return false;
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    if (query.isEmpty) return [];

    final hasToken = await _getAccessToken();
    if (!hasToken) {
      throw Exception('Spotify credentials not configured or invalid');
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&limit=10',
        ),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List tracksJson = data['tracks']['items'];
        return tracksJson.map((json) => SpotifyTrack.fromJson(json)).toList();
      } else {
        throw Exception('Spotify Search Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Spotify Search Error: $e');
      rethrow;
    }
  }
}
