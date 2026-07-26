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
Require-File 'scripts/ui/screens/world/bandages_enhanced_screen.nut'
Require-File 'scripts/skills/perks/bandages_enhanced_perk.nut'
Require-File 'gfx/ui/perks/bandages_enhanced.png'
Require-File 'gfx/ui/perks/bandages_enhanced_sw.png'
Require-File 'ui/mods/bandages_enhanced.js'
Require-File 'ui/mods/bandages_enhanced.css'
Require-File 'ui/mods/bandages_enhanced_screen.js'
Require-File 'ui/mods/bandages_enhanced_screen.css'

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
    '::BandagesEnhanced.HookMod.queue(">mod_msu", ">mod_druid", ">mod_aura_routing", ">mod_from_the_grave", ">mod_legends", function()',
    '::BandagesEnhanced.registerSettings();',
    '::BandagesEnhanced.configureDebugLogging();',
    '::BandagesEnhanced.registerKeybinds();',
    '::BandagesEnhanced.Helpers.debugLog("settings initialized");',
    '::BandagesEnhanced.Helpers.debugLog("opening treatment screen from keybind");',
    'local showRosterBandagePopup = function( _message )',
    '::BandagesEnhanced.Helpers.debugLog("roster bandage character popup show: " + _message);',
    '::World.State.m.CharacterScreen.m.JSHandle.asyncCall("showBandagesEnhancedPopup", {',
    '::BandagesEnhanced.Helpers.debugLog("roster bandage world popup fallback show: " + _message);',
    '::World.State.showDialogPopup("Bandages Enhanced", _message, null, null, true);',
    '::Hooks.registerJS("ui/mods/bandages_enhanced.js");',
    '::Hooks.registerCSS("ui/mods/bandages_enhanced.css");',
    '::Hooks.registerJS("ui/mods/bandages_enhanced_screen.js");',
    '::Hooks.registerCSS("ui/mods/bandages_enhanced_screen.css");',
    'this.m.BandagesEnhancedScreen <- this.new("scripts/ui/screens/world/bandages_enhanced_screen");',
    'this.m.BandagesEnhancedScreen.destroy();',
    'mod.hook("scripts/skills/actives/bandage_ally_skill", function(q)',
    'mod.hook("scripts/items/accessory/bandage_item", function(q)',
    'mod.hook("scripts/ui/global/data_helper", function(q)',
    'key.find("_perkTree") != null',
    'result[key] = ::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(value, row);',
    'result.bandages_enhanced_perkTree <- ::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(::Const.Perks.Perks, row);',
    'merged Bandages Enhanced perk into',
    'injecting Bandages Enhanced fallback perk tree',
    'bandage skill hook create',
    'bandage skill isUsable',
    'bandage skill verify target',
    'bandage skill use',
    'bandage item hook create',
    'bandage item roster use',
    'bandage item roster use rejected',
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
    'bandage item roster use redirected to treatment screen',
    'showRosterBandagePopup("Use Shift+C on the world map to open Bandages Enhanced treatment.");'
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
    'function clonePerkTree( _perkTree )',
    'function hasPerkInTree( _perkTree, _perkID )',
    'function appendBandagesEnhancedPerks( _perkTree, _row )',
    'function getCombatHealPercent( _actor )',
    'function getMaxHPHealAmount( _actor )',
    'function canTreatVanillaBandageCondition( _target )',
    'function canUseBandageInCombatOn( _target )',
    'function applyCombatBandage( _user, _target )',
    'function compressTemporaryInjuries( _actor )',
    'function getRosterBandageUseResult( _actor )',
    'function getRosterTreatmentRows()',
    'function countBandagesInStash()',
    'function consumeBandageFromStash()',
    'function applyRosterBandageByActorID( _actorID )',
    'function canUseBandageOnRoster( _actor )',
    'function applyRosterBandage( _actor )',
    'debugLog("combat bandage rejected',
    'debugLog("combat bandage used',
    'debugLog("roster bandage rejected',
    'debugLog("roster bandage compressed',
    'roster bandage eligibility: actor=',
    'hasPerk=',
    'hasTemporaryInjury=',
    'hasPermanentInjury=',
    'reason=missing_perk',
    'reason=permanent_injury_only',
    'reason=no_temporary_injury',
    '::Const.SkillType.TemporaryInjury',
    '::Const.SkillType.PermanentInjury',
    'actor.setHitpoints(::Math.min(actor.getHitpointsMax(), actor.getHitpoints() + healAmount));',
    'ImagePath = actor.getImagePath()',
    'ImageOffsetX = actor.getImageOffsetX()',
    'ImageOffsetY = actor.getImageOffsetY()',
    'BackgroundImagePath = actor.getBackground().getIconColored()'
)

Require-Token 'scripts/config/z_bandages_enhanced.nut' @(
    'if (!("BandagesEnhanced" in getroottable()))',
    '::Const.Perks.BandagesEnhanced <- [];',
    'ID = "perk.bandages_enhanced"',
    'Script = "scripts/skills/perks/bandages_enhanced_perk"',
    'Name = "Bandages Enhanced"',
    'Tooltip = "Improves bandages so they restore more hitpoints and speed up temporary injury recovery."',
    'Icon = "ui/perks/bandages_enhanced.png"',
    'IconDisabled = "ui/perks/bandages_enhanced_sw.png"',
    'Row = 2'
)

Require-Token 'scripts/skills/perks/bandages_enhanced_perk.nut' @(
    'this.bandages_enhanced_perk <- this.inherit("scripts/skills/skill", {',
    'this.m.ID = "perk.bandages_enhanced";',
    'this.m.Type = this.Const.SkillType.Perk;',
    'this.m.Order = this.Const.SkillOrder.Perk;'
)

Require-Token 'scripts/ui/screens/world/bandages_enhanced_screen.nut' @(
    'this.bandages_enhanced_screen <- {',
    'JSHandle = null',
    'function create()',
    'this.m.JSHandle = this.UI.connect("BandagesEnhancedScreen", this);',
    'function show()',
    'this.m.JSHandle.asyncCall("show", this.queryData());',
    'function hide( _withSlideAnimation = false )',
    'function queryData()',
    'function onApplyBandage( _data )',
    '::BandagesEnhanced.Helpers.applyRosterBandageByActorID(actorID)',
    'function onCloseButtonPressed()'
)

Require-Token 'ui/mods/bandages_enhanced.js' @(
    'var BandagesEnhanced = {};',
    'CharacterScreen.prototype.showBandagesEnhancedPopup = function(_data)',
    '$(''.character-screen'').createPopupDialog(title, null, null, ''bandages-enhanced-popup'');',
    'this.mDataSource.notifyBackendPopupDialogIsVisible(true);',
    'self.mDataSource.notifyBackendPopupDialogIsVisible(false);',
    'BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData',
    '_brother.bandages_enhanced_perkTree',
    'key !== ''bandages_enhanced_perkTree'' && key.indexOf(''_perkTree'') !== -1',
    'this.onPerkTreeLoaded(null, _brother.bandages_enhanced_perkTree);'
)

Require-Token 'ui/mods/bandages_enhanced_screen.js' @(
    'var BandagesEnhancedTreatmentScreen = function()',
    'BandagesEnhancedTreatmentScreen.prototype.onConnection = function (_handle)',
    'BandagesEnhancedTreatmentScreen.prototype.show = function (_data)',
    'BandagesEnhancedTreatmentScreen.prototype.hide = function ()',
    'BandagesEnhancedTreatmentScreen.prototype.loadFromData = function (_data)',
    'BandagesEnhancedTreatmentScreen.prototype.notifyBackendApplyBandage = function (_actorID)',
    'SQ.call(this.mSQHandle, ''onApplyBandage'', _actorID',
    'SQ.call(this.mSQHandle, ''onCloseButtonPressed'')',
    'var result = $(''<div class="bandages-enhanced-row l-row"/>'');',
    'var entry = $(''<div class="ui-control list-entry"/>'');',
    'Path.PROCEDURAL + _imagePath',
    'centerImageWithinParent(_imageOffsetX, _imageOffsetY, 0.64',
    'Path.GFX + rowData.BackgroundImagePath',
    'title-font-normal font-bold font-color-brother-name',
    'bandages-enhanced-row-bottom',
    'registerScreen("BandagesEnhancedScreen", new BandagesEnhancedTreatmentScreen());'
)

Require-Token 'ui/mods/bandages_enhanced_screen.css' @(
    '.bandages-enhanced-row.l-row',
    '.bandages-enhanced-list',
    '.bandages-enhanced-row .column.is-left',
    '.bandages-enhanced-row .column.is-right',
    '.bandages-enhanced-row .row.is-top > img',
    '.bandages-enhanced-row .row.is-top .name',
    '.bandages-enhanced-row-bottom .hp',
    '.bandages-enhanced-row-bottom .status'
)

Require-Token 'README.md' @(
    '# Bandages Enhanced',
    'Bandages restore hitpoints based on max HP.',
    'Without the perk, bandages restore 35% of max HP.',
    'With Bandages Enhanced, bandages restore 65% of max HP.',
    'Bandages can be used while engaged in melee.',
    'Bandages never heal permanent injuries.',
    'press `Shift+C` on the world map',
    'current stash bandage count',
    'can be rebound through MSU keybind settings',
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
