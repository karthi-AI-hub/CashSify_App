import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'package:cashsify_app/core/config/app_config.dart';

class StorageService {
  final _supabase = SupabaseService();
  static const String _bucketName = 'documents';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  /// Get the single PDF filename for withdrawal summary
  String _getWithdrawalPdfFileName() {
    return 'withdrawal_summary.pdf';
  }

  /// Validate file before upload
  bool _validateFile(File file) {
    if (!file.existsSync()) {
      AppLogger.error('File does not exist: ${file.path}');
      return false;
    }
    
    final fileSize = file.lengthSync();
    if (fileSize == 0) {
      AppLogger.error('File is empty: ${file.path}');
      return false;
    }
    
    // Check if file size is reasonable (max 10MB)
    if (fileSize > 10 * 1024 * 1024) {
      AppLogger.error('File too large: ${fileSize} bytes');
      return false;
    }
    
    return true;
  }

  /// Validate user and withdrawal IDs
  bool _validateIds(String userId, String withdrawalId) {
    if (userId.isEmpty || withdrawalId.isEmpty) {
      AppLogger.error('Invalid userId or withdrawalId provided');
      return false;
    }
    
    // Basic UUID validation
    if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false)
        .hasMatch(withdrawalId)) {
      AppLogger.warning('WithdrawalId may not be a valid UUID: $withdrawalId');
    }
    
    return true;
  }

  /// Upload or update withdrawal PDF to Supabase storage with retry mechanism
  /// Structure: withdrawals/{userId}/{withdrawalId}/withdrawal_summary.pdf
  Future<String?> uploadWithdrawalPdf({
    required String userId,
    required String withdrawalId,
    required File pdfFile,
  }) async {
    try {
      // Validate inputs
      if (!_validateIds(userId, withdrawalId)) {
        return null;
      }
      
      if (!_validateFile(pdfFile)) {
        return null;
      }
      
      AppLogger.info('Uploading withdrawal summary PDF for user: $userId, withdrawal: $withdrawalId');
      
      // Create proper file path structure
      final fileName = _getWithdrawalPdfFileName();
      final filePath = 'withdrawals/$userId/$withdrawalId/$fileName';
      
      AppLogger.info('Uploading to bucket: $_bucketName, path: $filePath');
      
      // Upload file to Supabase storage with retry logic
      FileOptions fileOptions = const FileOptions(
        cacheControl: '3600',
        upsert: true, // Allow overwriting for status updates
      );
      
      // Retry upload up to 3 times with exponential backoff
      int retryCount = 0;
      Exception? lastError;
      
      while (retryCount < _maxRetries) {
        try {
          await _supabase.client.storage
              .from(_bucketName)
              .upload(filePath, pdfFile, fileOptions: fileOptions);
          
          AppLogger.info('Upload successful on attempt ${retryCount + 1}');
          break;
        } catch (uploadError) {
          lastError = uploadError as Exception;
          retryCount++;
          AppLogger.warning('Upload attempt $retryCount failed: $uploadError');
          
          if (retryCount >= _maxRetries) {
            AppLogger.error('All upload attempts failed after $_maxRetries retries');
            break;
          }
          
          // Exponential backoff
          final delay = Duration(seconds: retryCount);
          AppLogger.info('Retrying in ${delay.inSeconds} seconds...');
          await Future.delayed(delay);
        }
      }
      
      if (retryCount >= _maxRetries) {
        AppLogger.error('Failed to upload after $_maxRetries attempts. Last error: $lastError');
        return null;
      }
      
      // Get public URL
      final publicUrl = _supabase.client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      
      AppLogger.info('Withdrawal summary PDF uploaded successfully. Public URL: $publicUrl');
      
      // Update withdrawal record with PDF URL
      await _updateWithdrawalRecord(withdrawalId, publicUrl, filePath);
      
      return publicUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Error uploading withdrawal summary PDF to storage: $e', e, stackTrace);
      return null;
    }
  }

  /// Update withdrawal record with PDF URL
  Future<void> _updateWithdrawalRecord(String withdrawalId, String publicUrl, String filePath) async {
    try {
      AppLogger.info('Attempting to update withdrawal record with PDF URL: $publicUrl');
      
      // First, check if the columns exist by trying to select them
      try {
        await _supabase.client
            .from('withdrawals')
            .select('pdf_url, pdf_path')
            .eq('id', withdrawalId)
            .limit(1);
        
        AppLogger.info('Columns exist check successful');
      } catch (columnError) {
        AppLogger.error('Columns may not exist in withdrawals table: $columnError');
        AppLogger.error('Please run the database migration to add pdf_url and pdf_path columns');
        return; // Exit early if columns don't exist
      }
      
      // Try to update the record
      final updateResponse = await _supabase.client
          .from('withdrawals')
          .update({
            'pdf_url': publicUrl,
            'pdf_path': filePath,
          })
          .eq('id', withdrawalId)
          .select();
      
      AppLogger.info('Withdrawal record updated with PDF URL. Response: $updateResponse');
    } catch (dbError) {
      AppLogger.error('Failed to update withdrawal record with PDF URL: $dbError');
      AppLogger.error('This might be due to missing columns or permissions. Please check the database schema.');
      // Don't rethrow - the PDF is still uploaded and accessible
    }
  }

  /// Download withdrawal PDF from Supabase storage with retry mechanism
  Future<File?> downloadWithdrawalPdf({
    required String userId,
    required String withdrawalId,
  }) async {
    try {
      // Validate inputs
      if (!_validateIds(userId, withdrawalId)) {
        return null;
      }
      
      AppLogger.info('Downloading withdrawal summary PDF for user: $userId, withdrawal: $withdrawalId');
      
      final fileName = _getWithdrawalPdfFileName();
      final filePath = 'withdrawals/$userId/$withdrawalId/$fileName';
      
      AppLogger.info('Downloading from bucket: $_bucketName, path: $filePath');
      
      // Download file from Supabase storage with retry
      List<int>? response;
      int retryCount = 0;
      Exception? lastError;
      
      while (retryCount < _maxRetries) {
        try {
          response = await _supabase.client.storage
              .from(_bucketName)
              .download(filePath);
          break;
        } catch (downloadError) {
          lastError = downloadError as Exception;
          retryCount++;
          AppLogger.warning('Download attempt $retryCount failed: $downloadError');
          
          if (retryCount >= _maxRetries) {
            AppLogger.error('All download attempts failed after $_maxRetries retries');
            break;
          }
          
          await Future.delayed(_retryDelay);
        }
      }
      
      if (response == null) {
        AppLogger.error('Failed to download after $_maxRetries attempts. Last error: $lastError');
        return null;
      }
      
      // Save to local storage
      final documentsDir = await getApplicationDocumentsDirectory();
      final localFile = File('${documentsDir.path}/withdrawal_${withdrawalId}_summary.pdf');
      await localFile.writeAsBytes(response);
      
      AppLogger.info('Withdrawal summary PDF saved locally to: ${localFile.path}');
      return localFile;
    } catch (e, stackTrace) {
      AppLogger.error('Error downloading withdrawal summary PDF from storage: $e', e, stackTrace);
      return null;
    }
  }

  /// Get PDF URL for a withdrawal
  Future<String?> getWithdrawalPdfUrl({
    required String userId,
    required String withdrawalId,
  }) async {
    try {
      final fileName = _getWithdrawalPdfFileName();
      final filePath = 'withdrawals/$userId/$withdrawalId/$fileName';
      
      final publicUrl = _supabase.client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      
      AppLogger.info('Got withdrawal summary PDF URL from bucket: $_bucketName');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error getting withdrawal summary PDF URL: $e');
      return null;
    }
  }

  /// Delete PDF from Supabase storage
  Future<bool> deleteWithdrawalPdf({
    required String userId,
    required String withdrawalId,
  }) async {
    try {
      AppLogger.info('Deleting withdrawal summary PDF for user: $userId, withdrawal: $withdrawalId');
      
      final fileName = _getWithdrawalPdfFileName();
      final filePath = 'withdrawals/$userId/$withdrawalId/$fileName';
      
      await _supabase.client.storage
          .from(_bucketName)
          .remove([filePath]);
      
      AppLogger.info('Withdrawal summary PDF deleted successfully from storage');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting withdrawal summary PDF from storage: $e', e, stackTrace);
      return false;
    }
  }

  /// Check if PDF exists in storage
  Future<bool> pdfExists({
    required String userId,
    required String withdrawalId,
  }) async {
    try {
      final fileName = _getWithdrawalPdfFileName();
      final filePath = 'withdrawals/$userId/$withdrawalId/$fileName';
      
      try {
        final files = await _supabase.client.storage
            .from(_bucketName)
            .list(path: 'withdrawals/$userId/$withdrawalId/');
        
        final exists = files.any((file) => file.name == fileName);
        if (exists) {
          AppLogger.info('Withdrawal summary PDF exists in bucket: $_bucketName');
          return true;
        }
        
        AppLogger.info('Withdrawal summary PDF does not exist in bucket: $_bucketName');
        return false;
        
      } catch (bucketError) {
        AppLogger.warning('Failed to check existence in bucket: $_bucketName. Error: $bucketError');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error checking if withdrawal summary PDF exists: $e');
      return false;
    }
  }

  /// Check if PDF URL exists in withdrawal record
  Future<bool> pdfUrlExistsInRecord({
    required String withdrawalId,
  }) async {
    try {
      final response = await _supabase.client
          .from('withdrawals')
          .select('pdf_url')
          .eq('id', withdrawalId)
          .single();
      
      final urlField = response['pdf_url'] as String?;
      final exists = urlField != null && urlField.isNotEmpty;
      AppLogger.info('Withdrawal summary PDF URL exists in record: $exists');
      return exists;
    } catch (e) {
      AppLogger.error('Error checking if withdrawal summary PDF URL exists in record: $e');
      return false;
    }
  }

  /// Manually update PDF URL for a withdrawal (useful for fixing missing URLs)
  Future<bool> updateWithdrawalPdfUrl({
    required String userId,
    required String withdrawalId,
  }) async {
    try {
      AppLogger.info('Manually updating PDF URL for withdrawal: $withdrawalId');
      
      final fileName = _getWithdrawalPdfFileName();
      final filePath = 'withdrawals/$userId/$withdrawalId/$fileName';
      
      // Check if file exists in storage
      final exists = await pdfExists(userId: userId, withdrawalId: withdrawalId);
      if (!exists) {
        AppLogger.warning('PDF file does not exist in storage for withdrawal: $withdrawalId');
        return false;
      }
      
      // Get public URL
      final publicUrl = _supabase.client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      
      // Update withdrawal record
      final updateResponse = await _supabase.client
          .from('withdrawals')
          .update({
            'pdf_url': publicUrl,
            'pdf_path': filePath,
          })
          .eq('id', withdrawalId)
          .select();
      
      AppLogger.info('Successfully updated PDF URL for withdrawal: $withdrawalId. Response: $updateResponse');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error manually updating PDF URL for withdrawal: $e', e, stackTrace);
      return false;
    }
  }

  /// Fix missing PDF URLs for all withdrawals of a user
  Future<int> fixMissingPdfUrls({
    required String userId,
  }) async {
    try {
      AppLogger.info('Fixing missing PDF URLs for user: $userId');
      
      // Get all withdrawals for the user
      final withdrawals = await _supabase.client
          .from('withdrawals')
          .select('id, pdf_url')
          .eq('user_id', userId);
      
      int fixedCount = 0;
      
      for (final withdrawal in withdrawals) {
        final withdrawalId = withdrawal['id'] as String;
        final pdfUrl = withdrawal['pdf_url'] as String?;
        
        // If PDF URL is missing, try to fix it
        if (pdfUrl == null || pdfUrl.isEmpty) {
          final success = await updateWithdrawalPdfUrl(
            userId: userId,
            withdrawalId: withdrawalId,
          );
          if (success) {
            fixedCount++;
          }
        }
      }
      
      AppLogger.info('Fixed $fixedCount missing PDF URLs for user: $userId');
      return fixedCount;
    } catch (e, stackTrace) {
      AppLogger.error('Error fixing missing PDF URLs: $e', e, stackTrace);
      return 0;
    }
  }

  Future<String?> getCashSifyDownloadsPath() async {
    try {
      if (Platform.isAndroid) {
        // Try to access the public Downloads directory
        final possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];
        
        for (final path in possiblePaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            final cashsifyDir = Directory('$path/${AppConfig.appName}');
            if (await cashsifyDir.exists()) {
              return cashsifyDir.path;
            }
          }
        }
        
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final cashsifyDir = Directory('${externalDir.path}/${AppConfig.appName}');
          if (await cashsifyDir.exists()) {
            return cashsifyDir.path;
          }
        }
      }
      
      final appDir = await getApplicationDocumentsDirectory();
      final cashsifyDir = Directory('${appDir.path}/${AppConfig.appName}');
      if (await cashsifyDir.exists()) {
        return cashsifyDir.path;
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Error getting ${AppConfig.appName} downloads path: $e');
      return null;
    }
  }

  Future<List<FileSystemEntity>> listDownloadedPdfs() async {
    try {
      final downloadsPath = await getCashSifyDownloadsPath();
      if (downloadsPath == null) {
        return [];
      }
      
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        return [];
      }
      
      final files = await dir.list().toList();
      final pdfFiles = files.where((file) => 
        file is File && file.path.toLowerCase().endsWith('.pdf')
      ).toList();
      
      // Sort by modification time (newest first)
      pdfFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
      
      AppLogger.info('Found ${pdfFiles.length} downloaded PDFs in ${AppConfig.appName} folder');
      return pdfFiles;
    } catch (e) {
      AppLogger.error('Error listing downloaded PDFs: $e');
      return [];
    }
  }

  /// Clear all downloaded PDFs from the CashSify folder
  Future<bool> clearDownloadedPdfs() async {
    try {
      final downloadsPath = await getCashSifyDownloadsPath();
      if (downloadsPath == null) {
        return false;
      }
      
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        return true; // Nothing to clear
      }
      
      final files = await dir.list().toList();
      int deletedCount = 0;
      
      for (final file in files) {
        if (file is File && file.path.toLowerCase().endsWith('.pdf')) {
          await file.delete();
          deletedCount++;
        }
      }
      
      AppLogger.info('Cleared $deletedCount downloaded PDFs from ${AppConfig.appName} folder');
      return true;
    } catch (e) {
      AppLogger.error('Error clearing downloaded PDFs: $e');
      return false;
    }
  }

  /// Download withdrawal PDF bytes from Supabase storage (without saving to app storage)
  Future<List<int>?> downloadWithdrawalPdfBytes({
    required String userId,
    required String withdrawalId,
  }) async {
    try {
      // Validate inputs
      if (!_validateIds(userId, withdrawalId)) {
        return null;
      }
      
      AppLogger.info('Downloading withdrawal summary PDF bytes for user: $userId, withdrawal: $withdrawalId');
      
      final fileName = _getWithdrawalPdfFileName();
      final filePath = 'withdrawals/$userId/$withdrawalId/$fileName';
      
      AppLogger.info('Downloading from bucket: $_bucketName, path: $filePath');
      
      // Download file from Supabase storage with retry
      List<int>? response;
      int retryCount = 0;
      Exception? lastError;
      
      while (retryCount < _maxRetries) {
        try {
          response = await _supabase.client.storage
              .from(_bucketName)
              .download(filePath);
          break;
        } catch (downloadError) {
          lastError = downloadError as Exception;
          retryCount++;
          AppLogger.warning('Download attempt $retryCount failed: $downloadError');
          
          if (retryCount >= _maxRetries) {
            AppLogger.error('All download attempts failed after $_maxRetries retries');
            break;
          }
          
          await Future.delayed(_retryDelay);
        }
      }
      
      if (response == null) {
        AppLogger.error('Failed to download after $_maxRetries attempts. Last error: $lastError');
        return null;
      }
      
      AppLogger.info('Withdrawal summary PDF bytes downloaded successfully: ${response.length} bytes');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Error downloading withdrawal summary PDF bytes from storage: $e', e, stackTrace);
      return null;
    }
  }
} 