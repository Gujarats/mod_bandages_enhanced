if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

if (!("Compatibility" in ::BandagesEnhanced))
{
	::BandagesEnhanced.Compatibility <- {};
}

::BandagesEnhanced.Compatibility.Legends <- {
	BandagesEnhancedPerkDef = null,

	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_legends")
			&& ("Legends" in getroottable())
			&& ("Perk" in ::Legends)
			&& ("PerkDefObjects" in ::Const.Perks)
			&& ("PerkDefs" in ::Const.Perks)
			&& ("addPerkDefObjects" in ::Const.Perks);
	},

	function setBandagesEnhancedPerkDef( _perkDef )
	{
		::Legends.Perk.BandagesEnhanced <- _perkDef;
		::Const.Perks.PerkDefs.BandagesEnhanced <- _perkDef;
	},

	function registerPerkDef()
	{
		foreach (i, perkDef in ::Const.Perks.PerkDefObjects)
		{
			if (perkDef != null && "ID" in perkDef && perkDef.ID == ::BandagesEnhanced.Constants.BandageEnchancePerkID)
			{
				this.setBandagesEnhancedPerkDef(i);
				this.BandagesEnhancedPerkDef = i;
				::BandagesEnhanced.Helpers.debugLog("[Legends] reused existing perk def index=" + i);
				return i;
			}
		}

		this.setBandagesEnhancedPerkDef(null);
		local perk = ::BandagesEnhanced.getBandagesEnhancedPerkDefinition();
		delete perk.Row;
		perk.Const <- "BandagesEnhanced";
		::Const.Perks.addPerkDefObjects([perk]);

		this.BandagesEnhancedPerkDef = ::Legends.Perk.BandagesEnhanced;
		::BandagesEnhanced.Helpers.debugLog("[Legends] registered perk def index=" + this.BandagesEnhancedPerkDef);
		return this.BandagesEnhancedPerkDef;
	},

	function getBandagesEnhancedPerkDefNumber()
	{
		if (this.BandagesEnhancedPerkDef != null)
		{
			return this.BandagesEnhancedPerkDef;
		}

		return this.registerPerkDef();
	},

	function addBandagesEnhancedToBackground( _background )
	{
		if (_background == null)
		{
			return false;
		}

		local perkDef = this.getBandagesEnhancedPerkDefNumber();
		if (perkDef == null)
		{
			::BandagesEnhanced.Helpers.debugLog("[Legends] background add skipped: perk def unavailable");
			return false;
		}

		if (_background.m.PerkTreeMap == null)
		{
			::BandagesEnhanced.Helpers.debugLog("[Legends] background add skipped: PerkTreeMap unavailable");
			return false;
		}

		if (_background.getPerk(::BandagesEnhanced.Constants.BandageEnchancePerkID) != null)
		{
			::BandagesEnhanced.Helpers.debugLog("[Legends] background getPerk() is not null");
			return false;
		}

		local added = _background.addPerk(perkDef, ::BandagesEnhanced.Helpers.getConfiguredRow(true), true);
		::BandagesEnhanced.Helpers.debugLog("[Legends] background add result=" + added + " id=" + _background.getID());
		return added;
	},

	function registerHooks( _mod )
	{
		local compLegends = ::BandagesEnhanced.Compatibility.Legends;
		compLegends.registerPerkDef();
		_mod.hook("scripts/skills/backgrounds/character_background", function(q)
		{
			q.buildPerkTree = @(__original) function()
			{
				local attributes = __original();
				compLegends.addBandagesEnhancedToBackground(this);
				return attributes;
			}
		});

		::BandagesEnhanced.Helpers.debugLog("[Legends] character_background buildPerkTree hook registered");
	}
};
