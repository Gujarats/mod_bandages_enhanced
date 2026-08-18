// This file will be loaded at the very end of the game startup after all other assets and script are loaded
// This is to make sure the perk definition is loaded after all other perk definitions are loaded
// th z_ file exist and work for vanilla and reforged and legend
if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.Constants <- {
	BandageEnchancePerkID = "perk.bandages_enhanced"
};

// Some how the perk definition only works on the z_ file config
// if we move this function to non z_ file, the game crash on loading the game or creating new game.
::BandagesEnhanced.getBandagesEnhancedPerkDefinition <- function()
{
	return {
		ID = ::BandagesEnhanced.Constants.BandageEnchancePerkID,
		Script = "scripts/skills/perks/bandages_enhanced_perk",
		Name = "Bandages Enhanced",
		Tooltip = "Improves bandages so they restore more hitpoints and speed up temporary injury recovery.",
		Icon = "ui/perks/bandages_enhanced.png",
		IconDisabled = "ui/perks/bandages_enhanced_sw.png",
		Row = 2 // just for temporary definition , this will be replaced by MSU option menu. (required restart if changed)
	};
}

// Make the Perks const on very late in the game to avoid missing Perks const in the early game
::Const.Perks.BandagesEnhanced <- [];

local function addPerk( perk )
{
	perk.Unlocks <- perk.Row;
	perk.verifyPrerequisites <- function( _player, _tooltip )
	{
		return true;
	}

	::Const.Perks.BandagesEnhanced.push(perk);
	::Const.Perks.LookupMap[perk.ID] <- perk;
}

addPerk(::BandagesEnhanced.getBandagesEnhancedPerkDefinition());