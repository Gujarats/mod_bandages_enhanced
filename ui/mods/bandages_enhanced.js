var BandagesEnhanced = {};

BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData
	= CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData;
CharacterScreenPerksModule.prototype.loadPerkTreesWithBrotherData = function(_brother)
{
	if (_brother.bandages_enhanced_perkTree)
	{
		this.onPerkTreeLoaded(null, _brother.bandages_enhanced_perkTree);
		return;
	}

	BandagesEnhanced.CharacterScreenPerksModule_loadPerkTreesWithBrotherData.call(this, _brother);
};
