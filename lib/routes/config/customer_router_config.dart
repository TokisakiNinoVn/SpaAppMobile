class CustomerRouterConfig {
  static String homeCustomer = "/home-customer";

  static String listTechnician = "/home-customer/list-technician";

  static String updateProfile = "/home-customer/update-profile";
  static String listLike = "/home-customer/likes";
  static String toNotificationScreen = "/home-customer/notifications";
  static String listDiscountScreen = "/home-customer/discounts";

  // order
  static String detailOrder = "/home-customer/detail-order";

  static String choosePackage = "/home-customer/choose-package";
  static String qrDeposit = "/home-customer/choose-package/qr-deposit";
  static String historyDeposit = "/home-customer/choose-package/history-deposit";

  static String listAddress = "/home-customer/list-address";
  static String addAddress = "/home-customer/list-address/add-address";
  static String editAddress = "/home-customer/list-address/edit-address";

  static String orderNow = "/home-customer/order-now";
  static String automaticMatching = "/home-customer/automatic-matching";

  static String createReqWithdraw = "/home-customer/withdraw";
  static String confirmWithdraw = "/home-customer/withdraw/confirm";
  static String historyWithdraw = "/home-customer/withdraw/history";

  // Order Now
  static String createOrderNow = "/home-customer/list-technician/create-order-technician";

  // Book Order
  static String listBookTechnician = "/home-customer/book";
  static String detailBookTechnician = "/home-customer/book/detail";
  static String createBookOrder = "/home-customer/book/create-order";

}