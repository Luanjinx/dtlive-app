## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings
-keep class * {
    public private *;
}

# Razorpay
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# Rules for Instamojo SDK
-keep class com.instamojo.android.**{*;}
-keep class android.window.BackEvent { *; }
-keep class android.window.OnBackInvokedCallback { *; }
-keep class android.window.OnBackInvokedDispatcher { *; }
-keep class android.window.BackEventCompat { *; }
# Flutter WebView
-keep class com.pichillilorenzo.** { *; }
-keep class * { @android.webkit.JavascriptInterface *; }
-dontwarn com.pichillilorenzo.**
-dontwarn android.webkit.**
-dontwarn java.nio.file.**

# For VDOCipher Player
-keep class androidx.media3.common.MediaLibraryInfo { *; }

# For Deep Link
# Keep AutoSafeParcelables
-keep public class * extends org.microg.safeparcel.AutoSafeParcelable {
    @org.microg.safeparcel.SafeParcelable.Field *;
    @org.microg.safeparcel.SafeParceled *;
}

# Keep asInterface method cause it's accessed from SafeParcel
-keepattributes InnerClasses
-keepclassmembers interface * extends android.os.IInterface {
    public static class *;
}
-keep public class * extends android.os.Binder { public static *; }

# For Stripe
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider