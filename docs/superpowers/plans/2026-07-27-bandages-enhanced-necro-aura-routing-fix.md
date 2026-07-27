# Bandages Enhanced compatibility patch: Necro perk tree with Aura Routing present

## Goal

Guarantee Necro perk-tree injection for `mod_bandages_enhanced` even when `mod_aura_routing` is active, without changing any other mod.

## Constraints

- Do not modify `mod_necro`, `mod_aura_routing`, or `mod_cro`.
- Preserve existing behavior for non-necro perk trees and existing deduplication.
- Keep changes scoped to `mod_bandages_enhanced`.

## Problem hypothesis

Current logic in `convertEntityToUIData` skips `necro_perkTree` in the generic loop and only adds it in a separate branch guarded by an `isNecro` skill check:

- If `_entity.getSkills()` state is not reliable at that callback point, `isNecro` can be false even though `result.necro_perkTree` already exists.
- Generic merge then skips `necro_perkTree`, so Bandages Enhanced is not injected for that entity.

## Plan

1. Add a focused implementation note plan file (this document) before editing code.
2. In `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_loader.nut`:
   - Update `q.convertEntityToUIData` to merge **all** `_perkTree` arrays except `bandages_enhanced_perkTree`.
   - Remove the dedicated `isNecro` gating for merge behavior.
   - Keep fallback injection behavior unchanged when no perk trees are present.
   - Keep dedupe behavior unchanged via `appendBandagesEnhancedPerks`.
3. Keep the queue ordering as-is because this plan assumes the existing `>mod_necro` dependency already remains.

## Expected behavior after patch

- Necro perk trees get Bandages Enhanced whenever `result.necro_perkTree` is present.
- Non-necro behavior remains unchanged.
- No dependency modifications to `mod_aura_routing` are required.
