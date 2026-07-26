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
- Outside combat, press `Shift+C` on the world map to open the Bandages Enhanced treatment screen.
- The treatment screen shows all roster members, their eligibility, the reason treatment is unavailable, and the current stash bandage count.
- Right-clicking bandages outside combat does not consume a bandage; use the treatment screen to choose the target.

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

- The perk uses project-local circular perk icons `ui/perks/bandages_enhanced.png` and `ui/perks/bandages_enhanced_sw.png`, derived from the vanilla bandage item icon.
- The treatment screen uses the proven custom world-screen pattern used by Item Spawner and Bro Editor: a Squirrel UI screen, registered JS/CSS, `UI.connect`, and a world-map MSU keybind.
- The default keybind is `Shift+C` and can be rebound through MSU keybind settings if another mod conflicts.
- Injury recovery compression changes only temporary injuries by adjusting their healing-time fields; permanent injuries are explicitly ignored.
- Shared helper functions live in `scripts/config/z_bandages_enhanced.nut` so they are available before the preload hook queue calls them.

## Build

Use `modbb` from this folder. Do not manually build the zip.

## Debug log

Check `C:\Users\gujar\Documents\Battle Brothers\log.html` for lines beginning with `[BandagesEnhanced]`.
