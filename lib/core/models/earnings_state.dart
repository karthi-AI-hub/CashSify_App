import 'package:freezed_annotation/freezed_annotation.dart';

part 'earnings_state.freezed.dart';
part 'earnings_state.g.dart';

@freezed
class EarningsState with _$EarningsState {
  const EarningsState._();

  const factory EarningsState({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'ads_watched') required int adsWatched,
    @JsonKey(name: 'coins_earned') required int coinsEarned,
    @JsonKey(name: 'last_updated') required DateTime lastUpdated,
    @Default(20) int dailyLimit,
    @Default(false) bool isDailyLimitReached,
  }) = _EarningsState;

  factory EarningsState.fromJson(Map<String, dynamic> json) => _$EarningsStateFromJson(json);

  bool get canWatchMoreAds => !isDailyLimitReached && adsWatched < dailyLimit;
  int get remainingAds => dailyLimit - adsWatched;
  double get progressPercentage => adsWatched / dailyLimit;
  int get adsWatchedToday => adsWatched;
  bool get hasReachedDailyLimit => isDailyLimitReached || adsWatched >= dailyLimit;
}