import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

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
    Locale('th'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fondue'**
  String get appTitle;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @mapFabLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapFabLabel;

  /// No description provided for @createSheetReportPetTitle.
  ///
  /// In en, this message translates to:
  /// **'Report pet'**
  String get createSheetReportPetTitle;

  /// No description provided for @createSheetReportPetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lost or found'**
  String get createSheetReportPetSubtitle;

  /// No description provided for @createSheetNewPostTitle.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get createSheetNewPostTitle;

  /// No description provided for @createSheetNewPostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share updates and photos'**
  String get createSheetNewPostSubtitle;

  /// No description provided for @profileStatsReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get profileStatsReports;

  /// No description provided for @profileStatsHelped.
  ///
  /// In en, this message translates to:
  /// **'Helped'**
  String get profileStatsHelped;

  /// No description provided for @profileStatsPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get profileStatsPoints;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @profileMenuMyPets.
  ///
  /// In en, this message translates to:
  /// **'My pets'**
  String get profileMenuMyPets;

  /// No description provided for @profileMenuMyReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get profileMenuMyReports;

  /// No description provided for @profileMenuPotentialMatches.
  ///
  /// In en, this message translates to:
  /// **'Potential matches'**
  String get profileMenuPotentialMatches;

  /// No description provided for @profileMenuActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get profileMenuActivity;

  /// No description provided for @profileMenuTopDonors.
  ///
  /// In en, this message translates to:
  /// **'Top donors'**
  String get profileMenuTopDonors;

  /// No description provided for @profileMenuNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileMenuNotifications;

  /// No description provided for @profileMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileMenuSettings;

  /// No description provided for @profileMenuLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileMenuLanguage;

  /// No description provided for @profileMenuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get profileMenuHelp;

  /// No description provided for @profileMenuPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get profileMenuPrivacy;

  /// No description provided for @profileMenuTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get profileMenuTerms;

  /// No description provided for @profileLoginSignup.
  ///
  /// In en, this message translates to:
  /// **'Log in / Sign up'**
  String get profileLoginSignup;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileLanguageDisplayThai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get profileLanguageDisplayThai;

  /// No description provided for @profileLanguageDisplayEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileLanguageDisplayEnglish;

  /// No description provided for @profileBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get profileBadgesTitle;

  /// No description provided for @profileBadgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'✅ Unlocked'**
  String get profileBadgeUnlocked;

  /// No description provided for @profileBadgeLocked.
  ///
  /// In en, this message translates to:
  /// **'🔒 Locked'**
  String get profileBadgeLocked;

  /// No description provided for @profilePointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String profilePointsLabel(int points);

  /// No description provided for @profileNextLevelPrefix.
  ///
  /// In en, this message translates to:
  /// **'Next: {label}'**
  String profileNextLevelPrefix(String label);

  /// No description provided for @profileMaxLevel.
  ///
  /// In en, this message translates to:
  /// **'Max level!'**
  String get profileMaxLevel;

  /// No description provided for @profileStreakDays.
  ///
  /// In en, this message translates to:
  /// **'🔥 {count} day streak'**
  String profileStreakDays(int count);

  /// No description provided for @storeTitle.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storeTitle;

  /// No description provided for @storeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Food • Gear • Toys'**
  String get storeSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account & security'**
  String get settingsSectionAccount;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlockedUsers;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get settingsSectionData;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear app cache'**
  String get settingsClearCache;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settingsComingSoon;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteDialogTitle;

  /// No description provided for @settingsDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.'**
  String get settingsDeleteDialogBody;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDelete;

  /// No description provided for @settingsDeletionRequested.
  ///
  /// In en, this message translates to:
  /// **'Account deletion requested'**
  String get settingsDeletionRequested;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageOptionDevice.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get languageOptionDevice;

  /// No description provided for @languageOptionThai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get languageOptionThai;

  /// No description provided for @languageOptionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageOptionEnglish;

  /// No description provided for @potentialMatchesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'My potential matches'**
  String get potentialMatchesScreenTitle;

  /// No description provided for @potentialMatchesRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get potentialMatchesRefreshTooltip;

  /// No description provided for @potentialMatchesSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching for matches…'**
  String get potentialMatchesSearching;

  /// No description provided for @potentialMatchesErrorLine.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String potentialMatchesErrorLine(String message);

  /// No description provided for @potentialMatchesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get potentialMatchesRetry;

  /// No description provided for @potentialMatchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get potentialMatchesEmptyTitle;

  /// No description provided for @potentialMatchesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'We haven\'t found any potential matches for your lost pets yet. Check back later as new found pets are reported.'**
  String get potentialMatchesEmptyBody;

  /// No description provided for @potentialMatchesCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get potentialMatchesCheckAgain;

  /// No description provided for @potentialMatchesCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Potential match'**
  String get potentialMatchesCardLabel;

  /// No description provided for @potentialMatchesScorePercent.
  ///
  /// In en, this message translates to:
  /// **'{score}% match'**
  String potentialMatchesScorePercent(int score);

  /// No description provided for @potentialMatchesYourLostPet.
  ///
  /// In en, this message translates to:
  /// **'Your lost pet'**
  String get potentialMatchesYourLostPet;

  /// No description provided for @potentialMatchesFoundPet.
  ///
  /// In en, this message translates to:
  /// **'Found pet'**
  String get potentialMatchesFoundPet;

  /// No description provided for @potentialMatchesViewFoundPet.
  ///
  /// In en, this message translates to:
  /// **'View found pet details'**
  String get potentialMatchesViewFoundPet;

  /// No description provided for @potentialMatchesDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not my pet, don\'t show again'**
  String get potentialMatchesDismiss;

  /// No description provided for @potentialMatchesHideDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide this match?'**
  String get potentialMatchesHideDialogTitle;

  /// No description provided for @potentialMatchesHideDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This match will be hidden from your list. You can still find this pet in the general feed.'**
  String get potentialMatchesHideDialogBody;

  /// No description provided for @potentialMatchesHideMatch.
  ///
  /// In en, this message translates to:
  /// **'Hide match'**
  String get potentialMatchesHideMatch;

  /// No description provided for @potentialMatchesHiddenSnack.
  ///
  /// In en, this message translates to:
  /// **'Match hidden. It won\'t appear again.'**
  String get potentialMatchesHiddenSnack;

  /// No description provided for @potentialMatchesHideFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Failed to hide match. Please try again.'**
  String get potentialMatchesHideFailedSnack;

  /// No description provided for @petFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get petFilterAll;

  /// No description provided for @petFilterLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get petFilterLost;

  /// No description provided for @petFilterFound.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get petFilterFound;

  /// No description provided for @petFilterDogs.
  ///
  /// In en, this message translates to:
  /// **'Dogs'**
  String get petFilterDogs;

  /// No description provided for @petFilterCats.
  ///
  /// In en, this message translates to:
  /// **'Cats'**
  String get petFilterCats;

  /// No description provided for @petStatusLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get petStatusLost;

  /// No description provided for @petStatusFound.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get petStatusFound;

  /// No description provided for @petStatusReunited.
  ///
  /// In en, this message translates to:
  /// **'Reunited'**
  String get petStatusReunited;

  /// No description provided for @petSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get petSexMale;

  /// No description provided for @petSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get petSexFemale;

  /// No description provided for @petSexUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get petSexUnknown;

  /// No description provided for @mapViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet map'**
  String get mapViewTitle;

  /// No description provided for @mapViewSearchPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Search by photo…'**
  String get mapViewSearchPhotoHint;

  /// No description provided for @mapViewListViewButton.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get mapViewListViewButton;

  /// No description provided for @mapViewErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading map: {message}'**
  String mapViewErrorLoading(String message);

  /// No description provided for @mapViewViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get mapViewViewDetails;

  /// No description provided for @mapViewTimeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String mapViewTimeMonthsAgo(int months);

  /// No description provided for @mapViewTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String mapViewTimeDaysAgo(int days);

  /// No description provided for @mapViewTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String mapViewTimeHoursAgo(int hours);

  /// No description provided for @mapViewTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String mapViewTimeMinutesAgo(int minutes);

  /// No description provided for @petFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Found & lost pets'**
  String get petFeedTitle;

  /// No description provided for @petFeedMapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Map view'**
  String get petFeedMapTooltip;

  /// No description provided for @petFeedMatchDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Potential match found!'**
  String get petFeedMatchDialogTitle;

  /// No description provided for @petFeedMatchDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Someone found a pet that looks like your lost {species} “{name}”!'**
  String petFeedMatchDialogBody(String species, String name);

  /// No description provided for @petFeedFoundPetDetails.
  ///
  /// In en, this message translates to:
  /// **'Found pet details'**
  String get petFeedFoundPetDetails;

  /// No description provided for @petFeedColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color: {color}'**
  String petFeedColorLabel(String color);

  /// No description provided for @petFeedNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get petFeedNoDescription;

  /// No description provided for @petFeedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get petFeedDismiss;

  /// No description provided for @petFeedViewFoundPet.
  ///
  /// In en, this message translates to:
  /// **'View found pet'**
  String get petFeedViewFoundPet;

  /// No description provided for @petFeedSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get petFeedSearch;

  /// No description provided for @petFeedDefaultPetName.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get petFeedDefaultPetName;

  /// No description provided for @petFeedUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get petFeedUnknownValue;

  /// No description provided for @petFeedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No pets found'**
  String get petFeedEmptyTitle;

  /// No description provided for @petFeedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or check back later'**
  String get petFeedEmptySubtitle;

  /// No description provided for @petFeedErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get petFeedErrorTitle;

  /// No description provided for @petDetailShareImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get petDetailShareImageTooltip;

  /// No description provided for @petDetailArchiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get petDetailArchiveTooltip;

  /// No description provided for @petDetailEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get petDetailEditTooltip;

  /// No description provided for @petDetailReportPost.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get petDetailReportPost;

  /// No description provided for @petDetailBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get petDetailBlockUser;

  /// No description provided for @petDetailEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit pet details'**
  String get petDetailEditTitle;

  /// No description provided for @petDetailLabelPetName.
  ///
  /// In en, this message translates to:
  /// **'Pet name'**
  String get petDetailLabelPetName;

  /// No description provided for @petDetailLabelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get petDetailLabelStatus;

  /// No description provided for @petDetailLabelSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get petDetailLabelSex;

  /// No description provided for @petDetailLabelColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get petDetailLabelColor;

  /// No description provided for @petDetailLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get petDetailLabelDescription;

  /// No description provided for @petDetailLabelContact.
  ///
  /// In en, this message translates to:
  /// **'Contact info'**
  String get petDetailLabelContact;

  /// No description provided for @petDetailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get petDetailSave;

  /// No description provided for @petDetailPetUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Pet details updated!'**
  String get petDetailPetUpdatedSnack;

  /// No description provided for @petDetailArchiveSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this post'**
  String get petDetailArchiveSheetTitle;

  /// No description provided for @petDetailArchiveSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an option for this pet post'**
  String get petDetailArchiveSheetSubtitle;

  /// No description provided for @petDetailArchiveFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet found'**
  String get petDetailArchiveFoundTitle;

  /// No description provided for @petDetailArchiveFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as reunited with owner'**
  String get petDetailArchiveFoundSubtitle;

  /// No description provided for @petDetailArchiveDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get petDetailArchiveDeleteTitle;

  /// No description provided for @petDetailArchiveDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove this post'**
  String get petDetailArchiveDeleteSubtitle;

  /// No description provided for @petDetailMarkFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet found!'**
  String get petDetailMarkFoundTitle;

  /// No description provided for @petDetailMarkFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Great news! Marking this pet as reunited will archive the post. Continue?'**
  String get petDetailMarkFoundBody;

  /// No description provided for @petDetailMarkReunitedButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as reunited'**
  String get petDetailMarkReunitedButton;

  /// No description provided for @petDetailReunitedSnack.
  ///
  /// In en, this message translates to:
  /// **'Pet marked as reunited!'**
  String get petDetailReunitedSnack;

  /// No description provided for @petDetailDeletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get petDetailDeletePostTitle;

  /// No description provided for @petDetailDeletePostBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this post? This action cannot be undone.'**
  String get petDetailDeletePostBody;

  /// No description provided for @petDetailPostDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get petDetailPostDeletedSnack;

  /// No description provided for @petDetailPhotoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo {current} of {total}'**
  String petDetailPhotoOf(int current, int total);

  /// No description provided for @petDetailCountdownExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get petDetailCountdownExpired;

  /// No description provided for @petDetailExpiresInLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get petDetailExpiresInLabel;

  /// No description provided for @petDetailReportExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Report expired'**
  String get petDetailReportExpiredTitle;

  /// No description provided for @petDetailReportExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'This report is no longer active'**
  String get petDetailReportExpiredBody;

  /// No description provided for @petDetailDurationDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days} days, {hours} hours'**
  String petDetailDurationDaysHours(int days, int hours);

  /// No description provided for @petDetailDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours, {minutes} min'**
  String petDetailDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @petDetailDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String petDetailDurationMinutes(int minutes);

  /// No description provided for @petDetailDescriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get petDetailDescriptionHeading;

  /// No description provided for @petDetailNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get petDetailNoDescription;

  /// No description provided for @petDetailLastSeenHeading.
  ///
  /// In en, this message translates to:
  /// **'Last seen location'**
  String get petDetailLastSeenHeading;

  /// No description provided for @petDetailSeeOnMap.
  ///
  /// In en, this message translates to:
  /// **'See on map'**
  String get petDetailSeeOnMap;

  /// No description provided for @petDetailPostId.
  ///
  /// In en, this message translates to:
  /// **'Post ID: {id}'**
  String petDetailPostId(String id);

  /// No description provided for @petDetailInfoSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get petDetailInfoSpecies;

  /// No description provided for @petDetailInfoSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get petDetailInfoSex;

  /// No description provided for @petDetailInfoColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get petDetailInfoColor;

  /// No description provided for @petDetailYourPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Your post'**
  String get petDetailYourPostTitle;

  /// No description provided for @petDetailYourPostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make changes or verify'**
  String get petDetailYourPostSubtitle;

  /// No description provided for @petDetailCheckingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Checking database…'**
  String get petDetailCheckingDatabase;

  /// No description provided for @petDetailRecheckMatches.
  ///
  /// In en, this message translates to:
  /// **'Recheck database for matches'**
  String get petDetailRecheckMatches;

  /// No description provided for @petDetailOwnerOfPost.
  ///
  /// In en, this message translates to:
  /// **'You are the owner of this post'**
  String get petDetailOwnerOfPost;

  /// No description provided for @petDetailPostOwnedBy.
  ///
  /// In en, this message translates to:
  /// **'Post owned by'**
  String get petDetailPostOwnedBy;

  /// No description provided for @petDetailDefaultOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Pet owner'**
  String get petDetailDefaultOwnerName;

  /// No description provided for @petDetailChatNow.
  ///
  /// In en, this message translates to:
  /// **'Chat now'**
  String get petDetailChatNow;

  /// No description provided for @petDetailContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get petDetailContact;

  /// No description provided for @petDetailNoNewMatches.
  ///
  /// In en, this message translates to:
  /// **'No new matches found at this time.'**
  String get petDetailNoNewMatches;

  /// No description provided for @petDetailErrorCheckingMatches.
  ///
  /// In en, this message translates to:
  /// **'Error checking matches: {message}'**
  String petDetailErrorCheckingMatches(String message);

  /// No description provided for @petDetailMatchResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} potential match(es)!'**
  String petDetailMatchResultsTitle(int count);

  /// No description provided for @petDetailMatchListTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Found {species} ({score}% match)'**
  String petDetailMatchListTileTitle(String species, int score);

  /// No description provided for @petDetailClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get petDetailClose;

  /// No description provided for @petDetailChatNoOwner.
  ///
  /// In en, this message translates to:
  /// **'Cannot start chat: owner information not available'**
  String get petDetailChatNoOwner;

  /// No description provided for @petDetailChatLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to start a chat'**
  String get petDetailChatLoginRequired;

  /// No description provided for @petDetailChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start chat: {message}'**
  String petDetailChatFailed(String message);

  /// No description provided for @petDetailCannotCall.
  ///
  /// In en, this message translates to:
  /// **'Cannot make phone call'**
  String get petDetailCannotCall;

  /// No description provided for @petDetailReportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get petDetailReportDialogTitle;

  /// No description provided for @petDetailReportDialogPrompt.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this post?'**
  String get petDetailReportDialogPrompt;

  /// No description provided for @petDetailReportHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. inappropriate content, spam…'**
  String get petDetailReportHint;

  /// No description provided for @petDetailReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get petDetailReportSubmit;

  /// No description provided for @petDetailReportLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to report content'**
  String get petDetailReportLoginRequired;

  /// No description provided for @petDetailReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for helping keep our community safe.'**
  String get petDetailReportThanks;

  /// No description provided for @petDetailReportError.
  ///
  /// In en, this message translates to:
  /// **'Error submitting report: {message}'**
  String petDetailReportError(String message);

  /// No description provided for @petDetailBlockDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get petDetailBlockDialogTitle;

  /// No description provided for @petDetailBlockDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user? You will no longer see their posts.'**
  String get petDetailBlockDialogBody;

  /// No description provided for @petDetailBlockSubmit.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get petDetailBlockSubmit;

  /// No description provided for @petDetailBlockLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to block users'**
  String get petDetailBlockLoginRequired;

  /// No description provided for @petDetailUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get petDetailUserBlocked;

  /// No description provided for @petDetailBlockError.
  ///
  /// In en, this message translates to:
  /// **'Error blocking user: {message}'**
  String petDetailBlockError(String message);

  /// No description provided for @petDetailGenericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String petDetailGenericError(String message);
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
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
