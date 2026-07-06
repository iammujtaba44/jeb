/// The nature of a [Plan]: something you're building toward owning, a debt
/// you're paying down, a giving/charity obligation (zakat, sadqa), or a
/// refundable deposit (e.g. a flat/shop security deposit) you expect back.
enum PlanKind {
  asset,
  loan,
  giving,
  deposit;

  String get storageValue => name;

  static PlanKind fromStorage(String value) => PlanKind.values.firstWhere(
        (PlanKind k) => k.name == value,
        orElse: () => PlanKind.asset,
      );

  String get label => switch (this) {
        PlanKind.asset => 'Asset',
        PlanKind.loan => 'Loan',
        PlanKind.giving => 'Giving',
        PlanKind.deposit => 'Deposit',
      };

  /// Verb describing money put toward this kind of plan.
  String get contributeVerb => switch (this) {
        PlanKind.asset => 'Saved',
        PlanKind.loan => 'Paid off',
        PlanKind.giving => 'Given',
        PlanKind.deposit => 'Deposited',
      };
}
