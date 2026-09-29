# Cookle Product Vocabulary

Source review September 30, 2026.

This note fixes the words Cookle uses for its core concepts in every supported
language, so screens, App Intents, Widgets, Watch, notifications, and Store copy
name the same thing the same way. English and Japanese are the reference
languages; the other locales keep the same concept boundaries.

## 1) Canonical terms

<!-- markdownlint-disable MD013 -->
| Concept | English | Japanese | Simplified Chinese | Spanish | French |
| --- | --- | --- | --- | --- | --- |
| A saved recipe | Recipe | レシピ | 食谱 | Receta | Recette |
| A day's record of meals | Diary | 日記 | 日记 | Diario | Journal |
| Meals of a diary day | Breakfast, Lunch, Dinner | 朝食、昼食、夕食 | 早餐、午餐、晚餐 | Desayuno, Almuerzo, Cena | Petit-déjeuner, Déjeuner, Dîner |
| Recipe ingredient | Ingredient | 材料 | 食材 | Ingrediente | Ingrédient |
| Recipe step list | Steps | 手順 | 步骤 | Pasos | Étapes |
| Recipe category | Category | カテゴリ | 分类 | Categoría | Catégorie |
| Free-text note | Note | メモ | 备注 | Nota | Note |
| Number of servings | Serving Size; `Servings: n`; unit `servings` | 人数; `n人分`; unit 人分 | 份数; `n人份`; unit 份 | Porciones | Portions |
| Cooking time | Cooking Time | 調理時間 | 烹饪时间 | Tiempo de cocción | Temps de cuisson |
| Recipe or diary image | Photo | 写真 | 照片 | Foto | Photo |
| Daily notification | Recipe Suggestion | レシピ提案 | 食谱推荐 | Sugerencia de receta | Suggestion de recette |
| Guided cooking | Start Cooking | 調理を開始 | 开始烹饪 | Comenzar a cocinar | Commencer à cuisiner |
| Moving data in and out | Import, Export | 取り込む、書き出す | 导入、导出 | Importar, Exportar | Importer, Exporter |
| Reading a recipe from an image | Read Recipe from Photo | 写真からレシピを読み取る | 从照片识别食谱 | Leer receta de una foto | Lire une recette sur une photo |
| App settings tab | Settings | 設定 | 设置 | Ajustes | Réglages |
<!-- markdownlint-enable MD013 -->

Usage rules:

- In Japanese, 手順 names the step list and its fields. ステップ is kept only
  for position and count, such as `ステップ2 / 5` while cooking.
- In Japanese, 取り込む means bringing content into Cookle: data files, text,
  web pages. 読み込む means loading, such as a page or a photo that failed to
  load. These are separate concepts.
- A timer's per-step suggestion (`この手順のおすすめ`) is not a Recipe
  Suggestion. It keeps its own wording.
- Reading a recipe from a photo says "read", not "import": the photo is read
  for text and never attached to the recipe, unlike adding a Photo.

## 2) Platform terms

Apple feature and app names stay as Apple localizes them, in every language:
Apple Intelligence, Image Playground, iCloud, Siri, Shortcuts, Spotlight,
Apple Watch, and the system Notes app (メモ in Japanese). The Settings tab uses
the same word each locale uses for iOS Settings.

## 3) Open vocabulary decisions

This wording depends on a product decision that is still open, so this note
does not fix it yet:

- **Recipe navigation wording**, such as "Open in Recipes" or tab-change
  phrasing, follows the recipe presentation contract in
  [#145](https://github.com/muhiro12/Cookle/issues/145).

## 4) Repeating the audit

`bash ci_scripts/tasks/check_repository_rules.sh` runs
`check_string_catalog_vocabulary.sh`, which fails when a tracked string catalog:

- keeps an entry Xcode marked `stale`, or
- uses a superseded translation of a term in section 1. The list lives in
  `ci_scripts/lib/check_string_catalog_vocabulary.py`.

The check covers the mechanical part. Before a major release, also:

1. Build every target so Xcode refreshes extraction states. Then remove stale
   entries that no source references in the target that owns the catalog.
2. Compare each concept in section 1 across the English and Japanese catalogs,
   App Shortcuts phrases, and Store metadata. Then carry the result to the other
   locales.
3. Add any newly superseded translation to the check so it cannot return.
