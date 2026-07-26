# Bandages Enhanced Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `mod_bandages_enhanced`, replacing vanilla bandage behavior so bandages can be used in melee, restore HP based on max HP, and gain stronger HP/injury recovery effects through a configurable perk.

**Architecture:** Use Modern Hooks/MSU like `mod_aura_routing`: register a new mod, settings, debug logging, and a configurable perk. Hook vanilla `scripts/skills/actives/bandage_ally_skill` for combat behavior and vanilla `scripts/items/accessory/bandage_item` for item tooltip, price, and roster/inventory use. Put shared healing and injury-duration logic in one helper namespace so combat and campaign item use behave consistently.

**Tech Stack:** Battle Brothers Squirrel scripts, Modern Hooks, MSU settings/debug, vanilla bandage item/skill hooks, `modbb` build flow, PowerShell static validator.

## Global Constraints

- Follow `context.md`: do not modify `data_001`; use it only as reference.
- Follow `context.md`: use `modbb` for build verification; do not manually build ZIP files.
- Follow `context.md`: add programmatic debug logs and make logging configurable; default logging enabled for the first version.
- Follow `context.md`: document runtime assumptions in `README.md`.
- Mod ID is `mod_bandages_enhanced`.
- Mod display name is `Bandages Enhanced`.
- Keep vanilla bandage item ID `accessory.bandage`; this replaces vanilla behavior and preserves existing save/item compatibility.
- Keep vanilla active skill ID `actives.bandage_ally`; this replaces vanilla behavior and preserves existing skill/item wiring.
- New perk ID is `perk.bandages_enhanced`.
- New perk display name is `Bandages Enhanced`.
- HP restore is percent of max HP, capped at max HP: without perk `35%`, with perk `65%`.
- Default perk row is `2`, configurable via MSU settings.
- Default bandage item price uses vanilla base value `25`, configurable via MSU settings.
- Bandages can be used in melee by both user and target.
- Existing battle behavior remains: remove bleeding and fresh Cut Artery, Cut Neck Vein, and Grazed Neck injuries.
- Bandages cannot heal or shorten permanent injuries.
- Roster/inventory injury recovery is perk-gated: only actors with `perk.bandages_enhanced` can use bandages outside combat for injury recovery.

---

## ID And Naming Review

Use these names unless the user explicitly changes them before implementation:

```text
Mod namespace: ::BandagesEnhanced
Mod ID: mod_bandages_enhanced
Mod name: Bandages Enhanced
Perk ID: perk.bandages_enhanced
Perk name: Bandages Enhanced
Config perk array: ::Const.Perks.BandagesEnhanced
Hook loader: scripts/!mods_preload/mod_bandages_enhanced_loader.nut
Settings file: scripts/!mods_preload/mod_bandages_enhanced_settings.nut
Perk config: scripts/config/z_bandages_enhanced.nut
Perk skill: scripts/skills/perks/bandages_enhanced_perk.nut
Shared helper: scripts/!mods_preload/mod_bandages_enhanced_helpers.nut
```

Rationale:

- `mod_bandages_enhanced` matches the requested mod name and common mod ID style.
- `perk.bandages_enhanced` avoids changing vanilla bandage IDs and makes save entries clear.
- The vanilla item/skill IDs remain unchanged because this is a behavior replacement, not a new item line.

---

## File Structure

- Create: `mod_bandages_enhanced/mod_config.json`
  - `modbb` metadata, matching the project style used by `mod_aura_routing`.
- Create: `mod_bandages_enhanced/README.md`
  - Player-facing behavior, settings, assumptions, and runtime verification notes.
- Create: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_loader.nut`
  - Registers Modern Hooks/MSU mod, settings, helper namespace, and hooks vanilla classes.
- Create: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_settings.nut`
  - MSU settings for debug, price, perk row, HP restore percent, and injury day targets.
- Create: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_helpers.nut`
  - Shared logic for debug logs, max-HP healing, target eligibility, and injury duration compression.
- Create: `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut`
  - Registers the perk into `::Const.Perks.LookupMap` and `::Const.Perks.BandagesEnhanced`.
- Create: `mod_bandages_enhanced/scripts/skills/perks/bandages_enhanced_perk.nut`
  - Passive perk definition.
- Create: `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`
  - Static validator to catch missing hooks, missing settings, invalid IDs, and accidental vanilla-file edits.

No custom art is required for v1. The perk should use the existing vanilla bandage item icon path `ui/items/consumables/bandages_01.png` if it renders correctly in perk UI; if it does not, use `skills/active_105.png` and document that assumption in `README.md`.

---

### Task 1: Scaffold Mod Project And Static Validator

**Files:**
- Create: `mod_config.json`
- Create: `README.md`
- Create: `tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Produces: project metadata and a validator that later tasks must satisfy.

- [ ] **Step 1: Write the failing validator**

Create `tools/test_bandages_enhanced_layout.ps1`:

```powershell
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $projectRoot

function Require-File {
    param([string] $Path)
    $fullPath = Join-Path $projectRoot $Path
    if (!(Test-Path -LiteralPath $fullPath)) {
        throw "Missing required file: $Path"
    }
}

function Require-Token {
    param([string] $Path, [string[]] $Tokens)
    $fullPath = Join-Path $projectRoot $Path
    if (!(Test-Path -LiteralPath $fullPath)) {
        throw "Missing required file: $Path"
    }

    $content = Get-Content -Raw -LiteralPath $fullPath
    foreach ($token in $Tokens) {
        if (!$content.Contains($token)) {
            throw "Missing token in ${Path}: $token"
        }
    }
}

function Forbid-Token {
    param([string] $Path, [string[]] $Tokens)
    $fullPath = Join-Path $projectRoot $Path
    if (!(Test-Path -LiteralPath $fullPath)) {
        return
    }

    $content = Get-Content -Raw -LiteralPath $fullPath
    foreach ($token in $Tokens) {
        if ($content.Contains($token)) {
            throw "Forbidden token in ${Path}: $token"
        }
    }
}

Require-File 'mod_config.json'
Require-File 'README.md'
Require-File 'scripts/!mods_preload/mod_bandages_enhanced_loader.nut'
Require-File 'scripts/!mods_preload/mod_bandages_enhanced_settings.nut'
Require-File 'scripts/!mods_preload/mod_bandages_enhanced_helpers.nut'
Require-File 'scripts/config/z_bandages_enhanced.nut'
Require-File 'scripts/skills/perks/bandages_enhanced_perk.nut'

Require-Token 'mod_config.json' @(
    '"mod_id": "mod_bandages_enhanced"',
    '"mod_name": "Battle Brothers Mod Bandages Enhanced"',
    '"version": "0.0.1"',
    '"steam_app_id": "365360"'
)

Require-Token 'scripts/!mods_preload/mod_bandages_enhanced_loader.nut' @(
    '::BandagesEnhanced <- {',
    'ID = "mod_bandages_enhanced"',
    'Name = "Bandages Enhanced"',
    'Version = "0.0.1"',
    '::Hooks.register(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name)',
    '::BandagesEnhanced.HookMod.require("mod_msu >= 1.9.0");',
    '::BandagesEnhanced.registerSettings();',
    '::BandagesEnhanced.configureDebugLogging();',
    '::BandagesEnhanced.Helpers.debugLog("settings initialized");',
    'mod.hook("scripts/skills/actives/bandage_ally_skill", function(q)',
    'mod.hook("scripts/items/accessory/bandage_item", function(q)',
    'mod.hook("scripts/ui/global/data_helper", function(q)',
    'bandage skill hook create',
    'bandage skill isUsable',
    'bandage skill verify target',
    'bandage skill use',
    'bandage item hook create',
    'bandage item roster use',
    'bandage item roster use rejected',
    'bandage item roster use applied'
)

Require-Token 'scripts/!mods_preload/mod_bandages_enhanced_settings.nut' @(
    '::BandagesEnhanced.registerSettings <- function()',
    'general.addBooleanSetting("DebugLogging", true',
    'general.addRangeSetting("BandageValue", 25, 1, 1000, 1',
    'general.addRangeSetting("PerkLevel", 2, 1, 7, 1',
    'combat.addRangeSetting("BaseHealPercentMaxHP", 35, 0, 100, 1',
    'combat.addRangeSetting("PerkHealPercentMaxHP", 65, 0, 100, 1',
    'recovery.addRangeSetting("LightInjuryMaxDays", 1, 1, 10, 1',
    'recovery.addRangeSetting("HeavyInjuryMaxDays", 2, 1, 10, 1',
    'recovery.addRangeSetting("LightInjuryThresholdDays", 3, 1, 10, 1'
)

Require-Token 'scripts/!mods_preload/mod_bandages_enhanced_helpers.nut' @(
    '::BandagesEnhanced.configureDebugLogging <- function()',
    '::BandagesEnhanced.Helpers <- {',
    'function debugLog( _message )',
    'function hasBandagesEnhancedPerk( _actor )',
    'function getCombatHealPercent( _actor )',
    'function getMaxHPHealAmount( _actor )',
    'function canTreatVanillaBandageCondition( _target )',
    'function canUseBandageInCombatOn( _target )',
    'function applyCombatBandage( _user, _target )',
    'function compressTemporaryInjuries( _actor )',
    'function canUseBandageOnRoster( _actor )',
    'function applyRosterBandage( _actor )',
    'debugLog("combat bandage rejected',
    'debugLog("combat bandage used',
    'debugLog("roster bandage rejected',
    'debugLog("roster bandage compressed',
    'this.Const.SkillType.TemporaryInjury',
    'this.Const.SkillType.PermanentInjury',
    'actor.setHitpoints(this.Math.min(actor.getHitpointsMax(), actor.getHitpoints() + healAmount));'
)

Require-Token 'scripts/config/z_bandages_enhanced.nut' @(
    '::Const.Perks.BandagesEnhanced <- [];',
    'ID = "perk.bandages_enhanced"',
    'Script = "scripts/skills/perks/bandages_enhanced_perk"',
    'Name = "Bandages Enhanced"',
    'Tooltip = "Improves bandages so they restore more hitpoints and speed up temporary injury recovery."',
    'Icon = "ui/items/consumables/bandages_01.png"',
    'IconDisabled = "ui/items/consumables/bandages_01.png"',
    'Row = 2'
)

Require-Token 'scripts/skills/perks/bandages_enhanced_perk.nut' @(
    'this.bandages_enhanced_perk <- this.inherit("scripts/skills/skill", {',
    'this.m.ID = "perk.bandages_enhanced";',
    'this.m.Type = this.Const.SkillType.Perk;',
    'this.m.Order = this.Const.SkillOrder.Perk;'
)

Require-Token 'README.md' @(
    '# Bandages Enhanced',
    'Bandages restore hitpoints based on max HP.',
    'Without the perk, bandages restore 35% of max HP.',
    'With Bandages Enhanced, bandages restore 65% of max HP.',
    'Bandages can be used while engaged in melee.',
    'Bandages never heal permanent injuries.',
    'Runtime assumptions'
)

Forbid-Token '..\data_001\scripts\items\accessory\bandage_item.nut' @(
    'Bandages Enhanced'
)

Forbid-Token '..\data_001\scripts\skills\actives\bandage_ally_skill.nut' @(
    'Bandages Enhanced'
)

Write-Host 'Bandages Enhanced layout validation passed.'
```

- [ ] **Step 2: Run validator to verify RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fails on missing `mod_config.json` or the first missing script file.

- [ ] **Step 3: Create `mod_config.json`**

Create `mod_config.json`:

```json
{
  "mod_id": "mod_bandages_enhanced",
  "mod_name": "Battle Brothers Mod Bandages Enhanced",
  "version": "0.0.1",
  "game_data_dir": "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Battle Brothers\\data",
  "steam_app_id": "365360"
}
```

- [ ] **Step 4: Create `README.md`**

Create `README.md`:

```markdown
# Bandages Enhanced

Bandages Enhanced replaces vanilla bandage behavior.

## Behavior

- Bandages restore hitpoints based on max HP.
- Without the perk, bandages restore 35% of max HP.
- With Bandages Enhanced, bandages restore 65% of max HP.
- Healing is capped at the actor's current maximum hitpoints.
- Bandages can be used while engaged in melee.
- Bandages still remove bleeding and fresh Cut Artery, Cut Neck Vein, and Grazed Neck injuries.
- Bandages never heal permanent injuries.
- With the perk, bandages can be used outside combat to speed up temporary injury recovery.

## Settings

- Debug Logging: enabled by default for the first version.
- Bandage Value: default 25, matching vanilla.
- Perk Row: default 2.
- Base Heal Percent Max HP: default 35.
- Perk Heal Percent Max HP: default 65.
- Light Injury Threshold Days: default 3.
- Light Injury Max Days: default 1.
- Heavy Injury Max Days: default 2.

## Runtime assumptions

- The perk uses the existing vanilla bandage item icon `ui/items/consumables/bandages_01.png`. If this icon path does not render correctly in the perk UI, switch the perk icon to `skills/active_105.png`.
- Roster/inventory use relies on vanilla item `onUse(_actor, _item = null)` behavior used by consumable items. Verify by right-clicking or dragging bandages onto the selected character outside combat.
- Injury recovery compression changes only temporary injuries by adjusting their healing-time fields; permanent injuries are explicitly ignored.

## Build

Use `modbb` from this folder. Do not manually build the zip.

## Debug log

Check `C:\Users\gujar\Documents\Battle Brothers\log.html` for lines beginning with `[BandagesEnhanced]`.
```

- [ ] **Step 5: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: still fails because hook/config scripts are not created yet.

---

### Task 2: Register Mod, Settings, Debug, And Perk

**Files:**
- Create: `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`
- Create: `scripts/!mods_preload/mod_bandages_enhanced_settings.nut`
- Create: `scripts/config/z_bandages_enhanced.nut`
- Create: `scripts/skills/perks/bandages_enhanced_perk.nut`

**Interfaces:**
- Produces: `::BandagesEnhanced.Mod.ModSettings` and `perk.bandages_enhanced`.
- Produces: `::Const.Perks.BandagesEnhanced`, injected into perk UI at configurable row.

- [ ] **Step 1: Create settings file**

Create `scripts/!mods_preload/mod_bandages_enhanced_settings.nut`:

```nut
::BandagesEnhanced.registerSettings <- function()
{
    local general = ::BandagesEnhanced.Mod.ModSettings.addPage("General");
    local combat = ::BandagesEnhanced.Mod.ModSettings.addPage("Combat");
    local recovery = ::BandagesEnhanced.Mod.ModSettings.addPage("Recovery");

    general.addBooleanSetting("DebugLogging", true, "Debug Logging", "Write Bandages Enhanced debug lines to log.html.");
    general.addRangeSetting("BandageValue", 25, 1, 1000, 1, "Bandage Value", "Base value for bandages. Default matches vanilla.");
    general.addRangeSetting("PerkLevel", 2, 1, 7, 1, "Perk Row", "Which perk row unlocks Bandages Enhanced. Requires restart.");

    combat.addRangeSetting("BaseHealPercentMaxHP", 35, 0, 100, 1, "Base Max HP Heal (%)", "Bandage healing as percent of max HP without the perk.");
    combat.addRangeSetting("PerkHealPercentMaxHP", 65, 0, 100, 1, "Perk Max HP Heal (%)", "Bandage healing as percent of max HP with Bandages Enhanced.");

    recovery.addRangeSetting("LightInjuryThresholdDays", 3, 1, 10, 1, "Light Injury Threshold Days", "Temporary injuries with current max recovery days at or below this value are compressed to Light Injury Max Days.");
    recovery.addRangeSetting("LightInjuryMaxDays", 1, 1, 10, 1, "Light Injury Max Days", "Target max recovery days for light temporary injuries.");
    recovery.addRangeSetting("HeavyInjuryMaxDays", 2, 1, 10, 1, "Heavy Injury Max Days", "Target max recovery days for heavier temporary injuries.");
}
```

- [ ] **Step 2: Create perk config**

Create `scripts/config/z_bandages_enhanced.nut`:

```nut
::Const.Perks.BandagesEnhanced <- [];

local function addPerk( perk )
{
    perk.Unlocks <- perk.Row;
    perk.verifyPrerequisites <- function( _player, _tooltip )
    {
        return true;
    }

    ::Const.Perks.BandagesEnhanced.push(perk);
    ::Const.Perks.LookupMap[perk.ID] <- perk;
}

addPerk({
    ID = "perk.bandages_enhanced",
    Script = "scripts/skills/perks/bandages_enhanced_perk",
    Name = "Bandages Enhanced",
    Tooltip = "Improves bandages so they restore more hitpoints and speed up temporary injury recovery.",
    Icon = "ui/items/consumables/bandages_01.png",
    IconDisabled = "ui/items/consumables/bandages_01.png",
    Row = 2
});
```

- [ ] **Step 3: Create perk skill**

Create `scripts/skills/perks/bandages_enhanced_perk.nut`:

```nut
this.bandages_enhanced_perk <- this.inherit("scripts/skills/skill", {
    m = {},

    function create()
    {
        this.m.ID = "perk.bandages_enhanced";
        local perk = ::Const.Perks.LookupMap[this.m.ID];
        this.m.Name = perk.Name;
        this.m.Description = perk.Tooltip;
        this.m.Icon = perk.Icon;
        this.m.IconDisabled = perk.IconDisabled;
        this.m.Type = this.Const.SkillType.Perk;
        this.m.Order = this.Const.SkillOrder.Perk;
    }
});
```

- [ ] **Step 4: Create loader skeleton**

Create `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`:

```nut
::BandagesEnhanced <- {
    ID = "mod_bandages_enhanced",
    Name = "Bandages Enhanced",
    Version = "0.0.1"
};

::BandagesEnhanced.HookMod <- ::Hooks.register(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name);
::BandagesEnhanced.HookMod.require("mod_msu >= 1.9.0");

::BandagesEnhanced.HookMod.queue(">mod_msu", function()
{
    ::BandagesEnhanced.Mod <- ::MSU.Class.Mod(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name);
    ::BandagesEnhanced.registerSettings();

    local mod = ::BandagesEnhanced.HookMod;

    mod.hook("scripts/ui/global/data_helper", function(q)
    {
        q.convertEntityToUIData = @(__original) function( _entity, _activeEntity )
        {
            local result = __original(_entity, _activeEntity);

            if (_entity != null)
            {
                local settings = ::BandagesEnhanced.Mod.ModSettings;
                local row = settings.getSetting("PerkLevel").getValue();
                local perks = ::Const.Perks.Perks.map(@(r) clone r);

                foreach (perk in ::Const.Perks.BandagesEnhanced)
                {
                    local p = clone perk;
                    delete p.verifyPrerequisites;
                    perks[row - 1].push(p);
                }

                result.bandages_enhanced_perkTree <- perks;
            }

            return result;
        }
    });

    mod.hook("scripts/skills/actives/bandage_ally_skill", function(q)
    {
    });

    mod.hook("scripts/items/accessory/bandage_item", function(q)
    {
    });
});
```

- [ ] **Step 5: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fails because helper functions and hook bodies are still missing.

---

### Task 3: Implement Shared Bandage Helper Logic

**Files:**
- Create: `scripts/!mods_preload/mod_bandages_enhanced_helpers.nut`

**Interfaces:**
- Consumes: `::BandagesEnhanced.Mod.ModSettings`
- Produces:
  - `debugLog(_message)`
  - `hasBandagesEnhancedPerk(_actor) -> bool`
  - `getCombatHealPercent(_actor) -> int`
  - `getMaxHPHealAmount(_actor) -> int`
  - `canTreatVanillaBandageCondition(_target) -> bool`
  - `canUseBandageInCombatOn(_target) -> bool`
  - `applyCombatBandage(_user, _target) -> bool`
  - `compressTemporaryInjuries(_actor) -> int`
  - `canUseBandageOnRoster(_actor) -> bool`
  - `applyRosterBandage(_actor) -> bool`

- [ ] **Step 1: Create helper file**

Create `scripts/!mods_preload/mod_bandages_enhanced_helpers.nut`:

```nut
::BandagesEnhanced.configureDebugLogging <- function()
{
    if (::BandagesEnhanced.Mod.ModSettings.getSetting("DebugLogging").getValue())
    {
        ::BandagesEnhanced.Mod.Debug.enable();
    }
    else
    {
        ::BandagesEnhanced.Mod.Debug.disable();
    }
}

::BandagesEnhanced.Helpers <- {
    function debugLog( _message )
    {
        if (::BandagesEnhanced.Mod.ModSettings.getSetting("DebugLogging").getValue())
        {
            ::BandagesEnhanced.Mod.Debug.printLog("[BandagesEnhanced] " + _message);
        }
    }

    function hasBandagesEnhancedPerk( _actor )
    {
        return _actor != null && _actor.getSkills() != null && _actor.getSkills().hasSkill("perk.bandages_enhanced");
    }

    function getCombatHealPercent( _actor )
    {
        local settings = ::BandagesEnhanced.Mod.ModSettings;
        return this.hasBandagesEnhancedPerk(_actor)
            ? settings.getSetting("PerkHealPercentMaxHP").getValue()
            : settings.getSetting("BaseHealPercentMaxHP").getValue();
    }

    function getMaxHPHealAmount( _actor )
    {
        if (_actor == null) return 0;

        local percent = this.getCombatHealPercent(_actor);
        local amount = ::Math.floor(_actor.getHitpointsMax() * percent / 100.0);
        local missing = _actor.getHitpointsMax() - _actor.getHitpoints();
        return ::Math.max(0, ::Math.min(missing, amount));
    }

    function canTreatVanillaBandageCondition( _target )
    {
        if (_target == null || _target.getSkills() == null) return false;

        if (_target.getSkills().hasSkill("effects.bleeding")) return true;

        local skill = _target.getSkills().getSkillByID("injury.cut_artery");
        if (skill != null && skill.isFresh()) return true;

        skill = _target.getSkills().getSkillByID("injury.cut_throat");
        if (skill != null && skill.isFresh()) return true;

        skill = _target.getSkills().getSkillByID("injury.grazed_neck");
        if (skill != null && skill.isFresh()) return true;

        return false;
    }

    function canUseBandageInCombatOn( _target )
    {
        if (_target == null || !_target.isAlive()) return false;
        if (this.canTreatVanillaBandageCondition(_target)) return true;
        return _target.getHitpoints() < _target.getHitpointsMax();
    }

    function removeVanillaBandageConditions( _target )
    {
        while (_target.getSkills().hasSkill("effects.bleeding"))
        {
            _target.getSkills().removeByID("effects.bleeding");
        }

        local skill = _target.getSkills().getSkillByID("injury.cut_artery");
        if (skill != null && skill.isFresh()) _target.getSkills().remove(skill);

        skill = _target.getSkills().getSkillByID("injury.cut_throat");
        if (skill != null && skill.isFresh()) _target.getSkills().remove(skill);

        skill = _target.getSkills().getSkillByID("injury.grazed_neck");
        if (skill != null && skill.isFresh()) _target.getSkills().remove(skill);
    }

    function applyCombatBandage( _user, _target )
    {
        if (_target == null) return false;

        local didTreat = this.canTreatVanillaBandageCondition(_target);
        this.removeVanillaBandageConditions(_target);

        local healAmount = this.getMaxHPHealAmount(_target);
        if (healAmount > 0)
        {
            local actor = _target;
            actor.setHitpoints(this.Math.min(actor.getHitpointsMax(), actor.getHitpoints() + healAmount));
            didTreat = true;

            if (!actor.isHiddenToPlayer())
            {
                ::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(actor) + " heals for " + healAmount + " hitpoints");
            }
        }

        if (!didTreat)
        {
            this.debugLog("combat bandage rejected for " + _target.getName() + ": no bleeding, fresh wound, or missing hitpoints");
        }

        this.debugLog("combat bandage used by " + (_user == null ? "<null>" : _user.getName()) + " on " + _target.getName() + ", heal=" + healAmount);
        return didTreat;
    }

    function getCurrentMaxHealingDays( _injury )
    {
        local ht = _injury.getHealingTime();
        return ht.Max;
    }

    function compressTemporaryInjuries( _actor )
    {
        if (_actor == null || !this.hasBandagesEnhancedPerk(_actor)) return 0;

        local settings = ::BandagesEnhanced.Mod.ModSettings;
        local lightThreshold = settings.getSetting("LightInjuryThresholdDays").getValue();
        local lightMax = settings.getSetting("LightInjuryMaxDays").getValue();
        local heavyMax = settings.getSetting("HeavyInjuryMaxDays").getValue();
        local changed = 0;
        local injuries = _actor.getSkills().query(this.Const.SkillType.TemporaryInjury);

        foreach (injury in injuries)
        {
            if (injury.isType(this.Const.SkillType.PermanentInjury)) continue;

            local currentMax = this.getCurrentMaxHealingDays(injury);
            local targetMax = currentMax <= lightThreshold ? lightMax : heavyMax;
            if (currentMax <= targetMax) continue;

            injury.m.HealingTimeMin = ::Math.min(injury.m.HealingTimeMin, targetMax);
            injury.m.HealingTimeMax = ::Math.max(injury.m.HealingTimeMin, targetMax);
            injury.setTreated(true);
            changed++;
        }

        if (changed > 0)
        {
            _actor.updateInjuryVisuals();
        }

        this.debugLog("roster bandage compressed " + changed + " temporary injuries on " + _actor.getName());
        return changed;
    }

    function canUseBandageOnRoster( _actor )
    {
        if (_actor == null || !this.hasBandagesEnhancedPerk(_actor)) return false;
        if (_actor.getSkills().hasSkillOfType(this.Const.SkillType.PermanentInjury)
            && !_actor.getSkills().hasSkillOfType(this.Const.SkillType.TemporaryInjury))
        {
            return false;
        }

        return _actor.getSkills().hasSkillOfType(this.Const.SkillType.TemporaryInjury);
    }

    function applyRosterBandage( _actor )
    {
        if (!this.canUseBandageOnRoster(_actor))
        {
            this.debugLog("roster bandage rejected for " + (_actor == null ? "<null>" : _actor.getName()));
            return false;
        }

        return this.compressTemporaryInjuries(_actor) > 0;
    }
};
```

- [ ] **Step 2: Include helper from loader**

In `mod_bandages_enhanced_loader.nut`, inside the MSU queue after `::BandagesEnhanced.registerSettings();`, add:

```nut
::include("scripts/!mods_preload/mod_bandages_enhanced_helpers");
::BandagesEnhanced.configureDebugLogging();
::BandagesEnhanced.Helpers.debugLog("settings initialized");
```

- [ ] **Step 3: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fails because bandage skill/item hook bodies are still missing.

---

### Task 4: Replace Combat Bandage Behavior

**Files:**
- Modify: `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`

**Interfaces:**
- Consumes: `::BandagesEnhanced.Helpers.canUseBandageInCombatOn(_target)`
- Consumes: `::BandagesEnhanced.Helpers.applyCombatBandage(_user, _target)`
- Produces: melee-usable bandage skill with max-HP healing.

- [ ] **Step 1: Add validator tokens for combat hook**

Extend `tools/test_bandages_enhanced_layout.ps1` loader tokens:

```powershell
    'this.m.Description = "Apply improved bandages to yourself or an ally. Removes bleeding and fresh bandage-treatable wounds, and restores hitpoints based on maximum hitpoints.";',
    'Can be used while engaged in melee',
    'Restores [color=" + this.Const.UI.Color.PositiveValue + "]"',
    '::BandagesEnhanced.Helpers.canUseBandageInCombatOn(target)',
    '::BandagesEnhanced.Helpers.applyCombatBandage(_user, target)',
    'this.m.Item.removeSelf();'
```

- [ ] **Step 2: Implement combat hook**

In `mod_bandages_enhanced_loader.nut`, replace the empty bandage skill hook:

```nut
mod.hook("scripts/skills/actives/bandage_ally_skill", function(q)
{
    q.create = @(__original) function()
    {
        __original();
        this.m.Description = "Apply improved bandages to yourself or an ally. Removes bleeding and fresh bandage-treatable wounds, and restores hitpoints based on maximum hitpoints.";
        ::BandagesEnhanced.Helpers.debugLog("bandage skill hook create");
    }

    q.getTooltip = @(__original) function()
    {
        local ret = __original();
        local actor = this.getContainer().getActor();
        local percent = ::BandagesEnhanced.Helpers.getCombatHealPercent(actor);

        ret.push({
            id = 20,
            type = "text",
            icon = "ui/icons/health.png",
            text = "Restores [color=" + this.Const.UI.Color.PositiveValue + "]" + percent + "%[/color] of max hitpoints, capped at maximum hitpoints"
        });
        ret.push({
            id = 21,
            type = "text",
            icon = "ui/icons/special.png",
            text = "Can be used while engaged in melee"
        });

        return ret;
    }

    q.isUsable = @(__original) function()
    {
        if (!this.Tactical.isActive()) return false;
        local result = this.skill.isUsable();
        local actor = this.getContainer().getActor();
        ::BandagesEnhanced.Helpers.debugLog("bandage skill isUsable actor=" + (actor == null ? "<null>" : actor.getName()) + " result=" + result);
        return result;
    }

    q.onVerifyTarget = @(__original) function( _originTile, _targetTile )
    {
        if (!this.skill.onVerifyTarget(_originTile, _targetTile)) return false;

        local target = _targetTile.getEntity();
        if (target == null)
        {
            ::BandagesEnhanced.Helpers.debugLog("bandage skill verify target rejected: null target");
            return false;
        }

        if (!this.m.Container.getActor().isAlliedWith(target))
        {
            ::BandagesEnhanced.Helpers.debugLog("bandage skill verify target rejected: target not allied");
            return false;
        }

        local result = ::BandagesEnhanced.Helpers.canUseBandageInCombatOn(target);
        ::BandagesEnhanced.Helpers.debugLog("bandage skill verify target=" + target.getName() + " result=" + result);
        return result;
    }

    q.onUse = @(__original) function( _user, _targetTile )
    {
        local target = _targetTile.getEntity();
        ::BandagesEnhanced.Helpers.debugLog("bandage skill use by " + (_user == null ? "<null>" : _user.getName()) + " on " + (target == null ? "<null>" : target.getName()));
        this.spawnIcon("perk_55", _targetTile);

        local didTreat = ::BandagesEnhanced.Helpers.applyCombatBandage(_user, target);
        if (!didTreat)
        {
            ::BandagesEnhanced.Helpers.debugLog("bandage skill use rejected after helper");
            return false;
        }

        if (this.m.Item != null && !this.m.Item.isNull())
        {
            this.m.Item.removeSelf();
        }

        this.updateAchievement("FirstAid", 1, 1);
        ::BandagesEnhanced.Helpers.debugLog("bandage skill use applied and item consumed");
        return true;
    }
});
```

- [ ] **Step 3: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fails only on item hook or README tokens if those are not done yet.

---

### Task 5: Replace Bandage Item Price, Tooltip, And Roster Use

**Files:**
- Modify: `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`

**Interfaces:**
- Consumes: `::BandagesEnhanced.Helpers.canUseBandageOnRoster(_actor)`
- Consumes: `::BandagesEnhanced.Helpers.applyRosterBandage(_actor)`
- Produces: bandages usable outside combat for perk holders with temporary injuries.

- [ ] **Step 1: Add validator tokens for item hook**

Extend `tools/test_bandages_enhanced_layout.ps1` loader tokens:

```powershell
    'this.m.Value = ::BandagesEnhanced.Mod.ModSettings.getSetting("BandageValue").getValue();',
    'this.m.IsUsable = true;',
    'this.m.ItemType = this.Const.Items.ItemType.Usable;',
    'Right-click or drag onto the currently selected character outside combat',
    '::BandagesEnhanced.Helpers.canUseBandageOnRoster(_actor)',
    '::BandagesEnhanced.Helpers.applyRosterBandage(_actor)'
```

- [ ] **Step 2: Implement item hook**

In `mod_bandages_enhanced_loader.nut`, replace the empty bandage item hook:

```nut
mod.hook("scripts/items/accessory/bandage_item", function(q)
{
    q.create = @(__original) function()
    {
        __original();
        this.m.Value = ::BandagesEnhanced.Mod.ModSettings.getSetting("BandageValue").getValue();
        this.m.IsUsable = true;
        this.m.ItemType = this.Const.Items.ItemType.Usable;
        this.m.Description = "Clean bandages that can be used in combat to stop bleeding and restore hitpoints. With Bandages Enhanced, they can also speed up temporary injury recovery outside combat.";
        ::BandagesEnhanced.Helpers.debugLog("bandage item hook create value=" + this.m.Value);
    }

    q.getTooltip = @(__original) function()
    {
        local result = __original();
        result.push({
            id = 70,
            type = "text",
            icon = "ui/icons/health.png",
            text = "Restores hitpoints based on maximum hitpoints when used in battle"
        });
        result.push({
            id = 71,
            type = "text",
            icon = "ui/icons/days_wounded.png",
            text = "With Bandages Enhanced, right-click or drag onto the currently selected character outside combat to speed up temporary injury recovery"
        });
        return result;
    }

    q.onUse = @(__original) function( _actor, _item = null )
    {
        ::BandagesEnhanced.Helpers.debugLog("bandage item roster use actor=" + (_actor == null ? "<null>" : _actor.getName()));

        if (this.Tactical.isActive())
        {
            ::BandagesEnhanced.Helpers.debugLog("bandage item roster use rejected: tactical active");
            return false;
        }

        if (!::BandagesEnhanced.Helpers.canUseBandageOnRoster(_actor))
        {
            ::BandagesEnhanced.Helpers.debugLog("roster bandage rejected for " + (_actor == null ? "<null>" : _actor.getName()));
            return false;
        }

        local applied = ::BandagesEnhanced.Helpers.applyRosterBandage(_actor);
        ::BandagesEnhanced.Helpers.debugLog("bandage item roster use applied=" + applied);
        return applied;
    }
});
```

- [ ] **Step 3: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected:

```text
Bandages Enhanced layout validation passed.
```

---

### Task 6: UI Perk Tree Integration

**Files:**
- Create: `ui/mods/bandages_enhanced.js`
- Create: `ui/mods/bandages_enhanced.css`
- Modify: `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`
- Modify: `tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Consumes: `result.bandages_enhanced_perkTree`.
- Produces: character screen perk tree injection so the perk can be acquired.

- [ ] **Step 1: Add validator tokens**

Add file requirements:

```powershell
Require-File 'ui/mods/bandages_enhanced.js'
Require-File 'ui/mods/bandages_enhanced.css'
```

Add loader tokens:

```powershell
    '::Hooks.registerJS("ui/mods/bandages_enhanced.js");',
    '::Hooks.registerCSS("ui/mods/bandages_enhanced.css");',
    'result.bandages_enhanced_perkTree <- perks;'
```

Add JS tokens:

```powershell
Require-Token 'ui/mods/bandages_enhanced.js' @(
    'var BandagesEnhanced = {};',
    'BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData',
    '_brother.bandages_enhanced_perkTree',
    'this.onPerkTreeLoaded(null, _brother.bandages_enhanced_perkTree);'
)
```

- [ ] **Step 2: Register JS/CSS from loader**

Inside the MSU queue in `mod_bandages_enhanced_loader.nut`, before class hooks:

```nut
::Hooks.registerJS("ui/mods/bandages_enhanced.js");
::Hooks.registerCSS("ui/mods/bandages_enhanced.css");
```

In the data helper hook, ensure the final injection line is:

```nut
result.bandages_enhanced_perkTree <- perks;
::BandagesEnhanced.Helpers.debugLog("injecting Bandages Enhanced perk tree for " + _entity.getName());
```

- [ ] **Step 3: Create JS file**

Create `ui/mods/bandages_enhanced.js`:

```javascript
var BandagesEnhanced = {};

BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData
    = CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData;
CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData = function(_brother)
{
    if (_brother.bandages_enhanced_perkTree)
    {
        this.onPerkTreeLoaded(null, _brother.bandages_enhanced_perkTree);
        return;
    }

    BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData.call(this, _brother);
};
```

- [ ] **Step 4: Create CSS file**

Create `ui/mods/bandages_enhanced.css`:

```css
/* Bandages Enhanced currently uses vanilla perk styling. */
```

- [ ] **Step 5: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected:

```text
Bandages Enhanced layout validation passed.
```

---

### Task 7: Build And Runtime Verification

**Files:**
- Read: `C:\Users\gujar\Documents\Battle Brothers\log.html`

**Interfaces:**
- Consumes: all previous tasks.
- Produces: verified build and runtime notes.

- [ ] **Step 1: Run static checks**

Run from `mod_bandages_enhanced`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
git diff --check
rg -n "mod_bandages_enhanced|perk.bandages_enhanced|accessory.bandage|actives.bandage_ally|BandagesEnhanced" .
```

Expected:

```text
Bandages Enhanced layout validation passed.
```

`git diff --check` exits `0`.

- [ ] **Step 2: Run local build**

Run:

```powershell
$out = Join-Path $env:TEMP ("bandages_enhanced_verify_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $out | Out-Null
modbb --game-data-dir $out
Write-Host "VERIFY_OUTPUT=$out"
```

Expected:

```text
Building Battle Brothers Mod Bandages Enhanced 0.0.1
Deployed mod_bandages_enhanced.zip to ...
Game launch not requested; skipping.
```

- [ ] **Step 3: Combat runtime test**

In game:

```text
Case A: Brother without perk is missing HP, not bleeding, and is engaged in melee.
Case B: Brother with perk is missing HP, not bleeding, and is engaged in melee.
Case C: Ally has bleeding or fresh bandage-treatable injury while target is engaged in melee.
Case D: Target is full HP and has no bleeding/fresh bandage-treatable injury.
```

Expected:

```text
Case A: bandage can be used and restores 35% of target max HP, capped at max HP.
Case B: bandage can be used and restores 65% of target max HP, capped at max HP.
Case C: bandage can be used, removes vanilla bandage conditions, and applies HP restore.
Case D: bandage cannot be used or returns false without consuming the item.
```

- [ ] **Step 4: Roster/inventory runtime test**

Outside combat:

```text
Case A: Brother without perk has temporary injury and bandages are dragged/right-clicked onto him.
Case B: Brother with perk has temporary injury with current max healing days <= 3.
Case C: Brother with perk has temporary injury with current max healing days > 3.
Case D: Brother with perk has only permanent injury.
```

Expected:

```text
Case A: item use is rejected and the bandage is not consumed.
Case B: temporary injury is compressed to max 1 day and treated.
Case C: temporary injury is compressed to max 2 days and treated.
Case D: item use is rejected and permanent injury is unchanged.
```

- [ ] **Step 5: Check log.html**

Run:

```powershell
Select-String -Path 'C:\Users\gujar\Documents\Battle Brothers\log.html' -Pattern 'BandagesEnhanced|bandage|Error|Exception|Unable to open file' | Select-Object -Last 120
```

Expected:

```text
[BandagesEnhanced] injecting Bandages Enhanced perk tree ...
[BandagesEnhanced] combat bandage used ...
[BandagesEnhanced] roster bandage compressed ...
```

No red IO/UI missing-file errors for the perk icon. If the perk icon path fails, change `Icon` and `IconDisabled` in `z_bandages_enhanced.nut` to `skills/active_105.png`, update the validator and README assumption, rebuild, and retest.

---

## Manual Review Checklist

- [ ] No files under `data_001` were modified.
- [ ] Existing save compatibility is preserved by keeping `accessory.bandage` and `actives.bandage_ally`.
- [ ] New perk ID is exactly `perk.bandages_enhanced`.
- [ ] HP healing uses max HP percent, not missing HP percent.
- [ ] Healing is capped at current max HP.
- [ ] Melee restriction is removed for both user and target.
- [ ] Vanilla bleeding/fresh injury removal still works.
- [ ] Roster/inventory injury recovery is perk-gated.
- [ ] Permanent injuries are never removed or shortened.
- [ ] Debug logging is configurable and enabled by default.
- [ ] Runtime assumptions are documented in `README.md`.

## Self-Review

- Spec coverage: the plan covers combat use in melee, max-HP healing at 35/65, configurable perk row and price, vanilla behavior preservation, outside-combat temporary injury recovery, no permanent injury healing, debug logging, `modbb`, and `context.md` constraints.
- Placeholder scan: no placeholder steps remain.
- Type consistency: IDs and helper function names match between validator tokens and implementation snippets.
