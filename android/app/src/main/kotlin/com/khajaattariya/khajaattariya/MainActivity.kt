package com.khajaattariya.khajaattariya

import io.flutter.embedding.android.FlutterFragmentActivity

// flutter_stripe's PaymentSheet needs a FragmentActivity host on Android
// (it uses Jetpack Activity Result APIs internally) — plain
// FlutterActivity crashes at runtime the moment presentPaymentSheet() is
// called.
class MainActivity : FlutterFragmentActivity()
