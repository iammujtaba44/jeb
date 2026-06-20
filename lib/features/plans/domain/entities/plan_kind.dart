/// The nature of a [Plan]: something you're building toward owning, a debt
/// you're paying down, or a giving/charity obligation (zakat, sadqa).
enum PlanKind {
  asset,
  loan,
  giving;

  String get storageValue => name;

  static PlanKind fromStorage(String value) => PlanKind.values.firstWhere(
        (PlanKind k) => k.name == value,
        orElse: () => PlanKind.asset,
      );

  String get label => switch (this) {
        PlanKind.asset => 'Asset',
        PlanKind.loan => 'Loan',
        PlanKind.giving => 'Giving',
      };

  /// Verb describing money put toward this kind of plan.
  String get contributeVerb => switch (this) {
        PlanKind.asset => 'Saved',
        PlanKind.loan => 'Paid off',
        PlanKind.giving => 'Given',
      };
}
