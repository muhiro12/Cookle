# Privacy Disclosure Review

Last reviewed: April 23, 2026

This document records the repo-side privacy disclosure review for release
readiness. It is not legal advice and does not replace the final App Store
Connect questionnaire review.

## Current Product Behavior

- Cookle stores user-created recipes, diary entries, tags, and photos locally
  with SwiftData.
- Cookle can sync supported user content through the user's Apple iCloud account
  when the user enables iCloud sync.
- Cookle does not operate a Cookle account system or a Cookle-owned server for
  recipe, diary, or photo content.
- Cookle uses Apple Photos, camera, notifications, widgets, Apple Watch, App
  Shortcuts, Image Playground, Vision text recognition, Foundation Models, and
  StoreKit where those features are available.
- Cookle uses Google Mobile Ads for non-subscribed users and Google User
  Messaging Platform through the ads dependency stack.

## App Store Connect Review Notes

- Do not disclose device location as app-owned collection unless new code starts
  requesting or deriving location data. Current code does not request location.
- Treat recipe text, diary text, tags, and photos as user content that is stored
  locally and optionally synced through the user's iCloud account.
- Review Google Mobile Ads and Google User Messaging Platform in the generated
  privacy report before submitting App Store privacy answers, because third-party
  SDK practices must be reflected in App Store Connect.
- Treat subscriptions and payments as App Store and StoreKit-managed. Cookle
  reads entitlement state but does not receive payment card details.
- Treat notifications, widgets, App Shortcuts, Apple Watch, Image Playground,
  Vision, and Foundation Models as Apple system integrations rather than
  Cookle-owned server collection.

## Privacy Manifest Notes

- The app target declares UserDefaults access because Cookle stores app-only
  settings and app-group shared route or recipe state.
- The app target declares file timestamp access because notification attachment
  cache freshness is checked inside the app container.
- The widget target declares UserDefaults access for app-group shared state used
  by widget and shared-library flows.
- Third-party SDK manifests are supplied by their packages and should still be
  reviewed in Xcode's generated privacy report before release submission.
