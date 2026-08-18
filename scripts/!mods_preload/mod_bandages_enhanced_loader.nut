if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.ID <- "mod_bandages_enhanced";
::BandagesEnhanced.Name <- "Bandages Enhanced";
::BandagesEnhanced.Version <- "0.1.2";

::BandagesEnhanced.HookMod <- ::Hooks.register(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name);
::BandagesEnhanced.HookMod.require("mod_msu >= 1.9.0");

::include("scripts/mods/bandages_enhanced/bandage_logic");
::include("scripts/mods/bandages_enhanced/hooks/vanilla_bandage_hooks");
::include("scripts/mods/bandages_enhanced/hooks/universal_hooks");
::include("scripts/mods/bandages_enhanced/compatibility/legends_perk_tree_patch");
::include("scripts/mods/bandages_enhanced/compatibility/reforged_perk_tree_patch");
::include("scripts/mods/bandages_enhanced/compatibility/pov_witcher_patch");

::BandagesEnhanced.openTreatmentScreen <- function()
{
	if (!("World" in getroottable()) || ::World.State == null)
	{
		::BandagesEnhanced.Helpers.debugLog("open treatment screen rejected: world state unavailable");
		return;
	}

	if (::World.State.getMenuStack().hasBacksteps()
		|| ::World.State.m.EventScreen.isAnimating()
		|| ::World.State.m.EventScreen.isVisible()
		|| (::LoadingScreen != null && (::LoadingScreen.isAnimating() || ::LoadingScreen.isVisible())))
	{
		::BandagesEnhanced.Helpers.debugLog("open treatment screen rejected: blocking screen active");
		return;
	}

	if (!("BandagesEnhancedScreen" in ::World.State.m) || ::World.State.m.BandagesEnhancedScreen == null)
	{
		::BandagesEnhanced.Helpers.debugLog("open treatment screen rejected: screen unavailable");
		return;
	}

	if (::World.State.m.BandagesEnhancedScreen.isVisible())
	{
		::BandagesEnhanced.Helpers.debugLog("closing treatment screen from keybind");
		::World.State.m.MenuStack.pop();
		return;
	}

	if (::World.State.m.BandagesEnhancedScreen.isAnimating())
	{
		::BandagesEnhanced.Helpers.debugLog("open treatment screen rejected: screen animating");
		return;
	}

	::BandagesEnhanced.Helpers.debugLog("opening treatment screen from keybind");
	::World.State.m.CustomZoom = ::World.getCamera().Zoom;
	::World.getCamera().zoomTo(1.0, 4.0);
	::World.State.setAutoPause(true);
	::World.State.m.BandagesEnhancedScreen.show();
	::World.State.m.WorldScreen.hide();
	::Cursor.setCursor(::Const.UI.Cursor.Hand);
	::World.State.m.MenuStack.push(function()
	{
		::World.getCamera().zoomTo(this.m.CustomZoom, 4.0);
		this.m.BandagesEnhancedScreen.hide();
		this.m.WorldScreen.show();
		this.setAutoPause(false);
		this.Cursor.setCursor(this.Const.UI.Cursor.Hand);
	}, function()
	{
		return !this.m.BandagesEnhancedScreen.isAnimating();
	});
}

::BandagesEnhanced.registerKeybinds <- function()
{
	::BandagesEnhanced.Mod.Keybinds.addSQKeybind(
		"open_bandages_enhanced_screen",
		"shift+c",
		::MSU.Key.State.World,
		function()
		{
			::BandagesEnhanced.openTreatmentScreen();
		},
		"Open Bandages Enhanced Screen",
		null,
		"Open the Bandages Enhanced roster treatment screen"
	);
}

::BandagesEnhanced.HookMod.queue(">mod_msu", ">mod_druid", ">mod_aura_routing", ">mod_from_the_grave", ">mod_legends", ">mod_PoV", ">mod_necro", ">mod_reforged", function()
{
	::BandagesEnhanced.Mod <- ::MSU.Class.Mod(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name);
	::BandagesEnhanced.registerSettings();
	::BandagesEnhanced.configureDebugLogging();
	::BandagesEnhanced.registerKeybinds();
	::BandagesEnhanced.Helpers.debugLog("settings initialized");
	::BandagesEnhanced.Helpers.debugLog("runtime mods: legends=" + ::Hooks.hasMod("mod_legends") + " pov=" + ::Hooks.hasMod("mod_PoV"));

	local mod = ::BandagesEnhanced.HookMod;

	::Hooks.registerJS("ui/mods/bandages_enhanced.js");
	::Hooks.registerCSS("ui/mods/bandages_enhanced.css");
	::Hooks.registerJS("ui/mods/bandages_enhanced_screen.js");
	::Hooks.registerCSS("ui/mods/bandages_enhanced_screen.css");

	// not sure why it does now showing the log message whenever I press shift + c
	local showRosterBandagePopup = function( _message )
	{
		if ("Tactical" in getroottable() && ::Tactical.isActive())
		{
			::BandagesEnhanced.Helpers.debugLog("roster bandage popup suppressed during tactical: " + _message);
			return;
		}

		if ("World" in getroottable()
			&& ::World.State != null
			&& "m" in ::World.State
			&& "CharacterScreen" in ::World.State.m
			&& ::World.State.m.CharacterScreen != null
			&& ::World.State.m.CharacterScreen.isVisible()
			&& ::World.State.m.CharacterScreen.m.JSHandle != null)
		{
			::BandagesEnhanced.Helpers.debugLog("roster bandage character popup show: " + _message);
			::World.State.m.CharacterScreen.m.JSHandle.asyncCall("showBandagesEnhancedPopup", {
				Title = "Bandages Enhanced",
				Message = _message
			});
		}
		else if ("World" in getroottable()
			&& ::World.State != null)
		{
			::BandagesEnhanced.Helpers.debugLog("roster bandage world popup fallback show: " + _message);
			::World.State.showDialogPopup("Bandages Enhanced", _message, null, null, true);
		}
		else
		{
			::BandagesEnhanced.Helpers.debugLog("roster bandage popup unavailable: " + _message);
		}
	}

	if (::Hooks.hasMod("mod_reforged"))
	{
		// This is just for logger
		// the registration is happend on different queue hooks
		// please see AfterHooks
		::BandagesEnhanced.Helpers.debugLog("[Reforged] Dynamic Perks compatibility selected");
	}
	else if (::Hooks.hasMod("mod_legends"))
	{
		::BandagesEnhanced.Compatibility.Legends.registerHooks(mod);

		if (::Hooks.hasMod("mod_PoV"))
		{
			::BandagesEnhanced.Compatibility.PoV.registerHooks(mod);
		}
	}
	else
	{
		::BandagesEnhanced.Vanilla.registerHooks(mod);
	}

	//Some hooks are works for all the 3 games : vanilla, mod legends, mod reforged
	// these hooks are mandatory for all those games type
	::BandagesEnhanced.Universal.registerHooks(mod)

});

// I assume the reforged needs to have its own hook queue
//because the register only work if included with AfterHooks
::BandagesEnhanced.HookMod.queue(">mod_reforged", function()
{
	::BandagesEnhanced.Compatibility.Reforged.register();
}, ::Hooks.QueueBucket.AfterHooks);
