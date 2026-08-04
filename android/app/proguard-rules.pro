# Gson + flutter_local_notifications (R8 / AGP 8)
# Fixes: IllegalStateException TypeToken must be created with a type argument
# when scheduling / loading notifications in release builds.

-keepattributes Signature
-keepattributes *Annotation*

-dontwarn sun.misc.**

-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses (R8 3.0+ / full mode).
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# flutter_local_notifications models used via Gson reflection
-keep class com.dexterous.flutterlocalnotifications.** { *; }

-keep class org.xmlpull.** { *; }

# Launcher shortcut icons (referenced from Dart / shortcuts.xml)
-keep class com.skytask.app.R$drawable { *; }
