# Keep Flutter engine and plugin classes; the app has no reflection rules
# beyond this. Add `-keep` lines here if release builds warn about
# missing classes.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-
-dontwarn com.google.android.play.core.splitinstall.**
