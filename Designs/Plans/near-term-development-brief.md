# Near-Term Release and iOS 27 Transition

> Status: Temporary execution brief, updated September 14, 2026. Use it
> through Cookle's first post-iOS 27 release, then remove or replace it.

## Mission

Ship one trustworthy Cookle release by early September 2026. Until then,
prioritize release hardening, confirmed defects, and valuable work that should
not wait for iOS 27. After that release, shift the main effort to iOS 27 and
prepare the first post-iOS 27 Cookle release with an intentional full MHUI
adoption.

This plan does not itself raise Cookle's minimum deployment target. A support
policy change requires a separate decision.

## Work Before the September Release

1. Treat the current implementation as the release candidate and control new
   scope. Do not resume every deferred feature during hardening.
2. Fix confirmed defects and finish only work whose value and regression risk
   justify inclusion in this release.
3. Prove release-sensitive behavior, especially persisted cooking data,
   backup and restore, iCloud behavior, subscription and ad suppression,
   notifications, Shortcuts, Widgets, and the Watch cooking session.
4. Confirm that actual AdMob behavior and App Store privacy declarations agree.
   Where practical, exercise an iCloud restore round trip on representative
   existing data and more than one real device.
5. Change a shared package before this release only when it directly resolves
   a scoped Cookle release need and the affected behavior can be verified.

## iOS 27 and Full MHUI Adoption

After the September release, use the latest selected Xcode and iOS 27 SDK as
the primary development environment. Adopt current platform capabilities where
they materially improve Cookle's recipe, diary, search, cooking, automation,
or companion experiences.

The first post-iOS 27 release should intentionally adopt the full `MHUI`
product in the main Cookle app. Cookle 3.9 shipped on September 13. The
expanded Recipe Detail direction was accepted on September 14, satisfying
the release and representative-screen approval gates.

The root theme, full product linkage, and expanded Recipe Detail established
the first slice under
[ADR 0009](../Decisions/0009-adopt-full-mhui-in-main-app.md). Broader main-app
implementation now includes lists, forms, search, settings, cooking, photos,
and detached editors. The [rollout record](mhui-app-rollout.md) tracks semantic
commits, screen-appropriate MHUI composition or native-container chrome,
and the remaining verification coverage. Existing content and operations are
preserved. New features and diary-list information architecture remain
separate.

Adoption requirements (the first slice now satisfies items 1, 2, and 4):

1. Agree on visual acceptance criteria using representative Cookle screens and
   capture a fresh before-state from current `main`.
2. Establish an accepted MHUI direction in the package and a small Cookle
   vertical slice before converting the rest of the app.
3. Evaluate companion surfaces independently under
   [ADR 0010](../Decisions/0010-evaluate-mhui-for-companion-surfaces.md).
   `CookleLibrary` remains presentation-free, Widgets retains native WidgetKit
   composition, and Watch adoption awaits a readable shared surface. The
   original companion exclusion no longer limits future adoption.
4. In the adoption change, add a new ADR that supersedes the app-target portion
   of ADR 0008. Update the README, architecture documents, and
   `check_package_consumer_boundaries.sh` to express the new contract.
5. Make accepted visual results, native behavior, accessibility, and product
   clarity the completion criteria. Linking the package is not completion.

## Guardrails

- Do not change the established direct-to-`main` and tag release workflow.
- Do not combine the pre-iOS 27 release with a broad MHUI migration or wrapper
  modernization unless a confirmed blocker requires it.
- Keep Cookle-specific composition, wording, domain behavior, persistence, and
  navigation in this repository.
- Fix package-owned visual defects in MHUI or MHDesign, then verify Cookle and
  another affected consumer rather than hiding the defect in one app.
- Treat backup, restore, CloudKit, schema, and subscription changes as
  high-consequence release work.

## Completion Evidence

For the September release, use CookleLibrary tests, repository rules, the app
build, affected Widget builds, and targeted runtime or UI evidence. Record the
Watch verification gap if real Watch behavior cannot be exercised.

For full MHUI adoption, require package tests and rules, targeted previews,
fresh before-and-after evidence on representative Cookle screens, and runtime
checks across relevant size classes, appearance modes, and accessibility
settings.
