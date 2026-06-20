import 'package:equatable/equatable.dart';

/// Money moved from one [Account] to another (e.g. cash withdrawal, card
/// payoff). [amount] is expressed in the source account's currency; it is
/// converted to the destination's currency when applied to balances.
class Transfer extends Equatable {
  const Transfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String? note;

  @override
  List<Object?> get props => <Object?>[
        id,
        fromAccountId,
        toAccountId,
        amount,
        date,
        note,
      ];
}
