import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/app_state_provider.dart';
import 'package:cashsify_app/core/widgets/layout/custom_app_bar.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:cashsify_app/core/widgets/layout/custom_card.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:cashsify_app/core/utils/storage_viewer.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'package:cashsify_app/core/utils/pdf_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DebugStorageScreen extends ConsumerStatefulWidget {
  const DebugStorageScreen({super.key});

  @override
  ConsumerState<DebugStorageScreen> createState() => _DebugStorageScreenState();
}

class _DebugStorageScreenState extends ConsumerState<DebugStorageScreen> {
  String _storageData = 'Loading...';
  String _logData = 'Loading...';
  bool _isLoading = false;
  String? _logFilePath;
  List<File> _savedPdfs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load storage data
      final storageInfo = await StorageViewer.getAllDataAsString();
      setState(() {
        _storageData = storageInfo;
      });

      // Load log file path and content
      _logFilePath = await AppLogger.getLogFilePath();
      final logContent = await AppLogger.getLogFileContent();
      setState(() {
        _logData = logContent ?? 'No log file found';
      });

      // Load saved PDF files
      final pdfs = await PdfUtils.getSavedPdfs();
      setState(() {
        _savedPdfs = pdfs;
      });
    } catch (e) {
      setState(() {
        _storageData = 'Error loading storage data: $e';
        _logData = 'Error loading log data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareLogFile() async {
    try {
      if (_logFilePath != null && await File(_logFilePath!).exists()) {
        await Share.shareXFiles(
          [XFile(_logFilePath!)],
          text: 'CashSify App Logs',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log file not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing log file: $e')),
      );
    }
  }

  Future<void> _clearLogs() async {
    try {
      await AppLogger.clearLogs();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing logs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: CustomAppBar(
        title: 'Debug Storage',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
          color: colorScheme.onPrimary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App State Info
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App State Status',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildInfoRow('Initialized', appState.isInitialized.toString()),
                      _buildInfoRow('Has Saved State', appState.hasSavedState.toString()),
                      if (appState.lastSaved != null)
                        _buildInfoRow('Last Saved', appState.lastSaved!.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Navigation State
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navigation State',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildDataViewer(
                        context,
                        ref.read(appStateProvider.notifier).loadNavigationState(),
                        'navigation_state',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // User Data
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Data',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildDataViewer(
                        context,
                        ref.read(appStateProvider.notifier).loadUserData(),
                        'user_data',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // App Settings
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Settings',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildDataViewer(
                        context,
                        ref.read(appStateProvider.notifier).loadAppSettings(),
                        'app_settings',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Log File Section
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'App Logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: _shareLogFile,
                                tooltip: 'Share Log File',
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearLogs,
                                tooltip: 'Clear Logs',
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_logFilePath != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Log File: $_logFilePath',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: SelectableText(
                            _logData,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // PDF Files Section
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved PDF Files',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _isLoading ? null : () async {
                                  final pdfs = await PdfUtils.getSavedPdfs();
                                  setState(() {
                                    _savedPdfs = pdfs;
                                  });
                                },
                                tooltip: 'Refresh PDF List',
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear_all),
                                onPressed: _isLoading ? null : () async {
                                  await PdfUtils.clearAllPdfs();
                                  setState(() {
                                    _savedPdfs = [];
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('All PDF files cleared')),
                                    );
                                  }
                                },
                                tooltip: 'Clear All PDFs',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_savedPdfs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'No PDF files found',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _savedPdfs.map((file) {
                            final fileName = file.path.split('/').last;
                            final fileSize = file.lengthSync();
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${(fileSize / 1024).toStringAsFixed(1)} KB',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new),
                                        onPressed: () async {
                                          try {
                                            await PdfUtils.openPdf(file.path);
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error opening PDF: $e')),
                                              );
                                            }
                                          }
                                        },
                                        tooltip: 'Open PDF',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () async {
                                          try {
                                            await Share.shareXFiles(
                                              [XFile(file.path)],
                                              text: 'CashSify Withdrawal PDF',
                                            );
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error sharing PDF: $e')),
                                              );
                                            }
                                          }
                                        },
                                        tooltip: 'Share PDF',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () async {
                                          final deleted = await PdfUtils.deletePdf(file.path);
                                          if (deleted) {
                                            setState(() {
                                              _savedPdfs.remove(file);
                                            });
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('PDF deleted')),
                                              );
                                            }
                                          }
                                        },
                                        tooltip: 'Delete PDF',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Storage Data Section
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Storage Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: SelectableText(
                            _storageData,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await StorageViewer.printAllData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Storage data printed to console'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print to Console'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await StorageViewer.clearAllData();
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Storage cleared'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Storage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDataViewer(BuildContext context, Map<String, dynamic>? data, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'No data saved',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.data_object,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'JSON Data:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(data),
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 