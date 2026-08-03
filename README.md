# Bandages Enhanced

Bandages Enhanced makes bandages feel useful after the bleeding stops.

In vanilla Battle Brothers, bandages are mostly a narrow emergency tool: stop bleeding, patch a few fresh wounds, move on. This mod keeps that role, then expands bandages into a real field-care option for wounded brothers. A prepared company can spend bandages to recover hitpoints in battle and shorten temporary injury recovery on the world map.

## Feature Highlights

- Bandages restore hitpoints based on max HP.
- Without the perk, bandages restore 35% of max HP.
- With Bandages Enhanced, bandages restore 65% of max HP.
- Healing is capped at the actor's current maximum hitpoints.
- Bandages can be used while engaged in melee.
- Bandages still remove bleeding and fresh Cut Artery, Cut Neck Vein, and Grazed Neck injuries.
- Bandages never heal permanent injuries.
- With the perk, bandages can be used outside combat to speed up temporary injury recovery.
- Outside combat, press `Shift+C` on the world map to open the Bandages Enhanced treatment screen.
- The treatment screen shows all roster members, their eligibility, the reason treatment is unavailable, and the current stash bandage count.
- Treatable temporary injuries are shown as hoverable injury icons in the treatment screen.
- Right-clicking bandages outside combat applies recovery to the selected character when that character has Bandages Enhanced and an eligible temporary injury.

## Why This Mod Exists

Battle Brothers injuries can create good campaign pressure, but the player has very little direct medical decision-making outside temples and waiting. Bandages are common, thematic, and already tied to battlefield care, yet they mostly stop mattering once bleeding is handled.

Bandages Enhanced gives them a clearer campaign role:

- In combat, bandages become a small but reliable recovery tool.
- Outside combat, the perk lets a trained brother use supplies to shorten temporary injury downtime.
- Permanent injuries stay permanent, so the mod does not erase long-term consequences.
- The treatment screen makes the decision explicit: who can be treated, why someone cannot be treated, how many bandages remain, and which injuries would be affected.

## How To Use

### In Combat

Use bandages normally from the item skill bar.

They still remove vanilla bandage conditions, and they also restore hitpoints based on the target's maximum HP. By default, the active skill restores 35% max HP without the perk and 65% max HP when the user has acquired Bandages Enhanced. These values come from MSU settings and can be changed.

### On The World Map

Press `Shift+C` to open the Bandages Enhanced treatment screen.

The screen lists your roster with portraits, background icons, HP, treatment status, and temporary injury icons. Select a character, review the reason shown at the bottom, then click `Apply Bandage` if the character is eligible.

Hover over an injury icon to see the normal Battle Brothers injury tooltip, including treated status and healing timing.

You can also right-click a bandage in the character menu on the world map. This silently applies Bandages Enhanced recovery to the selected character only when that character has acquired the perk and has an eligible temporary injury. No UI message is shown; debug logs record the reason if recovery cannot be applied.

### Keybind

The default shortcut is `Shift+C`.

The shortcut can be rebound through MSU keybind settings if it conflicts with another mod.

## Treatment Rules

A roster treatment requires all of the following:

- The character has the `Bandages Enhanced` perk.
- The character has at least one temporary injury that can still be shortened by the current settings.
- The company stash contains at least one bandage.

Treatment consumes one bandage from the stash. It does not restore hitpoints on the world map; it shortens temporary injury recovery.

Permanent injuries are ignored. If a character only has permanent injuries, the screen will explain that bandages cannot help.

## Settings

- Debug Logging: enabled by default for the first version.
- Bandage Value: default 25, matching vanilla.
- Perk Row: default 2.
- Base Heal Percent Max HP: default 35.
- Perk Heal Percent Max HP: default 65.
- Light Injury Threshold Days: default 3.
- Light Injury Max Days: default 1.
- Heavy Injury Max Days: default 2.
- Treat PoV Mutation Sickness: disabled by default.

## Compatibility Notes

The perk is injected into compatible perk trees, including common custom perk-tree setups. The treatment screen is opened from the world map with an MSU keybind, so it avoids changing the vanilla character screen interaction directly.

Necromancer characters from `mod_necro` are handled explicitly: Bandages Enhanced now injects into `necro_perkTree` when present while keeping the existing generic perk-tree merge logic unchanged.

### Legends + PoV

When `mod_legends` is installed, Bandages Enhanced uses a Legends-specific perk-tree patch instead of the vanilla UI-only perk-tree injection. The perk is registered as a real Legends perk and added to background perk trees so it can be unlocked through Legends backend logic.

When `mod_PoV` is also installed, Bandages Enhanced keeps the Legends path and adds PoV-aware logging. PoV Mutation Sickness is excluded from Bandages Enhanced recovery by default until tested otherwise.

Bandages Enhanced initially enhances the item-provided `actives.bandage_ally` path. Legends' free `actives.legend_bandage` from Bandage Mastery is not changed until runtime testing confirms it should receive the same HP restoration.

Assumption: this is a UI/data-rendering compatibility change only; existing save games should continue to load without schema or save-format changes.

Right-clicking bandages outside combat applies treatment to the currently selected character when eligible. The `Shift+C` treatment screen is available when you want to choose from the full roster.

## Runtime assumptions

- The perk uses project-local circular perk icons `ui/perks/bandages_enhanced.png` and `ui/perks/bandages_enhanced_sw.png`, derived from the vanilla bandage item icon.
- The treatment screen uses the proven custom world-screen pattern used by Item Spawner and Bro Editor: a Squirrel UI screen, registered JS/CSS, `UI.connect`, and a world-map MSU keybind.
- The default keybind is `Shift+C` and can be rebound through MSU keybind settings if another mod conflicts.
- Injury recovery compression changes only temporary injuries by adjusting their healing-time fields; permanent injuries are explicitly ignored.
- Shared helper functions live in `scripts/config/z_bandages_enhanced.nut` so they are available before the preload hook queue calls them.
- Injury icons in the treatment screen use the vanilla `status-effect` tooltip binding with the actor ID and injury ID.
- Modal world/character-screen popups are suppressed during tactical combat because that UI state can freeze combat input.
- In Legends, Bandages Enhanced is persisted into background custom perk trees through `background.addPerk()`. Saves that receive this perk should keep `mod_bandages_enhanced` installed.
- PoV's Modern Hooks ID is `mod_PoV`; this is the ID used for load-order and runtime detection.

## Build

Use `modbb` from this folder. Do not manually build the zip.

## Debug Log

Check `C:\Users\gujar\Documents\Battle Brothers\log.html` for lines beginning with `[BandagesEnhanced]`.
