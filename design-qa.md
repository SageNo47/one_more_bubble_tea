# Drink History Design QA

- Source visual truth: `docs/design/drink-history-reference.png`
- Implementation screenshot: `docs/design/drink-history-implementation.png`
- Full comparison: `docs/design/drink-history-comparison.png`
- Focused detail comparison: `docs/design/drink-history-detail-comparison.png`
- Native viewport: `780 × 560 pt`, captured at `2×` as `1560 × 1120 px`
- Source pixels: `1461 × 1076 px`; the generated source has no authoritative native point density
- Normalization: both full views were proportionally contained within `1200 × 900 px` slots; detail crops were proportionally contained within `760 × 560 px` slots
- State: September 2026, September 3 selected, one record at 15:20

## Findings

No actionable P0, P1, or P2 differences remain.

- Typography: rounded system typography, weight hierarchy, single-line selected date, and compact record time match the source intent. Chinese copy is readable without clipping.
- Spacing and layout: the calendar/detail split, header, month controls, statistics, grid density, right-pane padding, dividers, and record-row proportions preserve the selected direction.
- Colors and tokens: the implementation uses the existing warm off-white, warm gray-brown border, dark neutral text, and low-saturation brown accent. Sunday intentionally uses the same semantic color as other weekdays per the final user instruction.
- Image quality: the supplied milk-tea PNG is rendered directly for statistics, date counts, empty state, and record rows; no placeholder or code-drawn substitute is used.
- Copy and content: the record row intentionally omits “来自提醒” while `DrinkSource` remains in the persisted model. The selected-day heading, summary, actions, and statistics are present.
- Accessibility and states: interactive controls have accessibility labels/help, future dates visually dim and reject additions, and loading/error/empty states are implemented. The UI respects the existing app’s custom close-button convention rather than reproducing the generated mock’s decorative traffic-light dots.

## Focused Region Evidence

The right detail pane was compared separately because its heading, primary action, record content, and delete affordance are too small for reliable judgment in the normalized full view. The second capture keeps “9月3日 周四” on one line and preserves the requested removal of the source label.

## Comparison History

1. Initial implementation capture: `/private/tmp/milkteapet-history-implementation.png`
   - P2: “9月3日 周四” wrapped onto two lines because the heading and primary button competed for width.
   - Fix: reduced the heading from 18 pt to 17 pt, tightened horizontal spacing, narrowed the button by 4 pt, and added a one-line minimum scale guard.
2. Revised implementation capture: `docs/design/drink-history-implementation.png`
   - The heading remains on one line; no P0/P1/P2 visual issue remains.

## Interaction Verification

- Month grid generation begins on Monday and handles five- or six-row months.
- Manual add immediately updates selected-day, current-week, and displayed-month totals.
- Future-day additions are rejected.
- Individual deletion removes only the targeted UUID.
- Core Data add, range fetch, source retention, single deletion, and missing-record deletion were exercised by a compiled validation harness.
- Debug and Release builds completed successfully.

## Follow-up Polish

- P3: after broader real-data usage, the right-side list spacing can be revisited for days with unusually many records.

final result: passed
