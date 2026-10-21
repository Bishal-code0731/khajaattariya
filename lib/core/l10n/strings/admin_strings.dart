import '../localized_strings.dart';

/// Admin console: navigation, every section, dialogs, audit labels.
class AdminStrings extends LocalizedStrings {
  const AdminStrings(super.isNe);

  // Shell
  String get consoleTitle => t('Admin console', 'एडमिन कन्सोल');
  String get consoleSubtitle =>
      t('Khaja Attariya operations', 'खाजा अत्तरिया सञ्चालन');
  String get refresh => t('Refresh', 'रिफ्रेस गर्नुहोस्');
  String get logout => t('Log out', 'लग आउट');
  String get logoutConfirmTitle =>
      t('Log out of the admin console?', 'एडमिन कन्सोलबाट लग आउट गर्ने?');
  String get sections => t('Sections', 'खण्डहरू');

  // Section names
  String get navOverview => t('Overview', 'सारांश');
  String get navUsers => t('Users', 'प्रयोगकर्ता');
  String get navRestaurants => t('Restaurants', 'रेस्टुरेन्ट');
  String get navRiders => t('Riders', 'राइडर');
  String get navOrders => t('Orders', 'अर्डर');
  String get navCoupons => t('Coupons', 'कुपन');
  String get navSupport => t('Support', 'सहायता');
  String get navRefunds => t('Refunds', 'फिर्ता');
  String get navCash => t('Cash', 'नगद');
  String get navAudit => t('Audit log', 'अडिट लग');
  String get navSettings => t('Settings', 'सेटिङ');

  // Section subtitles
  String get subOverview => t('Today across the platform', 'आज प्लेटफर्मभरि');
  String get subUsers => t('Accounts and access', 'खाता र पहुँच');
  String get subRestaurants =>
      t('Approvals, visibility, featuring', 'स्वीकृति, देखिने स्थिति, फिचर');
  String get subRiders =>
      t('Approvals and cash in hand', 'स्वीकृति र हातमा भएको नगद');
  String get subOrders => t('Latest 100 orders', 'पछिल्ला १०० अर्डर');
  String get subCoupons => t('Discount codes', 'छुट कोडहरू');
  String get subSupport => t('Customer tickets', 'ग्राहकका टिकट');
  String get subRefunds => t('Refund requests', 'फिर्ता अनुरोधहरू');
  String get subCash => t('Rider cash settlements', 'राइडर नगद मिलान');
  String get subAudit => t('Who changed what', 'कसले के परिवर्तन गर्‍यो');
  String get subSettings => t('Platform configuration', 'प्लेटफर्म कन्फिगरेसन');

  // Generic bits
  String get all => t('All', 'सबै');
  String get unknown => t('Unknown', 'थाहा छैन');
  String get noPhone => t('No phone', 'फोन छैन');
  String get approve => t('Approve', 'स्वीकृत गर्नुहोस्');
  String get reject => t('Reject', 'अस्वीकार गर्नुहोस्');
  String get approved => t('Approved', 'स्वीकृत');
  String get rejected => t('Rejected', 'अस्वीकृत');
  String get pending => t('Pending', 'बाँकी');
  String get active => t('Active', 'सक्रिय');
  String get inactive => t('Inactive', 'निष्क्रिय');
  String get noResults => t('No matches', 'मिल्दो केही भेटिएन');
  String get noResultsHint => t(
      'Try another search or filter.', 'अर्को खोज वा फिल्टर प्रयास गर्नुहोस्।');
  String get notePrompt => t('Reason', 'कारण');
  String get noteHint => t('Tell them what to fix, e.g. menu photos missing',
      'के सुधार्नुपर्छ लेख्नुहोस्, जस्तै मेनु फोटो छैन');
  String get noteHelper => t('Shared with the applicant. 5–300 characters.',
      'आवेदकलाई देखाइन्छ। ५–३०० अक्षर।');
  String rejectedNote(String note) => t('Rejected: $note', 'अस्वीकृत: $note');
  String get actionDone => t('Done', 'भयो');

  // Overview
  String get kpiOrdersToday => t('Orders today', 'आजका अर्डर');
  String get kpiDeliveredToday => t('Delivered today', 'आज डेलिभर');
  String get kpiRevenueToday =>
      t('Delivered value today', 'आज डेलिभर भएको रकम');
  String get kpiActiveRestaurants =>
      t('Active restaurants', 'सक्रिय रेस्टुरेन्ट');
  String get kpiPendingApprovals =>
      t('Waiting for approval', 'स्वीकृति कुर्दै');
  String get kpiOpenTickets => t('Open tickets', 'खुला टिकट');
  String get kpiPendingRefunds => t('Pending refunds', 'बाँकी फिर्ता');
  String get kpiPendingCash => t('Cash to confirm', 'पुष्टि गर्न बाँकी नगद');
  String get needsAttention => t('Needs attention', 'ध्यान चाहिन्छ');
  String get needsAttentionHint =>
      t('Tap a tile to open its queue', 'लाइन खोल्न टाइल थिच्नुहोस्');
  String get todayHeading => t('Today', 'आज');
  String get timelineTitle => t('Order flow', 'अर्डर प्रवाह');
  String timelineSubtitle(int n) => t(
      'Last $n orders, from placed to delivered',
      'पछिल्ला $n अर्डर, राखेदेखि डेलिभरसम्म');
  String get timelineEmpty =>
      t('No orders to chart yet', 'चार्ट गर्न अर्डर छैन');
  String restaurantsAndRiders(int r, int d) =>
      t('$r restaurants · $d riders', '$r रेस्टुरेन्ट · $d राइडर');

  // Users
  String get searchUsers =>
      t('Search by name or phone', 'नाम वा फोनबाट खोज्नुहोस्');
  String get roleCustomer => t('Customer', 'ग्राहक');
  String get roleRestaurant => t('Restaurant', 'रेस्टुरेन्ट');
  String get roleRider => t('Rider', 'राइडर');
  String get roleAdmin => t('Admin', 'एडमिन');
  String get rolesCustomers => t('Customers', 'ग्राहक');
  String get rolesRestaurants => t('Restaurants', 'रेस्टुरेन्ट');
  String get rolesRiders => t('Riders', 'राइडर');
  String get rolesAdmins => t('Admins', 'एडमिन');
  String get banned => t('Banned', 'प्रतिबन्धित');
  String get ban => t('Ban', 'प्रतिबन्ध');
  String get unban => t('Unban', 'प्रतिबन्ध हटाउनुहोस्');
  String get you => t('You', 'तपाईं');
  String banTitle(String name) => t('Ban $name?', '$name लाई प्रतिबन्ध गर्ने?');
  String get banMessage => t(
      'They will be signed out and cannot use the app until you unban them.',
      'उहाँ लग आउट हुनुहुनेछ र प्रतिबन्ध नहटाएसम्म एप चलाउन सक्नुहुने छैन।');
  String unbanTitle(String name) =>
      t('Unban $name?', '$name को प्रतिबन्ध हटाउने?');
  String get unbanMessage => t('They can sign in and use the app again.',
      'उहाँ फेरि लग इन गरेर एप चलाउन सक्नुहुन्छ।');
  String get userBanned => t('User banned', 'प्रयोगकर्ता प्रतिबन्धित भयो');
  String get userUnbanned =>
      t('User can sign in again', 'प्रयोगकर्ता फेरि लग इन गर्न सक्नुहुन्छ');
  String get usersEmpty => t('No users yet', 'अहिलेसम्म प्रयोगकर्ता छैनन्');
  String joined(String date) => t('Joined $date', '$date मा जोडिएको');

  // Restaurants
  String get restaurantsPendingEmpty =>
      t('No restaurants waiting', 'कुनै रेस्टुरेन्ट कुरिरहेको छैन');
  String get restaurantsPendingEmptyHint => t(
      'New sign-ups will appear here for review.',
      'नयाँ दर्ता समीक्षाका लागि यहाँ देखिन्छन्।');
  String get restaurantsEmpty =>
      t('No restaurants here', 'यहाँ रेस्टुरेन्ट छैन');
  String owner(String name) => t('Owner: $name', 'मालिक: $name');
  String get featured => t('Featured', 'फिचर गरिएको');
  String get featureOnHome => t('Feature on home', 'गृहपृष्ठमा फिचर');
  String get deactivate => t('Deactivate', 'निष्क्रिय गर्नुहोस्');
  String get reactivate => t('Reactivate', 'फेरि सक्रिय गर्नुहोस्');
  String approveRestaurantTitle(String name) =>
      t('Approve $name?', '$name स्वीकृत गर्ने?');
  String get approveRestaurantMessage => t(
      'It will go live for customers right away.',
      'यो तुरुन्तै ग्राहकहरूलाई देखिनेछ।');
  String rejectRestaurantTitle(String name) =>
      t('Reject $name', '$name अस्वीकार गर्नुहोस्');
  String deactivateTitle(String name) =>
      t('Deactivate $name?', '$name निष्क्रिय गर्ने?');
  String get deactivateMessage => t(
      'It will be hidden from customers and cannot take new orders.',
      'यो ग्राहकबाट लुकाइनेछ र नयाँ अर्डर लिन सक्दैन।');
  String get restaurantApproved =>
      t('Restaurant approved', 'रेस्टुरेन्ट स्वीकृत भयो');
  String get restaurantRejected =>
      t('Restaurant rejected', 'रेस्टुरेन्ट अस्वीकृत भयो');
  String get restaurantDeactivated =>
      t('Restaurant hidden', 'रेस्टुरेन्ट लुकाइयो');
  String get restaurantReactivated =>
      t('Restaurant is live again', 'रेस्टुरेन्ट फेरि सक्रिय भयो');
  String get featuredOn =>
      t('Now featured on home', 'अब गृहपृष्ठमा फिचर गरिएको');
  String get featuredOff => t('Removed from featured', 'फिचरबाट हटाइयो');

  // Riders
  String get ridersPendingEmpty =>
      t('No riders waiting', 'कुनै राइडर कुरिरहेको छैन');
  String get ridersPendingEmptyHint => t(
      'Rider sign-ups will appear here for review.',
      'राइडर दर्ता समीक्षाका लागि यहाँ देखिन्छन्।');
  String get ridersEmpty =>
      t('No approved riders yet', 'अहिलेसम्म स्वीकृत राइडर छैनन्');
  String get online => t('Online', 'अनलाइन');
  String get offline => t('Offline', 'अफलाइन');
  String deliveries(int n) => t('$n deliveries', '$n डेलिभरी');
  String cashInHand(String amount) =>
      t('Cash in hand $amount', 'हातमा नगद $amount');
  String get overCashLimit => t('Over cash limit', 'नगद सीमा नाघ्यो');
  String vehicle(String type) => switch (type) {
        'motorcycle' => t('Motorcycle', 'मोटरसाइकल'),
        'scooter' => t('Scooter', 'स्कुटर'),
        'bicycle' => t('Bicycle', 'साइकल'),
        'car' => t('Car', 'कार'),
        _ => t('Other vehicle', 'अन्य सवारी'),
      };
  String approveRiderTitle(String name) =>
      t('Approve $name?', '$name स्वीकृत गर्ने?');
  String get approveRiderMessage => t('They can go online and take deliveries.',
      'उहाँ अनलाइन भएर डेलिभरी लिन सक्नुहुन्छ।');
  String rejectRiderTitle(String name) =>
      t('Reject $name', '$name अस्वीकार गर्नुहोस्');
  String get riderApproved => t('Rider approved', 'राइडर स्वीकृत भयो');
  String get riderRejected => t('Rider rejected', 'राइडर अस्वीकृत भयो');

  // Orders
  String get searchOrders => t('Search order code, e.g. A1B2C3D4',
      'अर्डर कोड खोज्नुहोस्, जस्तै A1B2C3D4');
  String get ordersEmpty => t('No orders yet', 'अहिलेसम्म अर्डर छैन');
  String get ordersEmptyHint => t(
      'Orders appear here as soon as customers check out.',
      'ग्राहकले अर्डर गर्नेबित्तिकै यहाँ देखिन्छ।');
  String get payCash => t('Cash', 'नगद');
  String get payKhalti => t('Khalti', 'खल्ती');
  String get payEsewa => t('eSewa', 'इसेवा');
  String customerLine(String name) => t('for $name', '$name का लागि');
  String get openOrder => t('Open order', 'अर्डर खोल्नुहोस्');

  // Coupons
  String get newCoupon => t('New coupon', 'नयाँ कुपन');
  String get editCoupon => t('Edit coupon', 'कुपन सम्पादन');
  String get couponsEmpty => t('No coupons yet', 'अहिलेसम्म कुपन छैन');
  String get couponsEmptyHint =>
      t('Create a code to run a promotion.', 'प्रचारका लागि कोड बनाउनुहोस्।');
  String percentOff(String v) => t('$v% off', '$v% छुट');
  String amountOff(String v) => t('$v off', '$v छुट');
  String upTo(String v) => t('up to $v', 'बढीमा $v');
  String minOrder(String v) => t('Min order $v', 'न्यूनतम अर्डर $v');
  String usage(int used, int? max) => max == null
      ? t('$used used', '$used पटक प्रयोग')
      : t('$used / $max used', '$used / $max प्रयोग');
  String validUntil(String d) => t('Until $d', '$d सम्म');
  String startsOn(String d) => t('Starts $d', '$d देखि सुरु');
  String get noExpiry => t('No end date', 'अन्तिम मिति छैन');
  String get couponLive => t('Live', 'चालु');
  String get couponPaused => t('Paused', 'रोकिएको');
  String get couponExpired => t('Expired', 'म्याद सकियो');
  String get couponScheduled => t('Scheduled', 'तालिकामा');
  String get couponUsedUp => t('Used up', 'सबै प्रयोग भयो');
  String get couponEnabled => t('Coupon is live', 'कुपन चालु भयो');
  String get couponDisabled => t('Coupon paused', 'कुपन रोकियो');
  String get couponSaved => t('Coupon saved', 'कुपन सेभ भयो');
  String get toggleCoupon => t('Coupon on or off', 'कुपन खोल्ने वा बन्द गर्ने');
  String get fieldCode => t('Code', 'कोड');
  String get codeHelper => t('4–20 letters or numbers, e.g. DASHAIN25',
      '४–२० अक्षर वा अंक, जस्तै DASHAIN25');
  String get codeInvalid => t('Use 4–20 capital letters or numbers only',
      '४–२० वटा ठूला अक्षर वा अंक मात्र प्रयोग गर्नुहोस्');
  String get discountType => t('Discount type', 'छुटको प्रकार');
  String get typePercent => t('Percent', 'प्रतिशत');
  String get typeFixed => t('Fixed amount', 'निश्चित रकम');
  String get fieldPercent => t('Discount (%)', 'छुट (%)');
  String get fieldAmount => t('Discount amount (Rs)', 'छुट रकम (रु)');
  String get percentRange => t('Enter 1 to 100', '१ देखि १०० सम्म लेख्नुहोस्');
  String get amountRange => t(
      'Enter more than 0, up to 10,000', '० भन्दा बढी, १०,००० सम्म लेख्नुहोस्');
  String get fieldMinOrder => t('Minimum order (Rs)', 'न्यूनतम अर्डर (रु)');
  String get fieldMaxDiscount => t('Maximum discount (Rs)', 'अधिकतम छुट (रु)');
  String get optionalHelper => t('Optional — leave empty for no limit',
      'ऐच्छिक — सीमा नचाहिए खाली छोड्नुहोस्');
  String get mustBePositive => t('Must be more than 0', '० भन्दा बढी हुनुपर्छ');
  String get fieldMaxUses => t('Total uses', 'जम्मा प्रयोग');
  String get fieldPerCustomer => t('Uses per customer', 'प्रति ग्राहक प्रयोग');
  String get wholeNumberRange => t('Enter a whole number from 1 to 100000',
      '१ देखि १००००० सम्मको पूर्ण अंक लेख्नुहोस्');
  String get perCustomerRange => t('Enter a whole number from 1 to 100',
      '१ देखि १०० सम्मको पूर्ण अंक लेख्नुहोस्');
  String get fieldValidFrom => t('Starts on', 'सुरु मिति');
  String get fieldValidUntil => t('Ends on', 'अन्तिम मिति');
  String get pickDate => t('Pick a date', 'मिति छान्नुहोस्');
  String get clearDate => t('Remove end date', 'अन्तिम मिति हटाउनुहोस्');
  String get untilAfterFrom => t('End date must be after the start date',
      'अन्तिम मिति सुरु मितिपछि हुनुपर्छ');
  String get fieldDescription =>
      t('Note for customers', 'ग्राहकका लागि टिप्पणी');
  String get descriptionHint => t('e.g. Dashain special on all restaurants',
      'जस्तै सबै रेस्टुरेन्टमा दशैं विशेष');
  String get createCoupon => t('Create coupon', 'कुपन बनाउनुहोस्');
  String get codeTaken => t('That code already exists — choose another.',
      'त्यो कोड पहिले नै छ — अर्को छान्नुहोस्।');

  // Support
  String get ticketOpen => t('Open', 'खुला');
  String get ticketInProgress => t('In progress', 'काम हुँदै');
  String get ticketResolved => t('Resolved', 'समाधान भयो');
  String get ticketClosed => t('Closed', 'बन्द');
  String get ticketsEmpty => t('Inbox is clear', 'इनबक्स खाली छ');
  String get ticketsEmptyHint => t('New customer tickets will show up here.',
      'नयाँ ग्राहक टिकट यहाँ देखिन्छन्।');
  String from(String name) => t('From $name', '$name बाट');
  String get selectTicket => t('Select a ticket to read the conversation',
      'कुराकानी पढ्न टिकट छान्नुहोस्');
  String get replyHint => t('Write a reply…', 'जवाफ लेख्नुहोस्…');
  String get replyLabel => t('Reply', 'जवाफ');
  String get send => t('Send', 'पठाउनुहोस्');
  String get internalNote => t('Internal note (customer won’t see it)',
      'आन्तरिक टिप्पणी (ग्राहकले देख्दैनन्)');
  String get internalTag => t('Internal', 'आन्तरिक');
  String get replySent => t('Reply sent', 'जवाफ पठाइयो');
  String get markResolved =>
      t('Mark resolved', 'समाधान भयो भनी चिन्ह लगाउनुहोस्');
  String get closeTicket => t('Close ticket', 'टिकट बन्द गर्नुहोस्');
  String get reopenTicket => t('Reopen', 'फेरि खोल्नुहोस्');
  String get ticketUpdated => t('Ticket updated', 'टिकट अपडेट भयो');
  String get noReplies => t('No replies yet', 'अहिलेसम्म जवाफ छैन');
  String get priorityHigh => t('High priority', 'उच्च प्राथमिकता');
  String get priorityUrgent => t('Urgent', 'अत्यावश्यक');
  String get linkedOrder => t('Linked order', 'सम्बन्धित अर्डर');
  String get conversation => t('Conversation', 'कुराकानी');

  // Refunds
  String get refundsEmpty => t('No refund requests', 'फिर्ता अनुरोध छैन');
  String get refundsEmptyHint => t(
      'Requests from customers will wait here for review.',
      'ग्राहकका अनुरोध समीक्षाका लागि यहाँ आउँछन्।');
  String get handled => t('Handled', 'निपटारा भयो');
  String get refundProcessed => t('Paid out', 'भुक्तानी भयो');
  String reason(String r) => t('Reason: $r', 'कारण: $r');
  String get noReason => t('No reason given', 'कारण दिइएको छैन');
  String orderTotal(String v) => t('Order total $v', 'अर्डर जम्मा $v');
  String approveRefundTitle(String amount) =>
      t('Approve refund of $amount?', '$amount फिर्ता स्वीकृत गर्ने?');
  String get approveRefundMessage => t(
      'The customer will be refunded through their original payment method.',
      'ग्राहकलाई उहाँकै भुक्तानी माध्यमबाट फिर्ता गरिनेछ।');
  String rejectRefundTitle(String amount) =>
      t('Reject refund of $amount?', '$amount फिर्ता अस्वीकार गर्ने?');
  String get rejectRefundMessage => t(
      'The customer keeps the order as charged.',
      'ग्राहकको अर्डर रकम जस्ताको तस्तै रहन्छ।');
  String get refundApproved => t('Refund approved', 'फिर्ता स्वीकृत भयो');
  String get refundRejected => t('Refund rejected', 'फिर्ता अस्वीकृत भयो');

  // Cash settlements
  String get pendingTotal => t('Waiting to confirm', 'पुष्टि गर्न बाँकी');
  String requests(int n) => t('$n requests', '$n अनुरोध');
  String get history => t('History', 'इतिहास');
  String get settlementsEmpty => t('No cash to confirm', 'पुष्टि गर्न नगद छैन');
  String get settlementsEmptyHint => t(
      'When a rider hands over cash, their request appears here.',
      'राइडरले नगद बुझाउँदा अनुरोध यहाँ देखिन्छ।');
  String get historyEmpty => t('No settlements yet', 'अहिलेसम्म मिलान छैन');
  String handedOver(String amount) =>
      t('Handed over $amount', '$amount बुझाएको');
  String nowHolds(String amount) =>
      t('Holds $amount now', 'अहिले $amount हातमा');
  String get confirmReceived =>
      t('Confirm received', 'प्राप्त भयो पुष्टि गर्नुहोस्');
  String confirmSettlementTitle(String amount, String name) =>
      t('Confirm $amount from $name?', '$name बाट $amount पुष्टि गर्ने?');
  String get confirmSettlementMessage => t(
      'Only confirm once the cash is counted and in hand. Their cash balance will go down.',
      'नगद गनेर हातमा आएपछि मात्र पुष्टि गर्नुहोस्। उहाँको नगद बाँकी घट्नेछ।');
  String rejectSettlementTitle(String amount, String name) =>
      t('Reject $amount from $name?', '$name बाट $amount अस्वीकार गर्ने?');
  String get rejectSettlementMessage => t('Their cash balance stays the same.',
      'उहाँको नगद बाँकी जस्ताको तस्तै रहन्छ।');
  String get settlementConfirmed => t('Cash confirmed', 'नगद पुष्टि भयो');
  String get settlementRejected =>
      t('Settlement rejected', 'मिलान अस्वीकृत भयो');
  String get confirmedLabel => t('Confirmed', 'पुष्टि भयो');

  // Audit
  String get auditEmpty => t('No activity yet', 'अहिलेसम्म गतिविधि छैन');
  String get auditEmptyHint => t('Every admin change is recorded here.',
      'एडमिनका सबै परिवर्तन यहाँ रेकर्ड हुन्छन्।');
  String get system => t('System', 'प्रणाली');
  String by(String name) => t('by $name', '$name द्वारा');
  String auditAction(String action) => switch (action) {
        'approve_restaurant' =>
          t('Approved a restaurant', 'रेस्टुरेन्ट स्वीकृत गरियो'),
        'reject_restaurant' =>
          t('Rejected a restaurant', 'रेस्टुरेन्ट अस्वीकृत गरियो'),
        'activate_restaurant' =>
          t('Reactivated a restaurant', 'रेस्टुरेन्ट फेरि सक्रिय गरियो'),
        'deactivate_restaurant' =>
          t('Deactivated a restaurant', 'रेस्टुरेन्ट निष्क्रिय गरियो'),
        'feature_restaurant' =>
          t('Featured a restaurant', 'रेस्टुरेन्ट फिचर गरियो'),
        'unfeature_restaurant' =>
          t('Unfeatured a restaurant', 'रेस्टुरेन्ट फिचरबाट हटाइयो'),
        'approve_rider' => t('Approved a rider', 'राइडर स्वीकृत गरियो'),
        'reject_rider' => t('Rejected a rider', 'राइडर अस्वीकृत गरियो'),
        'ban_user' => t('Banned a user', 'प्रयोगकर्ता प्रतिबन्धित गरियो'),
        'unban_user' => t('Unbanned a user', 'प्रयोगकर्ताको प्रतिबन्ध हटाइयो'),
        'create_coupon' => t('Created a coupon', 'कुपन बनाइयो'),
        'update_coupon' => t('Edited a coupon', 'कुपन सम्पादन गरियो'),
        'enable_coupon' => t('Turned a coupon on', 'कुपन चालु गरियो'),
        'disable_coupon' => t('Paused a coupon', 'कुपन रोकियो'),
        'reply_ticket' => t('Replied to a ticket', 'टिकटमा जवाफ दिइयो'),
        'update_ticket_status' =>
          t('Changed a ticket status', 'टिकटको स्थिति बदलियो'),
        'approve_refund' => t('Approved a refund', 'फिर्ता स्वीकृत गरियो'),
        'reject_refund' => t('Rejected a refund', 'फिर्ता अस्वीकृत गरियो'),
        'confirm_settlement' =>
          t('Confirmed rider cash', 'राइडरको नगद पुष्टि गरियो'),
        'reject_settlement' =>
          t('Rejected rider cash', 'राइडरको नगद अस्वीकृत गरियो'),
        'update_setting' => t('Changed a setting', 'सेटिङ परिवर्तन गरियो'),
        _ => action.replaceAll('_', ' '),
      };
  String auditTarget(String? table) => switch (table) {
        'restaurants' => t('Restaurant', 'रेस्टुरेन्ट'),
        'riders' => t('Rider', 'राइडर'),
        'profiles' => t('User', 'प्रयोगकर्ता'),
        'coupons' => t('Coupon', 'कुपन'),
        'support_tickets' => t('Ticket', 'टिकट'),
        'refunds' => t('Refund', 'फिर्ता'),
        'rider_cash_ledger' => t('Cash settlement', 'नगद मिलान'),
        'platform_settings' => t('Setting', 'सेटिङ'),
        _ => table ?? '',
      };

  // Settings
  String get groupPayments => t('Payment methods', 'भुक्तानी माध्यम');
  String get groupPaymentsHint => t(
      'What customers can choose at checkout', 'चेकआउटमा ग्राहकले छान्न सक्ने');
  String get groupMoney => t('Fees and cash', 'शुल्क र नगद');
  String get groupMoneyHint => t('Used by the server when it prices orders',
      'अर्डरको मूल्य निकाल्दा सर्भरले प्रयोग गर्छ');
  String get groupApp => t('App versions and terms', 'एप संस्करण र सर्तहरू');
  String get groupAppHint =>
      t('Older apps are asked to update', 'पुराना एपलाई अपडेट गर्न भनिन्छ');
  String get setCash => t('Cash on delivery', 'डेलिभरीमा नगद');
  String get setKhalti => t('Khalti', 'खल्ती');
  String get setEsewa => t('eSewa', 'इसेवा');
  String get setDeliveryFee =>
      t('Default delivery fee (Rs)', 'पूर्वनिर्धारित डेलिभरी शुल्क (रु)');
  String get setDeliveryFeeHelper => t('0 to 500', '० देखि ५००');
  String get setCommission =>
      t('Platform commission (%)', 'प्लेटफर्म कमिसन (%)');
  String get setRiderShare => t(
      'Rider share of delivery fee (%)', 'डेलिभरी शुल्कमा राइडरको हिस्सा (%)');
  String get percentHelper => t('0 to 100', '० देखि १००');
  String get setCodLimit =>
      t('Cash a rider may hold (Rs)', 'राइडरले राख्न पाउने नगद (रु)');
  String get setCodLimitHelper => t(
      'Riders over this cannot take new cash orders',
      'यो नाघेका राइडरले नयाँ नगद अर्डर लिन पाउँदैनन्');
  String get setMinVersion => t('Minimum app version', 'न्यूनतम एप संस्करण');
  String get setLatestVersion => t('Latest app version', 'नयाँ एप संस्करण');
  String get versionHelper => t('Format 1.4.0', 'ढाँचा 1.4.0');
  String get setTermsVersion => t('Terms version', 'सर्त संस्करण');
  String get setTermsHelper => t(
      'Changing this asks everyone to accept the terms again',
      'यो बदल्दा सबैलाई फेरि सर्त स्वीकार गर्न भनिन्छ');
  String get versionInvalid =>
      t('Use the format 1.4.0', '1.4.0 ढाँचा प्रयोग गर्नुहोस्');
  String get latestBelowMin => t(
      'Latest version must be the same as or newer than the minimum',
      'नयाँ संस्करण न्यूनतम जत्तिकै वा नयाँ हुनुपर्छ');
  String rangeError(String min, String max) =>
      t('Enter $min to $max', '$min देखि $max सम्म लेख्नुहोस्');
  String get atLeastOnePayment => t('Keep at least one payment method on',
      'कम्तीमा एउटा भुक्तानी माध्यम खुला राख्नुहोस्');
  String get noChanges => t('Nothing to save', 'सेभ गर्न केही छैन');
  String settingsSaved(int n) => t('$n settings saved', '$n सेटिङ सेभ भयो');
  String get unsavedChanges =>
      t('You have unsaved changes', 'सेभ नगरिएका परिवर्तन छन्');
  String get discard => t('Discard', 'हटाउनुहोस्');
}
