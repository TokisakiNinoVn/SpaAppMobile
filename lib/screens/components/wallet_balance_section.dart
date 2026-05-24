import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';

class WalletBalanceSection extends StatelessWidget {
  final int balance;
  final VoidCallback? onTapDeposit;
  final VoidCallback? onTapWithdraw;

  const WalletBalanceSection({
    super.key,
    required this.balance,
    this.onTapDeposit,
    this.onTapWithdraw,
  });

  @override
  Widget build(BuildContext context) {

    final depositCallback = onTapDeposit;
    final withdrawCallback = onTapWithdraw;
    final hasDeposit = depositCallback != null;
    final hasWithdraw = withdrawCallback != null;
    final hasBoth = hasDeposit && hasWithdraw;

    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ColorConfig.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👉 Balance
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorConfig.primaryBackground,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 22,
                  color: ColorConfig.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Số dư ví: ${FormatHelper.formatPrice(balance)} VNĐ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConfig.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 👉 Actions
          // Row(
          //   children: [
          //     if (depositCallback != null) ...[
          //       Expanded(
          //         child: _WalletActionButton(
          //           label: 'Nạp tiền',
          //           icon: Icons.add_card_rounded,
          //           filled: true,
          //           width: withdrawCallback != null ? 10 : 50,
          //           onTap: depositCallback,
          //           paddingVertical: 12,
          //         ),
          //       ),
          //     ],
          //
          //     if (depositCallback != null && withdrawCallback != null)
          //       const SizedBox(width: 12),
          //
          //     if (withdrawCallback != null) ...[
          //       Expanded(
          //         child: _WalletActionButton(
          //           label: 'Rút tiền',
          //           icon: Icons.arrow_forward_outlined,
          //           filled: false,
          //           width: depositCallback != null ? 10 : 50,
          //           onTap: withdrawCallback,
          //           paddingVertical: 12,
          //         ),
          //       ),
          //     ],
          //   ],
          // ),
          Row(
            mainAxisAlignment: hasBoth
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (hasDeposit)
                hasBoth
                    ? Expanded(
                  child: _WalletActionButton(
                    label: 'Nạp tiền',
                    icon: Icons.add_card_rounded,
                    filled: true,
                    onTap: depositCallback,
                  ),
                )
                    : _WalletActionButton(
                  label: 'Nạp tiền',
                  icon: Icons.add_card_rounded,
                  filled: true,
                  width: 120,
                  onTap: depositCallback,
                ),

              if (hasBoth) const SizedBox(width: 12),

              if (hasWithdraw)
                hasBoth
                    ? Expanded(
                  child: _WalletActionButton(
                    label: 'Rút tiền',
                    icon: Icons.arrow_forward_outlined,
                    filled: false,
                    onTap: withdrawCallback,
                  ),
                )
                    : _WalletActionButton(
                  label: 'Rút tiền',
                  icon: Icons.arrow_forward_outlined,
                  filled: false,
                  width: 120,
                  onTap: withdrawCallback,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final double? width;
  final double? paddingVertical;

  const _WalletActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.width,
    this.paddingVertical,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: filled ? ColorConfig.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: paddingVertical ?? 9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: filled
                  ? null
                  : Border.all(
                color: ColorConfig.primary,
                width: .5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: filled
                      ? Colors.white
                      : ColorConfig.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : ColorConfig.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}