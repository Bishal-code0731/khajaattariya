import '../domain/models/restaurant_model.dart';

enum RestaurantSort { recommended, rating, fastest }

class RestaurantFilter {
  const RestaurantFilter({
    this.sort = RestaurantSort.recommended,
    this.minRating4 = false,
    this.fastDelivery = false,
    this.offersOnly = false,
    this.openNow = false,
  });

  /// "Fast delivery" means this many minutes or less.
  static const fastDeliveryMaxMinutes = 30;

  final RestaurantSort sort;
  final bool minRating4;
  final bool fastDelivery;
  final bool offersOnly;
  final bool openNow;

  bool get hasFilters => minRating4 || fastDelivery || offersOnly || openNow;
  bool get isDefault => !hasFilters && sort == RestaurantSort.recommended;

  RestaurantFilter copyWith({
    RestaurantSort? sort,
    bool? minRating4,
    bool? fastDelivery,
    bool? offersOnly,
    bool? openNow,
  }) =>
      RestaurantFilter(
        sort: sort ?? this.sort,
        minRating4: minRating4 ?? this.minRating4,
        fastDelivery: fastDelivery ?? this.fastDelivery,
        offersOnly: offersOnly ?? this.offersOnly,
        openNow: openNow ?? this.openNow,
      );

  /// Filters, then sorts.
  List<RestaurantModel> apply(List<RestaurantModel> input,
      {Set<String>? onlyIds}) {
    final out = input.where((r) {
      if (onlyIds != null && !onlyIds.contains(r.id)) return false;
      if (minRating4 && r.rating < 4.0) return false;
      if (fastDelivery && r.deliveryTimeMin > fastDeliveryMaxMinutes) {
        return false;
      }
      if (offersOnly && !r.hasOffer) return false;
      if (openNow && !r.isOpen) return false;
      return true;
    }).toList();

    int openFirst(RestaurantModel a, RestaurantModel b) =>
        (a.isOpen ? 0 : 1).compareTo(b.isOpen ? 0 : 1);

    switch (sort) {
      case RestaurantSort.recommended:
        // List.sort isn't stable — sort indexes to keep server order.
        final index = {for (var i = 0; i < out.length; i++) out[i].id: i};
        out.sort((a, b) {
          final o = openFirst(a, b);
          return o != 0 ? o : index[a.id]!.compareTo(index[b.id]!);
        });
      case RestaurantSort.rating:
        out.sort((a, b) {
          final o = openFirst(a, b);
          if (o != 0) return o;
          final r = b.rating.compareTo(a.rating);
          return r != 0 ? r : b.reviewCount.compareTo(a.reviewCount);
        });
      case RestaurantSort.fastest:
        out.sort((a, b) {
          final o = openFirst(a, b);
          return o != 0 ? o : a.deliveryTimeMin.compareTo(b.deliveryTimeMin);
        });
    }
    return out;
  }
}
