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

			q.convertEntityToUIData = @(__original) function( _entity, _activeEntity )
			{
				local result = __original(_entity, _activeEntity);

				foreach (key, value in result)
				{
					if (typeof key == "string" && key.find("_perkTree") != null && typeof value == "array")
					{
						result[key] = ::BandagesEnhanced.Helpers.appendBandagesEnhancedPerks(value, ::BandagesEnhanced.Helpers.getConfiguredRow());
					}
				}

				return result;
			}
		});

		::BandagesEnhanced.Helpers.debugLog("[Vanilla] perk-tree hooks registered");
	}
};
