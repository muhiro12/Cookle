<style>
.hero {
  text-align: center;
  margin-top: 2rem;
}
.features {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 1.5rem;
  margin-top: 2rem;
}
.feature {
  max-width: 200px;
  text-align: center;
}
.feature img {
  width: 100%;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
table.gallery img {
  width: 250px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
</style>

<div class="hero">
  <img src="../../Cookle/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png" alt="Cookle Icon" width="120">
  <h1>Cookle</h1>
  <p>Recipes, diary, and cooking sessions that stay useful while you cook.</p>
  <p>
    <a href="https://apps.apple.com/app/id6483363226">
      <img src="https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2024-04-29&kind=iossoftware" alt="Download on the App Store" width="160">
    </a>
  </p>
</div>

Cookle helps you keep personal recipes, photos, cooking notes, and meal history
in one place. Open a recipe while cooking, log what you made, and return to the
right dish from widgets, notifications, Shortcuts, or Apple Watch.

<div class="features">
  <div class="feature">
    <img src="../../.Resources/SpaghettiCarbonara1.png" alt="Recipe Example">
    <p>Build a recipe library with photos, ingredients, steps, tags, and notes.</p>
  </div>
  <div class="feature">
    <img src="../../.Resources/Pancakes1.png" alt="Quick Search">
    <p>Search by name, ingredients, and categories when you need an idea fast.</p>
  </div>
  <div class="feature">
    <img src="../../.Resources/BeefStew1.png" alt="Diary">
    <p>Record breakfasts, lunches, dinners, and notes in the built-in diary.</p>
  </div>
</div>

## Highlights

- Active cooking mode keeps the recipe available through the cooking flow.
- Recipe suggestion notifications can surface something to make each day.
- Widgets bring today's diary and recipe suggestions to the Home Screen.
- Apple Watch support mirrors the active cooking session and timer state.
- App Shortcuts and App Intents open recipes, search, diary, settings, and
  suggestion flows from system surfaces.
- Image Playground, camera, and photo-library import help attach useful visuals
  to recipes.
- Optional iCloud sync keeps your collection available across devices.
- Backup export, restore, and delete-all controls help you stay in control of
  your cooking data.

## For Everyday Cooking

- Save recipes with serving sizes, cooking times, ingredients, categories,
  photos, and free-form notes.
- Use diary history to remember what worked, what changed, and what you cooked
  on a specific day.
- Jump back to the last opened or currently active recipe without searching
  again.
- Keep recipe content private by default, with optional iCloud sync through your
  Apple account.

## Accessibility

- Cookle uses standard SwiftUI controls, lists, forms, and navigation where
  possible so VoiceOver and Dynamic Type can follow system behavior.
- Recipe, diary, photo, notification, widget, and cooking-session surfaces use
  descriptive text labels for their primary actions.
- Widget content that may reveal recipe or diary details is marked privacy
  sensitive for supported system contexts.
- The app avoids color-only meaning for core cooking, diary, and data-management
  actions.

## Screenshots

<table class="gallery">
<tr>
<td><img src="https://github.com/user-attachments/assets/d1d874c5-b2d9-4342-873e-7efdfa88e865" alt="Recipe list screenshot"></td>
<td><img src="https://github.com/user-attachments/assets/ae8f05e2-5fe6-4123-a049-f56799ccc759" alt="Recipe detail screenshot"></td>
<td><img src="https://github.com/user-attachments/assets/ace07047-2005-4dd3-8dce-f3d694832e83" alt="Diary screenshot"></td>
</tr>
<tr>
<td><img src="https://github.com/user-attachments/assets/9fd3da4b-3739-4ac5-b581-48adbbbb7143" alt="iPad recipe library screenshot"></td>
<td><img src="https://github.com/user-attachments/assets/1b5364d0-75a8-4f44-9fa4-0b529fdef5f5" alt="iPad recipe detail screenshot"></td>
<td><img src="https://github.com/user-attachments/assets/e1e6aac3-8563-4560-be5d-ef473bf63e10" alt="iPad diary screenshot"></td>
</tr>
</table>

## Development

The project uses Swift 6 with Xcode 26.3 or later. After cloning the
repository, open `Cookle.xcodeproj` in Xcode and build the `Cookle` scheme.
