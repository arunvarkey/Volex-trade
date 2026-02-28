# Volex Terminal - ProGuard Rules for Maximum Security

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Obfuscate everything else aggressively
-repackageclasses 'o'
-allowaccessmodification
-mergeinterfacesaggressively

# Remove all logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Remove print statements
-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void println(**);
}

# Optimize aggressively
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5

# String encryption (makes reverse engineering harder)
-adaptclassstrings
-adaptresourcefilenames
-adaptresourcefilecontents

# Remove debug info
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Ensure data models for Firestore/JSON are not stripped if used via reflection (or if generic types are erased)
-keep class com.volex.terminal.features.signals.models.** { *; }
-keep class com.volex.terminal.features.market.models.** { *; }
-keep class com.volex.terminal.features.subscriptions.models.** { *; }

# Chart libraries sometimes use reflection
-keep class com.github.aachartmodel.** { *; }
-keep class fl.chart.** { *; }

# Fix for Missing Classes in R8 (Play Core & Firestore)
-dontwarn com.google.android.play.core.**
-keep class com.google.rpc.** { *; }
-keep class com.google.type.** { *; }
-keep class com.google.protobuf.** { *; }
