import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final networkStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
}); 