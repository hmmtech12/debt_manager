import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';

final defaultCurrencyProvider = StateProvider<String>((ref) => AppConstants.defaultCurrency);

final remindersEnabledProvider = StateProvider<bool>((ref) => true);

final appLockEnabledProvider = StateProvider<bool>((ref) => false);

final biometricEnabledProvider = StateProvider<bool>((ref) => false);

final userNameProvider = StateProvider<String>((ref) => '');
