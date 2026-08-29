# Keep the home-screen widget provider after R8 shrinking.
-keep class com.yasmen.pocketly.PocketlyHomeWidgetProvider { *; }
-keep class com.yasmen.pocketly.PocketlyQuickExpenseWidgetProvider { *; }
-keep class com.yasmen.pocketly.PocketlyWidgetIntents { *; }
-keep class es.antonborri.home_widget.** { *; }

# google_mlkit_text_recognition references optional script recognizers that are
# not bundled unless you add each language dependency. The app uses Latin only.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
