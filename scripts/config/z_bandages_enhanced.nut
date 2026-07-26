if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::Const.Perks.BandagesEnhanced <- [];

local function addPerk( perk )
{
	perk.Unlocks <- perk.Row;
	perk.verifyPrerequisites <- function( _player, _tooltip )
	{
		return true;
	}

	::Const.Perks.BandagesEnhanced.push(perk);
	::Const.Perks.LookupMap[perk.ID] <- perk;
}

addPerk({
	ID = "perk.bandages_enhanced",
	Script = "scripts/skills/perks/bandages_enhanced_perk",
	Name = "Bandages Enhanced",
	Tooltip = "Improves bandages so they restore more hitpoints and speed up temporary injury recovery.",
	Icon = "ui/perks/bandages_enhanced.png",
	IconDisabled = "ui/perks/bandages_enhanced_sw.png",
	Row = 2 // replaced by MSU setting
});

::BandagesEnhanced.configureDebugLogging <- function()
{
	if (::BandagesEnhanced.Mod.ModSettings.getSetting("DebugLogging").getValue())
	{
		::BandagesEnhanced.Mod.Debug.enable();
	}
	else
	{
		::BandagesEnhanced.Mod.Debug.disable();
	}
}

::BandagesEnhanced.Helpers <- {
	function debugLog( _message )
	{
		if (::BandagesEnhanced.Mod.ModSettings.getSetting("DebugLogging").getValue())
		{
			::BandagesEnhanced.Mod.Debug.printLog("[BandagesEnhanced] " + _message);
		}
	}

	function hasBandagesEnhancedPerk( _actor )
	{
		return _actor != null && _actor.getSkills() != null && _actor.getSkills().hasSkill("perk.bandages_enhanced");
	}

	function clonePerkTree( _perkTree )
	{
		local perks = [];
		foreach (row in _perkTree)
		{
			perks.push(clone row);
		}
		return perks;
	}

	function hasPerkInTree( _perkTree, _perkID )
	{
		foreach (row in _perkTree)
		{
			foreach (perk in row)
			{
				if ("ID" in perk && perk.ID == _perkID) return true;
			}
		}
		return false;
	}

	function appendBandagesEnhancedPerks( _perkTree, _row )
	{
		local perks = this.clonePerkTree(_perkTree);
		local row = ::Math.max(1, ::Math.min(_row, 7)) - 1;

		while (perks.len() <= row)
		{
			perks.push([]);
		}

		foreach (perk in ::Const.Perks.BandagesEnhanced)
		{
			if (this.hasPerkInTree(perks, perk.ID)) continue;

			local p = clone perk;
			if ("verifyPrerequisites" in p) delete p.verifyPrerequisites;
			perks[row].push(p);
		}

		return perks;
	}

	function getCombatHealPercent( _actor )
	{
		local settings = ::BandagesEnhanced.Mod.ModSettings;
		return this.hasBandagesEnhancedPerk(_actor)
			? settings.getSetting("PerkHealPercentMaxHP").getValue()
			: settings.getSetting("BaseHealPercentMaxHP").getValue();
	}

	function getMaxHPHealAmount( _actor )
	{
		if (_actor == null) return 0;

		local percent = this.getCombatHealPercent(_actor);
		local amount = ::Math.floor(_actor.getHitpointsMax() * percent / 100.0);
		local missing = _actor.getHitpointsMax() - _actor.getHitpoints();
		return ::Math.max(0, ::Math.min(missing, amount));
	}

	function canTreatVanillaBandageCondition( _target )
	{
		if (_target == null || _target.getSkills() == null) return false;

		if (_target.getSkills().hasSkill("effects.bleeding")) return true;

		local skill = _target.getSkills().getSkillByID("injury.cut_artery");
		if (skill != null && skill.isFresh()) return true;

		skill = _target.getSkills().getSkillByID("injury.cut_throat");
		if (skill != null && skill.isFresh()) return true;

		skill = _target.getSkills().getSkillByID("injury.grazed_neck");
		if (skill != null && skill.isFresh()) return true;

		return false;
	}

	function canUseBandageInCombatOn( _target )
	{
		if (_target == null || !_target.isAlive()) return false;
		if (this.canTreatVanillaBandageCondition(_target)) return true;
		return _target.getHitpoints() < _target.getHitpointsMax();
	}

	function removeVanillaBandageConditions( _target )
	{
		while (_target.getSkills().hasSkill("effects.bleeding"))
		{
			_target.getSkills().removeByID("effects.bleeding");
		}

		local skill = _target.getSkills().getSkillByID("injury.cut_artery");
		if (skill != null && skill.isFresh()) _target.getSkills().remove(skill);

		skill = _target.getSkills().getSkillByID("injury.cut_throat");
		if (skill != null && skill.isFresh()) _target.getSkills().remove(skill);

		skill = _target.getSkills().getSkillByID("injury.grazed_neck");
		if (skill != null && skill.isFresh()) _target.getSkills().remove(skill);
	}

	function applyCombatBandage( _user, _target )
	{
		if (_target == null) return false;

		local didTreat = this.canTreatVanillaBandageCondition(_target);
		this.removeVanillaBandageConditions(_target);

		local healAmount = this.getMaxHPHealAmount(_target);
		if (healAmount > 0)
		{
			local actor = _target;
			actor.setHitpoints(::Math.min(actor.getHitpointsMax(), actor.getHitpoints() + healAmount));
			didTreat = true;

			if (!actor.isHiddenToPlayer())
			{
				::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(actor) + " heals for " + healAmount + " hitpoints");
			}
		}

		if (!didTreat)
		{
			this.debugLog("combat bandage rejected for " + _target.getName() + ": no bleeding, fresh wound, or missing hitpoints");
		}

		this.debugLog("combat bandage used by " + (_user == null ? "<null>" : _user.getName()) + " on " + _target.getName() + ", heal=" + healAmount);
		return didTreat;
	}

	function getCurrentMaxHealingDays( _injury )
	{
		local ht = _injury.getHealingTime();
		return ht.Max;
	}

	function compressTemporaryInjuries( _actor )
	{
		if (_actor == null || !this.hasBandagesEnhancedPerk(_actor)) return 0;

		local settings = ::BandagesEnhanced.Mod.ModSettings;
		local lightThreshold = settings.getSetting("LightInjuryThresholdDays").getValue();
		local lightMax = settings.getSetting("LightInjuryMaxDays").getValue();
		local heavyMax = settings.getSetting("HeavyInjuryMaxDays").getValue();
		local changed = 0;
		local injuries = _actor.getSkills().query(::Const.SkillType.TemporaryInjury);

		foreach (injury in injuries)
		{
			if (injury.isType(::Const.SkillType.PermanentInjury)) continue;

			local currentMax = this.getCurrentMaxHealingDays(injury);
			local targetMax = currentMax <= lightThreshold ? lightMax : heavyMax;
			if (currentMax <= targetMax) continue;

			injury.m.HealingTimeMin = ::Math.min(injury.m.HealingTimeMin, targetMax);
			injury.m.HealingTimeMax = ::Math.max(injury.m.HealingTimeMin, targetMax);
			injury.setTreated(true);
			changed++;
		}

		if (changed > 0)
		{
			_actor.updateInjuryVisuals();
		}

		this.debugLog("roster bandage compressed " + changed + " temporary injuries on " + _actor.getName());
		return changed;
	}

	function getRosterBandageUseResult( _actor )
	{
		if (_actor == null)
		{
			this.debugLog("roster bandage eligibility: actor=<null> result=false reason=null_actor");
			return {
				CanUse = false,
				Reason = "null_actor",
				Message = "No character is selected."
			};
		}

		local hasPerk = this.hasBandagesEnhancedPerk(_actor);
		local hasTemporaryInjury = _actor.getSkills().hasSkillOfType(::Const.SkillType.TemporaryInjury);
		local hasPermanentInjury = _actor.getSkills().hasSkillOfType(::Const.SkillType.PermanentInjury);

		this.debugLog("roster bandage eligibility: actor=" + _actor.getName()
			+ " hasPerk=" + hasPerk
			+ " hasTemporaryInjury=" + hasTemporaryInjury
			+ " hasPermanentInjury=" + hasPermanentInjury);

		if (!hasPerk)
		{
			this.debugLog("roster bandage eligibility result=false actor=" + _actor.getName() + " reason=missing_perk");
			return {
				CanUse = false,
				Reason = "missing_perk",
				Message = _actor.getName() + " does not have the Bandages Enhanced perk."
			};
		}

		if (hasPermanentInjury && !hasTemporaryInjury)
		{
			this.debugLog("roster bandage eligibility result=false actor=" + _actor.getName() + " reason=permanent_injury_only");
			return {
				CanUse = false,
				Reason = "permanent_injury_only",
				Message = _actor.getName() + " only has permanent injuries. Bandages Enhanced never heals permanent injuries."
			};
		}

		if (!hasTemporaryInjury)
		{
			this.debugLog("roster bandage eligibility result=false actor=" + _actor.getName() + " reason=no_temporary_injury");
			return {
				CanUse = false,
				Reason = "no_temporary_injury",
				Message = _actor.getName() + " has no temporary injury to treat."
			};
		}

		this.debugLog("roster bandage eligibility result=true actor=" + _actor.getName());
		return {
			CanUse = true,
			Reason = "ok",
			Message = _actor.getName() + " can use Bandages Enhanced."
		};
	}

	function canUseBandageOnRoster( _actor )
	{
		return this.getRosterBandageUseResult(_actor).CanUse;
	}

	function applyRosterBandage( _actor )
	{
		local result = this.getRosterBandageUseResult(_actor);
		if (!result.CanUse)
		{
			this.debugLog("roster bandage rejected for " + (_actor == null ? "<null>" : _actor.getName()));
			return false;
		}

		return this.compressTemporaryInjuries(_actor) > 0;
	}
};
