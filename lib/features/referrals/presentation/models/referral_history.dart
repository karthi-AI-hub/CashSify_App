import 'package:cashsify_app/core/utils/logger.dart';

class ReferralHistory {
  final String name;
  final String email;
  final String profileImageUrl;
  final String date;
  final List<bool> status;
  final int coins;

  ReferralHistory({
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.date,
    required this.status,
    required this.coins,
  });

  factory ReferralHistory.fromMap(Map<String, dynamic> map) {
    AppLogger.info('Creating ReferralHistory from map: $map');
    
    // Ensure name is properly handled
    String userName = '';
    if (map['name'] != null) {
      userName = map['name'].toString().trim();
      AppLogger.info('Parsed user name: $userName');
    }
    
    // Ensure email is properly handled
    String userEmail = '';
    if (map['email'] != null) {
      userEmail = map['email'].toString().trim();
      AppLogger.info('Parsed user email: $userEmail');
    }
    
    // Ensure profile image URL is properly handled
    String userProfileImageUrl = '';
    if (map['profile_image_url'] != null) {
      userProfileImageUrl = map['profile_image_url'].toString().trim();
      AppLogger.info('Parsed user profile image: $userProfileImageUrl');
    }
    
    // Ensure date is properly formatted
    String userDate = '';
    if (map['date'] != null) {
      try {
        final dateTime = DateTime.parse(map['date'].toString());
        userDate = dateTime.toIso8601String();
        AppLogger.info('Parsed date: $userDate');
      } catch (e) {
        AppLogger.error('Error parsing date: $e');
        userDate = DateTime.now().toIso8601String();
      }
    }

    // Ensure status is a list of exactly 3 booleans
    List<bool> userStatus = [false, false, false];
    if (map['status'] != null && map['status'] is List) {
      final statusList = List<bool>.from(map['status']);
      if (statusList.length >= 3) {
        userStatus = statusList.sublist(0, 3);
      }
      AppLogger.info('Parsed status: $userStatus');
    }

    // Ensure coins is a valid integer
    int userCoins = 0;
    if (map['coins'] != null) {
      try {
        userCoins = int.parse(map['coins'].toString());
        AppLogger.info('Parsed coins: $userCoins');
      } catch (e) {
        AppLogger.error('Error parsing coins: $e');
        userCoins = 0;
      }
    }

    final result = ReferralHistory(
      name: userName.isNotEmpty ? userName : 'Anonymous User',
      email: userEmail,
      profileImageUrl: userProfileImageUrl,
      date: userDate,
      status: userStatus,
      coins: userCoins,
    );
    
    AppLogger.info('Created ReferralHistory object: ${result.toMap()}');
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profile_image_url': profileImageUrl,
      'date': date,
      'status': status,
      'coins': coins,
    };
  }
} 