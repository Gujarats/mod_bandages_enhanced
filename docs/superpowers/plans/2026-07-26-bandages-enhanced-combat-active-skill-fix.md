# Bandages Enhanced Combat Active Skill Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the combat active skill behavior explicit and correct: using the bandage active skill in combat restores 35% max HP without the perk and 65% max HP with the perk, while removing the wrong outside-combat messaging assumption.

**Architecture:** Keep combat use on `scripts/skills/actives/bandage_ally_skill`; keep world-map injury recovery available through both the `Shift+C` treatment screen and the character-menu right-click item path. Fix combat percent calculation so tooltip and actual heal use the same actor, remove misleading popup text, restore silent right-click roster treatment, and add validator coverage for the corrected contract.

**Tech Stack:** Battle Brothers Squirrel hooks, MSU settings, PowerShell validator, `modbb`.

## Global Constraints

- Do not modify `data_001`.
- Do not modify community mods.
- Combat active skill must work in tactical combat.
- Without `perk.bandages_enhanced`, combat bandage active skill restores 35% of the bandage user's max HP setting by default.
- With `perk.bandages_enhanced`, combat bandage active skill restores 65% of the bandage user's max HP setting by default.
- The heal is capped by the target's missing HP and max HP.
- Bandages still remove bleeding and fresh bandage-treatable wounds.
- Roster temporary-injury recovery remains outside-combat through `Shift+C` and through right-click bandage use on the selected character in the character menu.
- Right-click bandage use on the world-map character menu applies the mod recovery behavior silently only to the selected character if that character has acquired `perk.bandages_enhanced`; it must not spawn a UI message.
- No modal Bandages Enhanced popup should open during tactical combat.
- Build verification must use `modbb`.

---

## Current Findings

The current implementation already hooks `bandage_ally_skill` and intends to support combat healing, but there are two problems:

1. The tooltip uses the skill user to calculate the percent:

```squirrel
local actor = this.getContainer().getActor();
local percent = ::BandagesEnhanced.Helpers.getCombatHealPercent(actor);
```

2. The actual heal uses the target to calculate the percent:

```squirrel
local healAmount = this.getMaxHPHealAmount(_target);
```

That means applying bandages to an ally can heal for a different percent than the tooltip says. The fix should make the perk check come from the bandage user, while the heal cap still comes from the target's missing HP.

---

### Task 1: Lock The Combat Healing Contract In The Validator

**Files:**
- Modify: `tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Consumes: existing validator tokens.
- Produces: validator checks for user-based combat heal calculation and corrected combat messaging.

- [ ] **Step 1: Add failing validator tokens for the intended combat contract**

In the `Require-Token 'scripts/config/z_bandages_enhanced.nut'` block, require:

```powershell
'function getMaxHPHealAmount( _user, _target )',
'local percent = this.getCombatHealPercent(_user);',
'local missing = _target.getHitpointsMax() - _target.getHitpoints();',
'return ::Math.max(0, ::Math.min(missing, amount));'
```

In the `Require-Token 'scripts/!mods_preload/mod_bandages_enhanced_loader.nut'` block, require:

```powershell
'::BandagesEnhanced.Helpers.applyCombatBandage(_user, target)',
'::BandagesEnhanced.Helpers.applyRosterBandage(_actor)',
'this.m.Item.removeSelf();',
'bandage item roster use applied and item consumed'
```

Also forbid the wrong messages/UI redirects:

```powershell
Forbid-Token 'scripts/!mods_preload/mod_bandages_enhanced_loader.nut' @(
    'Bandages Enhanced can only be used from the character screen outside combat.',
    'showRosterBandagePopup("Use Shift+C on the world map to open Bandages Enhanced treatment.");'
)
```

- [ ] **Step 2: Run validator and confirm it fails**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fail because `getMaxHPHealAmount( _user, _target )` does not exist yet, the forbidden message still exists, and right-click roster treatment is still redirected instead of applied.

---

### Task 2: Fix Combat Heal Percent Source

**Files:**
- Modify: `scripts/config/z_bandages_enhanced.nut`

**Interfaces:**
- Consumes: `getCombatHealPercent(_actor)`.
- Produces: `getMaxHPHealAmount(_user, _target)` where percent is based on `_user`, cap is based on `_target`.

- [ ] **Step 1: Change helper signature**

Replace:

```squirrel
function getMaxHPHealAmount( _actor )
```

with:

```squirrel
function getMaxHPHealAmount( _user, _target )
```

- [ ] **Step 2: Change helper implementation**

Replace the body with:

```squirrel
if (_target == null) return 0;

local percent = this.getCombatHealPercent(_user);
local amount = ::Math.floor(_target.getHitpointsMax() * percent / 100.0);
local missing = _target.getHitpointsMax() - _target.getHitpoints();
return ::Math.max(0, ::Math.min(missing, amount));
```

- [ ] **Step 3: Change combat apply call**

In `applyCombatBandage(_user, _target)`, replace:

```squirrel
local healAmount = this.getMaxHPHealAmount(_target);
```

with:

```squirrel
local healAmount = this.getMaxHPHealAmount(_user, _target);
```

- [ ] **Step 4: Keep target HP mutation unchanged**

Keep:

```squirrel
actor.setHitpoints(::Math.min(actor.getHitpointsMax(), actor.getHitpoints() + healAmount));
```

This keeps the heal capped by the target's max HP.

---

### Task 3: Restore Silent World-Map Right-Click Roster Treatment

**Files:**
- Modify: `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`
- Modify: `README.md`

**Interfaces:**
- Consumes: existing `bandage_item.onUse` right-click/roster item path and `::BandagesEnhanced.Helpers.applyRosterBandage(_actor)`.
- Produces: world-map right-click bandage use silently applies temporary-injury recovery only when the selected character has acquired `perk.bandages_enhanced`, and consumes the bandage only on success.

- [ ] **Step 1: Remove misleading tactical-active popup call**

In `bandage_item.onUse`, replace:

```squirrel
if (this.Tactical.isActive())
{
    ::BandagesEnhanced.Helpers.debugLog("bandage item roster use rejected: tactical active");
    showRosterBandagePopup("Bandages Enhanced can only be used from the character screen outside combat.");
    return false;
}
```

with:

```squirrel
if (this.Tactical.isActive())
{
    ::BandagesEnhanced.Helpers.debugLog("bandage item roster use ignored during tactical; use active skill");
    return false;
}
```

Reason: combat use is handled by `bandage_ally_skill`, not the right-click roster item path. Returning `false` here prevents accidental item consumption and avoids modal UI freeze.

- [ ] **Step 2: Restore silent outside-combat right-click recovery**

Replace the outside-combat redirect:

```squirrel
::BandagesEnhanced.Helpers.debugLog("bandage item roster use redirected to treatment screen");
showRosterBandagePopup("Use Shift+C on the world map to open Bandages Enhanced treatment.");
return false;
```

with:

```squirrel
if (!::BandagesEnhanced.Helpers.applyRosterBandage(_actor))
{
    ::BandagesEnhanced.Helpers.debugLog("bandage item roster use rejected by helper");
    return false;
}

if (this.m.Item != null && !this.m.Item.isNull())
{
    this.m.Item.removeSelf();
}

::BandagesEnhanced.Helpers.debugLog("bandage item roster use applied and item consumed");
return true;
```

Reason: the agreed behavior is that right-clicking a bandage on the world-map character menu should use the mod behavior directly, make temporary injuries heal faster only for a selected character who acquired the Bandages Enhanced perk, and show no UI message. Debug logs are allowed for success/failure.

- [ ] **Step 3: Update item tooltip wording**

Replace the tooltip text:

```squirrel
"With Bandages Enhanced, Right-click or drag onto the currently selected character outside combat to speed up temporary injury recovery"
```

with:

```squirrel
"With Bandages Enhanced, using key-binding default Shift+C to speed up recovery"
```

- [ ] **Step 4: Update README wording**

Ensure README states:

```markdown
In combat, use the bandage active skill from the skill bar. By default, the active skill restores 35% max HP without the perk and 65% max HP when the user has acquired Bandages Enhanced. These values come from MSU settings and can be changed.

On the world map, right-clicking a bandage in the character menu applies Bandages Enhanced recovery to the selected character only when that character has acquired the Bandages Enhanced perk and has an eligible temporary injury. It does not show a UI message; check debug logs for failure reasons. The Shift+C screen is also available for choosing a target from the roster.
```

Ensure README does not state that Bandages Enhanced can only be used outside combat.

---

### Task 4: Verify Active Skill Hook Requirements

**Files:**
- Modify: `tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Consumes: hook implementation in `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`.
- Produces: validator coverage that active-skill combat behavior remains installed.

- [ ] **Step 1: Require active skill combat tokens**

In the loader token block, ensure all of these remain required:

```powershell
'mod.hook("scripts/skills/actives/bandage_ally_skill", function(q)',
'this.m.Description = "Apply improved bandages to yourself or an ally. Removes bleeding and fresh bandage-treatable wounds, and restores hitpoints based on maximum hitpoints.";',
'Restores [color=" + this.Const.UI.Color.PositiveValue + "]"',
'Can be used while engaged in melee',
'if (!this.Tactical.isActive()) return false;',
'local result = this.skill.isUsable();',
'::BandagesEnhanced.Helpers.canUseBandageInCombatOn(target)',
'::BandagesEnhanced.Helpers.applyCombatBandage(_user, target)',
'this.m.Item.removeSelf();'
```

- [ ] **Step 2: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: pass after Tasks 2-3 are implemented.

---

### Task 5: Build And Runtime Verification

**Files:**
- Read: `C:\Users\gujar\Documents\Battle Brothers\log.html`

**Interfaces:**
- Consumes: completed code changes.
- Produces: build verification and manual runtime checklist.

- [ ] **Step 1: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected:

```text
Bandages Enhanced layout validation passed.
```

- [ ] **Step 2: Run modbb**

Run:

```powershell
modbb --game-data-dir dist\verify_game_data
```

Expected: build completes and deploys `mod_bandages_enhanced.zip`.

- [ ] **Step 3: Manual combat test without perk**

In combat:

1. Select a brother without `perk.bandages_enhanced`.
2. Damage an allied target.
3. Use the bandage active skill from the skill bar.
4. Confirm target heals for 35% of target max HP, capped by missing HP.
5. Confirm one bandage is consumed.
6. Confirm no modal popup appears.

- [ ] **Step 4: Manual combat test with perk**

In combat:

1. Select a brother with `perk.bandages_enhanced`.
2. Damage an allied target.
3. Use the bandage active skill from the skill bar.
4. Confirm target heals for 65% of target max HP, capped by missing HP.
5. Confirm one bandage is consumed.
6. Confirm no modal popup appears.

- [ ] **Step 5: Check logs**

Filter:

```text
BandagesEnhanced
Script Error
Failed to load
Exception
popup suppressed during tactical
bandage skill use applied and item consumed
```

Expected:

- `bandage skill use applied and item consumed` appears for successful active skill uses.
- No `Script Error`.
- No modal popup freeze.

---

## Self-Review

- The plan fixes the incorrect assumption by removing the wrong combat popup wording.
- The plan fixes the incorrect world-map assumption by restoring silent right-click roster recovery instead of showing a message.
- The plan preserves the user requirement that combat active skills work.
- The plan makes 35%/65% behavior consistent between tooltip and actual heal.
- The plan keeps roster temporary-injury treatment outside combat through both right-click item use and `Shift+C`, which is separate from combat active-skill healing.
