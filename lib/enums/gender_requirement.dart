enum GenderRequirement {
  female('Nữ', 'female'),
  male('Nam', 'male'),
  any('Không yêu cầu', 'any');

  final String label;
  final String value;
  const GenderRequirement(this.label, this.value);
}