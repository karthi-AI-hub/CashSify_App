import 'dart:math';

String generateCaptcha() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz123456789';
  final random = Random();
  return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
} 