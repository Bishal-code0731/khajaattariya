import '../localized_strings.dart';

/// Rider dashboard, deliveries, earnings, cash ledger, registration.
class RiderStrings extends LocalizedStrings {
  const RiderStrings(super.isNe);

  // Shell / navigation
  String get dashboardTitle => t('Rider', 'राइडर');
  String greeting(String name) => t('Hi, $name', 'नमस्ते, $name');
  String get tabDeliveries => t('Deliveries', 'डेलिभरी');
  String get tabEarnings => t('Earnings', 'कमाइ');
  String get tabCash => t('Cash', 'नगद');
  String get tabSchedule => t('Today', 'आज');
  String get tabProfile => t('Vehicle', 'सवारी');
  String get accountTooltip => t('Account & settings', 'खाता र सेटिङ');
  String get statusOnline => t('Online', 'अनलाइन');
  String get statusOffline => t('Offline', 'अफलाइन');
  String get loginRequiredTitle => t('Please log in', 'कृपया लग इन गर्नुहोस्');
  String get loginRequiredBody => t(
      'Log in with your rider account to see deliveries.',
      'डेलिभरी हेर्न राइडर खाताबाट लग इन गर्नुहोस्।');
  String get profileLoadError =>
      t("Couldn't load your rider profile", 'तपाईंको राइडर प्रोफाइल लोड भएन');

  // Online switch
  String get onlineTitle => t("You're online", 'तपाईं अनलाइन हुनुहुन्छ');
  String get onlineSubtitle =>
      t('New deliveries will appear here', 'नयाँ डेलिभरी यहीँ देखिनेछन्');
  String get offlineTitle => t("You're offline", 'तपाईं अफलाइन हुनुहुन्छ');
  String get offlineSubtitle => t(
      'Go online to start getting deliveries', 'डेलिभरी पाउन अनलाइन हुनुहोस्');
  String get lockedSubtitle => t(
      'You can go online once your account is approved',
      'खाता स्वीकृत भएपछि अनलाइन हुन सक्नुहुन्छ');
  String get goOnline => t('Go online', 'अनलाइन हुनुहोस्');
  String get goOffline => t('Go offline', 'अफलाइन हुनुहोस्');
  String get wentOnline => t("You're online. Ride safe.",
      'तपाईं अनलाइन हुनुभयो। सुरक्षित चलाउनुहोस्।');
  String get wentOffline =>
      t("You're offline. See you soon.", 'तपाईं अफलाइन हुनुभयो। फेरि भेटौँला।');

  // Approval / registration state
  String get approvalPendingTitle =>
      t('Waiting for approval', 'स्वीकृतिको प्रतीक्षामा');
  String get approvalPendingBody => t(
      'Our team is checking your details. You can go online once approved.',
      'हाम्रो टोलीले तपाईंको विवरण जाँच गर्दैछ। स्वीकृत भएपछि अनलाइन हुन सक्नुहुन्छ।');
  String get approvalRejectedTitle => t('Changes needed', 'सुधार आवश्यक');
  String get approvalRejectedBody => t(
      'Please update your vehicle details and our team will check again.',
      'कृपया सवारीको विवरण सुधार गर्नुहोस्, हाम्रो टोलीले फेरि जाँच गर्नेछ।');
  String get adminNote => t('Note from the team', 'टोलीको टिप्पणी');
  String get approvedTitle => t('Approved rider', 'स्वीकृत राइडर');
  String get approvedBody => t('You can go online and take deliveries.',
      'तपाईं अनलाइन भएर डेलिभरी लिन सक्नुहुन्छ।');
  String get notRegisteredTitle =>
      t('Register your vehicle', 'आफ्नो सवारी दर्ता गर्नुहोस्');
  String get notRegisteredBody => t(
      'Add your vehicle details to start delivering.',
      'डेलिभरी सुरु गर्न सवारीको विवरण थप्नुहोस्।');
  String get registerNow => t('Register now', 'अहिले दर्ता गर्नुहोस्');
  String get viewDetails => t('View details', 'विवरण हेर्नुहोस्');

  // Active delivery
  String get activeDelivery => t('Active delivery', 'चालु डेलिभरी');
  String get stepPickedUp => t('Picked up', 'उठाइयो');
  String get stepDelivered => t('Delivered', 'डेलिभर भयो');
  String get pickupFrom => t('Pick up', 'उठाउने ठाउँ');
  String get dropAt => t('Drop off', 'पुर्‍याउने ठाउँ');
  String get noAddress => t('Address not given', 'ठेगाना दिइएको छैन');
  String get customerNote => t('Customer note', 'ग्राहकको टिप्पणी');
  String get itemsTitle => t('Items', 'परिकारहरू');
  String itemsCount(int n) =>
      t(n == 1 ? '1 item' : '$n items', '$n वटा परिकार');
  String get orderTotal => t('Order total', 'अर्डरको जम्मा');
  String collectCash(String amount) =>
      t('Collect $amount cash', '$amount नगद लिनुहोस्');
  String get collectCashHint =>
      t('Customer pays in cash at the door', 'ग्राहकले ढोकामा नगद तिर्नुहुन्छ');
  String get paidOnline => t('Paid online. Nothing to collect.',
      'अनलाइन भुक्तानी भइसक्यो। केही लिनु पर्दैन।');
  String get paidOnlineTag => t('Paid online', 'अनलाइन भुक्तानी');
  String get cashTag => t('Cash', 'नगद');
  String get openInMaps => t('Open in maps', 'नक्सामा खोल्नुहोस्');
  String get callSupport => t('Call support', 'सहायतामा फोन');
  String get getHelp => t('Get help', 'सहायता लिनुहोस्');
  String get callRestaurant => t('Call restaurant', 'रेस्टुरेन्टमा फोन');
  String get markDelivered => t('Mark delivered', 'डेलिभर भयो');
  String get confirmDeliveredTitle =>
      t('Mark this order delivered?', 'यो अर्डर डेलिभर भयो?');
  String confirmDeliveredCash(String amount) => t(
      "Only confirm after you've handed over the food and collected $amount in cash.",
      'खाना बुझाएर $amount नगद लिइसकेपछि मात्र पुष्टि गर्नुहोस्।');
  String get confirmDeliveredOnline => t(
      "Only confirm after you've handed over the food.",
      'खाना बुझाइसकेपछि मात्र पुष्टि गर्नुहोस्।');
  String get deliveredSuccess =>
      t('Delivered. Nice work!', 'डेलिभर भयो। राम्रो काम!');
  String get couldNotOpenMaps =>
      t("Couldn't open maps on this device.", 'यो उपकरणमा नक्सा खुलेन।');
  String get couldNotCall =>
      t("Couldn't start a call on this device.", 'यो उपकरणबाट फोन गर्न सकिएन।');

  // Available orders
  String get availableTitle => t('Ready for pickup', 'लैजान तयार');
  String availableSubtitle(int n) => t(
      n == 1 ? '1 order waiting' : '$n orders waiting',
      '$n अर्डर पर्खिरहेका छन्');
  String get youEarn => t('You earn', 'तपाईंको कमाइ');
  String get accept => t('Accept', 'स्वीकार गर्नुहोस्');
  String get acceptedSuccess => t('Order accepted. Head to the restaurant.',
      'अर्डर स्वीकार भयो। रेस्टुरेन्टतर्फ जानुहोस्।');
  String get alreadyTaken => t('Another rider just took this order.',
      'अर्को राइडरले भर्खरै यो अर्डर लिनुभयो।');
  String cashLimitReached(String limit) => t(
      "You'd go over your $limit cash limit. Hand over cash first.",
      'यसले तपाईंको $limit नगद सीमा नाघ्छ। पहिले नगद बुझाउनुहोस्।');
  String get overCashLimit => t('Over your cash limit', 'नगद सीमाभन्दा बढी');
  String get noOrdersTitle => t('No pickups right now', 'अहिले कुनै पिकअप छैन');
  String get noOrdersBody => t(
      'New orders show up here on their own. Keep the app open.',
      'नयाँ अर्डर आफैँ यहाँ देखिन्छन्। एप खुला राख्नुहोस्।');
  String get offlineEmptyBody => t(
      'Go online to see orders that are ready for pickup.',
      'लैजान तयार अर्डर हेर्न अनलाइन हुनुहोस्।');

  // Earnings
  String get today => t('Today', 'आज');
  String get thisWeek => t('This week', 'यो हप्ता');
  String get totalDeliveries => t('Deliveries', 'जम्मा डेलिभरी');
  String get totalEarned => t('Total earned', 'जम्मा कमाइ');
  String get earningsHistory => t('Earnings history', 'कमाइको विवरण');
  String get earningsHistorySubtitle =>
      t('Your share of each delivery fee', 'हरेक डेलिभरी शुल्कबाट तपाईंको भाग');
  String get paid => t('Paid', 'भुक्तानी भयो');
  String get pending => t('Pending', 'बाँकी');
  String get noEarningsTitle => t('No earnings yet', 'अहिलेसम्म कमाइ छैन');
  String get noEarningsBody => t(
      'Finish a delivery and your earnings show up here.',
      'डेलिभरी सकेपछि तपाईंको कमाइ यहाँ देखिन्छ।');
  String orderLabel(String code) => t('Order $code', 'अर्डर $code');

  // Cash ledger
  String get cashInHand => t('Cash in hand', 'हातमा रहेको नगद');
  String cashLimit(String limit) => t('Limit $limit', 'सीमा $limit');
  String cashLeft(String amount) =>
      t('$amount left before the limit', 'सीमा पुग्न $amount बाँकी');
  String get cashLimitHit => t(
      'Limit reached. Hand over cash to take cash orders again.',
      'सीमा पुग्यो। नगद अर्डर फेरि लिन नगद बुझाउनुहोस्।');
  String get cashNearLimit => t('Close to your limit. Hand over cash soon.',
      'सीमा नजिक छ। छिट्टै नगद बुझाउनुहोस्।');
  String pendingSettlement(String amount) =>
      t('$amount waiting for confirmation', '$amount पुष्टिको प्रतीक्षामा');
  String get settleTitle => t('Hand over cash', 'नगद बुझाउनुहोस्');
  String get settleBody => t(
      'Give the cash to the Khaja Attariya office, then send a request here. The team confirms it.',
      'खाजा अत्तरियाको कार्यालयमा नगद बुझाएर यहाँबाट अनुरोध पठाउनुहोस्। टोलीले पुष्टि गर्नेछ।');
  String get settleAmount => t('Amount', 'रकम');
  String settleAmountHelper(String max) =>
      t('You can hand over up to $max', 'तपाईं बढीमा $max बुझाउन सक्नुहुन्छ');
  String get settleNote => t('Note (optional)', 'टिप्पणी (ऐच्छिक)');
  String get settleNoteField => t('Note', 'टिप्पणी');
  String get settleNoteHint =>
      t('e.g. Handed to office on Monday', 'जस्तै: सोमबार कार्यालयमा बुझाएँ');
  String get settleSubmit =>
      t('Request settlement', 'फछ्र्यौट अनुरोध गर्नुहोस्');
  String get settleSuccess => t(
      'Request sent. It counts once the team confirms it.',
      'अनुरोध पठाइयो। टोलीले पुष्टि गरेपछि गनिन्छ।');
  String get amountMustBePositive =>
      t('Enter an amount above 0', '० भन्दा बढी रकम लेख्नुहोस्');
  String amountTooHigh(String max) =>
      t('You can hand over up to $max', 'तपाईं बढीमा $max बुझाउन सक्नुहुन्छ');
  String get nothingToSettle =>
      t('No cash to hand over right now.', 'अहिले बुझाउनुपर्ने नगद छैन।');
  String get ledgerTitle => t('Cash history', 'नगदको विवरण');
  String get ledgerSubtitle =>
      t('Cash you collected and handed over', 'तपाईंले उठाएको र बुझाएको नगद');
  String get entryCollected => t('Cash collected', 'नगद उठाइयो');
  String get entrySettlement => t('Handed over', 'नगद बुझाइयो');
  String get statusConfirmed => t('Confirmed', 'पुष्टि भयो');
  String get statusRejected => t('Rejected', 'अस्वीकृत');
  String get noLedgerTitle => t('No cash yet', 'अहिलेसम्म नगद छैन');
  String get noLedgerBody => t(
      'Cash from cash-on-delivery orders shows up here.',
      'नगद भुक्तानी अर्डरको नगद यहाँ देखिन्छ।');

  // Schedule
  String get scheduleTitle => t("Today's deliveries", 'आजका डेलिभरी');
  String get scheduleSubtitle =>
      t('Time spent at each step', 'हरेक चरणमा लागेको समय');
  String get noScheduleTitle =>
      t('No deliveries yet today', 'आज अहिलेसम्म डेलिभरी छैन');
  String get noScheduleBody => t('Jobs you accept show up here as a timeline.',
      'तपाईंले स्वीकार गरेका काम यहाँ समयरेखामा देखिन्छन्।');
  String deliveriesCount(int n) =>
      t(n == 1 ? '1 delivery' : '$n deliveries', '$n डेलिभरी');
  String get scheduleError =>
      t("Couldn't load today's schedule", 'आजको तालिका लोड भएन');

  // Vehicle / profile
  String get vehicleTitle => t('Your vehicle', 'तपाईंको सवारी');
  String get vehicleType => t('Vehicle type', 'सवारीको प्रकार');
  String get vehicleNumber => t('Vehicle number', 'सवारी नम्बर');
  String get vehicleNumberOptional =>
      t('Vehicle number (optional)', 'सवारी नम्बर (ऐच्छिक)');
  String get vehicleNumberHint => t('e.g. SE 1 PA 2345', 'जस्तै: से १ प २३४५');
  String get vehicleNumberBicycleHelper =>
      t('Not needed for a bicycle', 'साइकलका लागि आवश्यक छैन');
  String get vehicleMotorcycle => t('Motorbike', 'मोटरसाइकल');
  String get vehicleScooter => t('Scooter', 'स्कुटर');
  String get vehicleBicycle => t('Bicycle', 'साइकल');
  String get vehicleCar => t('Car', 'कार');
  String get vehicleOther => t('Other', 'अन्य');
  String vehicleTypeLabel(String type) => switch (type) {
        'motorcycle' => vehicleMotorcycle,
        'scooter' => vehicleScooter,
        'bicycle' => vehicleBicycle,
        'car' => vehicleCar,
        _ => vehicleOther,
      };
  String get registerTitle =>
      t('Deliver with Khaja Attariya', 'खाजा अत्तरियासँग डेलिभरी गर्नुहोस्');
  String get registerBody => t(
      'Tell us about your vehicle. Our team approves new riders before their first delivery.',
      'आफ्नो सवारीबारे बताउनुहोस्। पहिलो डेलिभरीअघि हाम्रो टोलीले नयाँ राइडर स्वीकृत गर्छ।');
  String get submitForApproval =>
      t('Submit for approval', 'स्वीकृतिका लागि पेश गर्नुहोस्');
  String get updateDetails => t('Update details', 'विवरण अपडेट गर्नुहोस्');
  String get editVehicle => t('Edit vehicle', 'सवारी सम्पादन');
  String get registeredSuccess => t(
      "Submitted. You can go online once you're approved.",
      'पेश भयो। स्वीकृत भएपछि अनलाइन हुन सक्नुहुन्छ।');
  String get vehicleUpdated =>
      t('Vehicle details updated', 'सवारीको विवरण अपडेट भयो');
  String get accountSettings => t('Account & settings', 'खाता र सेटिङ');
  String get notAdded => t('Not added', 'थपिएको छैन');
  String get logoutConfirmTitle => t('Log out?', 'लग आउट गर्ने?');
  String get logoutConfirmBody => t(
      "You won't get deliveries until you log in again.",
      'फेरि लग इन नगरेसम्म डेलिभरी पाउनुहुने छैन।');
}
