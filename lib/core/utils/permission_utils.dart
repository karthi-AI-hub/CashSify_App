import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cashsify_app/core/utils/logger.dart';

/// Utility class to handle app permissions
class PermissionUtils {
  static final AppLogger _logger = AppLogger();

  /// Request all essential permissions for the app
  static Future<Map<Permission, PermissionStatus>> requestEssentialPermissions() async {
    _logger.info('Requesting essential permissions...');
    
    final permissions = <Permission, PermissionStatus>{};
    
    // Request camera permission
    permissions[Permission.camera] = await Permission.camera.request();
    
    // Request storage permissions
    if (await _isAndroid13OrHigher()) {
      permissions[Permission.photos] = await Permission.photos.request();
    } else {
      permissions[Permission.storage] = await Permission.storage.request();
    }
    
    // Request network state permission
    permissions[Permission.accessMediaLocation] = await Permission.accessMediaLocation.request();
    
    _logger.info('Permission request results: $permissions');
    return permissions;
  }

  /// Check if all essential permissions are granted
  static Future<bool> areEssentialPermissionsGranted() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await _isAndroid13OrHigher() 
        ? await Permission.photos.status 
        : await Permission.storage.status;
    
    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  /// Request specific permission
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    _logger.info('Requesting permission: $permission');
    final status = await permission.request();
    _logger.info('Permission $permission status: $status');
    return status;
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    return await permission.isPermanentlyDenied;
  }

  /// Open app settings if permission is permanently denied
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Show permission explanation dialog
  static Future<void> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onGranted,
    VoidCallback? onDenied,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDenied?.call();
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onGranted();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  /// Show camera permission dialog
  static Future<void> showCameraPermissionDialog(BuildContext context) async {
    await showPermissionDialog(
      context,
      title: 'Camera Permission',
      message: 'CashSify needs camera access to let you take profile photos and verify your identity.',
      onGranted: () => requestPermission(Permission.camera),
    );
  }

  /// Show storage permission dialog
  static Future<void> showStoragePermissionDialog(BuildContext context) async {
    await showPermissionDialog(
      context,
      title: 'Storage Permission',
      message: 'CashSify needs storage access to save your profile photos and app data.',
      onGranted: () => _isAndroid13OrHigher() 
          ? requestPermission(Permission.photos)
          : requestPermission(Permission.storage),
    );
  }

  /// Check if device is Android 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    // This is a simplified check - in production you might want to use device_info_plus
    return true; // Assume Android 13+ for now
  }

  /// Get permission status for all essential permissions
  static Future<Map<Permission, PermissionStatus>> getPermissionStatuses() async {
    return {
      Permission.camera: await Permission.camera.status,
      Permission.storage: await Permission.storage.status,
      Permission.photos: await Permission.photos.status,
      Permission.accessMediaLocation: await Permission.accessMediaLocation.status,
    };
  }

  /// Handle permission denied permanently
  static Future<void> handlePermanentlyDeniedPermission(
    BuildContext context,
    Permission permission,
    String permissionName,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          '$permissionName permission is required for this feature. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
} 