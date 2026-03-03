import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/frappe_config.dart';
import '../../../../core/services/frappe_client.dart';
import 'invoice_models.dart';

class InvoiceService {
  InvoiceService({FrappeClient? client}) : _client = client ?? FrappeClient();

  final FrappeClient _client;

  Future<String> resolveClientIdFromEmail(String email) async {
    final response = await _client.get(
      '/api/resource/${FrappeConfig.clientDoctype}',
      queryParameters: {
        'filters': jsonEncode([
          [FrappeConfig.clientUserIdField, '=', email],
        ]),
        'fields': jsonEncode(['name']),
        'limit_page_length': '1',
      },
    );

    final data = response['data'] ?? response['message'];
    if (data is List && data.isNotEmpty) {
      final first = Map<String, dynamic>.from(data.first as Map);
      final id = first['name']?.toString() ?? '';
      if (id.isNotEmpty) return id;
    }
    throw Exception('Client record not found');
  }

  Future<List<ClientInvoice>> loadInvoices(String clientId) async {
    final response = await _client.get(
      '/api/resource/${FrappeConfig.clientInvoiceDoctype}',
      queryParameters: {
        'filters': jsonEncode([
          [FrappeConfig.clientInvoiceClientField, '=', clientId],
        ]),
      },
    );

    final data = response['data'] ?? response['message'];
    if (data is! List) return const [];
    return data
        .map(
          (row) =>
              ClientInvoice.fromListRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<ClientInvoice> loadInvoiceByName(String docName) async {
    final response = await _client.get(
      '/api/resource/${FrappeConfig.clientInvoiceDoctype}/$docName',
    );
    final data = response['data'] ?? response;
    if (data is! Map) {
      throw Exception('Invalid invoice response');
    }
    return ClientInvoice.fromDoc(Map<String, dynamic>.from(data));
  }

  Future<String> resolveInvoiceDateNameFieldKey() async {
    try {
      final parentMeta = await _client.get(
        '/api/resource/DocType/${Uri.encodeComponent(FrappeConfig.clientInvoiceDoctype)}',
      );
      final parentData = parentMeta['data'] as Map<String, dynamic>?;
      final parentFields = parentData?['fields'];
      if (parentFields is! List) {
        return FrappeConfig.clientInvoiceDateEntryNameField;
      }

      String? childDoctype;
      for (final raw in parentFields) {
        final field = Map<String, dynamic>.from(raw as Map);
        if (field['fieldname']?.toString() ==
            FrappeConfig.clientInvoiceDateTableField) {
          childDoctype = field['options']?.toString();
          break;
        }
      }

      if (childDoctype == null || childDoctype.isEmpty) {
        return FrappeConfig.clientInvoiceDateEntryNameField;
      }

      final childMeta = await _client.get(
        '/api/resource/DocType/${Uri.encodeComponent(childDoctype)}',
      );
      final childData = childMeta['data'] as Map<String, dynamic>?;
      final childFields = childData?['fields'];
      if (childFields is! List) {
        return FrappeConfig.clientInvoiceDateEntryNameField;
      }

      final excluded = <String>{
        'name',
        'owner',
        'creation',
        'modified',
        'modified_by',
        'docstatus',
        'idx',
        'parent',
        'parentfield',
        'parenttype',
        'doctype',
        FrappeConfig.clientInvoiceDateEntryValueField,
      };

      String? firstCandidate;
      for (final raw in childFields) {
        final field = Map<String, dynamic>.from(raw as Map);
        final fieldname = field['fieldname']?.toString() ?? '';
        final fieldtype = field['fieldtype']?.toString() ?? '';
        if (fieldname.isEmpty || excluded.contains(fieldname)) continue;
        if (fieldtype == 'Section Break' ||
            fieldtype == 'Column Break' ||
            fieldtype == 'Table') {
          continue;
        }

        final lowerName = fieldname.toLowerCase();
        final lowerLabel = (field['label']?.toString() ?? '').toLowerCase();
        if (lowerName.contains('name') ||
            lowerName.contains('field') ||
            lowerLabel.contains('name') ||
            lowerLabel.contains('field')) {
          return fieldname;
        }

        firstCandidate ??= fieldname;
      }

      return firstCandidate ?? FrappeConfig.clientInvoiceDateEntryNameField;
    } catch (_) {
      return FrappeConfig.clientInvoiceDateEntryNameField;
    }
  }

  Future<void> createInvoice(Map<String, dynamic> payload) async {
    await _client.post(
      '/api/resource/${FrappeConfig.clientInvoiceDoctype}',
      body: {'data': payload},
    );
  }

  Future<void> updateInvoice(
    String docName,
    Map<String, dynamic> payload,
  ) async {
    await _client.put(
      '/api/resource/${FrappeConfig.clientInvoiceDoctype}/$docName',
      body: {'data': payload},
    );
  }

  Future<void> downloadInvoicePdf(String docName) async {
    final baseUrl = FrappeConfig.baseUrl;
    final url = Uri.parse(
      '$baseUrl/api/method/frappe.utils.print_format.download_pdf?doctype=${Uri.encodeComponent(FrappeConfig.clientInvoiceDoctype)}&name=${Uri.encodeComponent(docName)}',
    );

    final headers = <String, String>{'Accept': 'application/pdf'};
    if (FrappeConfig.useTokenAuth) {
      headers['Authorization'] =
          'token ${FrappeConfig.apiKey}:${FrappeConfig.apiSecret}';
    }

    final response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Download failed with status ${response.statusCode}');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_$docName.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    await OpenFilex.open(file.path);
  }
}
