var BandagesEnhanced = {};

BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData
	= CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData;
CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData = function(_brother)
{
	if (_brother.bandages_enhanced_perkTree)
	{
		for (var key in _brother)
		{
			if (key !== 'bandages_enhanced_perkTree' && key.indexOf('_perkTree') !== -1)
			{
				BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData.call(this, _brother);
				return;
			}
		}

		this.onPerkTreeLoaded(null, _brother.bandages_enhanced_perkTree);
		return;
	}

	BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData.call(this, _brother);
};
