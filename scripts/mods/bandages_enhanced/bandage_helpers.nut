if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.Helpers <- {
	BandageTreatableWoundIDs = ["injury.cut_artery", "injury.cut_throat", "injury.grazed_neck"],

	function debugLog( _message )
	{
		::BandagesEnhanced.Mod.Debug.printLog("[BandagesEnhanced] " + _message);
	}

	function setting( _name )
	{
		return ::BandagesEnhanced.Mod.ModSettings.getSetting(_name).getValue();
	}

	function hasWorldState()
	{
		return "World" in getroottable() && ::World.State != null;
	}

	function hasPlayerRoster()
	{
		return this.hasWorldState() && ::World.getPlayerRoster() != null;
	}

	function hasWorldAssets()
	{
		return this.hasWorldState() && ::World.Assets != null;
	}

	function hasBandagesEnhancedPerk( _actor )
	{
		return _actor != null && _actor.getSkills() != null && _actor.getSkills().hasSkill(::BandagesEnhanced.Constants.BandageEnchancePerkID);
	}

	function getConfiguredRow( _zeroIndexed = false )
	{
		local row = this.setting("PerkLevel");
		if (_zeroIndexed) row -= 1;
		return _zeroIndexed ? ::Math.max(0, row) : ::Math.max(1, ::Math.min(row, 7));
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

	// append the bandage Enchance to the perk tree for specific row
	// _row is the level of the perk that can be unlocked in the UI perk tree character
	// if _row not specified then defaul 1
	function appendBandagesEnhancedPerks( _perkTree, _row = 1 )
	{
		local perks = this.clonePerkTree(_perkTree);
		_row = _row - 1;
		while (perks.len() <= _row)
		{
			perks.push([]);
		}

		foreach (perk in ::Const.Perks.BandagesEnhanced)
		{
			if (this.hasPerkInTree(perks, perk.ID)) continue;

			local p = clone perk;
			if ("verifyPrerequisites" in p) delete p.verifyPrerequisites;
			p.Row <- _row;
			p.Unlocks <- _row;
			perks[_row].push(p);
		}
		this.debugLog("Appending perk success")
		return perks;
	}

	function getCombatHealPercent( _actor )
	{
		return this.hasBandagesEnhancedPerk(_actor)
			? this.setting("PerkHealPercentMaxHP")
			: this.setting("BaseHealPercentMaxHP");
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

		foreach (woundID in this.BandageTreatableWoundIDs)
		{
			local skill = _target.getSkills().getSkillByID(woundID);
			if (skill != null && skill.isFresh()) return true;
		}

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

		foreach (woundID in this.BandageTreatableWoundIDs)
		{
			local skill = _target.getSkills().getSkillByID(woundID);
			if (skill != null && skill.isFresh()) _target.getSkills().remove(skill);
		}
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

	function getTargetMaxHealingDays( _currentMax )
	{
		local threshold = this.setting("LightInjuryThresholdDays");
		return _currentMax <= threshold
			? this.setting("LightInjuryMaxDays")
			: this.setting("HeavyInjuryMaxDays");
	}

	function isTreatableInjury( _actor, _injury )
	{
		if (_injury.isType(::Const.SkillType.PermanentInjury)) return false;
		if (this.shouldSkipPoVMutationSickness(_actor, _injury)) return false;

		local currentMax = this.getCurrentMaxHealingDays(_injury);
		return currentMax > this.getTargetMaxHealingDays(currentMax);
	}

	function compressTemporaryInjuries( _actor )
	{
		if (_actor == null || !this.hasBandagesEnhancedPerk(_actor)) return 0;

		local maxInjuries = this.setting("InjuriesPerBandageUse");
		local changed = 0;
		if (maxInjuries < 1) maxInjuries = 1;
		local preferHeaviestFirst = this.setting("PreferHeaviestInjuryFirst");

		local candidates = [];
		local injuries = _actor.getSkills().query(::Const.SkillType.TemporaryInjury);

		foreach (injury in injuries)
		{
			if (!this.isTreatableInjury(_actor, injury)) continue;

			candidates.push({
				Injury = injury,
				CurrentMax = this.getCurrentMaxHealingDays(injury)
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
			local targetMax = this.getTargetMaxHealingDays(candidate.CurrentMax);

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
			HasPerk = hasPerk,
			HasTemporaryInjury = hasTemporaryInjury,
			HasPermanentInjury = hasPermanentInjury,
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

		foreach (injury in allInjuries)
		{
			if (!this.isTreatableInjury(_actor, injury)) continue;

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

		if (this.setting("TreatPoVMutationSickness"))
		{
			return false;
		}

		this.debugLog("[PoV] skipped Mutation Sickness for " + (_actor == null ? "<null>" : _actor.getName()));
		return true;
	}

	function getRosterTreatmentRows()
	{
		local rows = [];

		if (!this.hasPlayerRoster())
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
				HasPerk = ("HasPerk" in result) ? result.HasPerk : this.hasBandagesEnhancedPerk(actor),
				HasTemporaryInjury = ("HasTemporaryInjury" in result) ? result.HasTemporaryInjury : actor.getSkills().hasSkillOfType(::Const.SkillType.TemporaryInjury),
				HasPermanentInjury = ("HasPermanentInjury" in result) ? result.HasPermanentInjury : actor.getSkills().hasSkillOfType(::Const.SkillType.PermanentInjury),
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
		if (!this.hasWorldAssets())
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
		if (!this.hasWorldAssets())
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

		if (!this.hasPlayerRoster())
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

		local applied = this.applyRosterBandage(actor, useResult);
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

	function applyRosterBandage( _actor, _useResult = null )
	{
		if (_useResult == null)
		{
			_useResult = this.getRosterBandageUseResult(_actor);
		}

		if (!_useResult.CanUse)
		{
			this.debugLog("roster bandage rejected for " + (_actor == null ? "<null>" : _actor.getName()));
			return false;
		}

		return this.compressTemporaryInjuries(_actor).Changed > 0;
	}
};