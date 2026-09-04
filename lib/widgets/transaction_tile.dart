import 'dart:io';
import 'package:flutter/material.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/format.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/widgets/common_widgets.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback? onTap;
  final VoidCallback? onToggleDebt;

  const TransactionTile({
    super.key,
    required this.tx,
    this.onTap,
    this.onToggleDebt,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isIncome = tx.type == TxType.income;
    final isLent = tx.type == TxType.lent;
    final isBorrowed = tx.type == TxType.borrowed;

    Color amountColor;
    String sign;
    if (isIncome) {
      amountColor = AppColors.income;
      sign = '+';
    } else if (isLent) {
      amountColor = const Color(0xFF0D9488);
      sign = 'Lent ';
    } else if (isBorrowed) {
      amountColor = const Color(0xFFE11D48);
      sign = 'Owed ';
    } else {
      amountColor = AppColors.expense;
      sign = '−';
    }

    final amountBg = amountColor.withValues(alpha: isDark ? 0.15 : 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _showDetailsModal(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: scheme.primary.withValues(alpha: 0.05),
        highlightColor: scheme.primary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: AppSizes.avatarMd,
                height: AppSizes.avatarMd,
                decoration: BoxDecoration(
                  color: tx.category.color.withValues(
                    alpha: isDark ? 0.15 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: tx.category.color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  tx.category.icon,
                  color: tx.category.color,
                  size: AppSizes.iconLg,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.title,
                            style: AppTypography.title(scheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tx.receiptPath != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.receipt_rounded,
                            size: 16,
                            color: Color(0xFF6366F1),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${tx.category.name} · ${Fmt.relativeDay(tx.date)}',
                          style: AppTypography.caption(scheme.onSurfaceVariant),
                        ),

                        if (tx.debtPerson != null)
                          StatusBadge(
                            label: tx.debtPerson!,
                            icon: Icons.person_outline_rounded,
                            color: isLent
                                ? const Color(0xFF0D9488)
                                : const Color(0xFFE11D48),
                          ),

                        if (tx.isDebt)
                          StatusBadge(
                            label: tx.isDebtSettled ? 'Settled' : 'Pending',
                            color: tx.isDebtSettled
                                ? AppColors.income
                                : AppColors.warning,
                          ),

                        if (tx.recurringTag != null)
                          StatusBadge(
                            label: tx.recurringTag!,
                            color: scheme.primary,
                            icon: Icons.event_repeat_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: amountBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '$sign${Fmt.currency(tx.amount)}',
                    style: AppTypography.financialAmount(amountColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSizes.dragHandleWidth,
                  height: AppSizes.dragHandleHeight,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Details',
                    style: AppTypography.h3(scheme.onSurface),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: tx.category.color.withValues(alpha: 0.15),
                  child: Icon(tx.category.icon, color: tx.category.color),
                ),
                title: Text(
                  tx.title,
                  style: AppTypography.title(scheme.onSurface),
                ),
                subtitle: Text('${tx.category.name} · ${Fmt.date(tx.date)}'),
                trailing: Text(
                  Fmt.currency(tx.amount),
                  style: AppTypography.financialAmountLarge(tx.category.color),
                ),
              ),
              if (tx.note != null && tx.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: ${tx.note}',
                  style: AppTypography.bodySmall(scheme.onSurfaceVariant),
                ),
              ],
              if (tx.debtPerson != null) ...[
                const SizedBox(height: 8),
                Text(
                  tx.type == TxType.lent
                      ? 'Lent to: ${tx.debtPerson}'
                      : 'Borrowed from: ${tx.debtPerson}',
                  style: AppTypography.bodyMedium(scheme.onSurface),
                ),
                if (tx.debtDueDate != null)
                  Text(
                    'Due Date: ${Fmt.date(tx.debtDueDate!)}',
                    style: AppTypography.caption(AppColors.warning),
                  ),
              ],
              if (tx.receiptPath != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Attached Receipt',
                  style: AppTypography.label(scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.file(
                    File(tx.receiptPath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}
