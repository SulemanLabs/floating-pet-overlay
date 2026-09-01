# Flutter's own Gradle plugin already ships the rules needed to keep the
# engine, plugin registrant, and MethodChannel machinery working under R8.
# Nothing in this app's own Kotlin uses reflection, JNI, or serialization
# that R8 could break, so no additional keep rules are needed yet. Add rules
# here if a future dependency (e.g. a JSON/Lottie library for custom pet
# import) requires them.
