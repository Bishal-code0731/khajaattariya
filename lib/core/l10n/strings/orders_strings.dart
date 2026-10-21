import '../localized_strings.dart';

/// Orders, order detail, payment, tracking, ratings, refunds.
class OrderStrings extends LocalizedStrings {
  const OrderStrings(super.isNe);

  // Orders list
  String get myOrders => t('Your orders', 'तपाईंका अर्डरहरू');
  String get tabActive => t('Active', 'चालु');
  String get tabPast => t('Past', 'पुराना');
  String get loginTitle =>
      t('Log in to see your orders', 'अर्डरहरू हेर्न लग इन गर्नुहोस्');
  String get loginBody => t('Track deliveries and reorder your favourites.',
      'डेलिभरी ट्र्याक गर्नुहोस् र मनपर्ने खाना फेरि मगाउनुहोस्।');
  String get noActiveTitle =>
      t('Nothing on the way', 'अहिले कुनै अर्डर बाटोमा छैन');
  String get noActiveBody => t('Hungry? Your next meal is a few taps away.',
      'भोक लाग्यो? अर्को खाना केही ट्यापमै आइपुग्छ।');
  String get noPastTitle =>
      t('No past orders yet', 'अहिलेसम्म पुराना अर्डर छैनन्');
  String get noPastBody => t(
      'Delivered and cancelled orders will show up here.',
      'डेलिभर भएका र रद्द भएका अर्डरहरू यहाँ देखिनेछन्।');
  String get browseRestaurants =>
      t('Browse restaurants', 'रेस्टुरेन्टहरू हेर्नुहोस्');
  String itemsCount(int n) =>
      t(n == 1 ? '1 item' : '$n items', '$n वटा परिकार');
  String get orderAgain => t('Order again', 'फेरि मगाउनुहोस्');
  String get rate => t('Rate', 'मूल्याङ्कन');
  String get unknownRestaurant => t('Restaurant', 'रेस्टुरेन्ट');
  String orderCardLabel(String restaurant, String status) =>
      t('Order from $restaurant, $status', '$restaurant बाट अर्डर, $status');

  // Order detail: header & progress
  String orderTitle(String code) => t('Order $code', 'अर्डर $code');
  String placedOn(String when) => t('Placed $when', '$when मा राखिएको');
  String get stepPlaced => t('Placed', 'राखियो');
  String get stepAccepted => t('Accepted', 'स्वीकृत');
  String get stepPreparing => t('Preparing', 'पाक्दैछ');
  String get stepReady => t('Ready', 'तयार');
  String get stepOnTheWay => t('On the way', 'बाटोमा');
  String get stepDelivered => t('Delivered', 'डेलिभर');
  String stepDone(String step, String time) =>
      t('$step, done at $time', '$step, $time मा सम्पन्न');
  String stepCurrent(String step) => t('$step, in progress', '$step, हुँदैछ');
  String stepUpcoming(String step) => t('$step, not yet', '$step, अझै बाँकी');
  String get hintPendingCustomer => t(
      "Waiting for the restaurant to accept. You can cancel until they do.",
      'रेस्टुरेन्टले स्वीकार गर्ने प्रतीक्षामा। स्वीकार नगरेसम्म तपाईं रद्द गर्न सक्नुहुन्छ।');
  String get hintPending => t('Waiting for the restaurant to accept.',
      'रेस्टुरेन्टले स्वीकार गर्ने प्रतीक्षामा।');
  String get hintConfirmed => t(
      'Accepted. The kitchen will start on it shortly.',
      'स्वीकार भयो। भान्छाले छिट्टै पकाउन सुरु गर्नेछ।');
  String get hintPreparing => t(
      'Being cooked now. This usually takes 15–25 min.',
      'अहिले पाक्दैछ। सामान्यतया १५–२५ मिनेट लाग्छ।');
  String get hintReady => t('Packed and waiting for a rider to pick it up.',
      'प्याक भयो, राइडरले लैजाने प्रतीक्षामा छ।');
  String get hintPickedUp => t(
      'Your rider is on the way. Keep your phone nearby.',
      'राइडर बाटोमा हुनुहुन्छ। फोन नजिकै राख्नुहोस्।');
  String get hintPickedUpOther => t('The rider is on the way to the customer.',
      'राइडर ग्राहकतर्फ जाँदै हुनुहुन्छ।');
  String deliveredAt(String time) => t('Delivered at $time. Enjoy your meal.',
      '$time मा डेलिभर भयो। मीठो गरी खानुहोस्।');
  String deliveredAtOther(String time) =>
      t('Delivered at $time.', '$time मा डेलिभर भयो।');
  String get hintCancelled =>
      t('This order was cancelled.', 'यो अर्डर रद्द भयो।');
  String cancelledAt(String time) =>
      t('Cancelled at $time', '$time मा रद्द भयो');
  String cancelReasonLine(String reason) =>
      t('Reason: $reason', 'कारण: $reason');
  String get orderCancelledTitle => t('Order cancelled', 'अर्डर रद्द भयो');

  // Order detail: sections
  String get sectionItems => t('Items', 'परिकारहरू');
  String get sectionBill => t('Bill details', 'बिल विवरण');
  String get itemTotal => t('Item total', 'परिकारको जम्मा');
  String get deliveryFee => t('Delivery fee', 'डेलिभरी शुल्क');
  String get discount => t('Discount', 'छुट');
  String get total => t('Total', 'जम्मा');
  String get sectionPayment => t('Payment', 'भुक्तानी');
  String get sectionDelivery => t('Deliver to', 'डेलिभरी ठेगाना');
  String get sectionNotes => t('Note for the restaurant', 'रेस्टुरेन्टलाई नोट');
  String get noAddress => t('No address given', 'ठेगाना दिइएको छैन');
  String get callRestaurant =>
      t('Call restaurant', 'रेस्टुरेन्टलाई फोन गर्नुहोस्');
  String get callFailed => t("Couldn't open the phone app.", 'फोन एप खुलेन।');
  String get orderNotFoundTitle =>
      t("We couldn't find this order", 'यो अर्डर फेला परेन');
  String get orderNotFoundBody => t(
      'It may have been removed, or you may not have access to it.',
      'यो हटाइएको हुन सक्छ, वा तपाईंलाई यसको पहुँच नहुन सक्छ।');
  String get backToOrders => t('Back to your orders', 'अर्डरहरूमा फर्कनुहोस्');

  // Payment method & status
  String get methodCash => t('Cash on delivery', 'डेलिभरीमा नगद');
  String get methodKhalti => t('Khalti', 'खल्ती');
  String get methodEsewa => t('eSewa', 'इसेवा');
  String get payPaid => t('Paid', 'भुक्तानी भयो');
  String get payOnDelivery => t('Pay on delivery', 'डेलिभरीमा तिर्नुहोस्');
  String get payPending => t('Payment pending', 'भुक्तानी बाँकी');
  String get payFailed => t('Payment failed', 'भुक्तानी असफल');
  String get payRefunded => t('Refunded', 'रकम फिर्ता भयो');

  // Order detail: actions
  String get trackRider => t('Track rider', 'राइडर ट्र्याक गर्नुहोस्');
  String get payNow => t('Pay now', 'अहिले तिर्नुहोस्');
  String get cancelOrder => t('Cancel order', 'अर्डर रद्द गर्नुहोस्');
  String get cancelConfirmTitle =>
      t('Cancel this order?', 'यो अर्डर रद्द गर्ने?');
  String get cancelConfirmBody => t(
      "The restaurant hasn't started on it yet. If you already paid online, you can request a refund afterwards.",
      'रेस्टुरेन्टले अझै तयार गर्न थालेको छैन। अनलाइन तिरिसक्नुभएको भए पछि रकम फिर्ता माग्न सक्नुहुन्छ।');
  String get keepOrder => t('Keep order', 'अर्डर राख्नुहोस्');
  String get cancelledSuccess => t('Order cancelled', 'अर्डर रद्द भयो');
  String get cancelTooLate => t(
      "The restaurant has already accepted this order, so it can't be cancelled here. Get help from support.",
      'रेस्टुरेन्टले यो अर्डर स्वीकार गरिसकेको छ, त्यसैले यहाँबाट रद्द गर्न मिल्दैन। सहायता टोलीलाई सम्पर्क गर्नुहोस्।');
  String get rateOrder => t('Rate order', 'अर्डरको मूल्याङ्कन गर्नुहोस्');
  String get youRated => t('You rated this order. Thank you!',
      'तपाईंले यो अर्डरको मूल्याङ्कन गर्नुभयो। धन्यवाद!');
  String get needHelp => t('Need help?', 'सहायता चाहियो?');
  String get getHelp =>
      t('Get help with this order', 'यो अर्डरबारे सहायता लिनुहोस्');
  String get getHelpBody => t('Missing items, late delivery or anything else',
      'नआएका परिकार, ढिलो डेलिभरी वा अरू कुनै समस्या');
  String get requestRefund => t('Request a refund', 'रकम फिर्ता माग्नुहोस्');
  String get requestRefundBody => t('For paid orders that went wrong',
      'तिरिसकेको तर समस्या भएको अर्डरका लागि');
  String get refundPending =>
      t('Refund requested, under review', 'रकम फिर्ता माग गरियो, जाँच हुँदैछ');
  String get refundApproved => t('Refund approved', 'रकम फिर्ता स्वीकृत भयो');
  String get refundRejected =>
      t('Refund request declined', 'रकम फिर्ता अनुरोध अस्वीकृत भयो');
  String get refundProcessed => t('Refund sent', 'रकम फिर्ता पठाइयो');

  // Refund sheet
  String get refundTitle => t('Request a refund', 'रकम फिर्ता माग्नुहोस्');
  String refundBody(String amount) => t(
      "Tell us what went wrong. We'll review it and refund up to $amount to how you paid.",
      'के समस्या भयो बताउनुहोस्। हामी जाँच गरेर बढीमा $amount तपाईंले तिरेकै माध्यममा फिर्ता गर्नेछौं।');
  String get refundReasonField => t('What went wrong?', 'के समस्या भयो?');
  String get refundReasonHint => t('e.g. Two items were missing from my order',
      'जस्तै: मेरो अर्डरमा दुईवटा परिकार आएनन्');
  String get sendRequest => t('Send request', 'अनुरोध पठाउनुहोस्');
  String get refundSent => t("Refund requested. We'll review it soon.",
      'रकम फिर्ताको अनुरोध पठाइयो। हामी छिट्टै जाँच गर्नेछौं।');
  String get refundNoPayment => t(
      'This order has no completed payment to refund.',
      'यो अर्डरमा फिर्ता गर्नुपर्ने भुक्तानी छैन।');
  String get refundAlreadyOpen => t(
      'You already have a refund request open for this order.',
      'यो अर्डरका लागि रकम फिर्ता अनुरोध पहिले नै खुला छ।');

  // Rate sheet
  String rateTitle(String restaurant) =>
      t('How was $restaurant?', '$restaurant कस्तो लाग्यो?');
  String get rateSubtitle => t(
      'Your rating helps others choose and helps the restaurant improve.',
      'तपाईंको मूल्याङ्कनले अरूलाई छान्न र रेस्टुरेन्टलाई सुधार गर्न मद्दत गर्छ।');
  String starLabel(int n) => t(n == 1 ? '1 star' : '$n stars', '$n तारा');
  String get tapToRate =>
      t('Tap a star to rate', 'मूल्याङ्कन गर्न तारामा थिच्नुहोस्');
  String get rating1 => t('Poor', 'नराम्रो');
  String get rating2 => t('Not great', 'त्यति राम्रो होइन');
  String get rating3 => t('Okay', 'ठीकै');
  String get rating4 => t('Good', 'राम्रो');
  String get rating5 => t('Excellent', 'उत्कृष्ट');
  String get tagsTitle =>
      t('What stood out? (optional)', 'के कुरा राम्रो लाग्यो? (ऐच्छिक)');
  String get tagTasty => t('Tasty food', 'मीठो खाना');
  String get tagFresh => t('Hot and fresh', 'तातो र ताजा');
  String get tagPortion => t('Good portion', 'पर्याप्त मात्रा');
  String get tagPacking => t('Well packed', 'राम्रो प्याकिङ');
  String get tagFast => t('Fast delivery', 'छिटो डेलिभरी');
  String get tagRider => t('Friendly rider', 'मिलनसार राइडर');
  String get reviewField => t('Comment (optional)', 'टिप्पणी (ऐच्छिक)');
  String get reviewHint => t('What did you like, or what could be better?',
      'के मन पर्यो, वा के अझ राम्रो हुन सक्थ्यो?');
  String get submitRating => t('Submit rating', 'मूल्याङ्कन पठाउनुहोस्');
  String get ratingThanks =>
      t('Thanks for rating your order', 'मूल्याङ्कनका लागि धन्यवाद');
  String get alreadyRated => t("You've already rated this order.",
      'तपाईंले यो अर्डरको मूल्याङ्कन गरिसक्नुभएको छ।');
  String get pickRatingFirst =>
      t('Choose a star rating first.', 'पहिले तारा छान्नुहोस्।');

  // Payment screen
  String get paymentTitle => t('Payment', 'भुक्तानी');
  String paymentSubtitle(int n) => t(
      n == 1 ? '1 order' : '$n orders, paid together',
      n == 1 ? '१ अर्डर' : '$n अर्डर, एकैपटक भुक्तानी');
  String get howToPay =>
      t('How would you like to pay?', 'कसरी तिर्न चाहनुहुन्छ?');
  String get cashSubtitle => t('Pay the rider in cash when your food arrives',
      'खाना आइपुगेपछि राइडरलाई नगद दिनुहोस्');
  String get khaltiSubtitle => t(
      'Pay now with your Khalti wallet', 'खल्ती वालेटबाट अहिले नै तिर्नुहोस्');
  String get esewaSubtitle =>
      t('Pay now with your eSewa wallet', 'इसेवा वालेटबाट अहिले नै तिर्नुहोस्');
  String get comingSoon => t('Coming soon', 'छिट्टै आउँदैछ');
  String get summaryTitle => t('Order summary', 'अर्डर सारांश');
  String get totalToPay => t('To pay', 'तिर्नुपर्ने');
  String get serverTotalsNote => t(
      'Prices, fees and discounts are confirmed by Khaja Attariya.',
      'मूल्य, शुल्क र छुट खाजा अत्तरियाले पुष्टि गर्छ।');
  String payAmount(String amount) => t('Pay $amount', '$amount तिर्नुहोस्');
  String get placeOrderCash =>
      t('Place order (Cash)', 'अर्डर पक्का गर्नुहोस् (नगद)');
  String get cashSuccess => t('Order placed. Pay the rider when it arrives.',
      'अर्डर पक्का भयो। खाना आएपछि राइडरलाई तिर्नुहोस्।');
  String get khaltiWaitingTitle =>
      t('Finish paying in Khalti', 'खल्तीमा भुक्तानी पूरा गर्नुहोस्');
  String get khaltiWaitingBody => t(
      "We'll pick it up automatically when you come back.",
      'तपाईं फर्केपछि हामी आफैं भुक्तानी जाँच गर्छौं।');
  String get checkPayment =>
      t('I have paid, check now', 'मैले तिरें, अहिले जाँच गर्नुहोस्');
  String get reopenKhalti => t('Open Khalti again', 'खल्ती फेरि खोल्नुहोस्');
  String get khaltiOpenFailed => t("Couldn't open Khalti. Please try again.",
      'खल्ती खुलेन। कृपया फेरि प्रयास गर्नुहोस्।');
  String get khaltiReceived => t("Payment received — we're confirming it.",
      'भुक्तानी प्राप्त भयो — हामी पुष्टि गर्दैछौं।');
  String get khaltiStillPending => t(
      "Khalti hasn't confirmed the payment yet. If you paid, wait a moment and check again.",
      'खल्तीले अझै भुक्तानी पुष्टि गरेको छैन। तिर्नुभएको भए केही बेर पर्खेर फेरि जाँच गर्नुहोस्।');
  String get khaltiFailed => t(
      'The Khalti payment was cancelled or expired. You can try again.',
      'खल्ती भुक्तानी रद्द भयो वा म्याद सकियो। फेरि प्रयास गर्न सक्नुहुन्छ।');
  String get paymentInProgress => t(
      'A payment for this order is already in progress. Wait a few minutes and try again, or pay with cash.',
      'यो अर्डरको भुक्तानी पहिले नै हुँदैछ। केही मिनेट पर्खेर फेरि प्रयास गर्नुहोस्, वा नगद रोज्नुहोस्।');
  String get alreadyPaid =>
      t('This order is already paid.', 'यो अर्डरको भुक्तानी भइसकेको छ।');
  String get gatewayUnavailable => t(
      "The payment service isn't responding. Please try again or pay with cash.",
      'भुक्तानी सेवाले जवाफ दिएन। फेरि प्रयास गर्नुहोस् वा नगद रोज्नुहोस्।');
  String get noMethods => t(
      'No payment methods are available right now. Please try again later.',
      'अहिले कुनै भुक्तानी विकल्प उपलब्ध छैन। केही बेरपछि प्रयास गर्नुहोस्।');
  String get esewaUnavailable => t(
      "eSewa payments aren't available in this version of the app yet.",
      'इसेवा भुक्तानी यो संस्करणमा अझै उपलब्ध छैन।');
  String get debugEnterPidx =>
      t('Enter Khalti pidx (debug)', 'खल्ती pidx लेख्नुहोस् (डिबग)');
  String get pidxField => t('pidx', 'pidx');
  String get verify => t('Verify', 'जाँच गर्नुहोस्');
  String get selected => t('Selected', 'छानिएको');

  // Tracking
  String get trackTitle => t('Track order', 'अर्डर ट्र्याक गर्नुहोस्');
  String riderUpdated(String ago) =>
      t('Rider location updated $ago', 'राइडरको स्थान $ago अपडेट भयो');
  String get waitingForRiderTitle =>
      t("Waiting for the rider's location", 'राइडरको स्थानको प्रतीक्षामा');
  String get waitingForRiderBody => t(
      'The map will show your rider as soon as they share their location.',
      'राइडरले स्थान पठाउनेबित्तिकै नक्सामा देखिनेछ।');
  String get riderMarker => t('Rider', 'राइडर');
  String get restaurantMarker => t('Restaurant', 'रेस्टुरेन्ट');
  String get contactSupport => t('Contact support', 'सहायता सम्पर्क');
  String get viewOrder => t('Order details', 'अर्डर विवरण');
  String get recenter => t('Show rider', 'राइडर देखाउनुहोस्');
  String get trackingDelivered =>
      t('This order has been delivered.', 'यो अर्डर डेलिभर भइसक्यो।');
  String get trackingCancelled =>
      t('This order was cancelled.', 'यो अर्डर रद्द भयो।');
  String get mapAttribution =>
      t('OpenStreetMap contributors', 'OpenStreetMap योगदानकर्ताहरू');
}
