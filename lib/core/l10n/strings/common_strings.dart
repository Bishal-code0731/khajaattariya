import '../localized_strings.dart';

/// App-wide words: actions, states, friendly messages, validation.
class CommonStrings extends LocalizedStrings {
  const CommonStrings(super.isNe);

  // Brand
  String get appName => t('Khaja Attariya', 'खाजा अत्तरिया');
  String get tagline =>
      t('Local food, delivered fast', 'स्थानीय खाना, छिटो घरमै');

  // Actions
  String get save => t('Save', 'सेभ गर्नुहोस्');
  String get saveChanges => t('Save changes', 'परिवर्तन सेभ गर्नुहोस्');
  String get cancel => t('Cancel', 'रद्द गर्नुहोस्');
  String get confirm => t('Confirm', 'पुष्टि गर्नुहोस्');
  String get continueLabel => t('Continue', 'जारी राख्नुहोस्');
  String get done => t('Done', 'सकियो');
  String get retry => t('Try again', 'फेरि प्रयास गर्नुहोस्');
  String get delete => t('Delete', 'मेटाउनुहोस्');
  String get remove => t('Remove', 'हटाउनुहोस्');
  String get edit => t('Edit', 'सम्पादन');
  String get add => t('Add', 'थप्नुहोस्');
  String get close => t('Close', 'बन्द गर्नुहोस्');
  String get back => t('Back', 'पछाडि');
  String get next => t('Next', 'अर्को');
  String get submit => t('Submit', 'पेश गर्नुहोस्');
  String get search => t('Search', 'खोज्नुहोस्');
  String get seeAll => t('See all', 'सबै हेर्नुहोस्');
  String get apply => t('Apply', 'लागू गर्नुहोस्');
  String get clear => t('Clear', 'खाली गर्नुहोस्');
  String get yes => t('Yes', 'हो');
  String get no => t('No', 'होइन');
  String get ok => t('OK', 'ठीक छ');
  String get logout => t('Log out', 'लग आउट');
  String get login => t('Log in', 'लग इन');
  String get signUp => t('Sign up', 'साइन अप');
  String get goHome => t('Go to home', 'गृहपृष्ठमा जानुहोस्');
  String get call => t('Call', 'फोन गर्नुहोस्');

  // Settings
  String get language => t('Language', 'भाषा');
  String get theme => t('Appearance', 'देखावट');
  String get themeLight => t('Light', 'उज्यालो');
  String get themeDark => t('Dark', 'अँध्यारो');
  String get themeSystem => t('System', 'प्रणाली');
  String get switchLanguage => t('Change language', 'भाषा बदल्नुहोस्');

  // States
  String get loading => t('Loading…', 'लोड हुँदैछ…');
  String get offlineBanner => t("You're offline — showing saved data",
      'तपाईं अफलाइन हुनुहुन्छ — सेभ गरिएको डेटा देखाइँदैछ');
  String get emptyTitle => t('Nothing here yet', 'अहिले केही छैन');
  String get errorTitle => t("Something didn't load", 'केही लोड भएन');
  String get notFoundTitle => t('Page not found', 'पृष्ठ फेला परेन');
  String get notFoundBody => t(
      "The page you're looking for doesn't exist or has moved.",
      'तपाईंले खोजेको पृष्ठ छैन वा सारिएको छ।');

  // Friendly errors (user_message.dart)
  String get errGeneric => t('Something went wrong. Please try again.',
      'केही गडबड भयो। कृपया फेरि प्रयास गर्नुहोस्।');
  String get errNoInternet => t(
      'No internet connection. Check your network and try again.',
      'इन्टरनेट जडान छैन। नेटवर्क जाँचेर फेरि प्रयास गर्नुहोस्।');
  String get errTimeout => t('This is taking too long. Please try again.',
      'धेरै समय लाग्यो। कृपया फेरि प्रयास गर्नुहोस्।');
  String get errPermission => t(
      "You don't have permission to do that.", 'तपाईंलाई यो गर्ने अनुमति छैन।');
  String get errSessionExpired => t(
      'Your session has expired. Please log in again.',
      'तपाईंको सत्र सकियो। कृपया फेरि लग इन गर्नुहोस्।');
  String get errNotFound => t("We couldn't find that.", 'त्यो फेला परेन।');
  String get errDuplicate => t('This already exists.', 'यो पहिले नै छ।');
  String get errInvalidLogin =>
      t('Email or password is incorrect.', 'इमेल वा पासवर्ड मिलेन।');
  String get errEmailNotConfirmed => t(
      'Please confirm your email first — check your inbox.',
      'पहिले आफ्नो इमेल पुष्टि गर्नुहोस् — इनबक्स हेर्नुहोस्।');
  String get errEmailTaken => t(
      'An account with this email already exists. Try logging in.',
      'यो इमेलबाट खाता पहिले नै छ। लग इन गर्नुहोस्।');
  String get errWeakPassword => t(
      'Choose a stronger password (8+ characters with letters and numbers).',
      'अझ बलियो पासवर्ड राख्नुहोस् (८+ अक्षर, अक्षर र अंक सहित)।');
  String get errTooManyAttempts => t(
      'Too many attempts. Please wait a minute and try again.',
      'धेरै प्रयास भयो। एक मिनेट पर्खेर फेरि प्रयास गर्नुहोस्।');
  String get errAccountDisabled => t(
      'This account has been disabled. Contact support for help.',
      'यो खाता बन्द गरिएको छ। सहायताका लागि सम्पर्क गर्नुहोस्।');
  String get errOtpInvalid => t(
      "That code is wrong or has expired. Check it or request a new one.",
      'कोड मिलेन वा म्याद सकियो। जाँच्नुहोस् वा नयाँ कोड माग्नुहोस्।');
  String get errUploadTooLarge => t(
      'That image is too large. Please choose a smaller one.',
      'तस्बिर धेरै ठूलो छ। सानो तस्बिर छान्नुहोस्।');

  // Generic success
  String get savedSuccess => t('Saved', 'सेभ भयो');
  String get updatedSuccess => t('Updated', 'अपडेट भयो');
  String get deletedSuccess => t('Deleted', 'मेटाइयो');

  // Validation
  String required(String field) => t('$field is required', '$field आवश्यक छ');
  String get fieldRequired => t('This field is required', 'यो भर्न आवश्यक छ');
  String get invalidEmail => t('Enter a valid email, e.g. name@example.com',
      'मान्य इमेल लेख्नुहोस्, जस्तै name@example.com');
  String get invalidPhone => t(
      'Enter a valid Nepali mobile number (98XXXXXXXX)',
      'मान्य नेपाली मोबाइल नम्बर लेख्नुहोस् (९८XXXXXXXX)');
  String passwordTooShort(int n) =>
      t('Use at least $n characters', 'कम्तीमा $n अक्षर राख्नुहोस्');
  String get passwordNeedsLetterAndNumber => t(
      'Use at least one letter and one number',
      'कम्तीमा एउटा अक्षर र एउटा अंक राख्नुहोस्');
  String get passwordsDontMatch => t("Passwords don't match", 'पासवर्ड मिलेन');
  String minLength(String field, int n) => t(
      '$field must be at least $n characters',
      '$field कम्तीमा $n अक्षरको हुनुपर्छ');
  String maxLength(String field, int n) => t(
      '$field must be at most $n characters',
      '$field बढीमा $n अक्षरको हुनुपर्छ');
  String get invalidNumber => t('Enter a valid number', 'मान्य अंक लेख्नुहोस्');
  String get priceMustBePositive =>
      t('Price must be more than 0', 'मूल्य ० भन्दा बढी हुनुपर्छ');
  String priceTooHigh(String max) =>
      t('Price must be at most $max', 'मूल्य बढीमा $max हुनुपर्छ');
  String get mustNotBeNegative => t("Can't be negative", 'ऋणात्मक हुन सक्दैन');
  String get invalidUrl => t('Enter a valid link starting with https://',
      'https:// बाट सुरु हुने मान्य लिङ्क लेख्नुहोस्');
  String get invalidTime =>
      t('Use 24-hour time like 09:30', '०९:३० जस्तो २४-घण्टे समय लेख्नुहोस्');

  // Field names
  String get fieldEmail => t('Email', 'इमेल');
  String get fieldPassword => t('Password', 'पासवर्ड');
  String get fieldName => t('Name', 'नाम');
  String get fieldFullName => t('Full name', 'पूरा नाम');
  String get fieldPhone => t('Phone number', 'फोन नम्बर');
  String get fieldAddress => t('Address', 'ठेगाना');
  String get fieldPrice => t('Price', 'मूल्य');

  // Order status (shared by every role)
  String get statusPending =>
      t('Waiting for restaurant', 'रेस्टुरेन्टको प्रतीक्षामा');
  String get statusConfirmed => t('Accepted', 'स्वीकार गरियो');
  String get statusPreparing => t('Preparing', 'तयार हुँदैछ');
  String get statusReady => t('Ready for pickup', 'लैजान तयार');
  String get statusPickedUp => t('On the way', 'बाटोमा');
  String get statusDelivered => t('Delivered', 'डेलिभर भयो');
  String get statusCancelled => t('Cancelled', 'रद्द भयो');

  // Time
  String get justNow => t('Just now', 'भर्खरै');
  String minutesAgo(int n) => t('${n}m ago', '$n मिनेट अघि');
  String hoursAgo(int n) => t('${n}h ago', '$n घण्टा अघि');
  String get yesterday => t('Yesterday', 'हिजो');
  String daysAgo(int n) => t('${n}d ago', '$n दिन अघि');
  String minutesShort(int n) => t('$n min', '$n मिनेट');
  String get currency => t('Rs', 'रु');
}
