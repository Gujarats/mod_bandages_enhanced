$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot

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
Require-File 'scripts/config/z_bandages_enhanced.nut'
Require-File 'scripts/skills/perks/bandages_enhanced_perk.nut'
Require-File 'ui/mods/bandages_enhanced.js'
Require-File 'ui/mods/bandages_enhanced.css'

Require-Token 'mod_config.json' @(
    '"mod_id": "mod_bandages_enhanced"',
    '"mod_name": "Battle Brothers Mod Bandages Enhanced"',
    '"version": "0.0.1"',
    '"steam_app_id": "365360"'
)

Require-Token 'scripts/!mods_preload/mod_bandages_enhanced_loader.nut' @(
    'if (!("BandagesEnhanced" in getroottable()))',
    '::BandagesEnhanced.ID <- "mod_bandages_enhanced";',
    '::BandagesEnhanced.Name <- "Bandages Enhanced";',
    '::BandagesEnhanced.Version <- "0.0.1";',
    '::Hooks.register(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name)',
    '::BandagesEnhanced.HookMod.require("mod_msu >= 1.9.0");',
    '::BandagesEnhanced.registerSettings();',
    '::BandagesEnhanced.configureDebugLogging();',
    '::BandagesEnhanced.Helpers.debugLog("settings initialized");',
    '::Hooks.registerJS("ui/mods/bandages_enhanced.js");',
    '::Hooks.registerCSS("ui/mods/bandages_enhanced.css");',
    'mod.hook("scripts/skills/actives/bandage_ally_skill", function(q)',
    'mod.hook("scripts/items/accessory/bandage_item", function(q)',
    'mod.hook("scripts/ui/global/data_helper", function(q)',
    'result.bandages_enhanced_perkTree <- perks;',
    'bandage skill hook create',
    'bandage skill isUsable',
    'bandage skill verify target',
    'bandage skill use',
    'bandage item hook create',
    'bandage item roster use',
    'bandage item roster use rejected',
    'bandage item roster use applied',
    'this.m.Description = "Apply improved bandages to yourself or an ally. Removes bleeding and fresh bandage-treatable wounds, and restores hitpoints based on maximum hitpoints.";',
    'Can be used while engaged in melee',
    'Restores [color=" + this.Const.UI.Color.PositiveValue + "]"',
    '::BandagesEnhanced.Helpers.canUseBandageInCombatOn(target)',
    '::BandagesEnhanced.Helpers.applyCombatBandage(_user, target)',
    'this.m.Item.removeSelf();',
    'this.m.Value = ::BandagesEnhanced.Mod.ModSettings.getSetting("BandageValue").getValue();',
    'this.m.IsUsable = true;',
    'this.m.ItemType = this.Const.Items.ItemType.Usable;',
    'Right-click or drag onto the currently selected character outside combat',
    '::BandagesEnhanced.Helpers.canUseBandageOnRoster(_actor)',
    '::BandagesEnhanced.Helpers.applyRosterBandage(_actor)'
)

Require-Token 'scripts/!mods_preload/mod_bandages_enhanced_settings.nut' @(
    'if (!("BandagesEnhanced" in getroottable()))',
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

Require-Token 'scripts/config/z_bandages_enhanced.nut' @(
    'if (!("BandagesEnhanced" in getroottable()))',
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
    '::Const.SkillType.TemporaryInjury',
    '::Const.SkillType.PermanentInjury',
    'actor.setHitpoints(::Math.min(actor.getHitpointsMax(), actor.getHitpoints() + healAmount));'
)

Require-Token 'scripts/config/z_bandages_enhanced.nut' @(
    'if (!("BandagesEnhanced" in getroottable()))',
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

Require-Token 'ui/mods/bandages_enhanced.js' @(
    'var BandagesEnhanced = {};',
    'BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData',
    '_brother.bandages_enhanced_perkTree',
    'this.onPerkTreeLoaded(null, _brother.bandages_enhanced_perkTree);'
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

Forbid-Token 'scripts/!mods_preload/mod_bandages_enhanced_loader.nut' @(
    'ID = "mod_bandages_enhanced"',
    '::include("scripts/!mods_preload/mod_bandages_enhanced_helpers");'
)

Write-Host 'Bandages Enhanced layout validation passed.'
