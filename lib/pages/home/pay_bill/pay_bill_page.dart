import 'dart:convert';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/storage/local_prefs/local_prefs.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/pay_bill/pay_bill_repository.dart';
import '../../profile/profile/profile_controller.dart';
import '../home/bound_broadband_provider.dart';

class PayBillPage extends ConsumerStatefulWidget {
  const PayBillPage({super.key});

  @override
  ConsumerState<PayBillPage> createState() => _PayBillPageState();
}

class _FavoriteAccount {
  const _FavoriteAccount({required this.account, required this.serviceType});

  final String account;
  final String serviceType;

  Map<String, String> toJson() => {
        'account': account,
        'service_type': serviceType,
      };

  static _FavoriteAccount? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final account = raw['account']?.toString().trim() ?? '';
    final serviceType = raw['service_type']?.toString().trim() ?? '';
    if (account.isEmpty || (serviceType != 'FTTH' && serviceType != 'CG')) {
      return null;
    }
    return _FavoriteAccount(account: account, serviceType: serviceType);
  }
}

enum _PayStep { account, confirm, pay, done }

class _PayBillPageState extends ConsumerState<PayBillPage> {
  static const _favoritesKey = 'pay_bill_favorites_v1';

  final _account = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _mode = 'mine';
  String _serviceType = 'FTTH';
  bool _checking = false;
  bool _paying = false;
  bool _favorite = false;
  _PayStep _step = _PayStep.account;
  PayBillQuote? _quote;
  PayBillReceipt? _receipt;
  String? _payKey;
  List<_FavoriteAccount> _favorites = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadFavorites);
  }

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final items = decoded.map(_FavoriteAccount.fromJson).whereType<_FavoriteAccount>().toList();
      if (!mounted) return;
      setState(() => _favorites = items);
    } catch (_) {}
  }

  Future<void> _saveFavorites(List<_FavoriteAccount> items) async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _favoritesKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
    if (!mounted) return;
    setState(() => _favorites = items);
  }

  String? get _myAccount {
    final bound = ref.read(boundBroadbandProvider);
    if (bound != null && bound.account.trim().isNotEmpty) return bound.account.trim();
    final profile = ref.read(profileControllerProvider);
    final account = profile.accountNumber.trim();
    return account.isEmpty ? null : account;
  }

  String get _myServiceType {
    final bound = ref.read(boundBroadbandProvider);
    if (bound != null && bound.serviceType.trim().isNotEmpty) {
      return bound.serviceType.trim();
    }
    final service = ref.read(profileControllerProvider).serviceType?.trim();
    if (service == 'FTTH' || service == 'CG') return service!;
    return 'FTTH';
  }

  String? _selectedAccount() {
    if (_mode == 'mine') return _myAccount;
    final account = _account.text.trim();
    return account.isEmpty ? null : account;
  }

  String _selectedService() => _mode == 'mine' ? _myServiceType : _serviceType;

  Future<void> _check() async {
    if (_checking) return;
    if (_mode == 'other' && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final account = _selectedAccount();
    if (account == null) return;

    setState(() => _checking = true);
    try {
      while (true) {
        try {
          final quote = await ref.read(payBillRepositoryProvider).check(
                accountNumber: account,
                serviceType: _selectedService(),
              );
          if (!mounted) return;
          final saved = _favorites.any(
            (item) => item.account == quote.account && item.serviceType == quote.serviceType,
          );
          setState(() {
            _quote = quote;
            _favorite = saved;
            _payKey = null;
            _step = _PayStep.confirm;
          });
          return;
        } on ApiException catch (error) {
          if (!mounted) return;
          if (isOfflineError(error)) {
            final retry = await showOfflineModal(context);
            if (!mounted || !retry) return;
            continue;
          }
          await showAppFailureModal(
            context,
            title: 'common.error'.tr(),
            body: apiErrorText(error),
          );
          return;
        }
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _toggleFavorite(bool value) async {
    final quote = _quote;
    if (quote == null || _mode != 'other') return;
    setState(() => _favorite = value);
    final next = _favorites
        .where((item) => !(item.account == quote.account && item.serviceType == quote.serviceType))
        .toList();
    if (value) {
      next.insert(
        0,
        _FavoriteAccount(account: quote.account, serviceType: quote.serviceType),
      );
    }
    await _saveFavorites(next);
  }

  Future<void> _pay() async {
    final quote = _quote;
    if (quote == null || _paying) return;
    final password = await showAppPasswordModal(
      context,
      title: 'home.pay_bill_password_title'.tr(),
      body: 'home.pay_bill_password_body'.tr(),
      amountPoints: quote.outstandingAmount.round(),
    );
    if (!mounted || password == null || password.length != 6) return;

    final key = _payKey ??= _newKey();
    setState(() => _paying = true);
    try {
      while (true) {
        try {
          final receipt = await ref.read(payBillRepositoryProvider).pay(
                accountNumber: quote.account,
                serviceType: quote.serviceType,
                idempotencyKey: key,
                password: password,
              );
          if (!mounted) return;
          setState(() {
            _receipt = receipt;
            _step = _PayStep.done;
          });
          return;
        } on ApiException catch (error) {
          if (!mounted) return;
          if (isOfflineError(error)) {
            final retry = await showOfflineModal(context);
            if (!mounted || !retry) return;
            continue;
          }
          await showAppFailureModal(
            context,
            title: 'common.error'.tr(),
            body: apiErrorText(error),
          );
          return;
        }
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  String _newKey() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final salt = Random().nextInt(0x7fffffff).toRadixString(16);
    return 'bill-$now-$salt';
  }

  void _back() {
    if (_step == _PayStep.confirm) {
      setState(() => _step = _PayStep.account);
      return;
    }
    if (_step == _PayStep.pay) {
      setState(() => _step = _PayStep.confirm);
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final bound = ref.watch(boundBroadbandProvider);
    final profile = ref.watch(profileControllerProvider);
    final myAccount = (bound?.account ?? profile.accountNumber).trim();

    return AppCurvedScaffold(
      title: Text('home.service_pay'.tr()),
      showBack: true,
      onBack: _back,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                if (_step == _PayStep.account)
                  _AccountSheet(
                    myAccount: myAccount,
                    mode: _mode,
                    account: _account,
                    formKey: _formKey,
                    serviceType: _serviceType,
                    favorites: _favorites,
                    onMode: (value) => setState(() => _mode = value),
                    onServiceType: (value) => setState(() => _serviceType = value),
                    onPickFavorite: (item) {
                      _account.text = item.account;
                      setState(() => _serviceType = item.serviceType);
                    },
                    onRemoveFavorite: (item) {
                      _saveFavorites(
                        _favorites
                            .where(
                              (saved) =>
                                  saved.account != item.account ||
                                  saved.serviceType != item.serviceType,
                            )
                            .toList(),
                      );
                    },
                  )
                else if (_step == _PayStep.confirm && _quote != null)
                  _ConfirmCard(
                    quote: _quote!,
                    showFavorite: _mode == 'other',
                    favorite: _favorite,
                    onFavorite: _toggleFavorite,
                  )
                else if (_step == _PayStep.pay && _quote != null)
                  _PaymentCard(quote: _quote!)
                else if (_step == _PayStep.done && _quote != null && _receipt != null)
                  _SuccessCard(quote: _quote!, receipt: _receipt!),
              ],
            ),
          ),
          Container(
            color: AppColors.background,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: AppButton(
                    label: switch (_step) {
                      _PayStep.account => 'home.pay_bill_check'.tr(),
                      _PayStep.confirm => 'common.continue'.tr(),
                      _PayStep.pay => 'home.pay_bill_confirm'.tr(),
                      _PayStep.done => 'common.done'.tr(),
                    },
                    isLoading: _checking || _paying,
                    onPressed: (_checking ||
                            _paying ||
                            (_step == _PayStep.account &&
                                _mode == 'mine' &&
                                myAccount.isEmpty))
                        ? null
                        : () {
                            switch (_step) {
                              case _PayStep.account:
                                _check();
                              case _PayStep.confirm:
                                setState(() => _step = _PayStep.pay);
                              case _PayStep.pay:
                                _pay();
                              case _PayStep.done:
                                Navigator.of(context).maybePop();
                            }
                          },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({
    required this.myAccount,
    required this.mode,
    required this.account,
    required this.formKey,
    required this.serviceType,
    required this.favorites,
    required this.onMode,
    required this.onServiceType,
    required this.onPickFavorite,
    required this.onRemoveFavorite,
  });

  final String myAccount;
  final String mode;
  final TextEditingController account;
  final GlobalKey<FormState> formKey;
  final String serviceType;
  final List<_FavoriteAccount> favorites;
  final ValueChanged<String> onMode;
  final ValueChanged<String> onServiceType;
  final ValueChanged<_FavoriteAccount> onPickFavorite;
  final ValueChanged<_FavoriteAccount> onRemoveFavorite;

  @override
  Widget build(BuildContext context) {
    final mine = mode == 'mine';
    final linked = myAccount.isNotEmpty;
    return AppCard(
      elevated: false,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: AppStyle.borderRadiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceBlock(
            asset: 'assets/images/pay_bill/equity.png',
            label: 'home.pay_bill_my_account'.tr(),
            selected: mine,
            onTap: () => onMode('mine'),
            value: linked ? myAccount : 'home.pay_bill_no_linked'.tr(),
            valueMuted: !linked,
          ),
          const _SheetRule(),
          _ChoiceBlock(
            asset: 'assets/images/pay_bill/bank.png',
            label: 'home.pay_bill_other_account'.tr(),
            selected: mode == 'other',
            onTap: () => onMode('other'),
            child: mode == 'other'
                ? _OtherAccountForm(
                    formKey: formKey,
                    controller: account,
                    serviceType: serviceType,
                    favorites: favorites,
                    onServiceType: onServiceType,
                    onPickFavorite: onPickFavorite,
                    onRemoveFavorite: onRemoveFavorite,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _SheetRule extends StatelessWidget {
  const _SheetRule();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: AppColors.borderLight),
      ),
    );
  }
}

class _ChoiceBlock extends StatelessWidget {
  const _ChoiceBlock({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
    this.value,
    this.valueMuted = false,
    this.child,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? value;
  final bool valueMuted;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, child == null ? 14 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ChoiceIcon(asset: asset),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 36,
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppStyle.fontSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.2,
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppStyle.fontCaption,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: valueMuted
                          ? AppColors.textMuted
                          : (selected ? AppColors.primary : AppColors.textPrimary),
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
          const SizedBox(width: 8),
          _ChoiceMark(selected: selected),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: header,
        ),
        if (child != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 14, 12),
            child: child,
          ),
      ],
    );
  }
}

class _ChoiceIcon extends StatelessWidget {
  const _ChoiceIcon({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppStyle.borderRadiusInput,
      ),
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.primary,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          asset,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _ChoiceMark extends StatelessWidget {
  const _ChoiceMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _OtherAccountForm extends StatelessWidget {
  const _OtherAccountForm({
    required this.formKey,
    required this.controller,
    required this.serviceType,
    required this.favorites,
    required this.onServiceType,
    required this.onPickFavorite,
    required this.onRemoveFavorite,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String serviceType;
  final List<_FavoriteAccount> favorites;
  final ValueChanged<String> onServiceType;
  final ValueChanged<_FavoriteAccount> onPickFavorite;
  final ValueChanged<_FavoriteAccount> onRemoveFavorite;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Row(
              children: [
                Expanded(child: _serviceCheck('FTTH')),
                const SizedBox(width: 12),
                Expanded(child: _serviceCheck('CG')),
              ],
            ),
            const SizedBox(height: 8),
            AppInput(
              controller: controller,
              label: 'home.pay_bill_account_number'.tr(),
              hint: 'home.pay_bill_account_hint'.tr(),
              textInputAction: TextInputAction.done,
              validator: (value) {
                final account = value?.trim() ?? '';
                if (account.isEmpty) return 'home.pay_bill_account_required'.tr();
                if (account.length > 32) return 'home.pay_bill_account_max'.tr();
                return null;
              },
            ),
            if (favorites.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'home.pay_bill_favorites'.tr(),
                style: const TextStyle(
                  fontSize: AppStyle.fontCaption,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              for (final item in favorites)
                _FavoriteRow(
                  item: item,
                  selected: controller.text.trim() == item.account &&
                      serviceType == item.serviceType,
                  onTap: () => onPickFavorite(item),
                  onRemove: () => onRemoveFavorite(item),
                ),
            ],
          ],
      ),
    );
  }

  Widget _serviceCheck(String value) {
    final selected = serviceType == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onServiceType(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _ClearCheck(selected: selected),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _serviceLabel(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppStyle.fontSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearCheck extends StatelessWidget {
  const _ClearCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.onPrimary)
          : null,
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final _FavoriteAccount item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.account,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppStyle.fontSecondary,
                      fontWeight: FontWeight.w500,
                      height: AppStyle.lineHeightCaption,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _serviceLabel(item.serviceType),
                  style: const TextStyle(
                    fontSize: AppStyle.fontCaption,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  style: IconButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: Colors.transparent,
                  ),
                  icon: const Icon(LucideIcons.x, size: 14, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.quote,
    required this.showFavorite,
    required this.favorite,
    required this.onFavorite,
  });

  final PayBillQuote quote;
  final bool showFavorite;
  final bool favorite;
  final ValueChanged<bool> onFavorite;

  @override
  Widget build(BuildContext context) {
    return _Ticket(
      label: 'home.pay_bill_outstanding'.tr(),
      amount: quote.outstandingAmount,
      children: [
        if (quote.customerName.trim().isNotEmpty)
          _line('home.pay_bill_name'.tr(), quote.customerName),
        _line('home.pay_bill_account_number'.tr(), quote.account),
        _line('home.pay_bill_service'.tr(), _serviceLabel(quote.serviceType)),
        _line('home.pay_bill_product'.tr(), _product(quote)),
        if (quote.productSpeed.trim().isNotEmpty)
          _line('home.pay_bill_speed'.tr(), quote.productSpeed.trim()),
        if (showFavorite)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onFavorite(!favorite),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    favorite ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'home.pay_bill_favorite'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.quote});

  final PayBillQuote quote;

  @override
  Widget build(BuildContext context) {
    return _Ticket(
      label: 'home.pay_bill_amount'.tr(),
      amount: quote.outstandingAmount,
      children: [
        _line('home.pay_bill_account_number'.tr(), quote.account),
        _line('home.pay_bill_service'.tr(), _serviceLabel(quote.serviceType)),
        _line('home.pay_bill_product'.tr(), _product(quote)),
        if (quote.productSpeed.trim().isNotEmpty)
          _line('home.pay_bill_speed'.tr(), quote.productSpeed.trim()),
      ],
    );
  }
}


class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.quote, required this.receipt});

  final PayBillQuote quote;
  final PayBillReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: false,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.circle_check, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'home.pay_bill_success_body'.tr(),
            textAlign: TextAlign.center,
            style: AppTheme.bodySecondary(),
          ),
          const SizedBox(height: 8),
          _amountLine('home.pay_bill_receipt'.tr(), quote.outstandingAmount),
          _line('home.pay_bill_transaction'.tr(), receipt.transactionNo),
          _line('home.pay_bill_account_number'.tr(), quote.account),
          _line('home.pay_bill_product'.tr(), _product(quote)),
          if (quote.productSpeed.trim().isNotEmpty)
            _line('home.pay_bill_speed'.tr(), quote.productSpeed.trim()),
        ],
      ),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.label,
    required this.amount,
    required this.children,
  });

  final String label;
  final num amount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final column = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppStyle.fontCaption,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _money(amount),
                style: AppTheme.amount(color: AppColors.primary),
              ),
              const SizedBox(width: 6),
              Text(
                'topup.pts'.tr(),
                style: const TextStyle(
                  fontSize: AppStyle.fontSecondary,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: double.infinity,
            height: 1,
            child: CustomPaint(painter: _DashPainter()),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      );
    return AppCard(
      elevated: false,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      borderRadius: BorderRadius.circular(12),
      child: column,
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(min(x + dash, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _amountLine(String label, num amount) {
  return _line(label, '${_money(amount)} ${'topup.pts'.tr()}', emphasize: true);
}

String _product(PayBillQuote quote) {
  final name = quote.productName.trim();
  final id = quote.productId.trim();
  if (name.isEmpty) return id;
  if (id.isEmpty) return name;
  return '$name · $id';
}

Widget _line(String label, String value, {bool emphasize = false}) {
  final shown = value.trim().isEmpty ? '—' : value.trim();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            shown,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
              color: emphasize ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

String _serviceLabel(String value) => value == 'CG' ? 'CG Router' : value;

String _money(num value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
