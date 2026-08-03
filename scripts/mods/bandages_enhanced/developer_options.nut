if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

if (!("DeveloperOptions" in ::BandagesEnhanced))
{
	::BandagesEnhanced.DeveloperOptions <- null;
}

::BandagesEnhanced.DeveloperOptions = {
	function init()
	{
		::BandagesEnhanced.DeveloperSession <- {
			HasGrantedTestKit = false
		};
	}

	function isEnabled()
	{
		return ::BandagesEnhanced.Mod.ModSettings.getSetting("EnableDeveloperOptions").getValue();
	}

	function getSetting( _key )
	{
		return ::BandagesEnhanced.Mod.ModSettings.getSetting(_key).getValue();
	}

	function debugLog( _message )
	{
		::BandagesEnhanced.Helpers.debugLog("[Developer] " + _message);
	}

	function hasWorldRuntime()
	{
		return ("World" in getroottable())
			&& ::World != null
			&& ("Assets" in ::World)
			&& ::World.Assets != null
			&& ::World.getPlayerRoster() != null;
	}

	function applyTestKitOnce()
	{
		if (!this.isEnabled()
			|| !this.getSetting("DeveloperGrantTestKitOnLoad")
			|| ::BandagesEnhanced.DeveloperSession.HasGrantedTestKit)
		{
			return;
		}

		if (!this.hasWorldRuntime())
		{
			return;
		}

		local stash = ::World.Assets.getStash();
		if (stash == null)
		{
			return;
		}

		::BandagesEnhanced.DeveloperSession.HasGrantedTestKit = true;

		local bandageCount = this.getSetting("DeveloperBandageCount");
		for (local i = 0; i < bandageCount; i = ++i)
		{
			stash.add(::new("scripts/items/accessory/bandage_item"));
		}

		local xp = this.getSetting("DeveloperXP");
		local perkPoints = this.getSetting("DeveloperPerkPoints");
		local roster = ::World.getPlayerRoster().getAll();

		foreach (bro in roster)
		{
			if (bro == null)
			{
				continue;
			}

			if (xp > 0)
			{
				bro.addXP(xp, false);
				bro.updateLevel();
			}

			if (perkPoints > 0)
			{
				bro.m.PerkPoints += perkPoints;
			}
		}

		this.debugLog("granted test kit bandages=" + bandageCount + " xp=" + xp + " perkPoints=" + perkPoints);
	}

	function getLegendsPerkDefNumber()
	{
		if (!::Hooks.hasMod("mod_legends"))
		{
			return null;
		}

		if (!("Compatibility" in ::BandagesEnhanced)
			|| !("Legends" in ::BandagesEnhanced.Compatibility))
		{
			return null;
		}

		return ::BandagesEnhanced.Compatibility.Legends.getBandagesEnhancedPerkDefNumber();
	}

	function grantBandagesEnhancedForTest( _entity )
	{
		if (!this.isEnabled()
			|| !this.getSetting("DeveloperGrantBandagesEnhancedPerk")
			|| _entity == null
			|| !("isPlayerControlled" in _entity)
			|| !_entity.isPlayerControlled()
			|| !("getSkills" in _entity))
		{
			return;
		}

		local skills = _entity.getSkills();
		if (skills == null)
		{
			return;
		}

		if (::Hooks.hasMod("mod_legends") && ("getBackground" in _entity))
		{
			local background = _entity.getBackground();
			local perkDef = this.getLegendsPerkDefNumber();

			if (background != null
				&& perkDef != null
				&& ("getPerk" in background)
				&& ("addPerk" in background)
				&& background.getPerk("perk.bandages_enhanced") == null)
			{
				background.addPerk(perkDef, ::BandagesEnhanced.Compatibility.Legends.getConfiguredRow(), true);
				this.debugLog("added perk to Legends background tree for " + _entity.getName());
			}
		}

		if (!skills.hasSkill("perk.bandages_enhanced"))
		{
			skills.add(::new("scripts/skills/perks/bandages_enhanced_perk"));
			skills.update();
			this.debugLog("granted perk skill to " + _entity.getName());
		}
	}
};
