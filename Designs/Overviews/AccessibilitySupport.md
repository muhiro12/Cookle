# Accessibility Support

Last reviewed: April 23, 2026

This document records the accessibility support that is safe to advertise for
the current Cookle release.

## Supported Surfaces

- VoiceOver can identify primary recipe rows, diary rows, quick-return actions,
  top diary suggestions, photo actions, destructive actions, and settings data
  management actions with text labels.
- Dynamic Type is supported through standard SwiftUI `Text`, `List`, `Form`,
  `NavigationStack`, and system controls on the main recipe, diary, search,
  photo, settings, and form surfaces.
- Widgets mark recipe and diary content as privacy sensitive where the system
  supports hidden sensitive content.
- Primary destructive actions use confirmation dialogs and descriptive copy
  before deleting recipes, diaries, tags, photos, or all app data.
- Active cooking controls use labeled buttons for previous step, next step,
  repeat timer, and cancel timer actions.
- Apple Watch active cooking uses labeled controls and hides decorative system
  images from accessibility.

## Current Review Notes

- Manual VoiceOver testing should focus on recipe forms, diary forms, and photo
  management because these surfaces combine lists, images, menus, and sheets.
- Screenshot contrast should be checked before adding stronger App Store
  accessibility claims.
- The current public claim should stay conservative: VoiceOver labels, Dynamic
  Type through system controls, descriptive destructive confirmations, and
  privacy-sensitive widgets.
