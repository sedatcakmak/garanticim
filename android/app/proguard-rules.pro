-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.baseflow.geolocator.** { *; }

-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**

-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_**

-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

-dontwarn com.google.android.play.**