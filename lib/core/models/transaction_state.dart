import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'transaction_state.freezed.dart';
part 'transaction_state.g.dart';

@freezed
class TransactionState with _$TransactionState {
  const TransactionState._(); // <-- Add this line

  const factory TransactionState({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String type,
    required int amount,
    String? note,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TransactionState;

  factory TransactionState.fromJson(Map<String, dynamic> json) =>
      _$TransactionStateFromJson(json);
}
