import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_te.dart';

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
    Locale('hi'),
    Locale('sat'),
    Locale('mr'),
    Locale('te'),
  ];

  /// No description provided for @santhali.
  ///
  /// In en, this message translates to:
  /// **'Santhali'**
  String get santhali;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Smart Civic Portal'**
  String get app_title;

  /// No description provided for @login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Report civic issues and connect with your local government'**
  String get login_subtitle;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @enter_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enter_phone_number;

  /// No description provided for @send_otp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get send_otp;

  /// No description provided for @login_as_worker.
  ///
  /// In en, this message translates to:
  /// **'Login as Worker'**
  String get login_as_worker;

  /// No description provided for @government_initiative.
  ///
  /// In en, this message translates to:
  /// **'Government of Jharkhand Initiative'**
  String get government_initiative;

  /// No description provided for @secure_and_verified.
  ///
  /// In en, this message translates to:
  /// **'Secure & Verified'**
  String get secure_and_verified;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @enter_valid_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number'**
  String get enter_valid_phone;

  /// No description provided for @enter_phone_number_message.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enter_phone_number_message;

  /// No description provided for @verification_failed.
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verification_failed;

  /// No description provided for @error_message.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error_message;

  /// No description provided for @verify_otp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verify_otp;

  /// No description provided for @enter_otp_code.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent'**
  String get enter_otp_code;

  /// No description provided for @verify_and_login.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verify_and_login;

  /// No description provided for @didnt_receive_otp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive OTP?'**
  String get didnt_receive_otp;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @otp_resent_web.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully (Web)'**
  String get otp_resent_web;

  /// No description provided for @otp_resent_mobile.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully (Mobile)'**
  String get otp_resent_mobile;

  /// No description provided for @complete_profile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get complete_profile;

  /// No description provided for @profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please provide your details to continue'**
  String get profile_subtitle;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name;

  /// No description provided for @name_validation_message.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name (no numbers)'**
  String get name_validation_message;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @email_optional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get email_optional;

  /// No description provided for @email_validation_message.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get email_validation_message;

  /// No description provided for @profile_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get profile_save_failed;

  /// No description provided for @continue_text.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_text;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @complaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get good_morning;

  /// No description provided for @good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get good_afternoon;

  /// No description provided for @good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get good_evening;

  /// No description provided for @quickReport.
  ///
  /// In en, this message translates to:
  /// **'Quick Report'**
  String get quickReport;

  /// No description provided for @garbage.
  ///
  /// In en, this message translates to:
  /// **'Garbage'**
  String get garbage;

  /// No description provided for @streetLight.
  ///
  /// In en, this message translates to:
  /// **'Street Light'**
  String get streetLight;

  /// No description provided for @roadDamage.
  ///
  /// In en, this message translates to:
  /// **'Road Damage'**
  String get roadDamage;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water Supply'**
  String get water;

  /// No description provided for @currentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current Badge'**
  String get currentBadge;

  /// No description provided for @civicHero.
  ///
  /// In en, this message translates to:
  /// **'Civic Hero'**
  String get civicHero;

  /// No description provided for @badgeProgress.
  ///
  /// In en, this message translates to:
  /// **'70% to next badge'**
  String get badgeProgress;

  /// No description provided for @reportsSummary.
  ///
  /// In en, this message translates to:
  /// **'Reports Summary'**
  String get reportsSummary;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @recentReports.
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get recentReports;

  /// No description provided for @brokenStreetLight.
  ///
  /// In en, this message translates to:
  /// **'Broken Street Light'**
  String get brokenStreetLight;

  /// No description provided for @garbageCollection.
  ///
  /// In en, this message translates to:
  /// **'Garbage Collection'**
  String get garbageCollection;

  /// No description provided for @potholeRepair.
  ///
  /// In en, this message translates to:
  /// **'Pothole Repair'**
  String get potholeRepair;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportIssue;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @selectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get selectCategoryHint;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get categoryRequired;

  /// No description provided for @subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get subcategory;

  /// No description provided for @subcategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a subcategory'**
  String get subcategoryHint;

  /// No description provided for @subcategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Subcategory is required'**
  String get subcategoryRequired;

  /// No description provided for @pleaseSpecify.
  ///
  /// In en, this message translates to:
  /// **'Please specify'**
  String get pleaseSpecify;

  /// No description provided for @pleaseSpecifyIssue.
  ///
  /// In en, this message translates to:
  /// **'Please specify the issue'**
  String get pleaseSpecifyIssue;

  /// No description provided for @capturePhotos.
  ///
  /// In en, this message translates to:
  /// **'Capture Photos'**
  String get capturePhotos;

  /// No description provided for @photoNote.
  ///
  /// In en, this message translates to:
  /// **'At least 1 photo required. Up to 3 photos allowed.'**
  String get photoNote;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @autoDetectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected Location'**
  String get autoDetectedLocation;

  /// No description provided for @fetchingAddress.
  ///
  /// In en, this message translates to:
  /// **'Fetching address...'**
  String get fetchingAddress;

  /// No description provided for @addressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Address not found'**
  String get addressNotFound;

  /// No description provided for @fetchingGps.
  ///
  /// In en, this message translates to:
  /// **'Fetching GPS...'**
  String get fetchingGps;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @enterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter details...'**
  String get enterDetails;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing...'**
  String get playing;

  /// No description provided for @recordVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Record voice note (optional)'**
  String get recordVoiceNote;

  /// No description provided for @voiceNoteRecorded.
  ///
  /// In en, this message translates to:
  /// **'Voice note recorded'**
  String get voiceNoteRecorded;

  /// No description provided for @deleteVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Delete voice note'**
  String get deleteVoiceNote;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Complaints'**
  String get myReports;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @footerNote.
  ///
  /// In en, this message translates to:
  /// **'Government of Jharkhand Initiative – Secure & Verified'**
  String get footerNote;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @workerLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker Login'**
  String get workerLoginTitle;

  /// No description provided for @workerLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access the Worker Dashboard'**
  String get workerLoginSubtitle;

  /// No description provided for @userIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userIdLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @backToCitizenLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Citizen Login'**
  String get backToCitizenLoginButton;

  /// No description provided for @enterCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Enter both User ID and Password'**
  String get enterCredentialsError;

  /// No description provided for @invalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Invalid User ID or Password'**
  String get invalidCredentialsError;

  /// No description provided for @workerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Worker Dashboard'**
  String get workerDashboard;

  /// No description provided for @municipalServices.
  ///
  /// In en, this message translates to:
  /// **'Municipal Services'**
  String get municipalServices;

  /// No description provided for @recentComplaints.
  ///
  /// In en, this message translates to:
  /// **'Recent Complaints'**
  String get recentComplaints;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @filterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filterInProgress;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @roadMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Road Maintenance'**
  String get roadMaintenance;

  /// No description provided for @wasteManagement.
  ///
  /// In en, this message translates to:
  /// **'Waste Management'**
  String get wasteManagement;

  /// No description provided for @streetLighting.
  ///
  /// In en, this message translates to:
  /// **'Street Lighting'**
  String get streetLighting;

  /// No description provided for @bulbReplacement.
  ///
  /// In en, this message translates to:
  /// **'Bulb Replacement'**
  String get bulbReplacement;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'Track Complaint'**
  String get viewDetails;

  /// No description provided for @workerId.
  ///
  /// In en, this message translates to:
  /// **'Worker ID'**
  String get workerId;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @assignedArea.
  ///
  /// In en, this message translates to:
  /// **'Assigned Area'**
  String get assignedArea;

  /// No description provided for @recognitionProgress.
  ///
  /// In en, this message translates to:
  /// **'Recognition & Progress'**
  String get recognitionProgress;

  /// No description provided for @tasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'Tasks Completed'**
  String get tasksCompleted;

  /// No description provided for @earnedBadges.
  ///
  /// In en, this message translates to:
  /// **'Earned Badges'**
  String get earnedBadges;

  /// No description provided for @quickResponse.
  ///
  /// In en, this message translates to:
  /// **'Quick Response'**
  String get quickResponse;

  /// No description provided for @qualityWork.
  ///
  /// In en, this message translates to:
  /// **'Quality Work'**
  String get qualityWork;

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'On Time'**
  String get onTime;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdateSuccess;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @pauseVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Pause Voice Note'**
  String get pauseVoiceNote;

  /// No description provided for @playVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Play Voice Note'**
  String get playVoiceNote;

  /// No description provided for @complaintNotFound.
  ///
  /// In en, this message translates to:
  /// **'Complaint not found.'**
  String get complaintNotFound;

  /// No description provided for @refId.
  ///
  /// In en, this message translates to:
  /// **'REF: {id}'**
  String refId(String id);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @raiseGrievance.
  ///
  /// In en, this message translates to:
  /// **'Raise a Grievance'**
  String get raiseGrievance;

  /// No description provided for @statusTimeline.
  ///
  /// In en, this message translates to:
  /// **'Status Timeline'**
  String get statusTimeline;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Complaint Submitted'**
  String get submitted;

  /// No description provided for @reportSubmittedByCitizen.
  ///
  /// In en, this message translates to:
  /// **'Your complaint has been submitted successfully!'**
  String get reportSubmittedByCitizen;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @timestampNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Timestamp not available'**
  String get timestampNotAvailable;

  /// No description provided for @assignedToMunicipalworker.
  ///
  /// In en, this message translates to:
  /// **'Your complaint will be reviewed by our team within 24 hours and assigned to the relevant department for resolution.'**
  String get assignedToMunicipalworker;

  /// No description provided for @updateTimestampPending.
  ///
  /// In en, this message translates to:
  /// **'Update timestamp pending'**
  String get updateTimestampPending;

  /// No description provided for @workHasStarted.
  ///
  /// In en, this message translates to:
  /// **'Work has started on your complaint.'**
  String get workHasStarted;

  /// No description provided for @issueResolved.
  ///
  /// In en, this message translates to:
  /// **'The issue has been resolved.'**
  String get issueResolved;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please enable it from app settings.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @unableToFetchLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch location'**
  String get unableToFetchLocation;

  /// No description provided for @gpsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'GPS coordinates: {gps}'**
  String gpsCoordinates(String gps);

  /// No description provided for @submitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit: {error}'**
  String submitFailed(String error);

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview;

  /// No description provided for @currentStage.
  ///
  /// In en, this message translates to:
  /// **'Current Stage'**
  String get currentStage;

  /// No description provided for @waitingForAssignment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for worker assignment'**
  String get waitingForAssignment;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not Yet'**
  String get notYet;

  /// No description provided for @assignedToMunicipalWorker.
  ///
  /// In en, this message translates to:
  /// **'Your complaint has been assigned to a municipal worker'**
  String get assignedToMunicipalWorker;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report Details'**
  String get reportDetails;

  /// No description provided for @photosSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Photos Submitted'**
  String get photosSubmitted;

  /// No description provided for @issueDescription.
  ///
  /// In en, this message translates to:
  /// **'Issue Description'**
  String get issueDescription;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorMessage;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @reportIssuee.
  ///
  /// In en, this message translates to:
  /// **'Report Another Issue'**
  String get reportIssuee;

  /// No description provided for @complaintDetails.
  ///
  /// In en, this message translates to:
  /// **'Complaint Details'**
  String get complaintDetails;

  /// No description provided for @complaintId.
  ///
  /// In en, this message translates to:
  /// **'Complaint ID'**
  String get complaintId;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @citizenSubmission.
  ///
  /// In en, this message translates to:
  /// **'Citizen Submission'**
  String get citizenSubmission;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @noPhotosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No photos available.'**
  String get noPhotosAvailable;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @completionProof.
  ///
  /// In en, this message translates to:
  /// **'Completion Proof'**
  String get completionProof;

  /// No description provided for @noCompletionPhotos.
  ///
  /// In en, this message translates to:
  /// **'No completion photos available.'**
  String get noCompletionPhotos;

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No description provided for @uploadCompletionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload Completion Photos'**
  String get uploadCompletionPhotos;

  /// No description provided for @markAsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Mark as In Progress'**
  String get markAsInProgress;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated to \"{status}\"'**
  String statusUpdated(String status);

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status: {error}'**
  String failedToUpdateStatus(String error);

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Maps'**
  String get couldNotOpenMaps;

  /// No description provided for @completionProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Completion Proof'**
  String get completionProofTitle;

  /// No description provided for @completionProofInfo.
  ///
  /// In en, this message translates to:
  /// **'Upload at least 1 photo (max 3) as proof of work completion.'**
  String get completionProofInfo;

  /// No description provided for @photoRequirementNote.
  ///
  /// In en, this message translates to:
  /// **'At least 1 photo required. Up to 3 photos allowed.'**
  String get photoRequirementNote;

  /// No description provided for @addNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes/remarks (optional)'**
  String get addNotesHint;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @failedToSubmitProof.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit proof: {error}'**
  String failedToSubmitProof(String error);

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get storagePermissionDenied;

  /// No description provided for @workCompletionReport.
  ///
  /// In en, this message translates to:
  /// **'Work Completion Report'**
  String get workCompletionReport;

  /// No description provided for @pdfComplaintId.
  ///
  /// In en, this message translates to:
  /// **'Complaint ID: {id}'**
  String pdfComplaintId(String id);

  /// No description provided for @pdfSupervisorId.
  ///
  /// In en, this message translates to:
  /// **'Supervisor ID: {id}'**
  String pdfSupervisorId(String id);

  /// No description provided for @pdfCitizenId.
  ///
  /// In en, this message translates to:
  /// **'Citizen ID: {id}'**
  String pdfCitizenId(String id);

  /// No description provided for @pdfStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: Completed'**
  String get pdfStatus;

  /// No description provided for @pdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String pdfDate(String date);

  /// No description provided for @downloadsDirNotFound.
  ///
  /// In en, this message translates to:
  /// **'Downloads directory not found'**
  String get downloadsDirNotFound;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded successfully'**
  String get downloaded;

  /// No description provided for @failedToDownloadReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to download report: {error}'**
  String failedToDownloadReport(String error);

  /// No description provided for @workMarkedAsResolved.
  ///
  /// In en, this message translates to:
  /// **'Work Marked as Resolved!'**
  String get workMarkedAsResolved;

  /// No description provided for @completionProofSent.
  ///
  /// In en, this message translates to:
  /// **'Your completion proof has been sent to the complaint owner and supervisor.'**
  String get completionProofSent;

  /// No description provided for @shareStatus.
  ///
  /// In en, this message translates to:
  /// **'Share Status'**
  String get shareStatus;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get downloadReport;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @workerNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get workerNotificationsTitle;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotificationsYet;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I submit a complaint?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'Go to the home page and tap the \'+\' button or \'Report Issue\' to submit a new complaint.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'How can I track my complaint status?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'Open \'My Reports\' to see the status and details of all your complaints.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile information?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'Tap the edit icon on your profile page to update your name or email.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'What do the different complaint statuses mean?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'Pending: Waiting for review.\nAssigned: Assigned to a worker.\nIn Progress: Work has started.\nResolved: Issue has been fixed.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I raise a grievance if my complaint is not resolved?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In en, this message translates to:
  /// **'Open the complaint details and tap \'Raise Grievance\' at the bottom.'**
  String get faqA5;
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
      <String>['en', 'hi', 'mr', 'sat', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'sat':
      return AppLocalizationsSat();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
