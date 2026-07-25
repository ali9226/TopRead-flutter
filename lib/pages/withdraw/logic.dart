import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/login.dart';
import 'package:app/models/transaction_inquire_type.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/number_util.dart';

/// 提现页逻辑层。
///
/// 负责：
/// 1. 首次进入时刷新用户余额。
/// 2. 请求提现网络和最低提现额度。
/// 3. 维护选中网络、输入金额、滑块金额和按钮状态。
/// 4. 在余额不足时弹出提示，但仍停留在当前页面。
class WithdrawLogic extends ChangeNotifier {
  final UserInformation userInformation = Get.find<UserInformation>();
  final AppGlobalConfigStore appGlobalConfigStore =
      Get.find<AppGlobalConfigStore>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();
  final FocusNode addressFocusNode = FocusNode();

  final List<TransactionInquireTypeItem> withdrawTypes = [];

  bool loading = false;
  bool submitting = false;
  bool hasShownInsufficientDialog = false;
  int selectedTypeId = 0;
  double balance = 0;
  double minWithdrawal = 0;
  double selectedAmount = 0;
  String walletAddress = '';
  WithdrawShortcut? selectedShortcut;

  void init() {
    amountController.addListener(_handleAmountInput);
    addressController.addListener(_handleAddressInput);
    amountFocusNode.addListener(_handleAmountFocusChange);
    addressFocusNode.addListener(_handleAddressFocusChange);
    unawaited(refreshData());
  }

  @override
  void dispose() {
    amountController.removeListener(_handleAmountInput);
    addressController.removeListener(_handleAddressInput);
    amountFocusNode.removeListener(_handleAmountFocusChange);
    addressFocusNode.removeListener(_handleAddressFocusChange);
    amountController.dispose();
    addressController.dispose();
    amountFocusNode.dispose();
    addressFocusNode.dispose();
    super.dispose();
  }

  bool get canWithdraw => balance >= minWithdrawal && minWithdrawal > 0;

  bool get hasTypeOptions => withdrawTypes.isNotEmpty;

  double get sliderMin => canWithdraw ? minWithdrawal : 0;

  double get sliderMax {
    if (!canWithdraw) return 1;
    if (balance <= minWithdrawal) return minWithdrawal;
    return balance;
  }

  String get submitTitle => canWithdraw
      ? easy.tr('withdraw_page.submit')
      : easy.tr('withdraw_page.back_home');

  /// 重新拉取余额与提现网络配置。
  ///
  /// 返回值：`subscriber/get_info` 成功时为 true，供下拉刷新成功后展示提示。
  Future<bool> refreshData() async {
    if (loading) return false;
    loading = true;
    notifyListeners();

    var userInfoOk = false;
    try {
      userInfoOk = await _refreshUserInfo();
      await _loadWithdrawInquireType();
      _syncAmountIfNeeded();
      // 弹窗出现前先结束 loading 并刷新一帧，让摘要卡上的余额、最低/最高提现显示为刚拉到的值，
      // 避免遮在弹窗下面仍全是 $0.00。
      loading = false;
      notifyListeners();
      await _showInsufficientDialogIfNeeded();
      return userInfoOk;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void onTapType(int id) {
    if (!canWithdraw) return;
    _dismissAmountInput();
    selectedTypeId = id;
    notifyListeners();
  }

  void onTapShortcut(double ratio) {
    if (!canWithdraw) return;
    _dismissAmountInput();
    final target = _normalizeAmount(balance * ratio);
    final amount = target < minWithdrawal ? minWithdrawal : target;
    updateAmount(amount);
    selectedShortcut = ratio == 0.5
        ? WithdrawShortcut.half
        : WithdrawShortcut.oneThird;
    notifyListeners();
  }

  void onTapWithdrawAll() {
    if (!canWithdraw) return;
    _dismissAmountInput();
    updateAmount(balance);
    selectedShortcut = WithdrawShortcut.all;
    notifyListeners();
  }

  void onSliderChanged(double value) {
    if (!canWithdraw) return;
    _dismissAmountInput();
    updateAmount(value);
  }

  Future<void> onSubmit() async {
    if (!canWithdraw) {
      AppRouter.replace('/');
      return;
    }
    final successMessage = await submitWithdrawRequest();
    if (successMessage == null) return;
    await showWithdrawSuccessDialog(successMessage);
  }

  Future<String?> submitWithdrawRequest() async {
    if (!canWithdraw) {
      AppRouter.replace('/');
      return null;
    }
    commitAddressInput();
    commitAmountInput();

    if (submitting) return null;
    if (selectedTypeId <= 0) {
      showBottomTip(easy.tr('withdraw_page.type_required'));
      return null;
    }
    if (walletAddress.isEmpty) {
      showBottomTip(easy.tr('withdraw_page.address_required'));
      return null;
    }
    if (selectedAmount <= 0) {
      showBottomTip(easy.tr('withdraw_page.amount_required'));
      return null;
    }

    submitting = true;
    notifyListeners();

    try {
      final results = await postRequest<void>(
        path: 'withdraw/add',
        parameter: {
          'pay_type': selectedTypeId,
          'pay_qr_code': walletAddress,
          'amount_payable': selectedAmount.toStringAsFixed(2),
        },
        showTips: false,
      );

      if (!results.status) {
        showBottomTip(results.message);
        return null;
      }

      await _refreshUserInfo();
      notifyListeners();
      return results.message.isNotEmpty
          ? results.message
          : easy.tr('withdraw_page.submit_success');
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> showWithdrawSuccessDialog(String message) async {
    await showMessage(
      message: message,
      allowMaskDismiss: false,
      showHelperText: false,
      iconData: Icons.access_time_rounded,
      leftButtonText: easy.tr('withdraw_page.go_records'),
      rightButtonText: easy.tr('withdraw_page.back_home'),
      rightButtonCountdownSeconds: 10,
      rightButtonTextBuilder: (seconds) => easy.tr(
        'withdraw_page.back_home_countdown',
        namedArgs: {'seconds': '$seconds'},
      ),
      onLeftPressed: () async {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppRouter.push('/withdraw_record');
        });
      },
      onRightPressed: () async {
        AppRouter.replace('/');
      },
    );
  }

  String displayAmount(double value) {
    return '\$${formatDisplayNumber(value)}';
  }

  String currentTypeLabel() {
    final current = withdrawTypes
        .cast<TransactionInquireTypeItem?>()
        .firstWhere(
          (item) => item?.id == selectedTypeId,
          orElse: () => withdrawTypes.isNotEmpty ? withdrawTypes.first : null,
        );
    return current?.label ?? '--';
  }

  void updateAmount(double value) {
    final normalized = _normalizeAmount(value);
    final clamped = canWithdraw
        ? normalized.clamp(minWithdrawal, balance).toDouble()
        : 0.0;

    selectedAmount = clamped;
    _syncShortcutSelection();
    final text = clamped <= 0 ? '' : _formatInputValue(clamped);
    if (amountController.text != text) {
      amountController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    notifyListeners();
  }

  /// 输入框失焦或用户点击“完成”时，统一把当前输入纠正到合法范围。
  ///
  /// 校验规则：
  /// 1. 非数字或空值回退到最低提现金额。
  /// 2. 小于最低提现金额时抬到最低值。
  /// 3. 大于余额时压到最大可提现值。
  void commitAmountInput() {
    if (!canWithdraw) {
      selectedAmount = 0;
      amountController.text = '';
      notifyListeners();
      return;
    }

    final raw = amountController.text.trim();
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      updateAmount(minWithdrawal);
      return;
    }

    updateAmount(parsed);
  }

  void commitAddressInput() {
    final trimmed = addressController.text.trim();
    walletAddress = trimmed;
    if (addressController.text != trimmed) {
      addressController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }
    notifyListeners();
  }

  void commitAddressInputAndFocusAmount() {
    commitAddressInput();
    if (!canWithdraw) return;
    FocusManager.instance.primaryFocus?.unfocus();
    amountFocusNode.requestFocus();
  }

  void clearWalletAddress() {
    walletAddress = '';
    if (addressController.text.isEmpty) {
      notifyListeners();
      return;
    }
    addressController.clear();
    notifyListeners();
  }

  Future<void> pasteWalletAddress() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';

    if (text.isEmpty) {
      showBottomTip(easy.tr('withdraw_page.address_paste_empty'));
      return;
    }

    walletAddress = text;
    addressController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    showBottomTip(easy.tr('withdraw_page.address_paste_success'));
    notifyListeners();
  }

  /// 返回值：请求成功并已写入本地用户信息时为 true。
  Future<bool> _refreshUserInfo() async {
    final results = await postRequest<Login>(
      path: 'subscriber/get_info',
      showTips: false,
      fromJson: (json) => Login.fromJson(json),
    );

    if (!results.status || results.content == null) return false;

    userInformation.saveUserInfo(results.content!.userInfo);
    balance = results.content!.userInfo.balance;
    return true;
  }

  Future<void> _loadWithdrawInquireType() async {
    if (!appGlobalConfigStore.configLoaded.value) {
      await appGlobalConfigStore.loadConfig();
    }

    withdrawTypes
      ..clear()
      ..addAll(appGlobalConfigStore.payTypeList);

    minWithdrawal = appGlobalConfigStore.businessConfig.minWithdrawal;

    if (selectedTypeId == 0 && withdrawTypes.isNotEmpty) {
      selectedTypeId = withdrawTypes.first.id;
    }
  }

  Future<void> _showInsufficientDialogIfNeeded() async {
    if (canWithdraw || hasShownInsufficientDialog) return;

    hasShownInsufficientDialog = true;
    await showMessage(
      message: easy.tr(
        'withdraw_page.insufficient_message',
        namedArgs: {
          'balance': displayAmount(balance),
          'min': displayAmount(minWithdrawal),
        },
      ),
      showHelperText: false,
      rightButtonText: easy.tr('withdraw_page.insufficient_acknowledged'),
      onRightPressed: () async {
        /// 仅关弹窗即可；`showMessage` 在 `changeShowMessageState(false)` 后有一帧延迟的
        /// `Navigator.pop`，会卸掉当前 `/withdraw`，勿在此处再 pop 以免连退两层。
      },
    );
  }

  void _syncAmountIfNeeded() {
    if (!canWithdraw) {
      selectedAmount = 0;
      selectedShortcut = null;
      amountController.text = '';
      return;
    }

    final target = selectedAmount <= 0 ? minWithdrawal : selectedAmount;
    updateAmount(target);
  }

  void _handleAmountInput() {
    if (!canWithdraw) return;
    final raw = amountController.text.trim();
    if (raw.isEmpty) {
      selectedAmount = minWithdrawal;
      _syncShortcutSelection();
      notifyListeners();
      return;
    }

    final parsed = double.tryParse(raw);
    if (parsed == null) return;

    final clamped = _normalizeAmount(parsed).clamp(minWithdrawal, balance);
    if ((clamped - selectedAmount).abs() < 0.001) return;
    selectedAmount = clamped.toDouble();
    _syncShortcutSelection();
    notifyListeners();
  }

  void _handleAmountFocusChange() {
    if (amountFocusNode.hasFocus) return;
    commitAmountInput();
  }

  void _handleAddressFocusChange() {
    if (addressFocusNode.hasFocus) return;
    commitAddressInput();
  }

  void _dismissAmountInput() {
    if (!amountFocusNode.hasFocus) return;
    amountFocusNode.unfocus();
    commitAmountInput();
  }

  void _handleAddressInput() {
    final trimmed = addressController.text.trimLeft();
    if (trimmed == walletAddress) return;
    walletAddress = trimmed;
    notifyListeners();
  }

  double oneThirdAmount() {
    final target = _normalizeAmount(balance / 3);
    return target < minWithdrawal ? minWithdrawal : target;
  }

  double halfAmount() {
    final target = _normalizeAmount(balance / 2);
    return target < minWithdrawal ? minWithdrawal : target;
  }

  bool get canUseOneThirdShortcut {
    if (!canWithdraw) return false;
    return _normalizeAmount(balance / 3) >= minWithdrawal;
  }

  bool get canUseHalfShortcut {
    if (!canWithdraw) return false;
    return _normalizeAmount(balance / 2) >= minWithdrawal;
  }

  bool isShortcutSelected(WithdrawShortcut shortcut) {
    return selectedShortcut == shortcut;
  }

  void _syncShortcutSelection() {
    if (!canWithdraw) {
      selectedShortcut = null;
      return;
    }

    if ((selectedAmount - balance).abs() < 0.01) {
      selectedShortcut = WithdrawShortcut.all;
      return;
    }
    if ((selectedAmount - halfAmount()).abs() < 0.01) {
      selectedShortcut = WithdrawShortcut.half;
      return;
    }
    if ((selectedAmount - oneThirdAmount()).abs() < 0.01) {
      selectedShortcut = WithdrawShortcut.oneThird;
      return;
    }
    selectedShortcut = null;
  }

  double _normalizeAmount(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  String _formatInputValue(double value) {
    final fixed = value.toStringAsFixed(2);
    if (fixed.endsWith('.00')) {
      return fixed.substring(0, fixed.length - 3);
    }
    if (fixed.endsWith('0')) {
      return fixed.substring(0, fixed.length - 1);
    }
    return fixed;
  }

  Color cardBorderColor(bool isDark) {
    return isDark
        ? const Color(0xFF8DB7FF).withValues(alpha: 0.16)
        : ColorConstants.themeColor.withValues(alpha: 0.14);
  }
}

enum WithdrawShortcut { oneThird, half, all }
