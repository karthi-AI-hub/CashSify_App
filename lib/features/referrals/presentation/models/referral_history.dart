class ReferralHistory {
  final String name;
  final String date;
  final List<bool> status;
  final int coins;

  ReferralHistory({
    required this.name,
    required this.date,
    required this.status,
    required this.coins,
  });

  factory ReferralHistory.fromMap(Map<String, dynamic> map) {
    return ReferralHistory(
      name: map['name'] ?? 'Anonymous User',
      date: map['date'] ?? '',
      status: List<bool>.from(map['status'] ?? [false, false, false]),
      coins: map['coins'] ?? 0,
    );
  }
} 