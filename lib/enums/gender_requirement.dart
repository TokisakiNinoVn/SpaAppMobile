enum GenderRequirement {
  male('Nam', 'male'),
  female('Nữ', 'female'),
  any('Không yêu cầu', 'any');

  final String label;
  final String value;
  const GenderRequirement(this.label, this.value);
}