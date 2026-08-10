**SpendWise:** AI-Powered Personal Finance Tracker (Flutter)
SpendWise is a full-featured, cross-platform expense tracking application
built with Flutter. It combines local data persistence, cloud authentication,
AI-driven automation, and monetization into a single production-ready app.

**WHAT IT DOES**

**Authentication & Data Privacy**
- Users sign up and log in with Firebase Authentication (email/password).
- Every transaction is stored locally (SQLite) but scoped to the signed-in
  user's Firebase UID, so each account's financial data stays private even
  though the database itself lives on the device.

**Expense & Income Tracking**
- Users can log both Cash In (income) and Cash Out (expenses), each with an
  amount, description, date, time, contact name, and payment mode.
- The History screen groups entries by date, supports search, and shows
  running totals for income, expenses, and net balance.

**AI-Powered Features (Google Gemini API)**
- Automatic category prediction from a plain-text description (e.g. "pizza
  with friends" -> Food), with an offline keyword-matching fallback if the
  API is unavailable.
- "Wise", an in-app AI chat assistant that can both answer questions about
  the user's spending and take real actions — adding or deleting entries —
  using Gemini's function calling (agentic AI).
- Voice Add: users can describe an expense out loud, and speech-to-text plus
  Gemini fill in the entry form automatically.
- Receipt Scanning: a photographed receipt is parsed by AI to auto-extract
  the merchant, amount, and date.
- Deep AI Insight: an on-demand, detailed spending analysis with practical
  saving suggestions, unlocked via a rewarded ad.

**Budgeting & Notifications**
- Users can set daily and monthly spending limits, visualized with progress
  bars, and receive local push notifications when a limit is exceeded.

**Reporting**
- One-tap PDF export of the complete transaction history, personalized with
  the user's name and shareable through the native Android share sheet.

**Personalization**
- An editable profile (name, age, profile photo) and an app settings screen.

**Monetization (Google AdMob)**
- Banner ads on the Summary screen.
- Interstitial ads shown after a PDF export.
- Rewarded video ads that unlock the Deep AI Insight feature.

**Engineering Quality**
- Clean, standard Flutter project structure: models/, screens/, services/,
  db/.
- Unit and widget tests written with flutter_test.
- Passes `flutter analyze` with no errors.
- Signed, release-ready APK build configuration (keystore + key.properties).

**TECH STACK**
Flutter, Dart, Firebase Authentication, sqflite (local SQLite), Google
Gemini API (categorization, chat agent, insights), Google Speech-to-Text
(voice input), flutter_local_notifications, the pdf and printing packages
for report generation, and Google Mobile Ads (AdMob) for monetization.
