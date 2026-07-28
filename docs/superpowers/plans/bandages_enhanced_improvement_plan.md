# Bandages Enhanced — Planned Improvements (No Logic Changes Yet)

## Goal

- Change roster bandage usage so one bandage treats only one temporary injury per use, instead of compressing all injuries at once.
- Keep combat bandage healing behavior unchanged.
- Keep permanent injuries untouched.
- Keep the treatment UI showing only injuries that can still be treated after each use.

## Current behavior snapshot

- Roster treatment is implemented in `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut`.
- The current loop in `compressTemporaryInjuries()` compresses every eligible temporary injury in one call.
- The menu list is built from `getRosterTreatableInjuries()` and reloaded after each apply via `onApplyBandage()`.

## UI diagnostic note (button symptom)

- The code line `bottomRow.append($('<div class="status text-font-normal"/>').text(rowData.Message));` is inside the roster row loop and creates one status text field per row.
- It is **not** a button element, so it does not create or duplicate footer buttons.
- The repeated/very long footer button issue is more consistent with button sizing/layout (`.ui-control.button-1` from `createTextButton(..., '', 1)` uses `width: 100%`) and the footer class mismatch (`.l-button` styles are defined, but those buttons do not have the `l-button` class).

## UI implementation plan (pending)

- File: [mod_bandages_enhanced/ui/mods/bandages_enhanced_screen.js](E:\\Battle Brother extract code\\mod_bandages_enhanced\\ui\\mods\\bandages_enhanced_screen.js)
  - Wrap each footer button in a fixed-size layout div (e.g., `.bandages-enhanced-footer-button`) before calling `createTextButton`.
  - Keep `createTextButton(..., '', 1)` unchanged for sprite/label behavior.
- File: [mod_bandages_enhanced/ui/mods/bandages_enhanced_screen.css](E:\\Battle Brother extract code\\mod_bandages_enhanced\\ui\\mods\\bandages_enhanced_screen.css)
  - Replace `.bandages-enhanced-footer .l-button` styling with `.bandages-enhanced-footer-button`.
  - Add explicit button width/height matching sprite size (`17.5rem` x `4.3rem`).
  - Force non-repeating background and full-size mapping for `.ui-control.button-1` inside this footer.

## Design rules before implementation

- One bandage consumes one unit and changes only one injury at a time by default.
- Default behavior should be conservative and costed, with existing fast path values preserved unless user opts into different recovery intensity.
- No combat behavior change unless explicitly needed later (BandageValue, 35%/65% HP healing stay as-is).
- Permanent injuries remain impossible to shorten/heal in both combat and map treatment.

## Settings to add

1. Add a new recovery setting in `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_settings.nut`.
2. Add `InjuriesPerBandageUse` (name suggestion) default `1`, min `1`, max `5`.
3. Optional adjacent setting (if needed after playtest): `PreferHeaviestInjuryFirst` boolean default `true` for deterministic selection.

## Code changes (functional)

1. Update `compressTemporaryInjuries()` in `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut`.
2. Build a candidate list of eligible temporary injuries where current max healing days are above target.
3. Sort the candidate list deterministically (for example by current max healing days descending).
4. Compress at most `InjuriesPerBandageUse` injuries instead of all injuries.
5. Return a payload that can include:
  - `changed`: number of injuries treated,
  - `treatedIDs`: injured IDs for possible UI messaging.
6. Preserve the `setTreated(true)` call and `updateInjuryVisuals()` behavior when at least one injury is changed.
7. Keep existing thresholds: `LightInjuryThresholdDays`, `LightInjuryMaxDays`, `HeavyInjuryMaxDays`.
8. Ensure `applyRosterBandage()` checks `compressTemporaryInjuries()` result count, not just truthy/false, so one-bandage semantics are enforced.

## UI behavior updates

1. Update `getRosterTreatmentRows()` / `getRosterBandageUseResult()` in `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut` message text to show remaining treatable injuries after one use (e.g. `x injury(s) remaining`).
2. Keep the treatment list tied to `getRosterTreatableInjuries()` so it naturally hides already-treated injuries after each apply.
3. Confirm screen refresh still works through existing `onApplyBandage()` data round-trip in `mod_bandages_enhanced/scripts/ui/screens/world/bandages_enhanced_screen.nut`.

## Edge cases to lock in before implementation

1. Actor with one eligible injury should consume one bandage and clear that eligibility immediately.
2. Actor with mixed temporary injuries should only reduce the first N chosen by the deterministic order.
3. Actor with only permanent injuries remains ineligible with the same reason message as today.
4. Actor with no temporary injuries remains rejected and does not consume bandage.
5. World stash empty path remains unchanged and returns `no_bandage`.

## Validation plan (manual)

1. Build a character with 3+ temporary injuries and apply one bandage from treatment screen.
2. Verify only one injury icon disappears from treatment list after that use.
3. Verify another bandage is required to further reduce additional injuries.
4. Verify combat bandage in `scripts/skills/actives/bandage_ally_skill` still restores by `% max HP` only and still removes bleeding/fresh bandage wounds.
5. Verify permanent injury-only character remains blocked and no error pops.

## Improvement 2 plan (UI status text readability and semantics)

### Scope

- File: [bandages_enhanced_screen.js](E:\\Battle Brother extract code\\mod_bandages_enhanced\\ui\\mods\\bandages_enhanced_screen.js)
- File: [bandages_enhanced_screen.css](E:\\Battle Brother extract code\\mod_bandages_enhanced\\ui\\mods\\bandages_enhanced_screen.css)
- File: [z_bandages_enhanced.nut](E:\\Battle Brother extract code\\mod_bandages_enhanced\\scripts\\config\\z_bandages_enhanced.nut) (backend reason/message harmonization if needed)

### Problem statement

- The right-side row status text is currently hard to read due to:
  - narrow layout width and clipping (`overflow`/`white-space` constraints),
  - mixed message semantics mapped to only two visible states (green/red).

### Acceptance behavior

1. Readable text must not be truncated to the first two words in normal status strings.
2. Color meaning is explicit:
  - green: character is currently treatable,
  - red: unrecoverable now because perk is missing or other hard blockers,
  - orange: all treatable wounds already shortened (no remaining treatable injuries this session).
3. Existing states must preserve current row status messages or use equivalent semantics without losing context.
4. No combat or roster logic changes beyond status rendering.

### Proposed implementation

1. Backend reason mapping
  - In `getRosterBandageUseResult()` keep returning `Reason` values that distinguish:
    - `missing_perk`,
    - `no_treatable_injury`,
    - `no_temporary_injury`,
    - `permanent_injury_only`,
    - `ok`.
  - Add/adjust a helper message for `no_treatable_injury` so orange text can be targeted cleanly.

2. Row class/state mapping
  - In `loadFromData()` add/keep explicit row class mapping from `Reason`:
    - `CanUse` true → green,
    - red reasons (`missing_perk`, `no_temporary_injury`, `permanent_injury_only`) → red,
    - `no_treatable_injury` → orange.
  - Use a deterministic mapping instead of relying only on `.is-eligible/.is-disabled`.

3. CSS readability updates
  - Update `.bandages-enhanced-row-bottom .status` layout rules:
    - increase width where needed,
    - remove `white-space: nowrap` / keep truncation controlled with ellipsis only where necessary,
    - keep layout stable for long lines.
  - Add/ensure orange state class style (e.g. `.bandages-enhanced-row.is-treated { color: <orange>; }` and/or `.bandages-enhanced-row-bottom .status.is-treated`).

4. Quick pass verification
  - Check with sample status messages:
    - green: treatable injury count text,
    - red: missing perk/permanent-only/no temporary,
    - orange: already at floor values.
  - Confirm buttons and hover behavior remain unchanged from current mod fix.

### Open items

1. Which exact orange color should be used (`#B56A58` currently exists for red/dark states; we can reuse with different tone if available)?
2. Confirm whether “already treated” should be a distinct row-level orange even if bandage can be used on another reason.

## Documentation

1. Update `mod_bandages_enhanced/README.md` to describe one-bandage-per-injury behavior.
2. Sync wording with your external note at `bandages_enhanced.md` once you confirm intended final defaults.

## Open questions before coding

1. Do you want strict `1` injury by default permanently, or keep a configurable `InjuriesPerBandageUse` for faster campaign play?
2. Should we hardcode deterministic heavy-first ordering, or expose it as a boolean option?
