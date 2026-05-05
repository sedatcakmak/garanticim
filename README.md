# garanticim

garanticim is a Flutter app for keeping track of product warranties.
You add a product with its category, brand and purchase date, and the
app tells you how long is left on the warranty and reminds you before
it runs out.

## Features

- Phone number sign-up with OTP
- Add warranties with photos of the product and receipt
- Categories and brands list bundled with the app
- Local notifications when a warranty is close to expiring
- Social feed to share product entries
- Optional premium subscription via in-app purchase
- AdMob ads for free users
- Cupertino-style UI

## Built With

- Flutter (Dart SDK ^3.9)
- Firebase: Core, Firestore, Storage
- flutter_local_notifications, timezone
- image_picker, shared_preferences
- google_mobile_ads, in_app_purchase
- flutter_screenutil, intl

## Getting Started

You'll need the Flutter SDK installed. Then:

```
flutter pub get
flutter run
```

## Configuration

The app uses Firebase. To build it yourself you'll need your own
Firebase project and config files (`google-services.json`,
`GoogleService-Info.plist`, and a generated `firebase_options.dart`).
If you want to test ads or in-app purchases you'll also need to set up
your own AdMob unit IDs and store products.
