
// NOTES : currently exist for reference just in case if the mod_PoV needed more compatibility
// just boilerplate for now, no actual hooks yet.
if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

if (!("Compatibility" in ::BandagesEnhanced))
{
	::BandagesEnhanced.Compatibility <- {};
}

::BandagesEnhanced.Compatibility.PoV <- {
	function hasRuntime()
	{
		return ::Hooks.hasMod("mod_PoV");
	},

	function registerHooks( _mod )
	{
		if (!this.hasRuntime())
		{
			return;
		}

		::BandagesEnhanced.Helpers.debugLog("[PoV] mod_PoV detected; Mutation Sickness treatment setting="
			+ ::BandagesEnhanced.Helpers.setting("TreatPoVMutationSickness"));
	}
};
