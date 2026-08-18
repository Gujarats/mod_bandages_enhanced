if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.registerSettings <- function()
{
	local general = ::BandagesEnhanced.Mod.ModSettings.addPage("General");
	local combat = ::BandagesEnhanced.Mod.ModSettings.addPage("Combat");
	local recovery = ::BandagesEnhanced.Mod.ModSettings.addPage("Recovery");

	local debugLogging = general.addBooleanSetting("DebugLogging", false, "Debug Logging", "Write Bandages Enhanced debug lines to log.html.");
	debugLogging.addCallback(function( _ )
	{
		::BandagesEnhanced.configureDebugLogging();
	});

	general.addRangeSetting("BandageValue", 25, 1, 1000, 1, "Bandage Value", "Base value for bandages. Default matches vanilla.");
	general.addRangeSetting("PerkLevel", 2, 1, 7, 1, "Perk Row", "Which perk row unlocks Bandages Enhanced. Requires restart.");

	combat.addRangeSetting("BaseHealPercentMaxHP", 35, 0, 100, 1, "Base Max HP Heal (%)", "Bandage healing as percent of max HP without the perk.");
	combat.addRangeSetting("PerkHealPercentMaxHP", 65, 0, 100, 1, "Perk Max HP Heal (%)", "Bandage healing as percent of max HP with Bandages Enhanced.");

	recovery.addRangeSetting("LightInjuryThresholdDays", 3, 1, 10, 1, "Light Injury Threshold Days", "Temporary injuries with current max recovery days at or below this value are compressed to Light Injury Max Days.");
	recovery.addRangeSetting("LightInjuryMaxDays", 1, 1, 10, 1, "Light Injury Max Days", "Target max recovery days for light temporary injuries.");
	recovery.addRangeSetting("HeavyInjuryMaxDays", 2, 1, 10, 1, "Heavy Injury Max Days", "Target max recovery days for heavier temporary injuries.");
	recovery.addRangeSetting("InjuriesPerBandageUse", 1, 1, 5, 1, "Injuries Treated Per Use", "How many temporary injuries one bandage use should speed up.");
	recovery.addBooleanSetting("PreferHeaviestInjuryFirst", true, "Prefer Heaviest Injuries First", "Treat heavier temporary injuries before lighter ones when multiple injuries are eligible.");
	recovery.addBooleanSetting("TreatPoVMutationSickness", false, "Treat PoV Mutation Sickness", "Allow Bandages Enhanced to shorten PoV Mutation Sickness. Disabled by default until runtime balance is confirmed.");

}
