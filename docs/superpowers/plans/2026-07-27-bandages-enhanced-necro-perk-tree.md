# Bandages Enhanced Necro perk_tree compatibility plan

## Goal

Add `Bandages Enhanced` into Necro perk trees while keeping the current `mod_bandages_enhanced` behavior for all other perk trees, without changing `mod_necro` or `mod_cro`.

## Constraints

- No edits to `mod_necro` and no edits to `mod_cro`.
- Preserve current perk injection behavior for non-necro trees.
- Keep deduplication logic so `perk.bandages_enhanced` is never duplicated.
- Maintain order-safe behavior so necro tree injection is not silently lost by later hook order changes.

## Affected files

- `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_loader.nut` (planned change)
- `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1` (optional hardening, planned)
- `mod_bandages_enhanced/README.md` (plan note update, optional)

## Planned implementation

### 1) Ensure queue ordering places Bandages Enhanced after mod_necro

- Update the queue line in `mod_bandages_enhanced_loader.nut`.
- Add `>mod_necro` in `::BandagesEnhanced.HookMod.queue(...)`.

```nut
::BandagesEnhanced.HookMod.queue(">mod_msu", ">mod_druid", ">mod_aura_routing", ">mod_from_the_grave", ">mod_legends", ">mod_necro", function()
{
    ...
}
);
```

- This ensures the `data_helper` hook registration for bandage perk injection runs after `mod_necro` has a chance to create `necro_perkTree`.

### 2) Make perk-tree injection explicitly include `necro_perkTree`

- In the existing `q.convertEntityToUIData` hook, keep existing `_perkTree` merge behavior.
- Add explicit handling for Necro so it is clear this is intended behavior and not dependent only on naming convention.
- Guard on Necro actor only when possible, to avoid side effects:

1. Keep current generic loop for keys that end in `_perkTree` and are arrays.
2. Add explicit step:
   - If `_entity` has `background.necro`, ensure `result.necro_perkTree` is passed through `appendBandagesEnhancedPerks`.
   - Log a debug line when necro injection succeeds.

```nut
local isNecro = _entity != null && _entity.getSkills() != null && _entity.getSkills().hasSkill("background.necro");

// existing loop keeps all *_perkTree entries
// ...

if (isNecro && ("necro_perkTree" in result))
{
    result.necro_perkTree = ::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(result.necro_perkTree, row);
    ::BandagesEnhanced.Helpers.debugLog("merged Bandages Enhanced perk into necro_perkTree for " + _entity.getName());
}
```

### 3) Keep fallback behavior safe and deterministic

- Keep the existing fallback assignment to `result.bandages_enhanced_perkTree` if no `*_perkTree` was found.
- Dedupe behavior remains in helper:
  - `appendBandagesEnhancedPerks` already skips insert if `perk.bandages_enhanced` already exists.
- This makes the necro-specific branch additive and non-destructive.

### 4) Optional test hardening

- Extend validator in `tools/test_bandages_enhanced_layout.ps1` with required snippet checks:
  - queue string includes `>mod_necro`
  - `result.necro_perkTree = ::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(` or equivalent explicit token
  - a debug log string for explicit necro merge path

### 5) Optional docs

- Add a short compatibility note in `README.md`:
  - "Necromancer perk trees receive Bandages Enhanced through Bandages Enhanced queue-order and explicit tree injection."

## Validation plan

- Run static validator after code changes:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1`
- Runtime check for Necro:
  - Load mod with `mod_bandages_enhanced` and `mod_necro`.
  - Open character UI for a Necro.
  - Confirm `necro_perkTree` includes `Bandages Enhanced` at configured row.
  - Confirm no duplicate `perk.bandages_enhanced` entries in displayed trees.
- Compatibility check:
  - Load a non-Necro character.
  - Confirm expected behavior of existing non-necro perk-tree injection is unchanged.
- Regression check:
  - Confirm `mod_bandages_enhanced` still builds and runs normally when Necro is absent.
