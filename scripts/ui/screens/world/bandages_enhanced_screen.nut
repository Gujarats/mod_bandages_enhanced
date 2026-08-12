this.bandages_enhanced_screen <- {
	m = {
		JSHandle = null,
		Visible = false,
		Animating = false,
		OnClosePressedListener = null
	},

	function isVisible()
	{
		return this.m.Visible != null && this.m.Visible == true;
	}

	function isAnimating()
	{
		return this.m.Animating != null && this.m.Animating == true;
	}

	function setOnClosePressedListener( _listener )
	{
		this.m.OnClosePressedListener = _listener;
	}

	function create()
	{
		if (this.m.JSHandle != null)
		{
			::BandagesEnhanced.Helpers.debugLog("treatment screen create skipped: already connected");
			return;
		}

		this.m.Visible = false;
		this.m.Animating = false;
		this.m.JSHandle = this.UI.connect("BandagesEnhancedScreen", this);
		::BandagesEnhanced.Helpers.debugLog("treatment screen created");
	}

	function destroy()
	{
		this.m.OnClosePressedListener = null;
		if (this.m.JSHandle != null)
		{
			this.m.JSHandle = this.UI.disconnect(this.m.JSHandle);
		}
		::BandagesEnhanced.Helpers.debugLog("treatment screen destroyed");
	}

	function show()
	{
		if (this.m.JSHandle != null)
		{
			this.Tooltip.hide();
			::BandagesEnhanced.Helpers.debugLog("treatment screen show");
			this.m.JSHandle.asyncCall("show", this.queryData());
		}
	}

	function hide( _withSlideAnimation = false )
	{
		if (this.m.JSHandle != null)
		{
			this.Tooltip.hide();
			::BandagesEnhanced.Helpers.debugLog("treatment screen hide");
			this.m.JSHandle.asyncCall("hide", _withSlideAnimation);
		}
	}

	function queryData()
	{
		return {
			BandageCount = ::BandagesEnhanced.Helpers.countBandagesInStash(),
			Rows = ::BandagesEnhanced.Helpers.getRosterTreatmentRows()
		};
	}

	function onApplyBandage( _data )
	{
		local actorID = typeof _data == "array" ? _data[0] : _data;
		::BandagesEnhanced.Helpers.debugLog("treatment screen apply requested actorID=" + actorID);

		local result = ::BandagesEnhanced.Helpers.applyRosterBandageByActorID(actorID);
		result.Data <- this.queryData();
		return result;
	}

	function onCloseButtonPressed()
	{
		::BandagesEnhanced.Helpers.debugLog("treatment screen close requested");
		if (this.m.OnClosePressedListener != null)
		{
			this.m.OnClosePressedListener();
		}
	}

	function onScreenConnected()
	{
	}

	function onScreenDisconnected()
	{
	}

	function onScreenShown()
	{
		this.m.Visible = true;
		this.m.Animating = false;
		::BandagesEnhanced.Helpers.debugLog("treatment screen shown");
	}

	function onScreenHidden()
	{
		this.m.Visible = false;
		this.m.Animating = false;
		::BandagesEnhanced.Helpers.debugLog("treatment screen hidden");
	}

	function onScreenAnimating()
	{
		this.m.Animating = true;
	}
};
