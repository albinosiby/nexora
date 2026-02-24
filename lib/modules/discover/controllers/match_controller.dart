import 'package:get/get.dart';
import '../models/match_user_model.dart';
import '../repositories/match_repository.dart';

class MatchController extends GetxController {
  static MatchController get to => Get.find<MatchController>();

  final MatchRepository _matchRepo = MatchRepository.instance;

  // State
  final allUsers = <MatchUserModel>[].obs;
  final filteredUsers = <MatchUserModel>[].obs;
  final isLoading = true.obs;
  final selectedFilter = 0.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Bind the stream to allUsers
    allUsers.bindStream(_matchRepo.getUsersStream());

    // Set isLoading to false once we have data
    ever(allUsers, (_) => isLoading.value = false);

    // Re-filter whenever users, selectedFilter, or searchQuery changed
    everAll([allUsers, selectedFilter, searchQuery], (_) => _applyFilters());
  }

  void _applyFilters() {
    filteredUsers.value = allUsers.where((user) {
      // Apply filter
      switch (selectedFilter.value) {
        case 1: // Online
          if (!user.isOnline) return false;
          break;
        case 2: // New (less than 50 connections)
          if (user.connections >= 50) return false;
          break;
        case 3: // Verified
          if (!user.isVerified) return false;
          break;
        default:
          break;
      }

      // Apply search
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        if (!(user.name.toLowerCase().contains(query) ||
            user.major.toLowerCase().contains(query) ||
            user.interests.join(' ').toLowerCase().contains(query) ||
            user.bio.toLowerCase().contains(query))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get onlineCount => allUsers.where((u) => u.isOnline).length;

  void setFilter(int index) {
    selectedFilter.value = index;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
}
