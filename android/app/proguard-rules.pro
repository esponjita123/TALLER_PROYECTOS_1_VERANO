# Flutter/TFLite ProGuard Rules
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Keep TFLite classes
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Gson (used by Firebase)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
