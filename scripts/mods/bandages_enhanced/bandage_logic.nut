if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.configureDebugLogging <- function()
{
	if ("GuzBluezDebugLogController" in getroottable()
		&& "registerTarget" in ::GuzBluezDebugLogController)
	{
		::GuzBluezDebugLogController.registerTarget(::BandagesEnhanced.ID, ::BandagesEnhanced.Mod);
		return;
	}

	::BandagesEnhanced.Mod.Debug.setFlag("default", ::BandagesEnhanced.Mod.ModSettings.getSetting("DebugLogging").getValue());
}

::BandagesEnhanced.Helpers <- {
	function debugLog( _message )
	{
		::BandagesEnhanced.Mod.Debug.printLog("[BandagesEnhanced] " + _message);
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

	function getMaxHPHealAmount( _user, _target )
	{
		if (_target == null) return 0;

		local percent = this.getCombatHealPercent(_user);
		local amount = ::Math.floor(_target.getHitpointsMax() * percent / 100.0);
		local missing = _target.getHitpointsMax() - _target.getHitpoints();
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

	function hasLegendsBandageMastery( _actor )
	{
		if (_actor == null
			|| !::Hooks.hasMod("mod_legends")
			|| !("Legends" in getroottable())
			|| !("Perk" in ::Legends)
			|| !("LegendSpecBandage" in ::Legends.Perk)
			|| _actor.getSkills() == null)
		{
			return false;
		}

		local skills = _actor.getSkills();
		if ("hasPerk" in skills)
		{
			return skills.hasPerk(::Legends.Perk.LegendSpecBandage);
		}

		return false;
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

		local healAmount = this.getMaxHPHealAmount(_user, _target);
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
		local maxInjuries = settings.getSetting("InjuriesPerBandageUse").getValue();
		local changed = 0;
		if (maxInjuries < 1) maxInjuries = 1;
		local preferHeaviestFirst = settings.getSetting("PreferHeaviestInjuryFirst").getValue();

		local candidates = [];
		local injuries = _actor.getSkills().query(::Const.SkillType.TemporaryInjury);

		foreach (injury in injuries)
		{
			if (injury.isType(::Const.SkillType.PermanentInjury)) continue;
			if (this.shouldSkipPoVMutationSickness(_actor, injury)) continue;

			local currentMax = this.getCurrentMaxHealingDays(injury);
			local targetMax = currentMax <= lightThreshold ? lightMax : heavyMax;
			if (currentMax <= targetMax) continue;

			candidates.push({
				Injury = injury,
				CurrentMax = currentMax
			});
		}

		if (preferHeaviestFirst && candidates.len() > 1)
		{
			for (local i = 0; i < candidates.len() - 1; i++)
			{
				local best = i;
				for (local j = i + 1; j < candidates.len(); j++)
				{
					local candidate = candidates[j];
					local bestCandidate = candidates[best];
					if (candidate.CurrentMax > bestCandidate.CurrentMax
						|| (candidate.CurrentMax == bestCandidate.CurrentMax && candidate.Injury.getID() > bestCandidate.Injury.getID()))
					{
						best = j;
					}
				}

				if (best != i)
				{
					local tmp = candidates[i];
					candidates[i] = candidates[best];
					candidates[best] = tmp;
				}
			}
		}

		local treatedIds = [];
		foreach (candidate in candidates)
		{
			if (changed >= maxInjuries)
			{
				break;
			}

			local injury = candidate.Injury;
			local currentMax = candidate.CurrentMax;
			local targetMax = currentMax <= lightThreshold ? lightMax : heavyMax;

			injury.m.HealingTimeMin = ::Math.min(injury.m.HealingTimeMin, targetMax);
			injury.m.HealingTimeMax = ::Math.max(injury.m.HealingTimeMin, targetMax);
			injury.setTreated(true);
			treatedIds.push(injury.getID());
			changed++;
		}

		if (changed > 0)
		{
			_actor.updateInjuryVisuals();
		}

		this.debugLog("roster bandage compressed " + changed + " temporary injuries on " + _actor.getName());
		return {
			Changed = changed,
			TreatedInjuries = treatedIds
		};
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
		local treatableInjuries = this.getRosterTreatableInjuries(_actor);
		local treatableCount = treatableInjuries.len();

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

		if (treatableCount == 0)
		{
			this.debugLog("roster bandage eligibility result=false actor=" + _actor.getName() + " reason=no_treatable_injury");
			return {
				CanUse = false,
				Reason = "no_treatable_injury",
				Message = _actor.getName() + " has only fully treated temporary injuries. No further reduction is possible."
			};
		}

		this.debugLog("roster bandage eligibility result=true actor=" + _actor.getName());
		local label = treatableCount == 1 ? " temporary injury." : " temporary injuries.";
		return {
			CanUse = true,
			Reason = "ok",
			Message = _actor.getName() + " can use Bandages Enhanced on " + treatableCount + label,
			TreatableInjuries = treatableInjuries,
			TreatableInjuryCount = treatableCount
		};
	}

	function getRosterTreatableInjuries( _actor )
	{
		local injuries = [];

		if (_actor == null || _actor.getSkills() == null)
		{
			return injuries;
		}

		local allInjuries = _actor.getSkills().query(::Const.SkillType.TemporaryInjury);
		local settings = ::BandagesEnhanced.Mod.ModSettings;
		local lightThreshold = settings.getSetting("LightInjuryThresholdDays").getValue();
		local lightMax = settings.getSetting("LightInjuryMaxDays").getValue();
		local heavyMax = settings.getSetting("HeavyInjuryMaxDays").getValue();

		foreach (injury in allInjuries)
		{
			if (injury.isType(::Const.SkillType.PermanentInjury)) continue;
			if (this.shouldSkipPoVMutationSickness(_actor, injury)) continue;

			local currentMax = this.getCurrentMaxHealingDays(injury);
			local targetMax = currentMax <= lightThreshold ? lightMax : heavyMax;
			if (currentMax <= targetMax) continue;

			injuries.push({
				ID = injury.getID(),
				Icon = injury.getIconColored(),
				Name = injury.getNameOnly()
			});
		}

		return injuries;
	}

	function shouldSkipPoVMutationSickness( _actor, _injury )
	{
		if (_injury == null || _injury.getID() != "injury.pov_sickness2" || !::Hooks.hasMod("mod_PoV"))
		{
			return false;
		}

		if (::BandagesEnhanced.Mod.ModSettings.getSetting("TreatPoVMutationSickness").getValue())
		{
			return false;
		}

		this.debugLog("[PoV] skipped Mutation Sickness for " + (_actor == null ? "<null>" : _actor.getName()));
		return true;
	}

	function getRosterTreatmentRows()
	{
		local rows = [];

		if (!("World" in getroottable()) || ::World.getPlayerRoster() == null)
		{
			this.debugLog("roster treatment query failed: player roster unavailable");
			return rows;
		}

		local roster = ::World.getPlayerRoster().getAll();

		foreach (actor in roster)
		{
			local result = this.getRosterBandageUseResult(actor);
			local treatableInjuries = ("TreatableInjuries" in result) ? result.TreatableInjuries : this.getRosterTreatableInjuries(actor);
			rows.push({
				ID = actor.getID(),
				Name = actor.getName(),
				ImagePath = actor.getImagePath(),
				ImageOffsetX = actor.getImageOffsetX(),
				ImageOffsetY = actor.getImageOffsetY(),
				BackgroundImagePath = actor.getBackground().getIconColored(),
				Level = actor.getLevel(),
				Hitpoints = actor.getHitpoints(),
				HitpointsMax = actor.getHitpointsMax(),
				HasPerk = this.hasBandagesEnhancedPerk(actor),
				HasTemporaryInjury = actor.getSkills().hasSkillOfType(::Const.SkillType.TemporaryInjury),
				HasPermanentInjury = actor.getSkills().hasSkillOfType(::Const.SkillType.PermanentInjury),
				TreatableInjuries = treatableInjuries,
				CanUse = result.CanUse,
				Reason = result.Reason,
				Message = result.Message
			});
		}

		this.debugLog("roster treatment query rows=" + rows.len());
		return rows;
	}

	function countBandagesInStash()
	{
		if (!("World" in getroottable()) || ::World.Assets == null)
		{
			this.debugLog("count bandages failed: world assets unavailable");
			return 0;
		}

		local stash = ::World.Assets.getStash();
		local count = 0;

		foreach (item in stash.m.Items)
		{
			if (item != null && item.getID() == "accessory.bandage")
			{
				count++;
			}
		}

		this.debugLog("count bandages in stash=" + count);
		return count;
	}

	function consumeBandageFromStash()
	{
		if (!("World" in getroottable()) || ::World.Assets == null)
		{
			this.debugLog("consume bandage failed: world assets unavailable");
			return false;
		}

		local stash = ::World.Assets.getStash();

		for (local i = 0; i < stash.m.Items.len(); i++)
		{
			local item = stash.m.Items[i];
			if (item != null && item.getID() == "accessory.bandage")
			{
				stash.removeByIndex(i);
				this.debugLog("consumed roster bandage from stash index=" + i);
				return true;
			}
		}

		this.debugLog("consume bandage failed: no bandage in stash");
		return false;
	}

	function applyRosterBandageByActorID( _actorID )
	{
		local response = {
			Success = false,
			Reason = "unknown",
			Message = "Bandages Enhanced could not apply treatment."
		};

		if (!("World" in getroottable()) || ::World.getPlayerRoster() == null)
		{
			response.Reason = "roster_unavailable";
			response.Message = "The company roster is unavailable.";
			this.debugLog("screen apply failed: roster unavailable actorID=" + _actorID);
			return response;
		}

		local actor = null;
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.getID() == _actorID)
			{
				actor = bro;
				break;
			}
		}

		if (actor == null)
		{
			response.Reason = "actor_not_found";
			response.Message = "The selected character could not be found.";
			this.debugLog("screen apply failed: actor not found actorID=" + _actorID);
			return response;
		}

		local useResult = this.getRosterBandageUseResult(actor);
		if (!useResult.CanUse)
		{
			response.Reason = useResult.Reason;
			response.Message = useResult.Message;
			this.debugLog("screen apply rejected actor=" + actor.getName() + " reason=" + useResult.Reason);
			return response;
		}

		if (this.countBandagesInStash() <= 0)
		{
			response.Reason = "no_bandage";
			response.Message = "No bandages are available in the stash.";
			this.debugLog("screen apply rejected actor=" + actor.getName() + " reason=no_bandage");
			return response;
		}

		local applied = this.applyRosterBandage(actor);
		if (!applied)
		{
			response.Reason = "not_shortened";
			response.Message = "Bandages could not shorten " + actor.getName() + "'s temporary injury recovery any further.";
			this.debugLog("screen apply failed after helper actor=" + actor.getName());
			return response;
		}

		if (!this.consumeBandageFromStash())
		{
			response.Reason = "consume_failed";
			response.Message = "Treatment was applied, but no bandage could be consumed. Check the debug log.";
			this.debugLog("screen apply consume failed after treatment actor=" + actor.getName());
			return response;
		}

		response.Success = true;
		response.Reason = "ok";
		response.Message = "Bandages applied to " + actor.getName() + ". Temporary injury recovery has been shortened.";
		this.debugLog("screen apply success actor=" + actor.getName());
		return response;
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

		return this.compressTemporaryInjuries(_actor).Changed > 0;
	}
};