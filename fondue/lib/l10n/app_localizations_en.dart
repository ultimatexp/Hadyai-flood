// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fondue';

  @override
  String get navSearch => 'Search';

  @override
  String get navFeed => 'Feed';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Profile';

  @override
  String get mapFabLabel => 'Map';

  @override
  String get createSheetReportPetTitle => 'Report pet';

  @override
  String get createSheetReportPetSubtitle => 'Lost or found';

  @override
  String get createSheetNewPostTitle => 'New post';

  @override
  String get createSheetNewPostSubtitle => 'Share updates and photos';

  @override
  String get profileStatsReports => 'Reports';

  @override
  String get profileStatsHelped => 'Helped';

  @override
  String get profileStatsPoints => 'Points';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileMenuMyPets => 'My pets';

  @override
  String get profileMenuMyReports => 'My reports';

  @override
  String get profileMenuPotentialMatches => 'Potential matches';

  @override
  String get profileMenuActivity => 'Activity';

  @override
  String get profileMenuTopDonors => 'Top donors';

  @override
  String get profileMenuNotifications => 'Notifications';

  @override
  String get profileMenuSettings => 'Settings';

  @override
  String get profileMenuLanguage => 'Language';

  @override
  String get profileMenuHelp => 'Help';

  @override
  String get profileMenuPrivacy => 'Privacy policy';

  @override
  String get profileMenuTerms => 'Terms of use';

  @override
  String get profileLoginSignup => 'Log in / Sign up';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileLanguageDisplayThai => 'Thai';

  @override
  String get profileLanguageDisplayEnglish => 'English';

  @override
  String get profileBadgesTitle => 'Badges';

  @override
  String get profileBadgeUnlocked => '✅ Unlocked';

  @override
  String get profileBadgeLocked => '🔒 Locked';

  @override
  String profilePointsLabel(int points) {
    return '$points pts';
  }

  @override
  String profileNextLevelPrefix(String label) {
    return 'Next: $label';
  }

  @override
  String get profileMaxLevel => 'Max level!';

  @override
  String profileStreakDays(int count) {
    return '🔥 $count day streak';
  }

  @override
  String get storeTitle => 'Store';

  @override
  String get storeSubtitle => 'Food • Gear • Toys';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account & security';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsBlockedUsers => 'Blocked users';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsPushNotifications => 'Push notifications';

  @override
  String get settingsSectionData => 'Data management';

  @override
  String get settingsClearCache => 'Clear app cache';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsTermsOfService => 'Terms of service';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsComingSoon => 'Coming soon';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsDeleteDialogTitle => 'Delete account';

  @override
  String get settingsDeleteDialogBody =>
      'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsDelete => 'Delete';

  @override
  String get settingsDeletionRequested => 'Account deletion requested';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageOptionDevice => 'Use device language';

  @override
  String get languageOptionThai => 'Thai';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get potentialMatchesScreenTitle => 'My potential matches';

  @override
  String get potentialMatchesRefreshTooltip => 'Refresh';

  @override
  String get potentialMatchesSearching => 'Searching for matches…';

  @override
  String potentialMatchesErrorLine(String message) {
    return 'Error: $message';
  }

  @override
  String get potentialMatchesRetry => 'Retry';

  @override
  String get potentialMatchesEmptyTitle => 'No matches found';

  @override
  String get potentialMatchesEmptyBody =>
      'We haven\'t found any potential matches for your lost pets yet. Check back later as new found pets are reported.';

  @override
  String get potentialMatchesCheckAgain => 'Check again';

  @override
  String get potentialMatchesCardLabel => 'Potential match';

  @override
  String potentialMatchesScorePercent(int score) {
    return '$score% match';
  }

  @override
  String get potentialMatchesYourLostPet => 'Your lost pet';

  @override
  String get potentialMatchesFoundPet => 'Found pet';

  @override
  String get potentialMatchesViewFoundPet => 'View found pet details';

  @override
  String get potentialMatchesDismiss => 'Not my pet, don\'t show again';

  @override
  String get potentialMatchesHideDialogTitle => 'Hide this match?';

  @override
  String get potentialMatchesHideDialogBody =>
      'This match will be hidden from your list. You can still find this pet in the general feed.';

  @override
  String get potentialMatchesHideMatch => 'Hide match';

  @override
  String get potentialMatchesHiddenSnack =>
      'Match hidden. It won\'t appear again.';

  @override
  String get potentialMatchesHideFailedSnack =>
      'Failed to hide match. Please try again.';

  @override
  String get petFilterAll => 'All';

  @override
  String get petFilterLost => 'Lost';

  @override
  String get petFilterFound => 'Found';

  @override
  String get petFilterDogs => 'Dogs';

  @override
  String get petFilterCats => 'Cats';

  @override
  String get petStatusLost => 'Lost';

  @override
  String get petStatusFound => 'Found';

  @override
  String get petStatusReunited => 'Reunited';

  @override
  String get petSexMale => 'Male';

  @override
  String get petSexFemale => 'Female';

  @override
  String get petSexUnknown => 'Unknown';

  @override
  String get mapViewTitle => 'Pet map';

  @override
  String get mapViewSearchPhotoHint => 'Search by photo…';

  @override
  String get mapViewListViewButton => 'List view';

  @override
  String mapViewErrorLoading(String message) {
    return 'Error loading map: $message';
  }

  @override
  String get mapViewViewDetails => 'View details';

  @override
  String mapViewTimeMonthsAgo(int months) {
    return '$months months ago';
  }

  @override
  String mapViewTimeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String mapViewTimeHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String mapViewTimeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String get petFeedTitle => 'Found & lost pets';

  @override
  String get petFeedMapTooltip => 'Map view';

  @override
  String get petFeedMatchDialogTitle => 'Potential match found!';

  @override
  String petFeedMatchDialogBody(String species, String name) {
    return 'Someone found a pet that looks like your lost $species “$name”!';
  }

  @override
  String get petFeedFoundPetDetails => 'Found pet details';

  @override
  String petFeedColorLabel(String color) {
    return 'Color: $color';
  }

  @override
  String get petFeedNoDescription => 'No description';

  @override
  String get petFeedDismiss => 'Dismiss';

  @override
  String get petFeedViewFoundPet => 'View found pet';

  @override
  String get petFeedSearch => 'Search';

  @override
  String get petFeedDefaultPetName => 'Pet';

  @override
  String get petFeedUnknownValue => 'Unknown';

  @override
  String get petFeedEmptyTitle => 'No pets found';

  @override
  String get petFeedEmptySubtitle =>
      'Try adjusting your filters or check back later';

  @override
  String get petFeedErrorTitle => 'Something went wrong';

  @override
  String get petDetailShareImageTooltip => 'Share as image';

  @override
  String get petDetailArchiveTooltip => 'Archive';

  @override
  String get petDetailEditTooltip => 'Edit';

  @override
  String get petDetailReportPost => 'Report post';

  @override
  String get petDetailBlockUser => 'Block user';

  @override
  String get petDetailEditTitle => 'Edit pet details';

  @override
  String get petDetailLabelPetName => 'Pet name';

  @override
  String get petDetailLabelStatus => 'Status';

  @override
  String get petDetailLabelSex => 'Sex';

  @override
  String get petDetailLabelColor => 'Color';

  @override
  String get petDetailLabelDescription => 'Description';

  @override
  String get petDetailLabelContact => 'Contact info';

  @override
  String get petDetailSave => 'Save';

  @override
  String get petDetailPetUpdatedSnack => 'Pet details updated!';

  @override
  String get petDetailArchiveSheetTitle => 'Archive this post';

  @override
  String get petDetailArchiveSheetSubtitle =>
      'Choose an option for this pet post';

  @override
  String get petDetailArchiveFoundTitle => 'Pet found';

  @override
  String get petDetailArchiveFoundSubtitle => 'Mark as reunited with owner';

  @override
  String get petDetailArchiveDeleteTitle => 'Delete';

  @override
  String get petDetailArchiveDeleteSubtitle => 'Permanently remove this post';

  @override
  String get petDetailMarkFoundTitle => 'Pet found!';

  @override
  String get petDetailMarkFoundBody =>
      'Great news! Marking this pet as reunited will archive the post. Continue?';

  @override
  String get petDetailMarkReunitedButton => 'Mark as reunited';

  @override
  String get petDetailReunitedSnack => 'Pet marked as reunited!';

  @override
  String get petDetailDeletePostTitle => 'Delete post';

  @override
  String get petDetailDeletePostBody =>
      'Are you sure you want to permanently delete this post? This action cannot be undone.';

  @override
  String get petDetailPostDeletedSnack => 'Post deleted';

  @override
  String petDetailPhotoOf(int current, int total) {
    return 'Photo $current of $total';
  }

  @override
  String get petDetailCountdownExpired => 'Expired';

  @override
  String get petDetailExpiresInLabel => 'Expires in';

  @override
  String get petDetailReportExpiredTitle => 'Report expired';

  @override
  String get petDetailReportExpiredBody => 'This report is no longer active';

  @override
  String petDetailDurationDaysHours(int days, int hours) {
    return '$days days, $hours hours';
  }

  @override
  String petDetailDurationHoursMinutes(int hours, int minutes) {
    return '$hours hours, $minutes min';
  }

  @override
  String petDetailDurationMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get petDetailDescriptionHeading => 'Description';

  @override
  String get petDetailNoDescription => 'No description provided.';

  @override
  String get petDetailLastSeenHeading => 'Last seen location';

  @override
  String get petDetailSeeOnMap => 'See on map';

  @override
  String petDetailPostId(String id) {
    return 'Post ID: $id';
  }

  @override
  String get petDetailInfoSpecies => 'Species';

  @override
  String get petDetailInfoSex => 'Sex';

  @override
  String get petDetailInfoColor => 'Color';

  @override
  String get petDetailYourPostTitle => 'Your post';

  @override
  String get petDetailYourPostSubtitle => 'Make changes or verify';

  @override
  String get petDetailCheckingDatabase => 'Checking database…';

  @override
  String get petDetailRecheckMatches => 'Recheck database for matches';

  @override
  String get petDetailOwnerOfPost => 'You are the owner of this post';

  @override
  String get petDetailPostOwnedBy => 'Post owned by';

  @override
  String get petDetailDefaultOwnerName => 'Pet owner';

  @override
  String get petDetailChatNow => 'Chat now';

  @override
  String get petDetailContact => 'Contact';

  @override
  String get petDetailNoNewMatches => 'No new matches found at this time.';

  @override
  String petDetailErrorCheckingMatches(String message) {
    return 'Error checking matches: $message';
  }

  @override
  String petDetailMatchResultsTitle(int count) {
    return '$count potential match(es)!';
  }

  @override
  String petDetailMatchListTileTitle(String species, int score) {
    return 'Found $species ($score% match)';
  }

  @override
  String get petDetailClose => 'Close';

  @override
  String get petDetailChatNoOwner =>
      'Cannot start chat: owner information not available';

  @override
  String get petDetailChatLoginRequired => 'Please log in to start a chat';

  @override
  String petDetailChatFailed(String message) {
    return 'Failed to start chat: $message';
  }

  @override
  String get petDetailCannotCall => 'Cannot make phone call';

  @override
  String get petDetailReportDialogTitle => 'Report post';

  @override
  String get petDetailReportDialogPrompt => 'Why are you reporting this post?';

  @override
  String get petDetailReportHint => 'e.g. inappropriate content, spam…';

  @override
  String get petDetailReportSubmit => 'Report';

  @override
  String get petDetailReportLoginRequired => 'Please log in to report content';

  @override
  String get petDetailReportThanks =>
      'Report submitted. Thank you for helping keep our community safe.';

  @override
  String petDetailReportError(String message) {
    return 'Error submitting report: $message';
  }

  @override
  String get petDetailBlockDialogTitle => 'Block user';

  @override
  String get petDetailBlockDialogBody =>
      'Are you sure you want to block this user? You will no longer see their posts.';

  @override
  String get petDetailBlockSubmit => 'Block';

  @override
  String get petDetailBlockLoginRequired => 'Please log in to block users';

  @override
  String get petDetailUserBlocked => 'User blocked.';

  @override
  String petDetailBlockError(String message) {
    return 'Error blocking user: $message';
  }

  @override
  String petDetailGenericError(String message) {
    return 'Error: $message';
  }
}
