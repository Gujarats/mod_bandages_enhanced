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

	function getConfiguredRow()
	{
		local row = ::BandagesEnhanced.Mod.ModSettings.getSetting("PerkLevel").getValue() - 1;
		return row < 0 ? 0 : row;
	},

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
	},

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
	},

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
	},

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

		if (_background.m.PerkTreeMap == null)
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
	},

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
};
