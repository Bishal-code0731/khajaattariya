import '../localized_strings.dart';

/// Restaurant dashboard, menu, hours, analytics, registration.
class RestaurantStrings extends LocalizedStrings {
  const RestaurantStrings(super.isNe);

  // Dashboard shell
  String get dashboardTitle =>
      t('Restaurant dashboard', 'रेस्टुरेन्ट ड्यासबोर्ड');
  String get navOrders => t('Orders', 'अर्डर');
  String get navTimeline => t('Timeline', 'टाइमलाइन');
  String get navAnalytics => t('Analytics', 'विश्लेषण');
  String get navSettings => t('Settings', 'सेटिङ');
  String get loginRequiredTitle =>
      t('Log in to your restaurant', 'आफ्नो रेस्टुरेन्टमा लग इन गर्नुहोस्');
  String get loginRequiredBody => t(
      'Use your restaurant owner account to see orders and your menu.',
      'अर्डर र मेनु हेर्न रेस्टुरेन्ट मालिकको खाताबाट लग इन गर्नुहोस्।');

  // Open / closed
  String get open => t('Open', 'खुला');
  String get closed => t('Closed', 'बन्द');
  String get takingOrders => t('Taking orders', 'अर्डर लिँदै');
  String get notTakingOrders => t('Not taking orders', 'अर्डर लिइँदैन');
  String get openSwitchLabel =>
      t('Restaurant open for orders', 'रेस्टुरेन्ट अर्डरका लागि खुला');
  String get closeConfirmTitle =>
      t('Stop taking orders?', 'अर्डर लिन बन्द गर्ने?');
  String get closeConfirmMessage => t(
      "Customers can't order from you until you open again. Orders already placed stay on your board.",
      'फेरि नखोलेसम्म ग्राहकले तपाईंबाट अर्डर गर्न सक्दैनन्। आइसकेका अर्डर बोर्डमै रहन्छन्।');
  String get closeConfirmAction =>
      t('Close restaurant', 'रेस्टुरेन्ट बन्द गर्नुहोस्');
  String get nowOpenToast => t("You're open — new orders can come in",
      'तपाईं खुला हुनुहुन्छ — नयाँ अर्डर आउन सक्छन्');
  String get nowClosedToast =>
      t("You're closed for new orders", 'नयाँ अर्डरका लागि बन्द गरियो');

  // Approval
  String get pendingTitle => t('Submitted — waiting for admin approval',
      'पेश गरियो — एडमिनको स्वीकृतिको प्रतीक्षामा');
  String get pendingBody => t(
      "Customers will see your restaurant once it's approved. Set up your menu and hours meanwhile.",
      'स्वीकृत भएपछि ग्राहकले तपाईंको रेस्टुरेन्ट देख्नेछन्। त्यतिन्जेल मेनु र खुल्ने समय मिलाउनुहोस्।');
  String get rejectedTitle =>
      t('Your restaurant is not live', 'तपाईंको रेस्टुरेन्ट अहिले देखिँदैन');
  String get rejectedBody => t(
      'Update your details below, or contact support if you have questions.',
      'तलको विवरण सुधार्नुहोस्, वा प्रश्न भए सहायतामा सम्पर्क गर्नुहोस्।');
  String rejectedNote(String note) =>
      t('Note from the admin: $note', 'एडमिनको नोट: $note');

  // Quick links
  String get quickMenu => t('Menu', 'मेनु');
  String get quickHours => t('Opening hours', 'खुल्ने समय');
  String get quickAccount => t('Account', 'खाता');
  String get logoutConfirmTitle => t('Log out?', 'लग आउट गर्ने?');
  String get logoutConfirmMessage => t(
      "You won't see new orders on this device until you log in again.",
      'फेरि लग इन नगरेसम्म यो डिभाइसमा नयाँ अर्डर देखिँदैन।');

  // Orders board
  String get filterNew => t('New', 'नयाँ');
  String get filterPreparing => t('Preparing', 'तयार हुँदै');
  String get filterReady => t('Ready', 'तयार');
  String get filterDone => t('Done today', 'आज सकिएका');
  String get accept => t('Accept', 'स्वीकार गर्नुहोस्');
  String get reject => t('Reject', 'अस्वीकार');
  String get startPreparing => t('Start preparing', 'पकाउन सुरु गर्नुहोस्');
  String get markReady => t('Mark ready', 'तयार भयो');
  String get waitingForRider => t('Waiting for rider', 'राइडरको प्रतीक्षामा');
  String get withRider => t('With the rider', 'राइडरसँग');
  String get rejectTitle => t('Reject this order?', 'यो अर्डर अस्वीकार गर्ने?');
  String get rejectMessage => t(
      "The customer will be told you can't take it. This can't be undone.",
      'ग्राहकलाई तपाईंले अर्डर लिन नसक्ने जानकारी दिइनेछ। यो फिर्ता गर्न मिल्दैन।');
  String get rejectConfirm => t('Reject order', 'अर्डर अस्वीकार गर्नुहोस्');
  String get acceptedToast => t('Order accepted', 'अर्डर स्वीकार गरियो');
  String get rejectedToast => t('Order rejected', 'अर्डर अस्वीकार गरियो');
  String get preparingToast =>
      t('Marked as preparing', 'पकाउँदै भनी चिनो लगाइयो');
  String get readyToast => t(
      'Marked ready — a rider will pick it up', 'तयार भयो — राइडरले लैजानेछन्');
  String itemsCount(int n) =>
      n == 1 ? t('1 item', '१ परिकार') : t('$n items', '$n परिकार');
  String get customerNote => t('Customer note', 'ग्राहकको नोट');
  String waitingMinutes(int n) => t('Waiting $n min', '$n मिनेटदेखि पर्खिँदै');
  String get openOrderHint =>
      t('Open order details', 'अर्डरको विवरण खोल्नुहोस्');
  String todayStrip(int orders, String revenue) =>
      t('Today: $orders delivered · $revenue', 'आज: $orders डेलिभर · $revenue');
  String get emptyNewTitle => t('No new orders', 'नयाँ अर्डर छैन');
  String get emptyNewBody => t(
      'New orders appear here instantly. Keep this screen open during service.',
      'नयाँ अर्डर यहाँ तुरुन्तै देखिन्छन्। सेवा समयमा यो स्क्रिन खुला राख्नुहोस्।');
  String get emptyPreparingTitle =>
      t('Nothing in the kitchen', 'भान्सामा केही छैन');
  String get emptyPreparingBody => t(
      "Accepted orders stay here until they're ready.",
      'स्वीकार गरिएका अर्डर तयार नहुन्जेल यहाँ रहन्छन्।');
  String get emptyReadyTitle =>
      t('Nothing waiting for pickup', 'लैजान बाँकी केही छैन');
  String get emptyReadyBody => t('Orders you mark ready wait here for a rider.',
      'तयार भनिएका अर्डर राइडर नआउन्जेल यहाँ रहन्छन्।');
  String get emptyDoneTitle =>
      t('No finished orders today', 'आज सकिएको अर्डर छैन');
  String get emptyDoneBody => t(
      "Today's delivered and cancelled orders show here.",
      'आजका डेलिभर र रद्द भएका अर्डर यहाँ देखिन्छन्।');

  // Timeline
  String get timelineTitle => t('Kitchen timeline', 'भान्साको टाइमलाइन');
  String get timelineSubtitle => t(
      'Time each active order has spent in every step. Tap a row to open the order.',
      'हरेक सक्रिय अर्डरले प्रत्येक चरणमा लगाएको समय। अर्डर खोल्न लाइनमा थिच्नुहोस्।');
  String get timelineEmptyTitle => t('No active orders', 'सक्रिय अर्डर छैन');
  String get timelineEmptyBody => t(
      'Orders in progress show their prep timeline here.',
      'चलिरहेका अर्डरको तयारी समय यहाँ देखिन्छ।');

  // Analytics
  String get analyticsTitle => t('Analytics', 'विश्लेषण');
  String get analyticsSubtitle => t(
      'Last 30 days · delivered orders', 'पछिल्लो ३० दिन · डेलिभर भएका अर्डर');
  String get exportCsv => t('Export CSV', 'CSV निर्यात');
  String exportSubject(String name) =>
      t('$name — sales export', '$name — बिक्री विवरण');
  String get exportNothing =>
      t('Nothing to export yet', 'निर्यात गर्ने डेटा अझै छैन');
  String get kpiToday => t('Today', 'आज');
  String get kpiWeek => t('Last 7 days', 'पछिल्लो ७ दिन');
  String get kpiMonth => t('Last 30 days', 'पछिल्लो ३० दिन');
  String ordersCount(int n) =>
      n == 1 ? t('1 order', '१ अर्डर') : t('$n orders', '$n अर्डर');
  String get kpiAverageOrder => t('Average order', 'औसत अर्डर');
  String get kpiCancellation => t('Cancellation rate', 'रद्द दर');
  String get kpiCustomers => t('Customers', 'ग्राहक');
  String repeatCustomers(int n) => t('$n came back', '$n जना फेरि आए');
  String get chartRevenue =>
      t('Revenue, last 30 days', 'आम्दानी, पछिल्लो ३० दिन');
  String chartRevenueSemantics(String total) => t(
      'Revenue chart for the last 30 days, total $total',
      'पछिल्लो ३० दिनको आम्दानी चार्ट, जम्मा $total');
  String get chartPeakHours => t('Busiest hours', 'सबैभन्दा व्यस्त समय');
  String get chartPeakHoursHint =>
      t('Orders by hour of the day', 'दिनको घण्टा अनुसार अर्डर');
  String peakHourSemantics(int hour, int orders) => t(
      'Busiest at $hour:00 with $orders orders',
      '$hour:०० बजे सबैभन्दा व्यस्त, $orders अर्डर');
  String get chartOutcomes => t('Order outcomes', 'अर्डरको नतिजा');
  String get outcomeInProgress => t('In progress', 'चलिरहेका');
  String get topDishes => t('Top dishes', 'धेरै बिक्ने परिकार');
  String soldCount(int n) => t('$n sold', '$n बिक्री');
  String get noSalesTitle => t('No sales yet', 'अहिलेसम्म बिक्री छैन');
  String get noSalesBody => t('Charts fill in as orders are delivered.',
      'अर्डर डेलिभर हुँदै जाँदा चार्ट भरिँदै जान्छ।');
  String get notEnoughHistory => t('Not enough orders yet for deeper insights.',
      'थप विश्लेषणका लागि अझै पर्याप्त अर्डर छैनन्।');

  // Restaurant details form
  String get detailsTitle => t('Restaurant details', 'रेस्टुरेन्टको विवरण');
  String get detailsSubtitle => t('What customers see on your restaurant page.',
      'तपाईंको रेस्टुरेन्ट पेजमा ग्राहकले देख्ने कुरा।');
  String get fieldRestaurantName => t('Restaurant name', 'रेस्टुरेन्टको नाम');
  String get hintRestaurantName => t('e.g. Khaja Ghar', 'जस्तै: खाजा घर');
  String get fieldCuisine => t('Cuisine', 'खानाको प्रकार');
  String get hintCuisine => t('e.g. Nepali, Momo', 'जस्तै: नेपाली, मम');
  String get cuisineHelper => t('Tap a suggestion or type your own',
      'सुझाव छान्नुहोस् वा आफैं लेख्नुहोस्');
  String get hintAddress => t('Street, tole, Attariya', 'सडक, टोल, अत्तरिया');
  String get fieldDeliveryTime =>
      t('Usual delivery time (minutes)', 'सामान्य डेलिभरी समय (मिनेट)');
  String get deliveryTimeHelper =>
      t('Between 5 and 240 minutes', '५ देखि २४० मिनेटसम्म');
  String get fieldOffer => t('Offer line (optional)', 'अफर (ऐच्छिक)');
  String get hintOffer =>
      t('e.g. 10% off momo on Fridays', 'जस्तै: शुक्रबार ममोमा १०% छुट');
  String get offerHelper =>
      t('Shown on your restaurant card', 'तपाईंको रेस्टुरेन्ट कार्डमा देखिन्छ');
  String get detailsSaved =>
      t('Restaurant details saved', 'रेस्टुरेन्टको विवरण सेभ भयो');

  /// Suggestions are stored in English so data stays consistent.
  static const cuisineSuggestions = [
    'Nepali',
    'Thakali',
    'Newari',
    'Momo',
    'Indian',
    'Chinese',
    'Fast food',
    'Bakery',
    'Sweets',
    'Cafe',
  ];

  String cuisineLabel(String key) => switch (key) {
        'Nepali' => t('Nepali', 'नेपाली'),
        'Thakali' => t('Thakali', 'थकाली'),
        'Newari' => t('Newari', 'नेवारी'),
        'Momo' => t('Momo', 'मम'),
        'Indian' => t('Indian', 'भारतीय'),
        'Chinese' => t('Chinese', 'चाइनिज'),
        'Fast food' => t('Fast food', 'फास्ट फुड'),
        'Bakery' => t('Bakery', 'बेकरी'),
        'Sweets' => t('Sweets', 'मिठाई'),
        'Cafe' => t('Cafe', 'क्याफे'),
        _ => key,
      };

  // Photo upload
  String get logoLabel => t('Logo or cover photo', 'लोगो वा कभर फोटो');
  String get photoHelper =>
      t('JPG, PNG or WebP, up to 1 MB', 'JPG, PNG वा WebP, बढीमा १ MB');
  String get uploadPhoto => t('Upload photo', 'फोटो अपलोड गर्नुहोस्');
  String get changePhoto => t('Change photo', 'फोटो बदल्नुहोस्');
  String get removePhoto => t('Remove photo', 'फोटो हटाउनुहोस्');
  String get photoUploaded => t('Photo uploaded', 'फोटो अपलोड भयो');

  // Registration
  String get registerTitle =>
      t('Set up your restaurant', 'आफ्नो रेस्टुरेन्ट सेटअप गर्नुहोस्');
  String get registerSubtitle => t(
      'Tell us about your place. Our team checks every restaurant before customers can see it.',
      'आफ्नो ठाउँबारे बताउनुहोस्। ग्राहकले देख्नुअघि हाम्रो टोलीले हरेक रेस्टुरेन्ट जाँच गर्छ।');
  String get registerSubmit =>
      t('Submit for approval', 'स्वीकृतिका लागि पेश गर्नुहोस्');
  String get nextStepsTitle => t('What happens next', 'अब के हुन्छ');
  String get nextStep1 =>
      t('You submit your details', 'तपाईं विवरण पेश गर्नुहुन्छ');
  String get nextStep2 =>
      t('An admin reviews and approves', 'एडमिनले जाँचेर स्वीकृत गर्छन्');
  String get nextStep3 => t('You add your menu and start taking orders',
      'मेनु थपेर अर्डर लिन सुरु गर्नुहुन्छ');
  String get registerSubmitted => t('Submitted — waiting for admin approval',
      'पेश गरियो — एडमिनको स्वीकृतिको प्रतीक्षामा');

  // Menu management
  String get menuTitle => t('Menu', 'मेनु');
  String dishesCount(int n) =>
      n == 1 ? t('1 dish', '१ परिकार') : t('$n dishes', '$n परिकार');
  String hiddenCount(int n) => t('$n hidden', '$n लुकाइएको');
  String get searchDishes => t('Search dishes', 'परिकार खोज्नुहोस्');
  String get addDish => t('Add dish', 'परिकार थप्नुहोस्');
  String get emptyMenuTitle =>
      t('Add your first dish', 'पहिलो परिकार थप्नुहोस्');
  String get emptyMenuBody => t(
      'Start with your bestsellers. Good photos and clear prices help customers decide.',
      'धेरै बिक्ने परिकारबाट सुरु गर्नुहोस्। राम्रो फोटो र स्पष्ट मूल्यले ग्राहकलाई छान्न सजिलो हुन्छ।');
  String noSearchResults(String q) =>
      t('No dishes match "$q"', '"$q" सँग मिल्ने परिकार छैन');
  String get otherDishes => t('Other dishes', 'अन्य परिकार');
  String get available => t('Available', 'उपलब्ध');
  String get hidden => t('Hidden', 'लुकाइएको');
  String availabilitySemantics(String name, bool isAvailable) => isAvailable
      ? t('$name is available. Double tap to hide it.',
          '$name उपलब्ध छ। लुकाउन दुई पटक थिच्नुहोस्।')
      : t('$name is hidden. Double tap to show it.',
          '$name लुकाइएको छ। देखाउन दुई पटक थिच्नुहोस्।');
  String nowAvailable(String name) =>
      t('$name is back on the menu', '$name फेरि मेनुमा छ');
  String nowHidden(String name) =>
      t('$name is hidden from customers', '$name ग्राहकबाट लुकाइयो');
  String get veg => t('Veg', 'शाकाहारी');
  String get nonVeg => t('Non-veg', 'मांसाहारी');
  String get editDish => t('Edit dish', 'परिकार सम्पादन');
  String get deleteDish => t('Delete dish', 'परिकार मेटाउनुहोस्');
  String deleteDishTitle(String name) => t('Delete $name?', '$name मेटाउने?');
  String get deleteDishMessage => t(
      'It will be removed from your menu for good. To take it off for a while, hide it instead.',
      'यो मेनुबाट सधैंका लागि हट्नेछ। केही समयका लागि मात्र हटाउन लुकाउनुहोस्।');
  String get dishDeleted => t('Dish deleted', 'परिकार मेटाइयो');
  String get dishInUseTitle =>
      t("This dish can't be deleted", 'यो परिकार मेटाउन मिल्दैन');
  String get dishInUseMessage => t(
      'It is part of past orders. Hide it from the menu instead — customers will no longer see it.',
      'यो पुराना अर्डरमा समावेश छ। बरु मेनुबाट लुकाउनुहोस् — ग्राहकले अब देख्ने छैनन्।');
  String get hideFromMenu => t('Hide from menu', 'मेनुबाट लुकाउनुहोस्');

  // Dish form
  String get newDishTitle => t('New dish', 'नयाँ परिकार');
  String get editDishTitle => t('Edit dish', 'परिकार सम्पादन');
  String get dishPhoto => t('Dish photo', 'परिकारको फोटो');
  String get dishPhotoHelper => t(
      'A clear, well-lit photo sells more. JPG, PNG or WebP, up to 1 MB.',
      'सफा, उज्यालो फोटोले बढी बिक्री हुन्छ। JPG, PNG वा WebP, बढीमा १ MB।');
  String get fieldDishName => t('Dish name', 'परिकारको नाम');
  String get hintDishName =>
      t('e.g. Chicken steam momo', 'जस्तै: चिकेन स्टिम मम');
  String get fieldDescription => t('Description (optional)', 'विवरण (ऐच्छिक)');
  String get fieldDescriptionShort => t('Description', 'विवरण');
  String get hintDescription => t('What is in it, portion size, spice level',
      'के-के छ, कति मात्रा, कति पिरो');
  String get fieldPriceRs => t('Price (Rs)', 'मूल्य (रु)');
  String get fieldCategory => t('Category', 'वर्ग');
  String get noCategory => t('No category', 'वर्ग छैन');
  String get fieldVeg => t('Vegetarian', 'शाकाहारी');
  String get vegHelper => t('Shows a green veg mark to customers',
      'ग्राहकलाई हरियो शाकाहारी चिनो देखिन्छ');
  String get fieldDishOffer => t('Offer tag (optional)', 'अफर ट्याग (ऐच्छिक)');
  String get fieldDishOfferShort => t('Offer tag', 'अफर ट्याग');
  String get hintDishOffer =>
      t('e.g. Bestseller, 10% off', 'जस्तै: बेस्टसेलर, १०% छुट');
  String get addToMenu => t('Add to menu', 'मेनुमा थप्नुहोस्');
  String get dishAdded => t('Dish added to your menu', 'परिकार मेनुमा थपियो');
  String get dishUpdated => t('Dish updated', 'परिकार अपडेट भयो');
  String get offerField => t('Offer', 'अफर');

  // Opening hours
  String get hoursTitle => t('Opening hours', 'खुल्ने समय');
  String get hoursSubtitle => t('Customers see these times on your page',
      'ग्राहकले यो समय तपाईंको पेजमा देख्छन्');
  String weekday(int weekday) => switch (weekday) {
        1 => t('Monday', 'सोमबार'),
        2 => t('Tuesday', 'मंगलबार'),
        3 => t('Wednesday', 'बुधबार'),
        4 => t('Thursday', 'बिहीबार'),
        5 => t('Friday', 'शुक्रबार'),
        6 => t('Saturday', 'शनिबार'),
        _ => t('Sunday', 'आइतबार'),
      };
  String get opensAt => t('Opens', 'खुल्छ');
  String get closesAt => t('Closes', 'बन्द हुन्छ');
  String get closedAllDay => t('Closed all day', 'दिनभर बन्द');
  String get copyMondayToAll =>
      t('Copy Monday to all days', 'सोमबारको समय सबै दिनमा राख्नुहोस्');
  String get mondayCopied =>
      t("Monday's hours copied to every day", 'सोमबारको समय सबै दिनमा राखियो');
  String closeBeforeOpen(String day) => t(
      '$day: closing time must be after opening time',
      '$day: बन्द हुने समय खुल्ने समयपछि हुनुपर्छ');
  String get closeBeforeOpenShort => t(
      'Closing time must be after opening time',
      'बन्द हुने समय खुल्ने समयपछि हुनुपर्छ');
  String get hoursSaved => t('Opening hours saved', 'खुल्ने समय सेभ भयो');
  String get saveHours => t('Save hours', 'समय सेभ गर्नुहोस्');
  String changeOpenTime(String day) =>
      t('Change opening time for $day', '$day को खुल्ने समय बदल्नुहोस्');
  String changeCloseTime(String day) =>
      t('Change closing time for $day', '$day को बन्द हुने समय बदल्नुहोस्');
  String dayOpenSwitch(String day) => t('$day open', '$day खुला');
  String get unsavedChanges =>
      t('You have unsaved changes', 'सेभ नगरिएका परिवर्तन छन्');
}
