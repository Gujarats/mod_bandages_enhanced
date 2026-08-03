# Legends + PoV Compatibility

Bandages Enhanced supports three runtime paths:

- Vanilla or non-Legends: use the existing UI perk-tree injection pattern.
- Legends: register Bandages Enhanced as a real Legends perk definition and add it to background perk trees through `character_background.buildPerkTree()`.
- Legends + PoV: use the Legends path, then apply a conservative PoV layer for logging and injury policy.

PoV is a Legends submod. Its Modern Hooks ID is `mod_PoV`. It rewrites some Legends perk text and adds injury mechanics such as Severe Pain and Mutation Sickness. Bandages Enhanced must not modify PoV source files.

## Save Assumption

In Legends, adding Bandages Enhanced through `background.addPerk()` persists the perk in the background's custom perk tree. Saves that receive the perk should keep `mod_bandages_enhanced` installed.

## PoV Injury Policy

Bandages Enhanced treats normal temporary injuries exposed through `Const.SkillType.TemporaryInjury`. Mutation Sickness (`injury.pov_sickness2`) is excluded by default until runtime testing confirms shortening it does not break PoV progression or balance. This assumption is logged when PoV is detected.

## Test Target

The primary manual test target is the user's current save with `mod_legends`, `mod_PoV`, and `mod_bandages_enhanced` enabled.
