# Recipe Detail Comparison Inputs

These are historical comparison inputs based on commit `0a9eda1`. The
expanded option was accepted on September 14, 2026 after Cookle 3.9 shipped.
See [adoption status](adoption-status.md) for the implemented slice and checks.

- `recipe-detail-candidate.patch`: proposed production app linkage, theme,
  native List canvas, and seven existing section headings; unapplied to main.
- `recipe-detail-expanded.patch`: alternative screen/section/row/action
  composition using MHUI, now used as the production-source adoption basis.
  Both patches remain baseline artifacts; do not apply them to adopted main
  or layer them together when reproducing the comparison.
- `capture-fixture.patch`: isolated, in-memory runtime entry point and
  deterministic sample setup shared by both comparison sides.
- `comparison.md`: paired captures with the same conditions.
- `three-way-comparison.md`: current, minimum MHUI, and expanded MHUI captures.
- `expanded-review.md`: expanded scope, visual tradeoffs, and adoption costs.
- `images/`: original capture files, without generated edits or retouching.

To reproduce the original comparison, start from an isolated copy of commit
`0a9eda1be5b24217ad69082f5862d406051e8248`. Apply the capture fixture patch.
Resolve MHUI `1.18.0` at revision
`5e9841f77b770184ea560cec4831adacc1e0fdb6`, then capture the current side on a
dedicated simulator. The fixture opens the real RecipeView with in-memory
sample data, no configured ads, and a nonpersisting cooking-session store.
It bypasses production bootstrap. Its primary recipe has no photos.

For the candidate, apply the implementation patch excluding CookleApp.swift,
which the capture fixture replaces. In that fixture app, add `import MHUI`
and `.mhTheme(.standard)` to the same screen root. All other fixture source,
launch controls, and dependency versions must stay identical.

The expanded alternative follows the same steps from a fresh fixture copy,
using `recipe-detail-expanded.patch` instead. The two new recipe presentation
helpers default to native sections at other consumers; only Recipe Detail
selects the composed treatment. The expanded capture uses the same launch
controls, root theme, and MHUI revision as the minimum candidate.

Launch both sides with Japanese language and locale. Per-run environment
values select the comparison conditions:

| Variable | Values |
| --- | --- |
| `COOKLE_REVIEW_APPEARANCE` | `light` or `dark` |
| `COOKLE_REVIEW_LARGE_TEXT` | `0` for Large; `1` for accessibility size 1 |

The historical patches do not contain the policy updates or minimum-version
requirement. Those are now implemented separately under
[ADR 0009](../../Decisions/0009-adopt-full-mhui-in-main-app.md). Never install
the capture fixture into a production target.
