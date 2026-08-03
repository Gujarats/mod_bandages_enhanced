# Bandages Enhanced Legends + PoV Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `mod_bandages_enhanced` work correctly in the user's active `mod_legends + mod_PoV` save while preserving vanilla/non-Legends behavior.

**Architecture:** Split Bandages Enhanced compatibility into target-specific modules. Vanilla keeps UI perk-tree injection; Legends registers Bandages Enhanced as a real Legends perk definition and injects it through `character_background.buildPerkTree()`. PoV is treated as an optional Legends submod layer with conservative detection, logging, and explicit handling of PoV injury assumptions.

**Tech Stack:** Battle Brothers Squirrel, Modern Hooks, MSU settings/debug logging, existing `mod_bandages_enhanced` UI assets, `modbb` for build validation.

## Global Constraints

- Modify only `mod_bandages_enhanced`.
- Do not modify `data_001`, `mod_legends`, `mod_pov_witcher`, or other community mods.
- Write docs before runtime code changes.
- Debug logging must be configurable and default to enabled for this compatibility work.
- Use `modbb`; do not build zip files manually.
- The primary runtime target is the user's current save with `mod_legends + mod_PoV`.
- PoV's actual Modern Hooks ID is `mod_PoV`.
- Any runtime assumption must be documented in `mod_bandages_enhanced/README.md`.

---

## File Structure

- Create: `mod_bandages_enhanced/docs/legends_pov_compatibility.md`
  - Explains the compatibility design, save assumptions, load order, and PoV injury policy.
- Create: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/vanilla_perk_tree_patch.nut`
  - Owns non-Legends perk-tree UI injection currently embedded in the loader.
- Create: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/compatibility/legends_perk_tree_patch.nut`
  - Registers `perk.bandages_enhanced` as a real Legends perk and adds it to built background perk trees.
- Create: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/compatibility/pov_witcher_patch.nut`
  - Detects `mod_PoV`, logs runtime status, and centralizes PoV-specific injury policy.
- Modify: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_loader.nut`
  - Includes the new modules, branches between vanilla and Legends hooks, and registers PoV layer after Legends.
- Modify: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_settings.nut`
  - Default debug logging to `true` and add any compatibility setting needed by the PoV injury policy.
- Modify: `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut`
  - Add helper functions needed by the Legends and PoV modules; avoid direct `mod_legends` or `mod_PoV` assumptions here.
- Modify: `mod_bandages_enhanced/README.md`
  - Add runtime assumptions, loadout target, save warning, and test instructions.
- Modify: `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`
  - Add static checks for includes, module branching, Legends registration, and PoV ID detection.

---

### Task 1: Document Compatibility Design

**Files:**
- Create: `mod_bandages_enhanced/docs/legends_pov_compatibility.md`
- Modify: `mod_bandages_enhanced/README.md`

**Interfaces:**
- Consumes: Current mod behavior from `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`.
- Produces: A documented policy for implementation tasks to follow.

- [ ] **Step 1: Create compatibility doc**

Write `mod_bandages_enhanced/docs/legends_pov_compatibility.md` with this content:

```markdown
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
```

- [ ] **Step 2: Update README compatibility notes**

Add a short section to `README.md`:

```markdown
### Legends + PoV

When `mod_legends` is installed, Bandages Enhanced uses a Legends-specific perk-tree patch instead of the vanilla UI-only perk-tree injection. The perk is registered as a real Legends perk and added to background perk trees so it can be unlocked through Legends backend logic.

When `mod_PoV` is also installed, Bandages Enhanced keeps the Legends path and adds PoV-aware logging. PoV Mutation Sickness is excluded from Bandages Enhanced recovery by default until tested otherwise.
```

- [ ] **Step 3: Review documentation**

Confirm the docs state:

```text
No edits to external mods.
PoV ID is mod_PoV.
Legends save persistence is accepted.
Mutation Sickness is excluded by default.
```

---

### Task 2: Add Module Shells And Loader Branching

**Files:**
- Create: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/vanilla_perk_tree_patch.nut`
- Create: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/compatibility/legends_perk_tree_patch.nut`
- Create: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/compatibility/pov_witcher_patch.nut`
- Modify: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_loader.nut`

**Interfaces:**
- Consumes: `::BandagesEnhanced.HookMod`, `::Hooks.hasMod`.
- Produces: `::BandagesEnhanced.Vanilla.registerHooks(_mod)`, `::BandagesEnhanced.Compatibility.Legends.registerHooks(_mod)`, `::BandagesEnhanced.Compatibility.PoV.registerHooks(_mod)`.

- [ ] **Step 1: Create vanilla module shell**

```nut
if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.Vanilla <- {
	function registerHooks( _mod )
	{
		::BandagesEnhanced.Helpers.debugLog("[Vanilla] perk-tree hook registration pending");
	}
};
```

- [ ] **Step 2: Create Legends module shell**

```nut
if (!("Compatibility" in ::BandagesEnhanced))
{
	::BandagesEnhanced.Compatibility <- {};
}

::BandagesEnhanced.Compatibility.Legends <- {
	function registerHooks( _mod )
	{
		::BandagesEnhanced.Helpers.debugLog("[Legends] compatibility hook registration pending");
	}
};
```

- [ ] **Step 3: Create PoV module shell**

```nut
if (!("Compatibility" in ::BandagesEnhanced))
{
	::BandagesEnhanced.Compatibility <- {};
}

::BandagesEnhanced.Compatibility.PoV <- {
	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_PoV");
	}

	function registerHooks( _mod )
	{
		::BandagesEnhanced.Helpers.debugLog("[PoV] detected mod_PoV; PoV compatibility layer active");
	}
};
```

- [ ] **Step 4: Include modules in loader before queue**

Add near the top of `mod_bandages_enhanced_loader.nut`, after HookMod setup:

```nut
::include("scripts/mods/bandages_enhanced/vanilla_perk_tree_patch");
::include("scripts/mods/bandages_enhanced/compatibility/legends_perk_tree_patch");
::include("scripts/mods/bandages_enhanced/compatibility/pov_witcher_patch");
```

- [ ] **Step 5: Branch hook registration inside queue**

Replace the current always-on `data_helper` perk injection block with:

```nut
if (::Hooks.hasMod("mod_legends"))
{
	::BandagesEnhanced.Compatibility.Legends.registerHooks(mod);

	if (::Hooks.hasMod("mod_PoV"))
	{
		::BandagesEnhanced.Compatibility.PoV.registerHooks(mod);
	}
}
else
{
	::BandagesEnhanced.Vanilla.registerHooks(mod);
}
```

- [ ] **Step 6: Keep queue order optional but concrete**

Use this queue:

```nut
::BandagesEnhanced.HookMod.queue(">mod_msu", ">mod_druid", ">mod_aura_routing", ">mod_from_the_grave", ">mod_legends", ">mod_PoV", ">mod_necro", function()
```

Expected behavior: Bandages Enhanced loads after Legends and PoV when present; it still loads without them because these are queue ordering edges, not `require()` calls.

---

### Task 3: Move Vanilla Perk-Tree Injection Into Vanilla Module

**Files:**
- Modify: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/vanilla_perk_tree_patch.nut`
- Modify: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_loader.nut`

**Interfaces:**
- Consumes: `::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(_perkTree, _row)`.
- Produces: vanilla/non-Legends UI trees named `*_perkTree` with `perk.bandages_enhanced` appended.

- [ ] **Step 1: Move existing `convertEntityToUIData` hook**

Implement `registerHooks` in the vanilla module:

```nut
function registerHooks( _mod )
{
	_mod.hook("scripts/ui/global/data_helper", function(q)
	{
		q.convertEntityToUIData = @(__original) function( _entity, _activeEntity )
		{
			local result = __original(_entity, _activeEntity);

			if (_entity != null)
			{
				local settings = ::BandagesEnhanced.Mod.ModSettings;
				local row = settings.getSetting("PerkLevel").getValue();
				local injected = false;

				foreach (key, value in result)
				{
					if (typeof key == "string"
						&& key.find("_perkTree") != null
						&& key != "bandages_enhanced_perkTree"
						&& typeof value == "array")
					{
						result[key] = ::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(value, row);
						injected = true;
						::BandagesEnhanced.Helpers.debugLog("[Vanilla] merged perk into " + key + " for " + _entity.getName());
					}
				}

				if (!injected)
				{
					result.bandages_enhanced_perkTree <- ::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(::Const.Perks.Perks, row);
					::BandagesEnhanced.Helpers.debugLog("[Vanilla] injected fallback perk tree for " + _entity.getName());
				}
			}

			return result;
		}
	});
}
```

- [ ] **Step 2: Remove duplicate hook from loader**

Delete the old `mod.hook("scripts/ui/global/data_helper", ...)` block from the loader after confirming the same logic is in the vanilla module.

- [ ] **Step 3: Confirm Legends skip is explicit**

Add a loader log before branching:

```nut
::BandagesEnhanced.Helpers.debugLog("runtime mods: legends=" + ::Hooks.hasMod("mod_legends") + " pov=" + ::Hooks.hasMod("mod_PoV"));
```

---

### Task 4: Register Bandages Enhanced As A Legends Perk

**Files:**
- Modify: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/compatibility/legends_perk_tree_patch.nut`
- Modify: `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut`

**Interfaces:**
- Consumes: `::Const.Perks.addPerkDefObjects`, `::Const.Perks.PerkDefObjects`, `::Legends.Perk`.
- Produces: `::Legends.Perk.BandagesEnhanced` and `::Const.Perks.PerkDefs.BandagesEnhanced`.

- [ ] **Step 1: Add Legends helper table**

```nut
::BandagesEnhanced.Compatibility.Legends <- {
	BandagesEnhancedPerkDef = null,

	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_legends")
			&& ("Legends" in getroottable())
			&& ("Perk" in ::Legends)
			&& ("PerkDefObjects" in ::Const.Perks)
			&& ("addPerkDefObjects" in ::Const.Perks);
	},

	function getConfiguredRow()
	{
		local row = ::BandagesEnhanced.Mod.ModSettings.getSetting("PerkLevel").getValue() - 1;
		return row < 0 ? 0 : row;
	}
};
```

- [ ] **Step 2: Add setter for numeric perk definition**

```nut
function setBandagesEnhancedPerkDef( _perkDef )
{
	if (!("BandagesEnhanced" in ::Legends.Perk))
	{
		::Legends.Perk.BandagesEnhanced <- _perkDef;
	}
	else
	{
		::Legends.Perk.BandagesEnhanced = _perkDef;
	}

	if (!("BandagesEnhanced" in ::Const.Perks.PerkDefs))
	{
		::Const.Perks.PerkDefs.BandagesEnhanced <- _perkDef;
	}
	else
	{
		::Const.Perks.PerkDefs.BandagesEnhanced = _perkDef;
	}
}
```

- [ ] **Step 3: Register or reuse perk definition**

```nut
function registerPerkDef()
{
	if (!this.hasRuntime())
	{
		this.BandagesEnhancedPerkDef = null;
		::BandagesEnhanced.Helpers.debugLog("[Legends] runtime unavailable; skipped perk def registration");
		return null;
	}

	foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
	{
		if (perkDef != null && "ID" in perkDef && perkDef.ID == "perk.bandages_enhanced")
		{
			this.setBandagesEnhancedPerkDef(i);
			this.BandagesEnhancedPerkDef = i;
			::BandagesEnhanced.Helpers.debugLog("[Legends] reused existing perk def index=" + i);
			return i;
		}
	}

	this.setBandagesEnhancedPerkDef(null);
	::Const.Perks.addPerkDefObjects([
		{
			ID = "perk.bandages_enhanced",
			Script = "scripts/skills/perks/bandages_enhanced_perk",
			Name = "Bandages Enhanced",
			Tooltip = "Improves bandages so they restore more hitpoints and speed up temporary injury recovery.",
			Icon = "ui/perks/bandages_enhanced.png",
			IconDisabled = "ui/perks/bandages_enhanced_sw.png",
			Const = "BandagesEnhanced"
		}
	]);

	this.BandagesEnhancedPerkDef = ::Legends.Perk.BandagesEnhanced;
	::BandagesEnhanced.Helpers.debugLog("[Legends] registered perk def index=" + this.BandagesEnhancedPerkDef);
	return this.BandagesEnhancedPerkDef;
}
```

- [ ] **Step 4: Add getter**

```nut
function getBandagesEnhancedPerkDefNumber()
{
	if (this.BandagesEnhancedPerkDef != null)
	{
		return this.BandagesEnhancedPerkDef;
	}

	if (!this.hasRuntime())
	{
		return null;
	}

	foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
	{
		if (perkDef != null && "ID" in perkDef && perkDef.ID == "perk.bandages_enhanced")
		{
			this.BandagesEnhancedPerkDef = i;
			return i;
		}
	}

	return null;
}
```

---

### Task 5: Add Bandages Enhanced To Legends Background Trees

**Files:**
- Modify: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/compatibility/legends_perk_tree_patch.nut`

**Interfaces:**
- Consumes: `background.addPerk(_perkDefNumber, _preferredRow, _isRefundable)`.
- Produces: built Legends backgrounds where `background.getPerk("perk.bandages_enhanced")` returns the perk.

- [ ] **Step 1: Add background injection function**

```nut
function addBandagesEnhancedToBackground( _background )
{
	if (!this.hasRuntime() || _background == null)
	{
		return false;
	}

	local perkDef = this.getBandagesEnhancedPerkDefNumber();
	if (perkDef == null)
	{
		::BandagesEnhanced.Helpers.debugLog("[Legends] background add skipped: perk def unavailable");
		return false;
	}

	if (!("m" in _background) || _background.m.PerkTreeMap == null)
	{
		::BandagesEnhanced.Helpers.debugLog("[Legends] background add skipped: PerkTreeMap unavailable");
		return false;
	}

	if (_background.getPerk("perk.bandages_enhanced") != null)
	{
		return false;
	}

	local added = _background.addPerk(perkDef, this.getConfiguredRow(), true);
	::BandagesEnhanced.Helpers.debugLog("[Legends] background add result=" + added + " id=" + _background.getID());
	return added;
}
```

- [ ] **Step 2: Wrap `character_background.buildPerkTree()`**

```nut
function registerHooks( _mod )
{
	this.registerPerkDef();

	if (!this.hasRuntime())
	{
		return;
	}

	local module = ::BandagesEnhanced.Compatibility.Legends;
	_mod.hook("scripts/skills/backgrounds/character_background", function(q)
	{
		q.buildPerkTree = @(__original) function()
		{
			local attributes = __original();
			module.addBandagesEnhancedToBackground(this);
			return attributes;
		}
	});

	::BandagesEnhanced.Helpers.debugLog("[Legends] character_background buildPerkTree hook registered");
}
```

- [ ] **Step 3: Ensure skill create remains compatible**

Keep `scripts/skills/perks/bandages_enhanced_perk.nut` using:

```nut
local perk = ::Const.Perks.LookupMap[this.m.ID];
```

Expected: Legends `addPerkDefObjects` writes `LookupMap["perk.bandages_enhanced"]`, so the existing perk skill can still initialize from the lookup map.

---

### Task 6: Add PoV Compatibility Policy

**Files:**
- Modify: `mod_bandages_enhanced/scripts/mods/bandages_enhanced/compatibility/pov_witcher_patch.nut`
- Modify: `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut`
- Modify: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_settings.nut`

**Interfaces:**
- Consumes: `::Hooks.hasMod("mod_PoV")`, injury IDs from actor skills.
- Produces: PoV detection logging and default exclusion for `injury.pov_sickness2`.

- [ ] **Step 1: Add setting for Mutation Sickness policy**

In settings:

```nut
recovery.addBooleanSetting("TreatPoVMutationSickness", false, "Treat PoV Mutation Sickness", "Allow Bandages Enhanced to shorten PoV Mutation Sickness. Disabled by default until runtime balance is confirmed.");
```

- [ ] **Step 2: Add helper exclusion**

In `getRosterTreatableInjuries` and `compressTemporaryInjuries`, skip PoV Mutation Sickness unless the setting is true:

```nut
if (injury.getID() == "injury.pov_sickness2"
	&& ::Hooks.hasMod("mod_PoV")
	&& !::BandagesEnhanced.Mod.ModSettings.getSetting("TreatPoVMutationSickness").getValue())
{
	this.debugLog("[PoV] skipped Mutation Sickness for " + _actor.getName());
	continue;
}
```

- [ ] **Step 3: Register PoV module**

```nut
function registerHooks( _mod )
{
	if (!this.hasRuntime())
	{
		return;
	}

	::BandagesEnhanced.Helpers.debugLog("[PoV] mod_PoV detected; Mutation Sickness treatment setting="
		+ ::BandagesEnhanced.Mod.ModSettings.getSetting("TreatPoVMutationSickness").getValue());
}
```

- [ ] **Step 4: Do not edit PoV perk strings**

Do not patch `LegendFieldTriage`, `LegendPotionBrewer`, or `LegendSpecBandage` tooltips in this task. Bandages Enhanced has its own perk tooltip and bandage item tooltip; PoV’s dissection/crafting text stays authoritative for PoV mechanics.

---

### Task 7: Preserve Combat Bandage Behavior With Legends Rules

**Files:**
- Modify: `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut`
- Modify: `mod_bandages_enhanced/scripts/!mods_preload/mod_bandages_enhanced_loader.nut`

**Interfaces:**
- Consumes: `::Legends.Perk.LegendSpecBandage` when Legends exists.
- Produces: enhanced HP healing without breaking Legends zone-of-control permission.

- [ ] **Step 1: Add helper for Legends Bandage Mastery**

```nut
function hasLegendsBandageMastery( _actor )
{
	return _actor != null
		&& ::Hooks.hasMod("mod_legends")
		&& ("Legends" in getroottable())
		&& ("Perk" in ::Legends)
		&& ("LegendSpecBandage" in ::Legends.Perk)
		&& _actor.getSkills() != null
		&& _actor.getSkills().hasPerk(::Legends.Perk.LegendSpecBandage);
}
```

- [ ] **Step 2: Keep current `bandage_ally_skill` hook**

Keep the existing `isUsable`, `onVerifyTarget`, and `onUse` behavior for `scripts/skills/actives/bandage_ally_skill`, because this is still the item-provided bandage skill.

- [ ] **Step 3: Do not hook `legend_bandage_skill` initially**

Document this assumption in README:

```markdown
Bandages Enhanced initially enhances the item-provided `actives.bandage_ally` path. Legends' free `actives.legend_bandage` from Bandage Mastery is not changed until runtime testing confirms it should receive the same HP restoration.
```

Reason: Legends' `actives.legend_bandage` is a separate active skill unlocked by `Bandage Mastery`, and changing it may blur the distinction between consuming a bandage item and using a mastery-granted free bandage action.

---

### Task 8: Static Validation And Build Checks

**Files:**
- Modify: `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Consumes: source files as text.
- Produces: fast pre-runtime validation before manual game testing.

- [ ] **Step 1: Add required token checks**

Add checks for:

```text
scripts/mods/bandages_enhanced/vanilla_perk_tree_patch
scripts/mods/bandages_enhanced/compatibility/legends_perk_tree_patch
scripts/mods/bandages_enhanced/compatibility/pov_witcher_patch
::Hooks.hasMod("mod_legends")
::Hooks.hasMod("mod_PoV")
::Const.Perks.addPerkDefObjects
background.addPerk
injury.pov_sickness2
TreatPoVMutationSickness
```

- [ ] **Step 2: Add queue validation**

Check loader contains:

```text
>mod_legends
>mod_PoV
```

- [ ] **Step 3: Run static validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: PASS.

- [ ] **Step 4: Run build**

Run from `mod_bandages_enhanced`:

```powershell
modbb
```

Expected: build succeeds under `mod_bandages_enhanced/build`.

---

### Task 9: Manual Runtime Test Matrix

**Files:**
- Create: `mod_bandages_enhanced/test-results/legends-pov-manual-matrix.md`

**Interfaces:**
- Consumes: user runtime save with `mod_legends + mod_PoV`.
- Produces: manual evidence for compatibility status.

- [ ] **Step 1: Create manual matrix**

```markdown
# Bandages Enhanced Legends + PoV Manual Matrix

## Loadout

- mod_legends:
- mod_PoV:
- mod_bandages_enhanced:
- Save name:

## Checks

- [ ] Game loads current save.
- [ ] log.html contains `[BandagesEnhanced] runtime mods: legends=true pov=true`.
- [ ] Character screen opens.
- [ ] Bandages Enhanced appears in the Legends perk tree.
- [ ] Bandages Enhanced can be unlocked.
- [ ] No duplicate Bandages Enhanced icons after reopening character screen.
- [ ] Combat bandage restores HP through `actives.bandage_ally`.
- [ ] Shift+C treatment screen opens.
- [ ] Normal temporary injury can be shortened.
- [ ] Permanent injury is not treated.
- [ ] PoV Mutation Sickness is excluded when `TreatPoVMutationSickness=false`.
- [ ] PoV Mutation Sickness behavior is logged when present.
```

- [ ] **Step 2: Monitor log**

Open:

```text
C:\Users\gujar\Documents\Battle Brothers\log.html
```

Expected lines include:

```text
[BandagesEnhanced] runtime mods: legends=true pov=true
[BandagesEnhanced][Legends] registered perk def
[BandagesEnhanced][Legends] character_background buildPerkTree hook registered
[BandagesEnhanced][PoV] mod_PoV detected
```

- [ ] **Step 3: Record result**

Fill the matrix with exact observed behavior and any crash or missing-perk symptom.

---

## Self-Review

**Spec coverage:** The plan covers docs-first workflow, vanilla separation, Legends backend perk registration, PoV direct testing, Mutation Sickness policy, debug logging, static validation, build, and manual runtime testing.

**Placeholder scan:** No `TBD`, `TODO`, or unspecified test target remains. The only intentionally deferred behavior is `legend_bandage_skill`, documented as an explicit runtime assumption.

**Type consistency:** The exported module names are consistent: `::BandagesEnhanced.Vanilla`, `::BandagesEnhanced.Compatibility.Legends`, and `::BandagesEnhanced.Compatibility.PoV`. The PoV mod ID is consistently `mod_PoV`.
