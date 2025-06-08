class AdEarningsModel {
  final String userId;
  final DateTime date;
  final int adsWatched;
  final DateTime lastUpdated;

  AdEarningsModel({
    required this.userId,
    required this.date,
    required this.adsWatched,
    required this.lastUpdated,
  });

  factory AdEarningsModel.fromJson(Map<String, dynamic> json) {
    return AdEarningsModel(
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      adsWatched: json['ads_watched'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String(),
      'ads_watched': adsWatched,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  AdEarningsModel copyWith({
    String? userId,
    DateTime? date,
    int? adsWatched,
    DateTime? lastUpdated,
  }) {
    return AdEarningsModel(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      adsWatched: adsWatched ?? this.adsWatched,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 