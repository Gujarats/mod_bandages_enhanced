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

addPerk({
	ID = "perk.bandages_enhanced",
	Script = "scripts/skills/perks/bandages_enhanced_perk",
	Name = "Bandages Enhanced",
	Tooltip = "Improves bandages so they restore more hitpoints and speed up temporary injury recovery.",
	Icon = "ui/items/consumables/bandages_01.png",
	IconDisabled = "ui/items/consumables/bandages_01.png",
	Row = 2 // replaced by MSU setting
});
