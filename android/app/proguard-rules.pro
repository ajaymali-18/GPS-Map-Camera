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

# Geolocator & Location
-keep class com.baseflow.geolocator.** { *; }

# Native EXIF & JNI
-keep class com.baseflow.native_exif.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
