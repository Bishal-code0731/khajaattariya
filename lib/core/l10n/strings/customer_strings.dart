import '../localized_strings.dart';

/// Home, search, restaurant page, cart, checkout.
class CustomerStrings extends LocalizedStrings {
  const CustomerStrings(super.isNe);

  // Bottom navigation
  String get navHome => t('Home', 'गृहपृष्ठ');
  String get navSearch => t('Search', 'खोज');
  String get navOrders => t('Orders', 'अर्डर');
  String get navAccount => t('Account', 'खाता');

  // Home header
  String get greetingMorning => t('Good morning', 'शुभ प्रभात');
  String get greetingAfternoon => t('Good afternoon', 'शुभ दिन');
  String get greetingEvening => t('Good evening', 'शुभ साँझ');
  String greetingWithName(String greeting, String name) =>
      t('$greeting, $name', '$greeting, $name');
  String get deliveringIn => t('Delivering in Attariya', 'अत्तरियामा डेलिभरी');
  String get notifications => t('Notifications', 'सूचनाहरू');
  String notificationsUnread(int n) =>
      t('Notifications, $n unread', 'सूचनाहरू, $n नपढिएका');
  String get searchHint => t('Search momo, thali or a restaurant',
      'मःम, थाली वा रेस्टुरेन्ट खोज्नुहोस्');

  // Home sections
  String get categoriesTitle => t('What are you craving?', 'के खान मन छ?');
  String get offersTitle => t('Offers for you', 'तपाईंका लागि अफर');
  String get offerOrderNow => t('Order now', 'अहिले अर्डर गर्नुहोस्');
  String get offerComingSoon => t('This offer opens soon — check back shortly.',
      'यो अफर छिट्टै खुल्छ — केही बेरमा फेरि हेर्नुहोस्।');
  String offerPage(int current, int total) =>
      t('Offer $current of $total', '$total मध्ये $current औं अफर');
  String get popularTitle => t('Popular right now', 'अहिले लोकप्रिय');
  String get popularSubtitle => t('Dishes people in Attariya are ordering',
      'अत्तरियामा धेरैले अर्डर गरिरहेका परिकार');
  String categoryDishesTitle(String category) =>
      t('$category near you', 'नजिकैको $category');
  String noDishesInCategory(String category) => t(
      'No $category dishes are available right now.',
      'अहिले $category परिकार उपलब्ध छैनन्।');
  String get restaurantsTitle =>
      t('Restaurants in Attariya', 'अत्तरियाका रेस्टुरेन्ट');
  String restaurantsServing(String category) =>
      t('Restaurants serving $category', '$category पाइने रेस्टुरेन्ट');
  String restaurantsCount(int n) =>
      t(n == 1 ? '1 place' : '$n places', '$n ठाउँ');
  String get showAllCategories => t('Show all', 'सबै देखाउनुहोस्');
  String get noRestaurantsTitle =>
      t('No restaurants yet', 'अहिले कुनै रेस्टुरेन्ट छैन');
  String get noRestaurantsBody => t(
      'Restaurants in Attariya will appear here as they join.',
      'अत्तरियाका रेस्टुरेन्ट जोडिएपछि यहाँ देखिनेछन्।');
  String get noMatchesTitle =>
      t('Nothing matches these filters', 'यी फिल्टरसँग केही मिलेन');
  String get noMatchesBody => t('Try removing a filter to see more places.',
      'थप ठाउँ हेर्न कुनै फिल्टर हटाउनुहोस्।');
  String get clearFilters => t('Clear filters', 'फिल्टर हटाउनुहोस्');
  String get endOfList =>
      t("That's every restaurant for now", 'अहिलेलाई यति नै रेस्टुरेन्ट छन्');

  // Filters & sort
  String get sort => t('Sort', 'क्रम');
  String get sortBy => t('Sort restaurants by', 'रेस्टुरेन्टको क्रम');
  String get sortRecommended => t('Recommended', 'सिफारिस गरिएको');
  String get sortRating => t('Top rated', 'उच्च रेटिङ');
  String get sortFastest => t('Fastest delivery', 'छिटो डेलिभरी');
  String get filterRating4 => t('Rating 4.0+', 'रेटिङ ४.०+');
  String get filterFast => t('Under 30 min', '३० मिनेटभित्र');
  String get filterOffers => t('Offers', 'अफर');
  String get filterOpenNow => t('Open now', 'अहिले खुला');

  // Restaurant card / info line
  String deliveryMinutes(int n) => t('$n min', '$n मिनेट');
  String deliveryFeeLine(String money) =>
      t('$money delivery', '$money डेलिभरी');
  String get freeDelivery => t('Free delivery', 'निःशुल्क डेलिभरी');
  String get closedNow => t('Closed now', 'अहिले बन्द');
  String get openNow => t('Open now', 'अहिले खुला');
  String get newRestaurant => t('New', 'नयाँ');
  String ratingSemantics(String rating, int count) => t(
      'Rated $rating out of 5 from $count reviews',
      '$count समीक्षाबाट ५ मा $rating रेटिङ');
  String get addFavourite => t('Save to favourites', 'मनपर्नेमा राख्नुहोस्');
  String get removeFavourite =>
      t('Remove from favourites', 'मनपर्नेबाट हटाउनुहोस्');
  String get savedToFavourites => t('Saved to favourites', 'मनपर्नेमा राखियो');
  String get removedFromFavourites =>
      t('Removed from favourites', 'मनपर्नेबाट हटाइयो');

  // Cart actions (shared)
  String get add => t('Add', 'थप्नुहोस्');
  String get soldOut => t('Sold out', 'सकियो');
  String get restaurantClosedCantAdd => t(
      'This restaurant is closed right now. Try again when it opens.',
      'यो रेस्टुरेन्ट अहिले बन्द छ। खुलेपछि फेरि प्रयास गर्नुहोस्।');
  String get viewCart => t('View cart', 'कार्ट हेर्नुहोस्');
  String itemsCount(int n) => t(n == 1 ? '1 item' : '$n items', '$n परिकार');
  String viewCartSemantics(int n, String money) => t(
      'View cart, ${n == 1 ? '1 item' : '$n items'}, $money',
      'कार्ट हेर्नुहोस्, $n परिकार, $money');
  String get plusDelivery => t('plus delivery', 'डेलिभरी बाहेक');
  String get veg => t('Vegetarian', 'शाकाहारी');
  String get nonVeg => t('Non-vegetarian', 'मांसाहारी');

  // Search
  String get searchTitle => t('Search', 'खोज');
  String get searchIdleTitle =>
      t('Find your next meal', 'अर्को खाना खोज्नुहोस्');
  String get searchIdleBody => t(
      'Search restaurants and dishes across Attariya.',
      'अत्तरियाभरका रेस्टुरेन्ट र परिकार खोज्नुहोस्।');
  String get recentSearches => t('Recent searches', 'हालैका खोजहरू');
  String get clearRecent => t('Clear', 'हटाउनुहोस्');
  String get trySearching => t('Try searching for', 'यी खोजेर हेर्नुहोस्');
  String noResultsTitle(String q) =>
      t('No results for “$q”', '“$q” का लागि केही भेटिएन');
  String get noResultsBody => t(
      'Check the spelling, or try a dish like momo or chowmein.',
      'हिज्जे जाँच्नुहोस्, वा मःम वा चाउमिन जस्ता परिकार खोज्नुहोस्।');
  String get resultsRestaurants => t('Restaurants', 'रेस्टुरेन्ट');
  String get resultsDishes => t('Dishes', 'परिकार');
  String resultsCount(int n) =>
      t(n == 1 ? '1 result' : '$n results', '$n नतिजा');
  String fromRestaurant(String name) => t('from $name', '$name बाट');

  /// Suggested searches: (label shown, text searched — menu names are in English).
  List<(String, String)> get suggestions => [
        (t('Momo', 'मःम'), 'momo'),
        (t('Chowmein', 'चाउमिन'), 'chowmein'),
        (t('Thali', 'थाली'), 'thali'),
        (t('Burger', 'बर्गर'), 'burger'),
        (t('Pizza', 'पिज्जा'), 'pizza'),
        (t('Biryani', 'बिरयानी'), 'biryani'),
      ];

  // Restaurant page
  String get restaurantNotFoundTitle =>
      t("We couldn't find this restaurant", 'यो रेस्टुरेन्ट भेटिएन');
  String get restaurantNotFoundBody => t(
      'It may have closed or moved. Browse other places nearby.',
      'यो बन्द भएको वा सरेको हुन सक्छ। नजिकका अरू ठाउँ हेर्नुहोस्।');
  String get backToHome => t('Browse restaurants', 'रेस्टुरेन्टहरू हेर्नुहोस्');
  String todayHours(String open, String close) =>
      t('Today $open – $close', 'आज $open – $close');
  String get closedToday => t('Closed today', 'आज बन्द');
  String get closedNotice => t(
        "Closed right now — you can browse the menu, and order when it opens.",
        'अहिले बन्द छ — मेनु हेर्न सक्नुहुन्छ, खुलेपछि अर्डर गर्नुहोस्।',
      );
  String get vegOnly => t('Veg only', 'शाकाहारी मात्र');
  String get menuAll => t('Menu', 'मेनु');
  String get menuMore => t('More dishes', 'थप परिकार');
  String get menuOffers => t('Offers', 'अफर');
  String get menuEmptyTitle =>
      t('The menu is being prepared', 'मेनु तयार हुँदैछ');
  String get menuEmptyBody => t(
      'This restaurant has not added dishes yet. Check back soon.',
      'यो रेस्टुरेन्टले अझै परिकार थपेको छैन। केही समयपछि हेर्नुहोस्।');
  String get menuVegEmpty => t(
      'No vegetarian dishes on this menu.', 'यो मेनुमा शाकाहारी परिकार छैनन्।');
  String get menuLoadFailed => t("The menu didn't load.", 'मेनु लोड भएन।');
  String get jumpToSection => t('Jump to section', 'खण्डमा जानुहोस्');

  // Reviews
  String get reviewsTitle => t('Ratings & reviews', 'रेटिङ र समीक्षा');
  String reviewsSummary(String rating, int n) => t(
      '$rating average · ${n == 1 ? '1 review' : '$n reviews'}',
      'औसत $rating · $n समीक्षा');
  String get noReviewsTitle => t('No reviews yet', 'अहिलेसम्म समीक्षा छैन');
  String get noReviewsBody => t(
      'Order from here and be the first to share how it was.',
      'यहाँबाट अर्डर गरेर पहिलो समीक्षा लेख्नुहोस्।');
  String get anonymous => t('Customer', 'ग्राहक');
  String showAllReviews(int n) =>
      t('Show all $n reviews', 'सबै $n समीक्षा हेर्नुहोस्');
  String get showFewerReviews => t('Show fewer', 'कम देखाउनुहोस्');
  String starsSemantics(int n) => t('$n out of 5 stars', '५ मध्ये $n तारा');
  String get reviewsLoadFailed => t("Reviews didn't load.", 'समीक्षा लोड भएन।');
  String get reviewsTab => t('Reviews', 'समीक्षा');

  // Info
  String get infoTab => t('Info', 'जानकारी');
  String get infoTitle => t('Restaurant info', 'रेस्टुरेन्टको जानकारी');
  String get address => t('Address', 'ठेगाना');
  String get addressNotListed =>
      t('Address not listed yet', 'ठेगाना अझै राखिएको छैन');
  String get phone => t('Phone', 'फोन');
  String get phoneNotListed =>
      t('Phone number not listed yet', 'फोन नम्बर अझै राखिएको छैन');
  String get callRestaurant => t('Call', 'फोन गर्नुहोस्');
  String get callFailed => t("Couldn't open the phone app on this device.",
      'यो डिभाइसमा फोन एप खुलेन।');
  String get openingHours => t('Opening hours', 'खुल्ने समय');
  String get hoursNotSet =>
      t('Opening hours not shared yet', 'खुल्ने समय अझै राखिएको छैन');
  String get closed => t('Closed', 'बन्द');
  String get today => t('Today', 'आज');

  // Cart / checkout
  String get cartTitle => t('Your cart', 'तपाईंको कार्ट');
  String get clearCart => t('Clear cart', 'कार्ट खाली गर्नुहोस्');
  String get clearCartTitle => t('Clear your cart?', 'कार्ट खाली गर्ने?');
  String get clearCartBody => t(
      'Every item from every restaurant will be removed.',
      'सबै रेस्टुरेन्टका सबै परिकार हटाइनेछन्।');
  String get emptyCartTitle => t('Your cart is empty', 'तपाईंको कार्ट खाली छ');
  String get emptyCartBody => t(
      'Add dishes from any restaurant in Attariya and they will show up here.',
      'अत्तरियाको कुनै पनि रेस्टुरेन्टबाट परिकार थप्नुहोस्, यहाँ देखिनेछ।');
  String multiRestaurantNote(int n) => t(
        'You are ordering from $n restaurants. Each one becomes its own order with its own delivery, paid together.',
        'तपाईं $n रेस्टुरेन्टबाट अर्डर गर्दै हुनुहुन्छ। हरेक छुट्टै अर्डर र डेलिभरी हुन्छ, भुक्तानी सँगै हुन्छ।',
      );
  String get addMoreItems => t('Add more', 'थप परिकार');
  String eachPrice(String money) => t('$money each', 'प्रति $money');
  String removeItem(String name) => t('Remove $name', '$name हटाउनुहोस्');

  String get deliverTo => t('Deliver to', 'यहाँ डेलिभर गर्नुहोस्');
  String get typeAnotherAddress =>
      t('Type a different address', 'अर्को ठेगाना लेख्नुहोस्');
  String get manageAddresses => t('Manage addresses', 'ठेगाना व्यवस्थापन');
  String get addressFieldLabel => t('Delivery address', 'डेलिभरी ठेगाना');
  String get addressHint =>
      t('Tole, street, nearby landmark', 'टोल, बाटो, नजिकको चिनारी');
  String get addressHelper => t(
      'Add a landmark so the rider finds you quickly.',
      'राइडरले छिटो भेटोस् भनेर नजिकको चिनारी लेख्नुहोस्।');
  String nearLandmark(String landmark) => t('Near $landmark', '$landmark नजिक');
  String get defaultAddress => t('Default', 'मुख्य');

  String get notesLabel =>
      t('Note for the restaurant (optional)', 'रेस्टुरेन्टलाई नोट (ऐच्छिक)');
  String get notesField => t('Note', 'नोट');
  String get notesHint =>
      t('e.g. less spicy, no onions', 'जस्तै: कम पिरो, प्याज नहाल्नुहोस्');

  String get couponTitle => t('Coupon', 'कुपन');
  String get couponLabel => t('Coupon code', 'कुपन कोड');
  String get couponHint => t('Enter code', 'कोड लेख्नुहोस्');
  String get couponEnterCode =>
      t('Enter a coupon code first.', 'पहिले कुपन कोड लेख्नुहोस्।');
  String couponApplied(String code) => t('$code applied', '$code लागू भयो');
  String couponSaving(String money) =>
      t('You save about $money', 'तपाईंले करिब $money बचाउनुहुन्छ');
  String get couponRemoved => t('Coupon removed', 'कुपन हटाइयो');

  String get billTitle => t('Bill details', 'बिल विवरण');
  String get itemsSubtotal => t('Items subtotal', 'परिकारको जम्मा');
  String get deliveryFee => t('Delivery fee', 'डेलिभरी शुल्क');
  String deliveryFeeOrders(int n) =>
      t('Delivery fee ($n orders)', 'डेलिभरी शुल्क ($n अर्डर)');
  String get discount => t('Coupon discount', 'कुपन छुट');
  String get estimatedTotal => t('Estimated total', 'अनुमानित जम्मा');
  String get estimateNote => t(
        'Estimated — the final amount is confirmed when you place the order.',
        'अनुमानित — अर्डर गरेपछि अन्तिम रकम पक्का हुन्छ।',
      );
  String placeOrder(String money) =>
      t('Place order · $money', 'अर्डर गर्नुहोस् · $money');
  String orderPlaced(String money) =>
      t('Order placed. Final total: $money', 'अर्डर भयो। अन्तिम जम्मा: $money');
  String get loginToOrderTitle =>
      t('Log in to place your order', 'अर्डर गर्न लग इन गर्नुहोस्');
  String get loginToOrderBody => t(
      'Your cart is saved. Log in and you can check out right away.',
      'तपाईंको कार्ट सुरक्षित छ। लग इन गरेपछि तुरुन्तै अर्डर गर्न सक्नुहुन्छ।');

  // Offers tab
  String get navOffers => t('Offers', 'अफर');
  String get offersPageTitle => t('Offers & coupons', 'अफर र कुपन');
  String get offersSubtitle => t('Save on your next order in Attariya',
      'अत्तरियामा अर्को अर्डरमा बचत गर्नुहोस्');
  String get couponsSection => t('Coupon codes', 'कुपन कोड');
  String get couponsHint => t(
      'Copy a code and apply it in your cart at checkout.',
      'कोड कपी गरेर कार्टमा चेकआउट गर्दा प्रयोग गर्नुहोस्।');
  String percentOff(String n) => t('$n% off', '$n% छुट');
  String flatOff(String money) => t('$money off', '$money छुट');
  String upTo(String money) => t('up to $money', 'बढीमा $money');
  String minOrder(String money) =>
      t('Min. order $money', 'न्यूनतम अर्डर $money');
  String get noMinOrder => t('No minimum order', 'न्यूनतम अर्डर छैन');
  String validUntil(String date) => t('Valid until $date', '$date सम्म मान्य');
  String get copyCode => t('Copy code', 'कोड कपी गर्नुहोस्');
  String codeCopied(String code) => t('"$code" copied — apply it in your cart',
      '"$code" कपी भयो — कार्टमा प्रयोग गर्नुहोस्');
  String get loginForCouponsTitle =>
      t('Log in to see coupon codes', 'कुपन कोड हेर्न लग इन गर्नुहोस्');
  String get loginForCouponsBody => t('Coupons are linked to your account.',
      'कुपन तपाईंको खातासँग जोडिएका हुन्छन्।');
  String get noCoupons => t('No coupon codes right now — check back soon.',
      'अहिले कुनै कुपन छैन — केही समयपछि हेर्नुहोस्।');
  String get restaurantDealsSection => t('Restaurant deals', 'रेस्टुरेन्ट अफर');
  String get restaurantDealsHint =>
      t('Restaurants running an offer today', 'आज अफर दिइरहेका रेस्टुरेन्ट');
  String get noRestaurantDeals =>
      t('No restaurant deals right now.', 'अहिले कुनै रेस्टुरेन्ट अफर छैन।');
}
