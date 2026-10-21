import '../localized_strings.dart';

/// Login, signup, password reset, splash, onboarding.
class AuthStrings extends LocalizedStrings {
  const AuthStrings(super.isNe);

  // Splash
  String get splashLoading => t('Getting things ready', 'तयारी हुँदैछ');

  // Brand panel (wide screens)
  String get panelHeadline => t(
      "Food from Attariya's kitchens, brought to your door",
      'अत्तरियाका भान्साको खाना, तपाईंको ढोकासम्म');
  String get pointRestaurants => t(
      'Order from local restaurants you already know',
      'चिनेका स्थानीय रेस्टुरेन्टबाट अर्डर गर्नुहोस्');
  String get pointTracking => t('Follow every order from kitchen to door',
      'हरेक अर्डर भान्साबाट ढोकासम्म हेर्नुहोस्');
  String get pointPayments => t('Pay with Khalti, eSewa or cash on delivery',
      'खल्ती, इसेवा वा डेलिभरीमा नगद तिर्नुहोस्');

  // Shared fields
  String get emailHint => t('name@example.com', 'name@example.com');
  String get showPassword => t('Show password', 'पासवर्ड देखाउनुहोस्');
  String get hidePassword => t('Hide password', 'पासवर्ड लुकाउनुहोस्');
  String get backToLogin => t('Back to login', 'लग इनमा फर्कनुहोस्');

  // Login
  String get loginTitle =>
      t('Log in to your account', 'आफ्नो खातामा लग इन गर्नुहोस्');
  String get loginSubtitle => t('Welcome back. Enter your email and password.',
      'फेरि स्वागत छ। आफ्नो इमेल र पासवर्ड लेख्नुहोस्।');
  String get loginPasswordHint => t('Your password', 'तपाईंको पासवर्ड');
  String get forgotPasswordLink => t('Forgot password?', 'पासवर्ड बिर्सनुभयो?');
  String get loginButton => t('Log in', 'लग इन गर्नुहोस्');
  String get noAccount =>
      t('New to Khaja Attariya?', 'खाजा अत्तरियामा नयाँ हुनुहुन्छ?');
  String get createAccountLink => t('Create an account', 'खाता बनाउनुहोस्');

  // Signup
  String get signupTitle => t('Create your account', 'आफ्नो खाता बनाउनुहोस्');
  String get signupSubtitle =>
      t('It takes less than a minute.', 'एक मिनेट पनि लाग्दैन।');
  String get sectionDetails => t('Your details', 'तपाईंको विवरण');
  String get sectionRole =>
      t('How will you use the app?', 'तपाईं एप कसरी प्रयोग गर्नुहुन्छ?');
  String get nameHint => t('e.g. Sita Chaudhary', 'जस्तै सीता चौधरी');
  String get phoneHint => t('98XXXXXXXX', '९८XXXXXXXX');
  String get phoneHelper => t(
      'Restaurants and riders use this to reach you about orders',
      'अर्डरबारे सम्पर्क गर्न रेस्टुरेन्ट र राइडरले यो प्रयोग गर्छन्');
  String get passwordHint => t('At least 8 characters', 'कम्तीमा ८ अक्षर');
  String get passwordHelper => t(
      'Use 8 or more characters with letters and numbers',
      '८ वा बढी अक्षर, अक्षर र अंक सहित प्रयोग गर्नुहोस्');
  String get confirmPasswordLabel =>
      t('Confirm password', 'पासवर्ड पुष्टि गर्नुहोस्');
  String get confirmPasswordHint => t('Type it again', 'फेरि लेख्नुहोस्');
  String get roleCustomerTitle => t('Order food', 'खाना अर्डर गर्ने');
  String get roleCustomerDesc => t(
      'Browse local restaurants and get food delivered',
      'स्थानीय रेस्टुरेन्ट हेर्नुहोस् र खाना घरमै मगाउनुहोस्');
  String get roleRestaurantTitle => t('Run a restaurant', 'रेस्टुरेन्ट चलाउने');
  String get roleRestaurantDesc => t(
      'List your menu and take orders. Needs admin approval.',
      'मेनु राख्नुहोस् र अर्डर लिनुहोस्। एडमिनको स्वीकृति चाहिन्छ।');
  String get roleRiderTitle => t('Deliver orders', 'अर्डर डेलिभर गर्ने');
  String get roleRiderDesc => t(
      'Earn by delivering around Attariya. Needs admin approval.',
      'अत्तरियाभित्र डेलिभरी गरेर कमाउनुहोस्। एडमिनको स्वीकृति चाहिन्छ।');
  String get termsAgree => t(
      'I agree to the Terms of Service and Privacy Policy',
      'म सेवाका सर्तहरू र गोपनीयता नीतिमा सहमत छु');
  String get termsRequired => t(
      'Please accept the terms to create your account',
      'खाता बनाउन सर्तहरूमा सहमति जनाउनुहोस्');
  String get createAccountButton => t('Create account', 'खाता बनाउनुहोस्');
  String get haveAccount => t('Already have an account?', 'पहिले नै खाता छ?');
  String get loginLink => t('Log in', 'लग इन गर्नुहोस्');

  // Email confirmation after signup
  String get confirmEmailTitle =>
      t('Check your inbox', 'आफ्नो इनबक्स हेर्नुहोस्');
  String confirmEmailBody(String email) => t(
      'We sent a confirmation link to $email. Open it to activate your account, then log in.',
      'हामीले $email मा पुष्टि लिङ्क पठाएका छौं। खाता सक्रिय गर्न लिङ्क खोल्नुहोस्, अनि लग इन गर्नुहोस्।');
  String get confirmEmailSpamHint => t(
      "Can't find it? Check your spam or promotions folder.",
      'भेटिएन? स्प्याम वा प्रमोसन फोल्डर हेर्नुहोस्।');
  String get goToLogin => t('Go to login', 'लग इनमा जानुहोस्');
  String get useDifferentEmail =>
      t('Use a different email', 'अर्को इमेल प्रयोग गर्नुहोस्');

  // Forgot password
  String get forgotTitle => t('Reset your password', 'पासवर्ड रिसेट गर्नुहोस्');
  String get forgotSubtitle => t(
      "Enter the email you signed up with. We'll send you a link to set a new password.",
      'खाता बनाउँदा प्रयोग गरेको इमेल लेख्नुहोस्। नयाँ पासवर्ड राख्ने लिङ्क पठाउनेछौं।');
  String get sendResetLink => t('Send reset link', 'रिसेट लिङ्क पठाउनुहोस्');
  String get resetSentTitle => t('Check your email', 'आफ्नो इमेल हेर्नुहोस्');
  String resetSentBody(String email) => t("We've sent a reset link to $email.",
      'हामीले $email मा रिसेट लिङ्क पठाएका छौं।');
  String get resetSentHint => t(
      "Open the link on this device to choose a new password. Didn't get it? Check spam, or send it again.",
      'नयाँ पासवर्ड राख्न यही डिभाइसमा लिङ्क खोल्नुहोस्। आएन? स्प्याम हेर्नुहोस् वा फेरि पठाउनुहोस्।');
  String get resendLink => t('Send again', 'फेरि पठाउनुहोस्');
  String get resendDone => t('We sent the link again', 'लिङ्क फेरि पठाइयो');

  // Set new password
  String get resetTitle => t('Set a new password', 'नयाँ पासवर्ड राख्नुहोस्');
  String get resetSubtitle => t('Choose a strong password you will remember.',
      'सम्झन सकिने बलियो पासवर्ड छान्नुहोस्।');
  String get newPasswordLabel => t('New password', 'नयाँ पासवर्ड');
  String get confirmNewPasswordLabel =>
      t('Confirm new password', 'नयाँ पासवर्ड पुष्टि गर्नुहोस्');
  String get updatePasswordButton =>
      t('Update password', 'पासवर्ड अपडेट गर्नुहोस्');
  String get passwordUpdated => t("Password updated. You're all set.",
      'पासवर्ड अपडेट भयो। अब तयार हुनुहुन्छ।');

  // Email verification (OTP)
  String get verifyTitle => t('Verify your email', 'इमेल प्रमाणित गर्नुहोस्');
  String verifySubtitle(String email) => t(
      'Enter the 6-digit code we sent to $email',
      '$email मा पठाइएको ६ अंकको कोड लेख्नुहोस्');
  String get codeFieldLabel => t('6-digit code', '६ अंकको कोड');
  String get enterFullCode => t('Enter all 6 digits', 'सबै ६ अंक लेख्नुहोस्');
  String get verifyButton =>
      t('Verify and continue', 'प्रमाणित गरेर जारी राख्नुहोस्');
  String resendIn(int seconds) =>
      t('Resend code in ${seconds}s', '$seconds सेकेन्डपछि फेरि पठाउन सकिन्छ');
  String get resendCode => t('Resend code', 'कोड फेरि पठाउनुहोस्');
  String get didntGetCode =>
      t("Didn't get it? Check spam, or", 'आएन? स्प्याम हेर्नुहोस्, वा');
  String get codeResent => t('A new code is on its way', 'नयाँ कोड पठाइयो');
  String get emailVerified =>
      t('Email verified — welcome!', 'इमेल प्रमाणित भयो — स्वागत छ!');
  String get wrongEmail =>
      t('Wrong email? Sign up again', 'इमेल गलत छ? फेरि साइन अप गर्नुहोस्');
  String get verifyBeforeLogin => t(
      'Please verify your email first — we sent you a new code.',
      'पहिले इमेल प्रमाणित गर्नुहोस् — नयाँ कोड पठाइएको छ।');
}
