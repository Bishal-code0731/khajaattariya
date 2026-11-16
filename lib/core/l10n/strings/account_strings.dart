import '../localized_strings.dart';

/// Profile, addresses, favourites, notifications, support, side menu.
class AccountStrings extends LocalizedStrings {
  const AccountStrings(super.isNe);

  // Account hub
  String get accountTitle => t('Account', 'खाता');
  String get editProfile => t('Edit profile', 'प्रोफाइल सम्पादन');
  String get changePhoto => t('Change photo', 'फोटो बदल्नुहोस्');
  String get photoUpdated =>
      t('Profile photo updated', 'प्रोफाइल फोटो अपडेट भयो');
  String get profileUpdated => t('Profile updated', 'प्रोफाइल अपडेट भयो');
  String get profileUpdateFailed => t(
      "We couldn't save your profile. Please try again.",
      'प्रोफाइल सेभ हुन सकेन। फेरि प्रयास गर्नुहोस्।');
  String get noPhone => t('No phone number added', 'फोन नम्बर थपिएको छैन');
  String get emailReadOnlyHelper =>
      t("Email can't be changed here", 'इमेल यहाँबाट बदल्न मिल्दैन');
  String get uploadingPhoto => t('Uploading photo…', 'फोटो अपलोड हुँदैछ…');

  String get sectionOrders => t('Orders & places', 'अर्डर र ठेगाना');
  String get sectionActivity => t('Activity', 'गतिविधि');
  String get sectionSettings => t('Settings', 'सेटिङ');
  String get sectionWork => t('Your workspace', 'तपाईंको कार्यस्थल');

  String get myOrders => t('My orders', 'मेरा अर्डरहरू');
  String get myOrdersSub => t('Track and reorder', 'ट्र्याक र फेरि अर्डर');
  String get savedAddresses => t('Saved addresses', 'सेभ गरिएका ठेगाना');
  String get savedAddressesSub => t('Home, work and more', 'घर, काम र अन्य');
  String get savedRestaurants =>
      t('Saved restaurants', 'सेभ गरिएका रेस्टुरेन्ट');
  String get savedRestaurantsSub =>
      t('Your favourite places', 'तपाईंका मनपर्ने ठाउँ');
  String get notifications => t('Notifications', 'सूचनाहरू');
  String get notificationsSub =>
      t('Order updates and news', 'अर्डर अपडेट र खबर');
  String get helpSupport => t('Help & support', 'सहायता');
  String get helpSupportSub =>
      t('Ask us about an order or account', 'अर्डर वा खाताबारे सोध्नुहोस्');
  String get backToDashboard =>
      t('Back to dashboard', 'ड्यासबोर्डमा फर्कनुहोस्');
  String get backToDashboardSub =>
      t('Return to your work screen', 'आफ्नो काम गर्ने स्क्रिनमा फर्कनुहोस्');
  String get about => t('About', 'बारेमा');
  String version(String v) => t('Version $v', 'संस्करण $v');
  String get aboutBody => t(
        'Food from Attariya’s favourite kitchens, delivered to your door. Made in Kailali.',
        'अत्तरियाका मनपर्ने भान्साको खाना, सिधै तपाईंको ढोकामा। कैलालीमा बनेको।',
      );
  String get logoutTitle => t('Log out?', 'लग आउट गर्ने?');
  String get logoutMessage => t(
      "You'll need to log in again to order or see your account.",
      'अर्डर गर्न वा खाता हेर्न फेरि लग इन गर्नुपर्नेछ।');
  String get chooseLanguage => t('Choose language', 'भाषा छान्नुहोस्');
  String get chooseAppearance => t('Choose appearance', 'देखावट छान्नुहोस्');
  String get themeSystemHint =>
      t('Match your phone setting', 'फोनको सेटिङ अनुसार');

  // Roles
  String get roleCustomer => t('Customer', 'ग्राहक');
  String get roleRestaurant => t('Restaurant partner', 'रेस्टुरेन्ट साझेदार');
  String get roleRider => t('Delivery rider', 'डेलिभरी राइडर');
  String get roleAdmin => t('Admin', 'एडमिन');

  // Addresses
  String get addressesTitle => t('Saved addresses', 'सेभ गरिएका ठेगाना');
  String get addAddress => t('Add address', 'ठेगाना थप्नुहोस्');
  String get editAddress => t('Edit address', 'ठेगाना सम्पादन');
  String get newAddress => t('New address', 'नयाँ ठेगाना');
  String get noAddressesTitle =>
      t('No saved addresses', 'कुनै ठेगाना सेभ गरिएको छैन');
  String get noAddressesBody => t(
      'Save where you usually eat so checkout takes seconds.',
      'प्रायः खाने ठाउँ सेभ गर्नुहोस्, चेकआउट छिटो हुन्छ।');
  String get labelHome => t('Home', 'घर');
  String get labelWork => t('Work', 'काम');
  String get labelOther => t('Other', 'अन्य');
  String get addressLabel => t('Save as', 'यस रूपमा सेभ');
  String get customLabel => t('Label name', 'लेबलको नाम');
  String get customLabelHint => t('e.g. Mum’s place', 'जस्तै: आमाको घर');
  String get fullAddress => t('Full address', 'पूरा ठेगाना');
  String get fullAddressHint =>
      t('Tole, street, ward — Attariya', 'टोल, सडक, वडा — अत्तरिया');
  String get landmark => t('Landmark (optional)', 'चिनारी ठाउँ (ऐच्छिक)');
  String get landmarkField => t('Landmark', 'चिनारी ठाउँ');
  String get landmarkHint =>
      t('e.g. Opposite Attariya Chowk', 'जस्तै: अत्तरिया चोकको अगाडि');
  String near(String landmark) => t('Near $landmark', '$landmark नजिक');
  String get defaultTag => t('Default', 'मुख्य');
  String get makeDefault => t('Use as default', 'मुख्य बनाउनुहोस्');
  String get makeDefaultHint =>
      t('Selected first at checkout', 'चेकआउटमा पहिले छानिन्छ');
  String get setDefault => t('Set as default', 'मुख्य बनाउनुहोस्');
  String get defaultUpdated =>
      t('Default address updated', 'मुख्य ठेगाना अपडेट भयो');
  String get addressSaved => t('Address saved', 'ठेगाना सेभ भयो');
  String get addressDeleted => t('Address deleted', 'ठेगाना मेटाइयो');
  String get deleteAddressTitle =>
      t('Delete this address?', 'यो ठेगाना मेटाउने?');
  String deleteAddressMessage(String label) => t(
      '"$label" will be removed from your saved addresses.',
      '"$label" तपाईंका सेभ गरिएका ठेगानाबाट हटाइनेछ।');
  String get addressOptions => t('Address options', 'ठेगानाका विकल्प');

  // Favourites
  String get favoritesTitle => t('Saved restaurants', 'सेभ गरिएका रेस्टुरेन्ट');
  String get noFavoritesTitle =>
      t('Nothing saved yet', 'अहिलेसम्म केही सेभ छैन');
  String get noFavoritesBody => t('Tap the heart on a restaurant to save it.',
      'रेस्टुरेन्टमा मुटुको चिन्ह थिचेर सेभ गर्नुहोस्।');
  String get browseRestaurants =>
      t('Browse restaurants', 'रेस्टुरेन्ट हेर्नुहोस्');
  String get removeFavorite => t('Remove from saved', 'सेभबाट हटाउनुहोस्');
  String get favoriteRemoved => t('Removed from saved', 'सेभबाट हटाइयो');
  String get favoriteQueued => t(
      "You're offline — we'll sync this when you're back.",
      'तपाईं अफलाइन हुनुहुन्छ — अनलाइन भएपछि मिलाइनेछ।');
  String savedCount(int n) => t(n == 1 ? '1 place' : '$n places', '$n ठाउँ');
  String deliveryMinutes(int n) => t('$n–${n + 10} min', '$n–${n + 10} मिनेट');
  String get newRestaurant => t('New', 'नयाँ');

  // Notifications
  String get notificationsTitle => t('Notifications', 'सूचनाहरू');
  String get markAllRead => t('Mark all as read', 'सबै पढिएको बनाउनुहोस्');
  String get allMarkedRead => t('All caught up', 'सबै पढियो');
  String get today => t('Today', 'आज');
  String get earlier => t('Earlier', 'पहिले');
  String get noNotificationsTitle =>
      t('No notifications yet', 'अहिलेसम्म कुनै सूचना छैन');
  String get noNotificationsBody =>
      t("Order updates will show up here.", 'अर्डरका अपडेट यहाँ देखिनेछन्।');
  String get notificationDeleted => t('Notification deleted', 'सूचना मेटाइयो');
  String get unread => t('Unread', 'नपढिएको');
  String unreadCount(int n) => t('$n unread', '$n नपढिएका');
  String get swipeToDelete =>
      t('Swipe left to delete', 'मेटाउन बायाँ स्वाइप गर्नुहोस्');

  // Support
  String get supportTitle => t('Help & support', 'सहायता');
  String get supportSubtitle => t(
      'We usually reply within a day', 'हामी प्रायः एक दिनभित्र जवाफ दिन्छौं');
  String get newRequest => t('New request', 'नयाँ अनुरोध');
  String get yourRequests => t('Your requests', 'तपाईंका अनुरोधहरू');
  String get noTicketsTitle =>
      t('No requests yet', 'अहिलेसम्म कुनै अनुरोध छैन');
  String get noTicketsBody => t(
        'Problem with an order or your account? Send us a message.',
        'अर्डर वा खातामा समस्या? हामीलाई सन्देश पठाउनुहोस्।',
      );
  String get subject => t('Subject', 'विषय');
  String get subjectHint =>
      t('e.g. Missing item in my order', 'जस्तै: मेरो अर्डरमा परिकार छुट्यो');
  String get message => t('Message', 'सन्देश');
  String get messageHint => t(
      'Tell us what happened. Include your order code if you have it.',
      'के भयो लेख्नुहोस्। अर्डर कोड भए राख्नुहोस्।');
  String get sendRequest => t('Send request', 'अनुरोध पठाउनुहोस्');
  String get requestSent => t("Request sent. We'll get back to you soon.",
      'अनुरोध पठाइयो। हामी छिट्टै जवाफ दिनेछौं।');
  String get ticketTitle => t('Support request', 'सहायता अनुरोध');
  String get you => t('You', 'तपाईं');
  String get supportTeam => t('Khaja support', 'खाजा सहायता');
  String get replyHint => t('Write a reply…', 'जवाफ लेख्नुहोस्…');
  String get send => t('Send', 'पठाउनुहोस्');
  String get replyRequired =>
      t('Write a message first', 'पहिले सन्देश लेख्नुहोस्');
  String get waitingForReply => t('Our team will reply here soon.',
      'हाम्रो टोलीले यहीँ छिट्टै जवाफ दिनेछ।');
  String get ticketClosedNote => t(
        'This request is closed. Start a new request if you still need help.',
        'यो अनुरोध बन्द भयो। अझै सहायता चाहिए नयाँ अनुरोध पठाउनुहोस्।',
      );
  String updated(String when) => t('Updated $when', '$when अपडेट');
  String opened(String when) => t('Opened $when', '$when खोलिएको');
  String get statusOpen => t('Open', 'खुला');
  String get statusInProgress => t('In progress', 'काम हुँदैछ');
  String get statusResolved => t('Resolved', 'समाधान भयो');
  String get statusClosed => t('Closed', 'बन्द');
}
