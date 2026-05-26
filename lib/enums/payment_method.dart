enum PaymentMethod {
  cast('Tiền mặt', 'cast'),
  bank('Chuyển khoản', 'bank');

  final String label;
  final String name;
  const PaymentMethod(this.label, this.name);
}