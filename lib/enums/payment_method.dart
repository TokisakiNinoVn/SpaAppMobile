enum PaymentMethod {
  cash('Tiền mặt', 'cash'),
  bank('Chuyển khoản', 'bank');

  final String label;
  final String name;
  const PaymentMethod(this.label, this.name);
}