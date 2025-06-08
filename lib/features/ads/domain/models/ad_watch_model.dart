class AdWatchModel {
  final String id;
  final String userId;
  final DateTime watchedAt;
  final String captchaCode;

  AdWatchModel({
    required this.id,
    required this.userId,
    required this.watchedAt,
    required this.captchaCode,
  });

  factory AdWatchModel.fromJson(Map<String, dynamic> json) {
    return AdWatchModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      watchedAt: DateTime.parse(json['watched_at'] as String),
      captchaCode: json['captcha_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'watched_at': watchedAt.toIso8601String(),
      'captcha_code': captchaCode,
    };
  }
} 