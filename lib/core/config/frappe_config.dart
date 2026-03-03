class FrappeConfig {
  const FrappeConfig._();

  static const String baseUrl = String.fromEnvironment(
    'FRAPPE_BASE_URL',
    defaultValue: 'http://10.174.8.118:8000',
    // defaultValue: 'http://192.168.0.144:8000',
  );

  static const String apiKey = String.fromEnvironment(
    'FRAPPE_API_KEY',
    defaultValue: 'c3637bac574b748',
  );

  static const String apiSecret = String.fromEnvironment(
    'FRAPPE_API_SECRET',
    defaultValue: '183429d6ef3227b',
  );

  static bool get useTokenAuth => apiKey.isNotEmpty && apiSecret.isNotEmpty;

  // ERPNext doctypes and fields (adjust to match your instance)
  static const String userDoctype = 'User';
  static const String taxDocumentDoctype = 'Tax Document';
  static const String countryDoctype = 'Country';
  static const String businessTypeDoctype = 'Business Type';
  static const String taxCategoryDoctype = 'Tax Category';
  static const String transactionDoctype = 'Client Transactions';
  static const String transactionCategoryDoctype = 'Transaction Category';
  static const String clientDoctype = 'Client';

  // Custom API endpoints
  static const String registerClientUserMethod =
      'habesha_tax.api.register_client_user';
  static const String updatePasswordMethod = 'habesha_tax.api.forgot_password';

  // User field mapping
  static const String userIdField = 'name';
  static const String userEmailField = 'email';
  static const String userFirstNameField = 'first_name';
  static const String userLastNameField = 'last_name';
  static const String userFullNameField = 'full_name';
  static const String userUsernameField = 'username';
  static const String userLanguageField = 'language';
  static const String userTimeZoneField = 'time_zone';
  static const String userCountryField = 'country';
  static const String userCategoryField = 'user_category';
  static const String userMobileNoField = 'mobile_no';

  // Client registration fields
  static const String clientBusinessTypeField = 'business_type';
  static const String clientStatusField = 'status';
  static const String clientUserIdField = 'user_id';
  static const String clientFullNameField = 'full_name';
  static const String clientPhoneField = 'phone_number';
  static const String clientEmailField = 'email';
  static const String clientTypeField = 'client_type';
  static const String clientTinNumberField = 'tax_id';
  static const String clientTaxCategoryField = 'tax_category';
  static const String clientAddressLine1Field = 'address_line_1';
  static const String clientAddressLine2Field = 'address_line_2';
  static const String clientPostalCodeField = 'postal_code';
  static const String clientCityField = 'city';
  static const String clientStateField = 'state';
  static const String clientCompanyNameField = 'company_name';
  static const String clientCompanyRegistrationNumberField =
      'company_registration_number';
  static const String clientVatNumberField = 'vat_number';

  // Tax document field mapping
  static const String taxUserIdField = 'user_id';
  static const String taxDocumentTypeField = 'document_type';
  static const String taxFileUrlField = 'file_url';
  static const String taxAmountField = 'amount';
  static const String taxCategoryField = 'category';
  static const String taxUploadDateField = 'upload_date';
  static const String taxDescriptionField = 'description';

  // Transaction field mapping
  static const String transactionPostingDateField = 'posting_date';
  static const String transactionClientField = 'client';
  static const String transactionUserIdField = 'user_id';
  static const String transactionClientFullNameField = 'full_name';
  static const String transactionClientPhoneField = 'phone';
  static const String transactionClientEmailField = 'email';
  static const String transactionClientTypeField = 'client_type';
  static const String transactionClientBusinessTypeField = 'business_type';
  static const String transactionClientStatusField = 'status';
  static const String transactionAmountField = 'amount';
  static const String transactionCategoryField = 'category';
  static const String transactionTypeField = 'transaction_type';
  static const String transactionNoteField = 'note';
  static const String transactionMainFileField = 'main_file';
  static const String transactionAttachmentsField = 'multiple_attachment';
  static const String transactionAttachmentFileField = 'file';

  // Client invoice doctype and fields
  static const String clientInvoiceDoctype = 'Client Invoices';
  static const String clientInvoiceClientField = 'client';

  // Bill-to fields
  static const String clientInvoiceBillToCompanyField = 'to_company_name';
  static const String clientInvoiceBillToEmailField = 'to_email';
  static const String clientInvoiceBillToAddressField = 'to_address';
  static const String clientInvoiceBillToPhoneField = 'to_phone';

  // Invoice date child table
  static const String clientInvoiceDateTableField = 'invoice_date';
  static const String clientInvoiceDateEntryNameField = 'field_name';
  static const String clientInvoiceDateEntryValueField = 'value';

  // Services details child table
  static const String clientInvoiceServicesTableField = 'service_details';
  static const String clientInvoiceServiceItemField = 'item';
  static const String clientInvoiceServiceDescriptionField = 'description';
  static const String clientInvoiceServiceQuantityField = 'quantity';
  static const String clientInvoiceServiceRateField = 'rate';
  static const String clientInvoiceServiceTimeField = 'time';
  static const String clientInvoiceServiceTotalAmountField = 'total_amount';

  // Totals
  static const String clientInvoiceSubtotalField = 'subtotal';
  static const String clientInvoiceVatAmountField = 'vat_amount';
  static const String clientInvoiceTotalAmountField = 'total_amount';

  // Account details fields
  static const String clientInvoiceBankNameField = 'bank_name';
  static const String clientInvoiceBankAccountNameField = 'account_name';
  static const String clientInvoiceAccountNumberField = 'account_number';
  static const String clientInvoiceSortCodeField = 'sort_code';
  static const String clientInvoicePaymentMethodField = 'payment_method';
  static const String clientInvoicePaymentEmailField = 'payment_email';

  // Client employee management (adjust to match your ERPNext setup)
  static const String clientEmployeeDoctype = 'Client Employee';
  static const String clientEmployeeClientField = 'client';
  static const String clientEmployeeHourlyRateField = 'hourly_rate';
  static const String clientEmployeeNameField = 'employee_name';
  static const String clientEmployeeStatusField = 'status';
  static const String clientEmployeePositionField = 'position';
  static const String clientEmployeeJoiningDateField = 'joining_date';
  static const String clientEmployeeEmailField = 'email';
  static const String clientEmployeePhoneField = 'phone';
  static const String clientEmployeePayrollTableField = 'payroll_details';

  static const String payrollPeriodField = 'payroll_period';
  static const String payrollPostingDateField = 'posting_date';
  static const String payrollHourlyRateField = 'salary_rate';
  static const String payrollWorkedHoursField = 'worked_hours';
  static const String payrollTotalAmountField = 'total_amount';

  // Payroll period doctype (adjust to match your ERPNext setup)
  static const String payrollPeriodDoctype = 'Client Payroll Period';
  static const String payrollPeriodLabelField = 'name';

  // Contact message doctype and fields
  static const String contactMessageDoctype = 'Contact Message';
  static const String contactMessageNameField = 'name';
  static const String contactMessageEmailField = 'email';
  static const String contactMessageSubjectField = 'subject';
  static const String contactMessageBodyField = 'message';
  static const String contactMessageTimestampField = 'timestamp';

  // Chat configuration
  static const String chatMessageDoctype = 'Chat Message';
  static const String chatMessageSenderField = 'sender';
  static const String chatMessageReceiverField = 'receiver';
  static const String chatMessageBodyField = 'message';
  static const String chatMessageTimestampField = 'timestamp';

  // Notifications configuration
  static const String notificationDoctype = 'Notification Log';
  static const String notificationTitleField = 'subject';
  static const String notificationBodyField = 'email_content';
  static const String notificationTimestampField = 'creation';
  static const String notificationRecipientField = 'for_user';
  static const String notificationTypeField = 'type';
  static const String notificationTargetTypeField = 'target_type';
  static const String notificationCategoriesField = 'categories';
  static const String notificationUserIdsField = 'user_ids';
  static const String notificationDataField = 'data';
}
