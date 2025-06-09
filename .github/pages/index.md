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
  <p>Keep your favorite recipes organised across all your devices.</p>
  <p>
    <a href="https://apps.apple.com/app/id6483363226">
      <img src="https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2024-04-29&kind=iossoftware" alt="Download on the App Store" width="160">
    </a>
  </p>
</div>

Cookle is a lightweight recipe manager built entirely with SwiftUI.

<div class="features">
  <div class="feature">
    <img src="../../.Resources/SpaghettiCarbonara1.png" alt="Recipe Example">
    <p>Create and manage recipes with photos and detailed steps.</p>
  </div>
  <div class="feature">
    <img src="../../.Resources/Pancakes1.png" alt="Quick Search">
    <p>Organize with categories and quickly search by keywords.</p>
  </div>
  <div class="feature">
    <img src="../../.Resources/BeefStew1.png" alt="Diary">
    <p>Record your cooking experiences in the built‑in diary.</p>
  </div>
</div>

## More Features

- App Shortcuts for search and showing the last opened recipe
- Optional iCloud synchronisation and subscription support
- Google Mobile Ads integration

## Screenshots

<table class="gallery">
<tr>
<td><img src="https://github.com/user-attachments/assets/d1d874c5-b2d9-4342-873e-7efdfa88e865" alt="iPhone screenshot 1"></td>
<td><img src="https://github.com/user-attachments/assets/ae8f05e2-5fe6-4123-a049-f56799ccc759" alt="iPhone screenshot 2"></td>
<td><img src="https://github.com/user-attachments/assets/ace07047-2005-4dd3-8dce-f3d694832e83" alt="iPhone screenshot 3"></td>
</tr>
<tr>
<td><img src="https://github.com/user-attachments/assets/9fd3da4b-3739-4ac5-b581-48adbbbb7143" alt="iPad screenshot 1"></td>
<td><img src="https://github.com/user-attachments/assets/1b5364d0-75a8-4f44-9fa4-0b529fdef5f5" alt="iPad screenshot 2"></td>
<td><img src="https://github.com/user-attachments/assets/e1e6aac3-8563-4560-be5d-ef473bf63e10" alt="iPad screenshot 3"></td>
</tr>
</table>

## Development

The project uses **Swift 5** and requires **Xcode 15** or later. After cloning the repository, open `Cookle.xcodeproj` in Xcode and build the `Cookle` scheme.
