import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'SANTA MARIA'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Funeral Organizer'**
  String get welcomeSubtitle;

  /// No description provided for @aiConsultBtn.
  ///
  /// In en, this message translates to:
  /// **'Start AI Consultation'**
  String get aiConsultBtn;

  /// No description provided for @personnelLoginBtn.
  ///
  /// In en, this message translates to:
  /// **'Login as Personnel'**
  String get personnelLoginBtn;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @orderActive.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get orderActive;

  /// No description provided for @orderPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderPending;

  /// No description provided for @orderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderCompleted;

  /// No description provided for @workshopPeti.
  ///
  /// In en, this message translates to:
  /// **'Coffin Workshop'**
  String get workshopPeti;

  /// No description provided for @coffinOrderNew.
  ///
  /// In en, this message translates to:
  /// **'New Coffin Order'**
  String get coffinOrderNew;

  /// No description provided for @coffinStage.
  ///
  /// In en, this message translates to:
  /// **'Production Stage'**
  String get coffinStage;

  /// No description provided for @coffinQc.
  ///
  /// In en, this message translates to:
  /// **'Quality Control'**
  String get coffinQc;

  /// No description provided for @qcPassed.
  ///
  /// In en, this message translates to:
  /// **'QC Passed'**
  String get qcPassed;

  /// No description provided for @qcFailed.
  ///
  /// In en, this message translates to:
  /// **'QC Failed'**
  String get qcFailed;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @equipmentChecklist.
  ///
  /// In en, this message translates to:
  /// **'Equipment Checklist'**
  String get equipmentChecklist;

  /// No description provided for @equipmentLoan.
  ///
  /// In en, this message translates to:
  /// **'Equipment Loan'**
  String get equipmentLoan;

  /// No description provided for @equipmentMissing.
  ///
  /// In en, this message translates to:
  /// **'Unreturned Equipment'**
  String get equipmentMissing;

  /// No description provided for @sendEquipment.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendEquipment;

  /// No description provided for @returnEquipment.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnEquipment;

  /// No description provided for @stockAlert.
  ///
  /// In en, this message translates to:
  /// **'Stock Alert'**
  String get stockAlert;

  /// No description provided for @stockLow.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get stockLow;

  /// No description provided for @stockOut.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get stockOut;

  /// No description provided for @stockForm.
  ///
  /// In en, this message translates to:
  /// **'Take/Return Items'**
  String get stockForm;

  /// No description provided for @stockTake.
  ///
  /// In en, this message translates to:
  /// **'Take Out'**
  String get stockTake;

  /// No description provided for @stockReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get stockReturn;

  /// No description provided for @consumableDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Consumables'**
  String get consumableDaily;

  /// No description provided for @shiftPagi.
  ///
  /// In en, this message translates to:
  /// **'Morning (P)'**
  String get shiftPagi;

  /// No description provided for @shiftKirim.
  ///
  /// In en, this message translates to:
  /// **'Delivery (K)'**
  String get shiftKirim;

  /// No description provided for @shiftMalam.
  ///
  /// In en, this message translates to:
  /// **'Night (M)'**
  String get shiftMalam;

  /// No description provided for @billingReport.
  ///
  /// In en, this message translates to:
  /// **'Billing Report'**
  String get billingReport;

  /// No description provided for @billingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get billingTotal;

  /// No description provided for @billingTambahan.
  ///
  /// In en, this message translates to:
  /// **'Additional'**
  String get billingTambahan;

  /// No description provided for @billingKembali.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get billingKembali;

  /// No description provided for @billingGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get billingGrandTotal;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @deathCertChecklist.
  ///
  /// In en, this message translates to:
  /// **'Death Certificate Docs'**
  String get deathCertChecklist;

  /// No description provided for @deathCertReceived.
  ///
  /// In en, this message translates to:
  /// **'Received by SM'**
  String get deathCertReceived;

  /// No description provided for @deathCertReturnedFamily.
  ///
  /// In en, this message translates to:
  /// **'Returned to Family'**
  String get deathCertReturnedFamily;

  /// No description provided for @extraApproval.
  ///
  /// In en, this message translates to:
  /// **'Additional Approval'**
  String get extraApproval;

  /// No description provided for @extraApprovalSign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get extraApprovalSign;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-Out'**
  String get checkOut;

  /// No description provided for @attendancePresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresent;

  /// No description provided for @attendanceLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLate;

  /// No description provided for @attendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// No description provided for @vehicleTripLog.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Trip Log'**
  String get vehicleTripLog;

  /// No description provided for @dekorDailyPackage.
  ///
  /// In en, this message translates to:
  /// **'La Fiore Daily Package'**
  String get dekorDailyPackage;

  /// No description provided for @kpi.
  ///
  /// In en, this message translates to:
  /// **'KPI'**
  String get kpi;

  /// No description provided for @kpiMyScore.
  ///
  /// In en, this message translates to:
  /// **'My KPI'**
  String get kpiMyScore;

  /// No description provided for @kpiMetrics.
  ///
  /// In en, this message translates to:
  /// **'KPI Metrics'**
  String get kpiMetrics;

  /// No description provided for @kpiRanking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get kpiRanking;

  /// No description provided for @kpiPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get kpiPeriod;

  /// No description provided for @gradeA.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get gradeA;

  /// No description provided for @gradeB.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get gradeB;

  /// No description provided for @gradeC.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get gradeC;

  /// No description provided for @gradeD.
  ///
  /// In en, this message translates to:
  /// **'Below Average'**
  String get gradeD;

  /// No description provided for @gradeE.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get gradeE;

  /// No description provided for @violation.
  ///
  /// In en, this message translates to:
  /// **'Violation'**
  String get violation;

  /// No description provided for @violationAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get violationAcknowledge;

  /// No description provided for @violationResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get violationResolve;

  /// No description provided for @violationEscalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get violationEscalate;

  /// No description provided for @threshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold Settings'**
  String get threshold;

  /// No description provided for @paymentVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment'**
  String get paymentVerify;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentTransfer;

  /// No description provided for @paymentUploadProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Transfer Proof'**
  String get paymentUploadProof;

  /// No description provided for @paymentReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get paymentReject;

  /// No description provided for @paymentApprove.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get paymentApprove;

  /// No description provided for @whatsappContact.
  ///
  /// In en, this message translates to:
  /// **'Contact via WhatsApp'**
  String get whatsappContact;

  /// No description provided for @alarmTitle.
  ///
  /// In en, this message translates to:
  /// **'ATTENTION!'**
  String get alarmTitle;

  /// No description provided for @alarmDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get alarmDismiss;

  /// No description provided for @alarmView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get alarmView;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noData;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
