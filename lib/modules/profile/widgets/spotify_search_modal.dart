import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/spotify_service.dart';
import '../../../../core/theme/nexora_theme.dart';
import '../../../../core/widgets/glass_container.dart';

class SpotifySearchModal extends StatefulWidget {
  const SpotifySearchModal({super.key});

  @override
  State<SpotifySearchModal> createState() => _SpotifySearchModalState();
}

class _SpotifySearchModalState extends State<SpotifySearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final SpotifyService _spotifyService = SpotifyService.to;

  List<SpotifyTrack> _results = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _spotifyService.searchTracks(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('YOUR_CLIENT_ID')
            ? 'Spotify API not configured. Please add Client ID/Secret.'
            : 'Failed to fetch tracks. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NexoraColors.midnightPurple.withOpacity(0.95),
            NexoraColors.midnightDark.withOpacity(0.98),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        border: Border.all(
          color: NexoraColors.primaryPurple.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: NexoraColors.primaryPurple,
                  size: 24.r,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Search Spotify',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: NexoraColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: NexoraColors.textMuted,
                    size: 24.r,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: GlassContainer(
              borderRadius: 16.r,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _search,
                style: const TextStyle(color: NexoraColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search for a song or artist...',
                  hintStyle: TextStyle(color: NexoraColors.textMuted),
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.search,
                    color: NexoraColors.primaryPurple,
                    size: 20.r,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: NexoraColors.primaryPurple,
                    ),
                  )
                : _error != null
                ? _buildErrorState()
                : _results.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final track = _results[index];
                      return _buildTrackTile(track);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(SpotifyTrack track) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: GlassContainer(
        borderRadius: 16.r,
        padding: EdgeInsets.all(12.r),
        child: InkWell(
          onTap: () => Navigator.pop(context, track),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  track.albumArt,
                  width: 50.r,
                  height: 50.r,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: TextStyle(
                        color: NexoraColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: TextStyle(
                        color: NexoraColors.textMuted,
                        fontSize: 13.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: NexoraColors.primaryPurple,
                size: 24.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: NexoraColors.error, size: 48.r),
            SizedBox(height: 16.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: NexoraColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_off_outlined,
            color: Colors.white.withOpacity(0.1),
            size: 64.r,
          ),
          SizedBox(height: 16.h),
          Text(
            _searchController.text.isEmpty
                ? 'Type to find your anthem'
                : 'No tracks found',
            style: TextStyle(color: NexoraColors.textMuted, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
