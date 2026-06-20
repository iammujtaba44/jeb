import 'package:equatable/equatable.dart';

/// A single payment recorded against a [Plan].
class PlanPayment extends Equatable {
  const PlanPayment({
    required this.id,
    required this.planId,
    required this.amount,
    required this.date,
    this.note,
    this.receiptPaths = const <String>[],
  });

  final String id;
  final String planId;
  final double amount;
  final DateTime date;
  final String? note;

  /// Relative paths of attached receipt photos (0–2).
  final List<String> receiptPaths;

  bool get hasReceipts => receiptPaths.isNotEmpty;

  @override
  List<Object?> get props =>
      <Object?>[id, planId, amount, date, note, receiptPaths];
}
