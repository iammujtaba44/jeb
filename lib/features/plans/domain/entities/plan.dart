import 'package:equatable/equatable.dart';
import 'package:jeb/features/plans/domain/entities/plan_kind.dart';

/// A long-running financial commitment tracked by accumulating payments toward
/// an optional [targetAmount] — e.g. property installments, a loan, or zakat.
class Plan extends Equatable {
  const Plan({
    required this.id,
    required this.name,
    required this.kind,
    required this.currencyCode,
    required this.startDate,
    this.targetAmount,
    this.installmentAmount,
    this.note,
    this.dueDate,
    this.returnedDate,
  });

  final String id;
  final String name;
  final PlanKind kind;
  final String currencyCode;
  final DateTime startDate;

  /// The total to reach, or null for an open-ended plan (e.g. ongoing sadqa).
  final double? targetAmount;

  /// The expected per-month payment, used to project how long is left.
  final double? installmentAmount;

  final String? note;

  /// When a [PlanKind.deposit] is expected to be paid back (optional).
  final DateTime? dueDate;

  /// When a [PlanKind.deposit] was actually returned; null while outstanding.
  final DateTime? returnedDate;

  bool get hasTarget => targetAmount != null && targetAmount! > 0;

  bool get isReturned => returnedDate != null;

  /// A deposit whose expected-back date has passed without being returned.
  bool get isOverdue =>
      kind == PlanKind.deposit &&
      !isReturned &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  /// Fraction complete given an amount [paid] so far (0..1), or null if there's
  /// no target to measure against.
  double? progress(double paid) =>
      hasTarget ? (paid / targetAmount!).clamp(0.0, 1.0) : null;

  double remaining(double paid) =>
      hasTarget ? (targetAmount! - paid).clamp(0.0, double.infinity) : 0;

  bool isComplete(double paid) => hasTarget && paid >= targetAmount!;

  /// Estimated months left at [installmentAmount]/month, or null if unknown.
  int? monthsLeft(double paid) {
    if (!hasTarget || installmentAmount == null || installmentAmount! <= 0) {
      return null;
    }
    final double left = remaining(paid);
    if (left <= 0) return 0;
    return (left / installmentAmount!).ceil();
  }

  Plan copyWith({
    String? name,
    PlanKind? kind,
    String? currencyCode,
    DateTime? startDate,
    double? targetAmount,
    double? installmentAmount,
    String? note,
    DateTime? dueDate,
    DateTime? returnedDate,
  }) {
    return Plan(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      currencyCode: currencyCode ?? this.currencyCode,
      startDate: startDate ?? this.startDate,
      targetAmount: targetAmount ?? this.targetAmount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      returnedDate: returnedDate ?? this.returnedDate,
    );
  }

  /// [copyWith] can't clear a nullable field; this sets [returnedDate]
  /// explicitly (pass null to mark the deposit as outstanding again).
  Plan withReturnedDate(DateTime? date) {
    return Plan(
      id: id,
      name: name,
      kind: kind,
      currencyCode: currencyCode,
      startDate: startDate,
      targetAmount: targetAmount,
      installmentAmount: installmentAmount,
      note: note,
      dueDate: dueDate,
      returnedDate: date,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        kind,
        currencyCode,
        startDate,
        targetAmount,
        installmentAmount,
        note,
        dueDate,
        returnedDate,
      ];
}
