var BandagesEnhanced = {};

CharacterScreen.prototype.showBandagesEnhancedPopup = function(_data)
{
	var title = 'Bandages Enhanced';
	var message = '';

	if (_data !== undefined && _data !== null && typeof(_data) === 'object')
	{
		if (_data.Title !== undefined && _data.Title !== null)
		{
			title = _data.Title;
		}

		if (_data.Message !== undefined && _data.Message !== null)
		{
			message = _data.Message;
		}
	}

	if (this.mDataSource !== null)
	{
		this.mDataSource.notifyBackendPopupDialogIsVisible(true);
	}

	var self = this;
	var popupDialog = $('.character-screen').createPopupDialog(title, null, null, 'bandages-enhanced-popup');
	var content = $('<div class="bandages-enhanced-popup-dialog-content-container"/>');
	var messageLabel = $('<div class="message description-font-medium font-color-description"/>');
	messageLabel.text(message);
	content.append(messageLabel);

	popupDialog.addPopupDialogContent(content);
	popupDialog.addPopupDialogOkButton(function(_dialog)
	{
		_dialog.destroyPopupDialog();

		if (self.mDataSource !== null)
		{
			self.mDataSource.notifyBackendPopupDialogIsVisible(false);
		}
	});
};

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
