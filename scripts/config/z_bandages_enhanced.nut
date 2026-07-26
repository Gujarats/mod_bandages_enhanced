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
	Icon = "ui/items/consumables/bandages_01.png",
	IconDisabled = "ui/items/consumables/bandages_01.png",
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

	function canUseBandageOnRoster( _actor )
	{
		if (_actor == null || !this.hasBandagesEnhancedPerk(_actor)) return false;
		if (_actor.getSkills().hasSkillOfType(::Const.SkillType.PermanentInjury)
			&& !_actor.getSkills().hasSkillOfType(::Const.SkillType.TemporaryInjury))
		{
			return false;
		}

		return _actor.getSkills().hasSkillOfType(::Const.SkillType.TemporaryInjury);
	}

	function applyRosterBandage( _actor )
	{
		if (!this.canUseBandageOnRoster(_actor))
		{
			this.debugLog("roster bandage rejected for " + (_actor == null ? "<null>" : _actor.getName()));
			return false;
		}

		return this.compressTemporaryInjuries(_actor) > 0;
	}
};
