if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.Vanilla <- {
	function registerHooks( _mod )
	{
		_mod.hook("scripts/ui/global/data_helper", function(q)
		{
			q.convertPerksToUIData = @(__original) function()
			{
				local perks = __original();
				return ::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(perks, ::BandagesEnhanced.Helpers.getConfiguredRow());
			}
		});

		::BandagesEnhanced.Helpers.debugLog("[Vanilla] perk-tree hooks registered");
	}
};
