::BandagesEnhanced <- {
	ID = "mod_bandages_enhanced",
	Name = "Bandages Enhanced",
	Version = "0.0.1"
};

::BandagesEnhanced.HookMod <- ::Hooks.register(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name);
::BandagesEnhanced.HookMod.require("mod_msu >= 1.9.0");

::BandagesEnhanced.HookMod.queue(">mod_msu", function()
{
	::BandagesEnhanced.Mod <- ::MSU.Class.Mod(::BandagesEnhanced.ID, ::BandagesEnhanced.Version, ::BandagesEnhanced.Name);
	::BandagesEnhanced.registerSettings();
	::include("scripts/!mods_preload/mod_bandages_enhanced_helpers");
	::BandagesEnhanced.configureDebugLogging();
	::BandagesEnhanced.Helpers.debugLog("settings initialized");

	local mod = ::BandagesEnhanced.HookMod;

	::Hooks.registerJS("ui/mods/bandages_enhanced.js");
	::Hooks.registerCSS("ui/mods/bandages_enhanced.css");

	mod.hook("scripts/ui/global/data_helper", function(q)
	{
		q.convertEntityToUIData = @(__original) function( _entity, _activeEntity )
		{
			local result = __original(_entity, _activeEntity);

			if (_entity != null)
			{
				local settings = ::BandagesEnhanced.Mod.ModSettings;
				local row = settings.getSetting("PerkLevel").getValue();
				local perks = ::Const.Perks.Perks.map(@(r) clone r);

				foreach (perk in ::Const.Perks.BandagesEnhanced)
				{
					local p = clone perk;
					delete p.verifyPrerequisites;
					perks[row - 1].push(p);
				}

				result.bandages_enhanced_perkTree <- perks;
				::BandagesEnhanced.Helpers.debugLog("injecting Bandages Enhanced perk tree for " + _entity.getName());
			}

			return result;
		}
	});

	mod.hook("scripts/skills/actives/bandage_ally_skill", function(q)
	{
		q.create = @(__original) function()
		{
			__original();
			this.m.Description = "Apply improved bandages to yourself or an ally. Removes bleeding and fresh bandage-treatable wounds, and restores hitpoints based on maximum hitpoints.";
			::BandagesEnhanced.Helpers.debugLog("bandage skill hook create");
		}

		q.getTooltip = @(__original) function()
		{
			local ret = __original();
			local actor = this.getContainer().getActor();
			local percent = ::BandagesEnhanced.Helpers.getCombatHealPercent(actor);

			ret.push({
				id = 20,
				type = "text",
				icon = "ui/icons/health.png",
				text = "Restores [color=" + this.Const.UI.Color.PositiveValue + "]" + percent + "%[/color] of max hitpoints, capped at maximum hitpoints"
			});
			ret.push({
				id = 21,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Can be used while engaged in melee"
			});

			return ret;
		}

		q.isUsable = @(__original) function()
		{
			if (!this.Tactical.isActive()) return false;
			local result = this.skill.isUsable();
			local actor = this.getContainer().getActor();
			::BandagesEnhanced.Helpers.debugLog("bandage skill isUsable actor=" + (actor == null ? "<null>" : actor.getName()) + " result=" + result);
			return result;
		}

		q.onVerifyTarget = @(__original) function( _originTile, _targetTile )
		{
			if (!this.skill.onVerifyTarget(_originTile, _targetTile)) return false;

			local target = _targetTile.getEntity();
			if (target == null)
			{
				::BandagesEnhanced.Helpers.debugLog("bandage skill verify target rejected: null target");
				return false;
			}

			if (!this.m.Container.getActor().isAlliedWith(target))
			{
				::BandagesEnhanced.Helpers.debugLog("bandage skill verify target rejected: target not allied");
				return false;
			}

			local result = ::BandagesEnhanced.Helpers.canUseBandageInCombatOn(target);
			::BandagesEnhanced.Helpers.debugLog("bandage skill verify target=" + target.getName() + " result=" + result);
			return result;
		}

		q.onUse = @(__original) function( _user, _targetTile )
		{
			local target = _targetTile.getEntity();
			::BandagesEnhanced.Helpers.debugLog("bandage skill use by " + (_user == null ? "<null>" : _user.getName()) + " on " + (target == null ? "<null>" : target.getName()));
			this.spawnIcon("perk_55", _targetTile);

			local didTreat = ::BandagesEnhanced.Helpers.applyCombatBandage(_user, target);
			if (!didTreat)
			{
				::BandagesEnhanced.Helpers.debugLog("bandage skill use rejected after helper");
				return false;
			}

			if (this.m.Item != null && !this.m.Item.isNull())
			{
				this.m.Item.removeSelf();
			}

			this.updateAchievement("FirstAid", 1, 1);
			::BandagesEnhanced.Helpers.debugLog("bandage skill use applied and item consumed");
			return true;
		}
	});

	mod.hook("scripts/items/accessory/bandage_item", function(q)
	{
		q.create = @(__original) function()
		{
			__original();
			this.m.Value = ::BandagesEnhanced.Mod.ModSettings.getSetting("BandageValue").getValue();
			this.m.IsUsable = true;
			this.m.ItemType = this.Const.Items.ItemType.Usable;
			this.m.Description = "Clean bandages that can be used in combat to stop bleeding and restore hitpoints. With Bandages Enhanced, they can also speed up temporary injury recovery outside combat.";
			::BandagesEnhanced.Helpers.debugLog("bandage item hook create value=" + this.m.Value);
		}

		q.getTooltip = @(__original) function()
		{
			local result = __original();
			result.push({
				id = 70,
				type = "text",
				icon = "ui/icons/health.png",
				text = "Restores hitpoints based on maximum hitpoints when used in battle"
			});
			result.push({
				id = 71,
				type = "text",
				icon = "ui/icons/days_wounded.png",
				text = "With Bandages Enhanced, Right-click or drag onto the currently selected character outside combat to speed up temporary injury recovery"
			});
			return result;
		}

		q.onUse = @(__original) function( _actor, _item = null )
		{
			::BandagesEnhanced.Helpers.debugLog("bandage item roster use actor=" + (_actor == null ? "<null>" : _actor.getName()));

			if (this.Tactical.isActive())
			{
				::BandagesEnhanced.Helpers.debugLog("bandage item roster use rejected: tactical active");
				return false;
			}

			if (!::BandagesEnhanced.Helpers.canUseBandageOnRoster(_actor))
			{
				::BandagesEnhanced.Helpers.debugLog("bandage item roster use rejected: actor cannot use roster bandage");
				::BandagesEnhanced.Helpers.debugLog("roster bandage rejected for " + (_actor == null ? "<null>" : _actor.getName()));
				return false;
			}

			local applied = ::BandagesEnhanced.Helpers.applyRosterBandage(_actor);
			::BandagesEnhanced.Helpers.debugLog("bandage item roster use applied=" + applied);
			return applied;
		}
	});
});
