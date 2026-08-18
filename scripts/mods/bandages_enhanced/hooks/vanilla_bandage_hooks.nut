if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.Vanilla <- {
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

		::BandagesEnhanced.Helpers.debugLog("[Vanilla] perk-tree hooks registered");
	}
};