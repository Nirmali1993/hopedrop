import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

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
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HopeDrop'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @bloodNeeded.
  ///
  /// In en, this message translates to:
  /// **'Blood Needed!'**
  String get bloodNeeded;

  /// No description provided for @findDonors.
  ///
  /// In en, this message translates to:
  /// **'Find Donors'**
  String get findDonors;

  /// No description provided for @postRequest.
  ///
  /// In en, this message translates to:
  /// **'Post Request'**
  String get postRequest;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @donationHistory.
  ///
  /// In en, this message translates to:
  /// **'Donation History'**
  String get donationHistory;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @hospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get hospital;

  /// No description provided for @donor.
  ///
  /// In en, this message translates to:
  /// **'Donor'**
  String get donor;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @recordDonation.
  ///
  /// In en, this message translates to:
  /// **'Record Donation'**
  String get recordDonation;

  /// No description provided for @markFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Mark as Fulfilled'**
  String get markFulfilled;

  /// No description provided for @rateDonor.
  ///
  /// In en, this message translates to:
  /// **'Rate this Donor'**
  String get rateDonor;

  /// No description provided for @callDonor.
  ///
  /// In en, this message translates to:
  /// **'Call Donor'**
  String get callDonor;

  /// No description provided for @unitsRequired.
  ///
  /// In en, this message translates to:
  /// **'Units Required'**
  String get unitsRequired;

  /// No description provided for @patientName.
  ///
  /// In en, this message translates to:
  /// **'Patient Name'**
  String get patientName;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequestsYet;

  /// No description provided for @waitingForDonors.
  ///
  /// In en, this message translates to:
  /// **'Waiting for donors...'**
  String get waitingForDonors;

  /// No description provided for @donorsResponded.
  ///
  /// In en, this message translates to:
  /// **'donors responded'**
  String get donorsResponded;

  /// No description provided for @eligibleToDonate.
  ///
  /// In en, this message translates to:
  /// **'Available to Donate'**
  String get eligibleToDonate;

  /// No description provided for @notEligibleYet.
  ///
  /// In en, this message translates to:
  /// **'Not Eligible Yet'**
  String get notEligibleYet;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'days remaining'**
  String get daysRemaining;

  /// No description provided for @totalDonations.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get totalDonations;

  /// No description provided for @livesImpacted.
  ///
  /// In en, this message translates to:
  /// **'Lives Impacted'**
  String get livesImpacted;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @aboutHopeDrop.
  ///
  /// In en, this message translates to:
  /// **'About HopeDrop'**
  String get aboutHopeDrop;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetHere.
  ///
  /// In en, this message translates to:
  /// **'Reset here'**
  String get resetHere;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get name;

  /// No description provided for @bloodRequestAlerts.
  ///
  /// In en, this message translates to:
  /// **'Blood Request Alerts'**
  String get bloodRequestAlerts;

  /// No description provided for @nearbyRequests.
  ///
  /// In en, this message translates to:
  /// **'Nearby Requests'**
  String get nearbyRequests;

  /// No description provided for @myBloodTypeOnly.
  ///
  /// In en, this message translates to:
  /// **'My Blood Type Only'**
  String get myBloodTypeOnly;

  /// No description provided for @donorResponses.
  ///
  /// In en, this message translates to:
  /// **'Donor Responses'**
  String get donorResponses;

  /// No description provided for @appSounds.
  ///
  /// In en, this message translates to:
  /// **'App Sounds'**
  String get appSounds;

  /// No description provided for @manageAlerts.
  ///
  /// In en, this message translates to:
  /// **'Manage alerts'**
  String get manageAlerts;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get excellent;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get veryGood;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @urgentRequests.
  ///
  /// In en, this message translates to:
  /// **'Urgent Requests'**
  String get urgentRequests;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @readyToSaveLife.
  ///
  /// In en, this message translates to:
  /// **'Ready to save a life?'**
  String get readyToSaveLife;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @donors.
  ///
  /// In en, this message translates to:
  /// **'Donors'**
  String get donors;

  /// No description provided for @iAmDonor.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Donor '**
  String get iAmDonor;

  /// No description provided for @iAmRecipient.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Recipient'**
  String get iAmRecipient;

  /// No description provided for @unitsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Unit Needed'**
  String get unitsNeeded;

  /// No description provided for @unitNeeded.
  ///
  /// In en, this message translates to:
  /// **'Unit Needed'**
  String get unitNeeded;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @bloodDonor.
  ///
  /// In en, this message translates to:
  /// **'Blood Donor'**
  String get bloodDonor;

  /// No description provided for @bloodRecipient.
  ///
  /// In en, this message translates to:
  /// **'Blood Recipient'**
  String get bloodRecipient;

  /// No description provided for @availableToDonate.
  ///
  /// In en, this message translates to:
  /// **'Available to Donate'**
  String get availableToDonate;

  /// No description provided for @recordADonation.
  ///
  /// In en, this message translates to:
  /// **'Record a Donation'**
  String get recordADonation;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get gettingLocation;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @urgencyLevel.
  ///
  /// In en, this message translates to:
  /// **'Urgency Level'**
  String get urgencyLevel;

  /// No description provided for @postBloodRequest.
  ///
  /// In en, this message translates to:
  /// **'Post Blood Request'**
  String get postBloodRequest;

  /// No description provided for @requestPosted.
  ///
  /// In en, this message translates to:
  /// **'Request Posted!'**
  String get requestPosted;

  /// No description provided for @requestPostedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your blood request has been posted. Nearby donors have been notified!'**
  String get requestPostedMsg;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @bloodRequests.
  ///
  /// In en, this message translates to:
  /// **'Blood Requests'**
  String get bloodRequests;

  /// No description provided for @allRequests.
  ///
  /// In en, this message translates to:
  /// **'All Requests'**
  String get allRequests;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @fulfilled.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled'**
  String get fulfilled;

  /// No description provided for @noDonorsYet.
  ///
  /// In en, this message translates to:
  /// **'No donors yet'**
  String get noDonorsYet;

  /// No description provided for @donorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Donor not found'**
  String get donorNotFound;

  /// No description provided for @searchDonors.
  ///
  /// In en, this message translates to:
  /// **'Search donors'**
  String get searchDonors;

  /// No description provided for @filterByBloodType.
  ///
  /// In en, this message translates to:
  /// **'Filter by blood type'**
  String get filterByBloodType;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @selectBloodType.
  ///
  /// In en, this message translates to:
  /// **'Select blood type'**
  String get selectBloodType;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @updateProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Photo'**
  String get updateProfilePhoto;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get useCamera;

  /// No description provided for @pickFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Pick from your photos'**
  String get pickFromPhotos;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @donationRecorded.
  ///
  /// In en, this message translates to:
  /// **'Donation recorded! Eligible again in 90 days.'**
  String get donationRecorded;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully!'**
  String get locationUpdated;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get location. Please allow location permission.'**
  String get locationError;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get profilePhotoUpdated;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved!'**
  String get settingsSaved;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get enterPhoneNumber;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPassword;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @forgotYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotYourPassword;

  /// No description provided for @dontHaveAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccountQ;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Role'**
  String get chooseRole;

  /// No description provided for @donorRole.
  ///
  /// In en, this message translates to:
  /// **'I want to Donate Blood'**
  String get donorRole;

  /// No description provided for @recipientRole.
  ///
  /// In en, this message translates to:
  /// **'I need Blood'**
  String get recipientRole;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @enterOTP.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOTP;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get units;

  /// No description provided for @noResponsesYet.
  ///
  /// In en, this message translates to:
  /// **'No responses yet. Waiting for donors...'**
  String get noResponsesYet;

  /// No description provided for @respond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get respond;

  /// No description provided for @responded.
  ///
  /// In en, this message translates to:
  /// **'Responded'**
  String get responded;

  /// No description provided for @callText.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callText;

  /// No description provided for @rateExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your experience with this donor?'**
  String get rateExperience;

  /// No description provided for @tapToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get tapToRate;

  /// No description provided for @leaveComment.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment (optional)'**
  String get leaveComment;

  /// No description provided for @thankYouRating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for rating!'**
  String get thankYouRating;

  /// No description provided for @confirmDonation.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmDonation;

  /// No description provided for @recordDonationMsg.
  ///
  /// In en, this message translates to:
  /// **'Recording a donation will mark you unavailable for 90 days.'**
  String get recordDonationMsg;

  /// No description provided for @hospitalName.
  ///
  /// In en, this message translates to:
  /// **'Hospital Name'**
  String get hospitalName;

  /// No description provided for @daysRemaining90.
  ///
  /// In en, this message translates to:
  /// **'days remaining'**
  String get daysRemaining90;

  /// No description provided for @eligibleIn.
  ///
  /// In en, this message translates to:
  /// **'Eligible again in 90 days'**
  String get eligibleIn;

  /// No description provided for @notEligibleMsg.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible to donate yet. Help button is hidden until you are eligible.'**
  String get notEligibleMsg;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguage;

  /// No description provided for @manageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage how you receive alerts for blood requests and donations.'**
  String get manageNotifications;

  /// No description provided for @donorActivity.
  ///
  /// In en, this message translates to:
  /// **'Donor Activity'**
  String get donorActivity;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @version100.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version100;

  /// No description provided for @chooseYourRole.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Role'**
  String get chooseYourRole;

  /// No description provided for @iWantToDonate.
  ///
  /// In en, this message translates to:
  /// **'I want to Donate Blood'**
  String get iWantToDonate;

  /// No description provided for @iNeedBlood.
  ///
  /// In en, this message translates to:
  /// **'I need Blood'**
  String get iNeedBlood;

  /// No description provided for @donorDescription.
  ///
  /// In en, this message translates to:
  /// **'Help save lives by donating blood to those in need'**
  String get donorDescription;

  /// No description provided for @recipientDescription.
  ///
  /// In en, this message translates to:
  /// **'Find donors and request blood quickly'**
  String get recipientDescription;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterPhoneToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to reset password'**
  String get enterPhoneToReset;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent!'**
  String get resetSent;

  /// No description provided for @registerAsDonor.
  ///
  /// In en, this message translates to:
  /// **'Register as Donor'**
  String get registerAsDonor;

  /// No description provided for @registerAsRecipient.
  ///
  /// In en, this message translates to:
  /// **'Register as Recipient'**
  String get registerAsRecipient;

  /// No description provided for @fillDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details to create account'**
  String get fillDetails;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @eligibilityRequirements.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Requirements'**
  String get eligibilityRequirements;

  /// No description provided for @ageMustBe18.
  ///
  /// In en, this message translates to:
  /// **'Age must be 18 years or older'**
  String get ageMustBe18;

  /// No description provided for @weightMustBe50.
  ///
  /// In en, this message translates to:
  /// **'Weight must be 50 kg or more'**
  String get weightMustBe50;

  /// No description provided for @lastDonation3Months.
  ///
  /// In en, this message translates to:
  /// **'Last donation must be 3+ months ago'**
  String get lastDonation3Months;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age (years)'**
  String get age;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weight;

  /// No description provided for @lastDonationDate.
  ///
  /// In en, this message translates to:
  /// **'Last Donation Date'**
  String get lastDonationDate;

  /// No description provided for @neverDonatedBefore.
  ///
  /// In en, this message translates to:
  /// **'I have never donated before'**
  String get neverDonatedBefore;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @notEligibleAge.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible. Age must be 18 or older.'**
  String get notEligibleAge;

  /// No description provided for @notEligibleWeight.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible. Weight must be 50 kg or more.'**
  String get notEligibleWeight;

  /// No description provided for @notEligibleDonation.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible. Last donation must be at least 3 months ago.'**
  String get notEligibleDonation;

  /// No description provided for @youAreEligible.
  ///
  /// In en, this message translates to:
  /// **'You are eligible to donate!'**
  String get youAreEligible;

  /// No description provided for @bloodTypeNeeded.
  ///
  /// In en, this message translates to:
  /// **'Blood Type Needed'**
  String get bloodTypeNeeded;

  /// No description provided for @locationCity.
  ///
  /// In en, this message translates to:
  /// **'Location (City)'**
  String get locationCity;

  /// No description provided for @onboard1Title.
  ///
  /// In en, this message translates to:
  /// **'Secure blood for\nSurgeries & Emergencies'**
  String get onboard1Title;

  /// No description provided for @onboard1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Book Blood from trusted banks to avoid\nlast-minute stress'**
  String get onboard1Subtitle;

  /// No description provided for @onboard2Title.
  ///
  /// In en, this message translates to:
  /// **'Need Blood?\nJust a Tap away!'**
  String get onboard2Title;

  /// No description provided for @onboard2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Find donors or blood bank instantly\nwith just a few taps'**
  String get onboard2Subtitle;

  /// No description provided for @onboard3Title.
  ///
  /// In en, this message translates to:
  /// **'Find Blood,\nSave Life'**
  String get onboard3Title;

  /// No description provided for @onboard3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the fastest way to request, Book\nand donate blood anytime, anywhere'**
  String get onboard3Subtitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageTitle;

  /// No description provided for @nearbyBloodRequests.
  ///
  /// In en, this message translates to:
  /// **'Nearby Blood Requests'**
  String get nearbyBloodRequests;

  /// No description provided for @findDonorsNearby.
  ///
  /// In en, this message translates to:
  /// **'Find Donors Nearby'**
  String get findDonorsNearby;

  /// No description provided for @nearbyDonors.
  ///
  /// In en, this message translates to:
  /// **'Nearby Donors'**
  String get nearbyDonors;

  /// No description provided for @searchByHospital.
  ///
  /// In en, this message translates to:
  /// **'Search by hospital or location...'**
  String get searchByHospital;

  /// No description provided for @searchDonorsByName.
  ///
  /// In en, this message translates to:
  /// **'Search donors by name...'**
  String get searchDonorsByName;

  /// No description provided for @noRequestsNearby.
  ///
  /// In en, this message translates to:
  /// **'No requests nearby'**
  String get noRequestsNearby;

  /// No description provided for @noDonorsFound.
  ///
  /// In en, this message translates to:
  /// **'No donors found'**
  String get noDonorsFound;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Showing default location.'**
  String get locationDenied;

  /// No description provided for @notEligibleYetShort.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible to donate yet.'**
  String get notEligibleYetShort;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @donations.
  ///
  /// In en, this message translates to:
  /// **'donations'**
  String get donations;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
