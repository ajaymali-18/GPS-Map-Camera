# Flutter Wrapper Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.autofill.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.gamepad.** { *; }
-dontwarn io.flutter.embedding.**

# Keep generated plugin registrants
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Preserve native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# AndroidX and CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Geolocator, Geocoding & Location
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# Native EXIF & JNI
-keep class com.cloudacy.native_exif.** { *; }
-keep class com.baseflow.native_exif.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Saver Gallery
-keep class com.mhz.savegallery.saver_gallery.** { *; }
