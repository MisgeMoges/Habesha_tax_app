import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:habesha_tax_app/core/config/frappe_config.dart';
import 'package:habesha_tax_app/core/services/frappe_client.dart';
import 'package:habesha_tax_app/core/utils/user_friendly_error.dart';
import 'package:habesha_tax_app/data/model/transaction.dart';
import 'add_transaction_form.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final FrappeClient _client = FrappeClient();
  late Transaction _transaction;
  bool _loadingFiles = false;
  String? _filesError;
  List<_TransactionAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _loadTransactionFiles();
  }

  Future<void> _loadTransactionFiles() async {
    if (_transaction.id.trim().isEmpty) return;

    setState(() {
      _loadingFiles = true;
      _filesError = null;
    });

    try {
      final response = await _client.get(
        '/api/resource/${FrappeConfig.transactionDoctype}/${_transaction.id}',
      );
      final raw = response['data'] ?? response;
      final data = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);

      final collected = <_TransactionAttachment>[];
      final seen = <String>{};

      void addAttachment(String? rawUrl, String sourceLabel) {
        final resolved = _resolveFileUrl(rawUrl);
        if (resolved == null || resolved.isEmpty) return;
        if (seen.contains(resolved)) return;
        seen.add(resolved);
        collected.add(
          _TransactionAttachment(url: resolved, source: sourceLabel),
        );
      }

      addAttachment(
        data[FrappeConfig.transactionMainFileField]?.toString(),
        'Main file',
      );

      final childRows = data[FrappeConfig.transactionAttachmentsField];
      if (childRows is List) {
        for (var i = 0; i < childRows.length; i++) {
          final rowRaw = childRows[i];
          if (rowRaw is! Map) continue;
          final row = Map<String, dynamic>.from(rowRaw);
          addAttachment(
            row[FrappeConfig.transactionAttachmentFileField]?.toString() ??
                row['file_url']?.toString() ??
                row['attachment']?.toString(),
            'Attachment ${i + 1}',
          );
        }
      }

      if (!mounted) return;
      setState(() => _attachments = collected);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _filesError = UserFriendlyError.message(
          e,
          fallback: 'Unable to load attachments right now.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingFiles = false);
      }
    }
  }

  String? _resolveFileUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final base = FrappeConfig.baseUrl.endsWith('/')
        ? FrappeConfig.baseUrl.substring(0, FrappeConfig.baseUrl.length - 1)
        : FrappeConfig.baseUrl;
    final path = value.startsWith('/') ? value : '/$value';
    return '$base$path';
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).trim();
    final fileName = path.split('/').where((part) => part.isNotEmpty).isEmpty
        ? 'Attachment'
        : path.split('/').where((part) => part.isNotEmpty).last;
    return Uri.decodeComponent(fileName);
  }

  void _showAttachmentPreview(_TransactionAttachment attachment) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isImage = _isImageUrl(attachment.url);
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.source,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _fileNameFromUrl(attachment.url),
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 10),
                if (isImage)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: InteractiveViewer(
                      child: Image.network(
                        attachment.url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Unable to load image.')),
                        ),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Icon(Icons.insert_drive_file, size: 60),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _transaction.isIncome;
    final amountText =
        '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: r'$').format(_transaction.amount.abs())}';
    final dateText = _transaction.postingDateValue != null
        ? DateFormat('MMM dd, yyyy').format(_transaction.postingDateValue!)
        : _transaction.postingDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionFormScreen(
                    initialTransaction: _transaction,
                    initialTransactionType: _transaction.type,
                  ),
                ),
              );
              if (updated == true && mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(amountText, isIncome),
            const SizedBox(height: 20),
            _buildDetailCard(
              title: 'Category',
              value: _transaction.category_name.isNotEmpty
                  ? _transaction.category_name
                  : _transaction.category,
            ),
            _buildDetailCard(title: 'Type', value: _transaction.type),
            _buildDetailCard(title: 'Posting Date', value: dateText),
            _buildDetailCard(
              title: 'Note',
              value: _transaction.note.isNotEmpty
                  ? _transaction.note
                  : 'No note',
            ),
            _buildDetailCard(title: 'Transaction ID', value: _transaction.id),
            _buildAttachmentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Attachments',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              if (_loadingFiles)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Refresh files',
                  onPressed: _loadTransactionFiles,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
            ],
          ),
          if (_filesError != null) ...[
            const SizedBox(height: 8),
            Text(_filesError!, style: const TextStyle(color: Colors.red)),
          ] else if (!_loadingFiles && _attachments.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'No main file or child-table attachments found.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ] else if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final attachment in _attachments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _isImageUrl(attachment.url)
                      ? Icons.image_outlined
                      : Icons.insert_drive_file_outlined,
                ),
                title: Text(
                  attachment.source,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _fileNameFromUrl(attachment.url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _showAttachmentPreview(attachment),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String amountText, bool isIncome) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isIncome
              ? [const Color(0xFF8A56E8), const Color(0xFFBCA8F7)]
              : [
                  const Color.fromARGB(234, 239, 135, 127),
                  const Color.fromARGB(200, 255, 192, 178),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _transaction.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amountText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TransactionAttachment {
  const _TransactionAttachment({required this.url, required this.source});

  final String url;
  final String source;
}
