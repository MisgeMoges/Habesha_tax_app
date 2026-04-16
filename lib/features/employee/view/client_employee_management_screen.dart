import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/frappe_config.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_bloc.dart';
import 'package:habesha_tax_app/features/auth/bloc/auth_state.dart';
import '../../../core/services/frappe_client.dart';
import '../../../core/utils/user_friendly_error.dart';

class ClientEmployeeManagementScreen extends StatefulWidget {
  const ClientEmployeeManagementScreen({super.key});

  @override
  State<ClientEmployeeManagementScreen> createState() =>
      _ClientEmployeeManagementScreenState();
}

class _ClientEmployeeManagementScreenState
    extends State<ClientEmployeeManagementScreen>
    with SingleTickerProviderStateMixin {
  final FrappeClient _client = FrappeClient();

  final _formKey = GlobalKey<FormState>();

  final _employeeNameController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _positionController = TextEditingController();
  final _joiningDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late final TabController _tabController;

  bool _loadingEmployees = false;
  bool _loadingEmployeeDetails = false;
  bool _loadingClientId = false;
  bool _loadingPayrollPeriods = false;
  bool _isSaving = false;
  bool _isDirty = false;

  String? _employeeError;
  String? _detailError;
  String? _clientIdError;
  String? _payrollPeriodError;

  String? _selectedStatus = 'Active';
  String? _editingEmployeeId;
  String? _selectedEmployeeIdForPayroll;
  String? _selectedEmployeeNameForPayroll;
  String? _clientId;

  final List<Map<String, dynamic>> _employees = [];
  final List<Map<String, dynamic>> _payrollEntries = [];
  final List<Map<String, dynamic>> _payrollPeriods = [];

  static const List<String> _statuses = ['Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _joiningDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now());
    _loadEmployees();
    _loadPayrollPeriods();
  }

  Future<bool> _ensureClientIdLoaded() async {
    if (_clientId != null && _clientId!.isNotEmpty) return true;
    await _loadClientId();
    return _clientId != null && _clientId!.isNotEmpty;
  }

  Future<void> _loadPayrollPeriods() async {
    setState(() {
      _loadingPayrollPeriods = true;
      _payrollPeriodError = null;
    });

    try {
      final response = await _client.get(
        '/api/resource/${FrappeConfig.payrollPeriodDoctype}',
        queryParameters: {
          'fields': '["name","${FrappeConfig.payrollPeriodLabelField}"]',
          'order_by': 'modified desc',
          'limit_page_length': '100',
        },
      );

      final data = response['data'] ?? response['message'];
      if (data is List) {
        _payrollPeriods
          ..clear()
          ..addAll(data.map((e) => Map<String, dynamic>.from(e as Map)));
      } else {
        throw Exception('Invalid payroll period data');
      }
    } catch (e) {
      _payrollPeriodError = UserFriendlyError.message(
        e,
        fallback: 'Unable to load payroll periods right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingPayrollPeriods = false);
    }
  }

  Future<void> _loadClientId() async {
    if (_clientId != null && _clientId!.isNotEmpty) return;
    setState(() {
      _loadingClientId = true;
      _clientIdError = null;
    });

    try {
      // Use authenticated user's email to query the Client doctype
      final authState = context.read<AuthBloc>().state;
      final user = authState is Authenticated ? authState.user : null;
      final userEmail = user?.email ?? '';
      if (userEmail.isEmpty) throw Exception('User not authenticated');

      final response = await _client.get(
        '/api/resource/${FrappeConfig.clientDoctype}',
        queryParameters: {
          'filters': '[["user_id","=","$userEmail"]]',
          'limit_page_length': '1',
        },
      );

      final data = response['data'] ?? response['message'];
      if (data is List && data.isNotEmpty) {
        final first = Map<String, dynamic>.from(data.first as Map);
        _clientId = first['name']?.toString() ?? first['id']?.toString() ?? '';
      } else {
        throw Exception('Client record not found');
      }
    } catch (e) {
      _clientIdError = UserFriendlyError.message(
        e,
        fallback: 'Unable to load your client account right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingClientId = false);
    }
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _hourlyRateController.dispose();
    _positionController.dispose();
    _joiningDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _loadingEmployees = true;
      _employeeError = null;
    });

    try {
      final hasClient = await _ensureClientIdLoaded();
      if (!hasClient) {
        throw Exception(_clientIdError ?? 'Client record not found');
      }

      final response = await _client.get(
        '/api/resource/${FrappeConfig.clientEmployeeDoctype}',
        queryParameters: {
          'filters': jsonEncode([
            [FrappeConfig.clientEmployeeClientField, '=', _clientId],
          ]),
          'fields':
              '["name","${FrappeConfig.clientEmployeeClientField}","${FrappeConfig.clientEmployeeNameField}","${FrappeConfig.clientEmployeeHourlyRateField}","${FrappeConfig.clientEmployeeStatusField}"]',
          'order_by': 'modified desc',
          'limit_page_length': '100',
        },
      );

      final data = response['data'] ?? response['message'];
      if (data is List) {
        _employees
          ..clear()
          ..addAll(data.map((e) => Map<String, dynamic>.from(e as Map)));

        final stillSelected = _employees.any(
          (e) => e['name']?.toString() == _selectedEmployeeIdForPayroll,
        );
        if (!stillSelected) {
          _selectedEmployeeIdForPayroll = null;
          _selectedEmployeeNameForPayroll = null;
          _payrollEntries.clear();
        }
      } else {
        throw Exception('Invalid employee data');
      }
    } catch (e) {
      _employeeError = UserFriendlyError.message(
        e,
        fallback: 'Unable to load employees right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Future<Map<String, dynamic>> _fetchEmployeeDetails(String employeeId) async {
    final hasClient = await _ensureClientIdLoaded();
    if (!hasClient) {
      throw Exception(_clientIdError ?? 'Client record not found');
    }

    final response = await _client.get(
      '/api/resource/${FrappeConfig.clientEmployeeDoctype}/$employeeId',
    );

    final data = response['data'] ?? response['message'];
    if (data is Map) {
      final employee = Map<String, dynamic>.from(data);
      final employeeClient = employee[FrappeConfig.clientEmployeeClientField]
          ?.toString();
      if (employeeClient == null || employeeClient != _clientId) {
        throw Exception('Employee does not belong to the logged in client');
      }
      return employee;
    }
    throw Exception('Invalid employee data');
  }

  Future<void> _loadEmployeeDetails(String employeeId) async {
    setState(() {
      _loadingEmployeeDetails = true;
      _detailError = null;
    });

    try {
      final data = await _fetchEmployeeDetails(employeeId);
      if (data.isNotEmpty) {
        _editingEmployeeId = employeeId;
        _employeeNameController.text =
            data[FrappeConfig.clientEmployeeNameField]?.toString() ?? '';
        _hourlyRateController.text =
            data[FrappeConfig.clientEmployeeHourlyRateField]?.toString() ?? '';
        _selectedStatus =
            data[FrappeConfig.clientEmployeeStatusField]?.toString() ??
            'Active';
        _positionController.text =
            data[FrappeConfig.clientEmployeePositionField]?.toString() ?? '';
        _joiningDateController.text =
            data[FrappeConfig.clientEmployeeJoiningDateField]?.toString() ?? '';
        _emailController.text =
            data[FrappeConfig.clientEmployeeEmailField]?.toString() ?? '';
        _phoneController.text =
            data[FrappeConfig.clientEmployeePhoneField]?.toString() ?? '';
        _isDirty = false;
        _tabController.animateTo(2);
      } else {
        throw Exception('Invalid employee data');
      }
    } catch (e) {
      _detailError = UserFriendlyError.message(
        e,
        fallback: 'Unable to load employee details right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingEmployeeDetails = false);
    }
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  double _hourlyRateValue() {
    return double.tryParse(_hourlyRateController.text.trim()) ?? 0;
  }

  Future<void> _selectJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _joiningDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      _markDirty();
    }
  }

  Future<void> _loadPayrollEntries(String employeeId) async {
    setState(() {
      _loadingEmployeeDetails = true;
      _detailError = null;
    });

    try {
      final data = await _fetchEmployeeDetails(employeeId);
      _selectedEmployeeIdForPayroll = employeeId;
      _selectedEmployeeNameForPayroll =
          data[FrappeConfig.clientEmployeeNameField]?.toString();

      final rows =
          data[FrappeConfig.clientEmployeePayrollTableField] as List? ?? [];
      _payrollEntries
        ..clear()
        ..addAll(rows.map((e) => Map<String, dynamic>.from(e as Map)));

      // If payroll entries don't include an hourly/salary rate, default to
      // the employee's hourly rate so the list displays a value.
      final employeeHourly = data[FrappeConfig.clientEmployeeHourlyRateField]
          ?.toString()
          .trim();
      if (employeeHourly != null && employeeHourly.isNotEmpty) {
        for (final entry in _payrollEntries) {
          final rate = entry[FrappeConfig.payrollHourlyRateField];
          if (rate == null || rate.toString().trim().isEmpty) {
            entry[FrappeConfig.payrollHourlyRateField] = employeeHourly;
          }
        }
      }
    } catch (e) {
      _detailError = UserFriendlyError.message(
        e,
        fallback: 'Unable to load payroll entries right now.',
      );
    } finally {
      if (mounted) setState(() => _loadingEmployeeDetails = false);
    }
  }

  Future<void> _openPayrollModal(String employeeId) async {
    final data = await _fetchEmployeeDetails(employeeId);
    final name = data[FrappeConfig.clientEmployeeNameField]?.toString() ?? '';
    final position =
        data[FrappeConfig.clientEmployeePositionField]?.toString() ?? '';
    final hourlyRate =
        data[FrappeConfig.clientEmployeeHourlyRateField]?.toString() ?? '';

    if (_payrollPeriods.isEmpty && !_loadingPayrollPeriods) {
      await _loadPayrollPeriods();
    }

    String? selectedPeriodId = _payrollPeriods.isNotEmpty
        ? _payrollPeriods.first['name']?.toString()
        : null;
    final postingDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final workedHoursController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Payroll Entry'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildReadOnlyField(label: 'Employee', value: name),
                    const SizedBox(height: 10),
                    _buildReadOnlyField(label: 'Position', value: position),
                    const SizedBox(height: 10),
                    _buildReadOnlyField(
                      label: 'Hourly Rate',
                      value: hourlyRate,
                    ),
                    const SizedBox(height: 10),
                    if (_loadingPayrollPeriods)
                      const LinearProgressIndicator()
                    else if (_payrollPeriodError != null)
                      Text(
                        _payrollPeriodError!,
                        style: const TextStyle(color: Colors.red),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedPeriodId,
                        decoration: const InputDecoration(
                          labelText: 'Payroll Period',
                          border: OutlineInputBorder(),
                        ),
                        items: _payrollPeriods
                            .map(
                              (period) => DropdownMenuItem(
                                value: period['name']?.toString() ?? '',
                                child: Text(_payrollPeriodLabel(period)),
                              ),
                            )
                            .where(
                              (item) =>
                                  item.value != null && item.value!.isNotEmpty,
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null || value.isEmpty) return;
                          setDialogState(() => selectedPeriodId = value);
                        },
                      ),
                    const SizedBox(height: 10),
                    _buildDateField(
                      controller: postingDateController,
                      label: 'Posting Date',
                      onTap: () =>
                          _selectPostingDateController(postingDateController),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: workedHoursController,
                      label: 'Worked Hours',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (workedHoursController.text.trim().isEmpty ||
                        selectedPeriodId == null ||
                        selectedPeriodId!.isEmpty) {
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      // Schedule disposal after the current microtask to avoid disposing
      // controllers while the dialog/pop is still finalizing which can
      // cause "wrong build scope" assertions.
      Future.microtask(() {
        try {
          postingDateController.dispose();
        } catch (_) {}
        try {
          workedHoursController.dispose();
        } catch (_) {}
      });
      return;
    }

    await _savePayrollEntry(
      employeeId: employeeId,
      payrollPeriod: selectedPeriodId ?? '',
      postingDate: postingDateController.text.trim(),
      workedHours: workedHoursController.text.trim(),
      hourlyRate: hourlyRate,
    );

    // Dispose controllers after a microtask to avoid race with dialog
    Future.microtask(() {
      try {
        postingDateController.dispose();
      } catch (_) {}
      try {
        workedHoursController.dispose();
      } catch (_) {}
    });
  }

  Future<void> _savePayrollEntry({
    required String employeeId,
    required String payrollPeriod,
    required String postingDate,
    required String workedHours,
    required String hourlyRate,
  }) async {
    setState(() => _isSaving = true);

    try {
      // First get employee details to get employee name and position
      final employeeData = await _fetchEmployeeDetails(employeeId);

      // Prepare the payload for the custom endpoint
      final payload = {
        'client_employee': employeeId,
        'payroll_period': payrollPeriod,
        'posting_date': postingDate,
        'worked_hours': double.tryParse(workedHours) ?? 0,
        'hourly_rate': double.tryParse(hourlyRate) ?? 0,
        'employee_name': employeeData[FrappeConfig.clientEmployeeNameField],
        'position': employeeData[FrappeConfig.clientEmployeePositionField],
      };

      print('Sending payroll data: $payload'); // Debugging

      // Call the custom endpoint instead of direct document update
      final response = await _client.post(
        'api/method/habesha_tax.habesha_tax.doctype.client_employee.client_employee.post_employee_payroll', // Adjust this path to match your app's actual path
        body: {
          'payroll': jsonEncode(
            payload,
          ), // Send as JSON string as expected by the backend
        },
      );

      print('Response: $response'); // Debugging

      // Reload the payroll entries after successful save
      await _loadPayrollEntries(employeeId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll entry saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserFriendlyError.message(
              e,
              fallback:
                  'Unable to save payroll entry right now. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveEmployee() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_clientId == null || _clientId!.isEmpty) {
      await _loadClientId();
    }
    if (_clientId == null || _clientId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_clientIdError ?? 'Client is required.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final hourlyRate = _hourlyRateValue();
      final payload = <String, dynamic>{
        FrappeConfig.clientEmployeeClientField: _clientId,
        FrappeConfig.clientEmployeeHourlyRateField: hourlyRate,
        FrappeConfig.clientEmployeeNameField: _employeeNameController.text
            .trim(),
        FrappeConfig.clientEmployeeStatusField: _selectedStatus ?? 'Active',
        FrappeConfig.clientEmployeePositionField: _positionController.text
            .trim(),
        FrappeConfig.clientEmployeeJoiningDateField: _joiningDateController.text
            .trim(),
        FrappeConfig.clientEmployeeEmailField: _emailController.text.trim(),
        FrappeConfig.clientEmployeePhoneField: _phoneController.text.trim(),
      };

      if (_editingEmployeeId == null || _editingEmployeeId!.isEmpty) {
        await _client.post(
          '/api/resource/${FrappeConfig.clientEmployeeDoctype}',
          body: {'data': payload},
        );
      } else {
        await _client.put(
          '/api/resource/${FrappeConfig.clientEmployeeDoctype}/$_editingEmployeeId',
          body: {'data': payload},
        );
      }

      await _loadEmployees();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee saved successfully.')),
      );
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserFriendlyError.message(
              e,
              fallback: 'Unable to save employee right now. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _editingEmployeeId = null;
    _employeeNameController.clear();
    _hourlyRateController.clear();
    _positionController.clear();
    _joiningDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now());
    _emailController.clear();
    _phoneController.clear();
    _selectedStatus = 'Active';
    setState(() => _isDirty = false);
  }

  void _startAddEmployee() {
    _resetForm();
    _tabController.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Employees'),
            Tab(text: 'Payroll'),
            Tab(text: 'Add Employee'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeeTab(),
                _buildPayrollTab(),
                _buildEmployeeForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: _startAddEmployee,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Employee'),
          ),
        ),
        const SizedBox(height: 12),
        _buildEmployeeTable(),
      ],
    );
  }

  Widget _buildPayrollTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildPayrollEmployeeSelector(),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: _selectedEmployeeIdForPayroll == null
                ? null
                : () => _openPayrollModal(_selectedEmployeeIdForPayroll!),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Payroll Entry'),
          ),
        ),
        const SizedBox(height: 16),
        _buildPayrollList(),
      ],
    );
  }

  Widget _buildEmployeeTable() {
    if (_loadingEmployees) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_employeeError != null) {
      return Center(child: Text(_employeeError!));
    }

    if (_employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No employees found.')),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Hourly Rate')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Edit')),
        ],
        rows: _employees.map((employee) {
          final id = employee['name']?.toString() ?? '';
          return DataRow(
            cells: [
              DataCell(
                Text(
                  employee[FrappeConfig.clientEmployeeNameField]?.toString() ??
                      '-',
                ),
              ),
              DataCell(
                Text(
                  employee[FrappeConfig.clientEmployeeHourlyRateField]
                          ?.toString() ??
                      '-',
                ),
              ),
              DataCell(
                Text(
                  employee[FrappeConfig.clientEmployeeStatusField]
                          ?.toString() ??
                      '-',
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Employee',
                  onPressed: id.isEmpty ? null : () => _loadEmployeeDetails(id),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmployeeForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingClientId)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
          if (_loadingEmployeeDetails)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          _buildFormHeader(),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            onChanged: _markDirty,
            child: Column(
              children: [
                _buildTextField(
                  controller: _employeeNameController,
                  label: 'Employee Name *',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Employee Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _hourlyRateController,
                  label: 'Hourly Rate *',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Hourly Rate is required';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Hourly Rate must be numeric';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _markDirty();
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _positionController,
                  label: 'Position',
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  controller: _joiningDateController,
                  label: 'Joining Date',
                  onTap: _selectJoiningDate,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildFormActions(),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _editingEmployeeId == null ? 'New Employee' : 'Edit Employee',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (_isDirty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Not Saved',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _resetForm,
          icon: const Icon(Icons.refresh),
          label: const Text('New'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveEmployee,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool dense = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: dense,
      ),
    );
  }

  Widget _buildPayrollEmployeeSelector() {
    if (_loadingEmployees) {
      return const LinearProgressIndicator();
    }

    if (_employeeError != null) {
      return Text(_employeeError!, style: const TextStyle(color: Colors.red));
    }

    if (_employees.isEmpty) {
      return const Text('No employees available for payroll.');
    }

    return DropdownButtonFormField<String>(
      value: _selectedEmployeeIdForPayroll,
      decoration: const InputDecoration(
        labelText: 'Employee',
        border: OutlineInputBorder(),
      ),
      items: _employees
          .map(
            (employee) => DropdownMenuItem(
              value: employee['name']?.toString() ?? '',
              child: Text(
                employee[FrappeConfig.clientEmployeeNameField]?.toString() ??
                    '-',
              ),
            ),
          )
          .where((item) => item.value != null && item.value!.isNotEmpty)
          .toList(),
      onChanged: (value) {
        if (value == null || value.isEmpty) return;
        _loadPayrollEntries(value);
      },
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
        isDense: dense,
      ),
      onTap: onTap,
    );
  }

  String _payrollPeriodLabel(Map<String, dynamic> period) {
    final labelField = FrappeConfig.payrollPeriodLabelField;
    return period[labelField]?.toString() ??
        period['name']?.toString() ??
        'Payroll Period';
  }

  Future<void> _selectPostingDateController(
    TextEditingController controller,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Widget _buildPayrollList() {
    if (_loadingEmployeeDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_detailError != null) {
      return Text(_detailError!, style: const TextStyle(color: Colors.red));
    }

    if (_selectedEmployeeIdForPayroll == null) {
      return const Text('Select an employee to view payroll entries.');
    }

    if (_payrollEntries.isEmpty) {
      return const Text('No payroll entries for the selected employee.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payroll: ${_selectedEmployeeNameForPayroll ?? ''}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Period')),
              DataColumn(label: Text('Posting Date')),
              DataColumn(label: Text('Rate')),
              DataColumn(label: Text('Worked Hours')),
              DataColumn(label: Text('Total Amount')),
            ],
            rows: _payrollEntries.map((entry) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      entry[FrappeConfig.payrollPeriodField]?.toString() ?? '-',
                    ),
                  ),
                  DataCell(
                    Text(
                      entry[FrappeConfig.payrollPostingDateField]?.toString() ??
                          '-',
                    ),
                  ),
                  DataCell(
                    Text(
                      entry[FrappeConfig.payrollHourlyRateField]?.toString() ??
                          '-',
                    ),
                  ),
                  DataCell(
                    Text(
                      entry[FrappeConfig.payrollWorkedHoursField]?.toString() ??
                          '-',
                    ),
                  ),
                  DataCell(
                    Text(
                      entry[FrappeConfig.payrollTotalAmountField]?.toString() ??
                          '-',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
