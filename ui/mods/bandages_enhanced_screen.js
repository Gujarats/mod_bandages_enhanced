"use strict";

var BandagesEnhancedTreatmentScreen = function()
{
	this.mSQHandle = null;
	this.mContainer = null;
	this.mDialog = null;
	this.mRows = null;
	this.mSelectedActorID = null;
	this.mStatus = null;
	this.mBandageCount = null;
	this.mApplyButton = null;
};

BandagesEnhancedTreatmentScreen.prototype.isConnected = function()
{
	return this.mSQHandle !== null;
};

BandagesEnhancedTreatmentScreen.prototype.onConnection = function (_handle)
{
	this.mSQHandle = _handle;
	this.register($('.root-screen'));
};

BandagesEnhancedTreatmentScreen.prototype.onDisconnection = function()
{
	this.mSQHandle = null;
	this.unregister();
};

BandagesEnhancedTreatmentScreen.prototype.register = function(_parentDiv)
{
	if (this.mContainer !== null)
	{
		return;
	}

	this.mContainer = $('<div class="bandages-enhanced-screen display-none opacity-none"/>');
	_parentDiv.append(this.mContainer);

	this.mDialog = $('<div class="bandages-enhanced-dialog"/>');
	this.mContainer.append(this.mDialog);

	var header = $('<div class="bandages-enhanced-header"/>');
	this.mDialog.append(header);
	header.append($('<div class="title title-font-big font-bold font-color-title">Bandages Enhanced</div>'));
	this.mBandageCount = $('<div class="bandage-count text-font-normal font-color-label"/>');
	header.append(this.mBandageCount);

	this.mRows = $('<div class="bandages-enhanced-roster"/>');
	this.mDialog.append(this.mRows);

	this.mStatus = $('<div class="bandages-enhanced-status text-font-normal font-color-description"/>');
	this.mDialog.append(this.mStatus);

	var footer = $('<div class="bandages-enhanced-footer"/>');
	this.mDialog.append(footer);

	var self = this;
	this.mApplyButton = footer.createTextButton('Apply Bandage', function()
	{
		if (self.mSelectedActorID !== null)
		{
			self.notifyBackendApplyBandage(self.mSelectedActorID);
		}
	}, '', 1);

	footer.createTextButton('Close', function()
	{
		self.notifyBackendClose();
	}, '', 1);
};

BandagesEnhancedTreatmentScreen.prototype.unregister = function()
{
	if (this.mContainer === null)
	{
		return;
	}

	this.mContainer.empty();
	this.mContainer.remove();
	this.mContainer = null;
};

BandagesEnhancedTreatmentScreen.prototype.loadFromData = function (_data)
{
	var self = this;
	var bandageCount = (_data && _data.BandageCount) ? _data.BandageCount : 0;

	this.mSelectedActorID = null;
	this.mRows.empty();
	this.mBandageCount.text('Bandages in stash: ' + bandageCount);
	this.mStatus.text('Select a character to treat.');

	if (!_data || !_data.Rows || _data.Rows.length === 0)
	{
		this.mStatus.text('No roster members are available.');
		this.mApplyButton.enableButton(false);
		return;
	}

	for (var i = 0; i < _data.Rows.length; i++)
	{
		var rowData = _data.Rows[i];
		var row = $('<div class="bandages-enhanced-row"/>');
		row.data('actorID', rowData.ID);
		row.data('canUse', rowData.CanUse === true);
		row.data('message', rowData.Message);

		row.append($('<div class="name text-font-normal font-bold font-color-label"/>').text(rowData.Name));
		row.append($('<div class="hp text-font-normal font-color-description"/>').text(rowData.Hitpoints + '/' + rowData.HitpointsMax + ' HP'));
		row.append($('<div class="status text-font-normal"/>').text(rowData.Message));

		if (rowData.CanUse === true)
		{
			row.addClass('is-eligible');
		}
		else
		{
			row.addClass('is-disabled');
		}

		row.on('click', function()
		{
			self.mRows.find('.bandages-enhanced-row').removeClass('is-selected');
			$(this).addClass('is-selected');
			self.mSelectedActorID = $(this).data('actorID');
			self.mStatus.text($(this).data('message'));
			self.mApplyButton.enableButton($(this).data('canUse') === true && bandageCount > 0);
		});

		this.mRows.append(row);
	}

	this.mApplyButton.enableButton(false);
};

BandagesEnhancedTreatmentScreen.prototype.show = function (_data)
{
	var self = this;
	this.loadFromData(_data);
	this.mContainer.velocity("finish", true).velocity({ opacity: 1 },
	{
		duration: Constants.SCREEN_FADE_IN_OUT_DELAY,
		easing: 'swing',
		begin: function()
		{
			$(this).removeClass('display-none').addClass('display-block');
			self.notifyBackendOnAnimating();
		},
		complete: function()
		{
			self.notifyBackendOnShown();
		}
	});
};

BandagesEnhancedTreatmentScreen.prototype.hide = function ()
{
	var self = this;
	this.mContainer.velocity("finish", true).velocity({ opacity: 0 },
	{
		duration: Constants.SCREEN_FADE_IN_OUT_DELAY,
		easing: 'swing',
		begin: function()
		{
			self.notifyBackendOnAnimating();
		},
		complete: function()
		{
			$(this).removeClass('display-block').addClass('display-none');
			self.notifyBackendOnHidden();
		}
	});
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendApplyBandage = function (_actorID)
{
	var self = this;
	SQ.call(this.mSQHandle, 'onApplyBandage', _actorID, function(_result)
	{
		if (_result && _result.Message)
		{
			self.mStatus.text(_result.Message);
		}

		if (_result && _result.Data)
		{
			self.loadFromData(_result.Data);
			self.mStatus.text(_result.Message);
		}
	});
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendClose = function()
{
	SQ.call(this.mSQHandle, 'onCloseButtonPressed');
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendOnShown = function()
{
	SQ.call(this.mSQHandle, 'onScreenShown');
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendOnHidden = function()
{
	SQ.call(this.mSQHandle, 'onScreenHidden');
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendOnAnimating = function()
{
	SQ.call(this.mSQHandle, 'onScreenAnimating');
};

registerScreen("BandagesEnhancedScreen", new BandagesEnhancedTreatmentScreen());
