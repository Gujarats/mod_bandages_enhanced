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
