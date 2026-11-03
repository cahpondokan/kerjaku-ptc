/// Monthly wage components in whole rupiah (PP 35/2021, Article 32).
class OvertimeSalary {
  const OvertimeSalary({
    required this.basic,
    this.fixed = 0,
    this.variable = 0,
  });
  static const maxComponent = 999999999;
  static const maxBasis = maxComponent * 3;
  final int basic;
  final int fixed;
  final int variable;

  bool get isValid =>
      [basic, fixed, variable].every((v) => v >= 0 && v <= maxComponent) &&
      basisCents > 0;
  bool get usesSeventyFivePercent =>
      (basic + fixed) * 4 < (basic + fixed + variable) * 3;
  int get basisCents =>
      usesSeventyFivePercent
          ? (basic + fixed + variable) * 75
          : (basic + fixed) * 100;

  Map<String, Object> toMap() => {
    'basic': basic,
    'fixed': fixed,
    'variable': variable,
  };
  factory OvertimeSalary.fromMap(Map<String, dynamic> map) => OvertimeSalary(
    basic: map['basic'] as int,
    fixed: map['fixed'] as int,
    variable: map['variable'] as int,
  );
}
