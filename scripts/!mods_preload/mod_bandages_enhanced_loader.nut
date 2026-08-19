if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.ID <- "mod_bandages_enhanced";
::BandagesEnhanced.Name <- "Bandages Enhanced";
::BandagesEnhanced.Version <- "0.2.1";

::BandagesEnhanced.HookMod <- ::Hooks.register(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name);
::BandagesEnhanced.HookMod.require("mod_msu >= 1.9.0");

::include("scripts/mods/bandages_enhanced/bandage_helpers");
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

	local mod = ::BandagesEnhanced.HookMod;

	::Hooks.registerJS("ui/mods/bandages_enhanced.js");
	::Hooks.registerCSS("ui/mods/bandages_enhanced.css");
	::Hooks.registerJS("ui/mods/bandages_enhanced_screen.js");
	::Hooks.registerCSS("ui/mods/bandages_enhanced_screen.css");

	if (::Hooks.hasMod("mod_reforged"))
	{
		::BandagesEnhanced.Helpers.debugLog("[Reforged] Dynamic Perks compatibility selected");
	}
	else if (::BandagesEnhanced.Compatibility.Legends.hasRuntime())
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

	::BandagesEnhanced.Universal.registerHooks(mod)

});

::BandagesEnhanced.HookMod.queue(">mod_reforged", function()
{
	::BandagesEnhanced.Compatibility.Reforged.register();
}, ::Hooks.QueueBucket.AfterHooks);
