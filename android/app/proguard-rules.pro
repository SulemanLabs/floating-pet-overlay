# Flutter's own Gradle plugin already ships the rules needed to keep the
# engine, plugin registrant, and MethodChannel machinery working under R8.
# Nothing in this app's own Kotlin uses reflection, JNI, or serialization
# that R8 could break, so no additional keep rules are needed yet. Add rules
# here if a future dependency (e.g. a JSON/Lottie library for custom pet
# import) requires them.

# okio (pulled in transitively, e.g. by Lottie's networking) references the
# JSR-305 javax.annotation.Nullable annotation at compile time only; it's not
# on the runtime classpath and isn't needed there, so tell R8 not to worry
# about resolving it.
-dontwarn javax.annotation.Nullable

# Firebase Crashlytics' recommended rules: keep file/line info so obfuscated
# release stack traces stay symbol-mappable, and keep exception subclasses
# so their type names survive in reports.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
