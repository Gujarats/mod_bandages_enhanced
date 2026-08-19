if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

if (!("Compatibility" in ::BandagesEnhanced))
{
	::BandagesEnhanced.Compatibility <- {};
}

::BandagesEnhanced.Compatibility.Reforged <- {
	ExistingPlayersMigrated = false,

	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_reforged")
			&& ("DynamicPerks" in getroottable())
			&& ("Perks" in ::DynamicPerks)
			&& ("PerkGroups" in ::DynamicPerks)
			&& ("addPerks" in ::DynamicPerks.Perks)
			&& ("findById" in ::DynamicPerks.PerkGroups);
	},

	function registerPerkDefinition()
	{
		if (::Const.Perks.findById(::BandagesEnhanced.Constants.BandageEnchancePerkID) != null)
		{
			::BandagesEnhanced.Helpers.debugLog("[Reforged] Bandages Enhanced perk definition already registered");
			return true;
		}

		local perk = ::BandagesEnhanced.getBandagesEnhancedPerkDefinition();
		delete perk.Row;
		::DynamicPerks.Perks.addPerks([perk]);
		::BandagesEnhanced.Helpers.debugLog("[Reforged] Bandages Enhanced perk definition registered");
		return true;
	},

	//in mod_reforged pg.rf_always_1 is the perk group that is used for bag perks and available to all characters, so we can use it to inject the perk into all characters.
	function addBandagesEnhancedToUniversalGroup()
	{
		local group = ::DynamicPerks.PerkGroups.findById("pg.rf_always_1");
		if (group == null)
		{
			::BandagesEnhanced.Helpers.debugLog("[Reforged] Bandages Enhanced insertion skipped: universal perk group is unavailable");
			return false;
		}

		local tree = group.getTree();
		foreach (i, perks in tree)
		{
			foreach (perkID in perks)
			{
				if (perkID == ::BandagesEnhanced.Constants.BandageEnchancePerkID)
				{
					::BandagesEnhanced.Helpers.debugLog("[Reforged] Bandages Enhanced already present in universal perk group row=" + (i + 1));
					return true;
				}
			}
		}

		local row = ::BandagesEnhanced.Helpers.getConfiguredRow();
		while (tree.len() < row)
		{
			tree.push([]);
		}

		tree[row - 1].push(::BandagesEnhanced.Constants.BandageEnchancePerkID);
		::BandagesEnhanced.Helpers.debugLog("[Reforged] Bandages Enhanced inserted into universal perk group row=" + row);
		return true;
	},

	function addBandagesEnhancedToExistingPlayerTrees()
	{
		local added = 0;
		local alreadyPresent = 0;
		local unavailable = 0;
		foreach (actor in ::World.getPlayerRoster().getAll())
		{
			if (actor == null)
			{
				unavailable++;
				continue;
			}

			local perkTree = actor.getPerkTree();
			if (perkTree == null)
			{
				unavailable++;
				continue;
			}

			if (::BandagesEnhanced.Constants.BandageEnchancePerkID in perkTree.getPerks())
			{
				alreadyPresent++;
				continue;
			}

			perkTree.addPerk(::BandagesEnhanced.Constants.BandageEnchancePerkID, ::BandagesEnhanced.Helpers.getConfiguredRow());
			added++;
			::BandagesEnhanced.Helpers.debugLog("[Reforged] Bandages Enhanced added to existing player perk tree for " + actor.getName() + " row=" + ::BandagesEnhanced.Helpers.getConfiguredRow());
		}

		::BandagesEnhanced.Helpers.debugLog("[Reforged] existing-player Bandages Enhanced migration complete added=" + added + " already_present=" + alreadyPresent + " unavailable=" + unavailable);
		return true;
	},

	// using this approach to prevent the perk being added over and over again to existing players on each load, since the perk is already added to the universal group.
	// this approach used for existing saves that does not installed the mod_bandages_enhanced
	function tryMigrateExistingPlayerTrees()
	{
		if (this.ExistingPlayersMigrated) return true;
		if (!this.hasRuntime()
			|| !("World" in getroottable())
			|| ::World.getPlayerRoster() == null
			|| ::World.getPlayerRoster().getAll().len() == 0)
		{
			return false;
		}

		this.addBandagesEnhancedToExistingPlayerTrees();
		this.ExistingPlayersMigrated = true;
		return true;
	},

	// for new campaigns, the perk is added to the universal perk group, so all new characters will have it available automatically.
	function register()
	{
		if (!this.hasRuntime())
		{
			::BandagesEnhanced.Helpers.debugLog("[Reforged] Bandages Enhanced registration skipped: required Dynamic Perks APIs are unavailable");
			return false;
		}

		if (!this.registerPerkDefinition()) return false;
		return this.addBandagesEnhancedToUniversalGroup();
	}
};
