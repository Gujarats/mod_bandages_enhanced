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
- Right-clicking bandages outside combat does not consume a bandage; use the treatment screen to choose the target.

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

They still remove vanilla bandage conditions, and they also restore hitpoints based on the target's maximum HP. With the Bandages Enhanced perk, the heal amount is larger.

### On The World Map

Press `Shift+C` to open the Bandages Enhanced treatment screen.

The screen lists your roster with portraits, background icons, HP, treatment status, and temporary injury icons. Select a character, review the reason shown at the bottom, then click `Apply Bandage` if the character is eligible.

Hover over an injury icon to see the normal Battle Brothers injury tooltip, including treated status and healing timing.

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

## Compatibility Notes

The perk is injected into compatible perk trees, including common custom perk-tree setups. The treatment screen is opened from the world map with an MSU keybind, so it avoids changing the vanilla character screen interaction directly.

Right-clicking bandages outside combat intentionally redirects players to the `Shift+C` treatment screen instead of silently applying treatment to the currently selected character.
