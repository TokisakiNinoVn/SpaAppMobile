enum GenderCustomer {
  male('Khách nam', 'male'),
  female('Khách nữ', 'female'),;
  // any('Không xác định', 'any');

  final String label;
  final String value;
  const GenderCustomer(this.label, this.value);
}