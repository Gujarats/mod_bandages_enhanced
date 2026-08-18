if (!("BandagesEnhanced" in getroottable()))
{
	::BandagesEnhanced <- {};
}

::BandagesEnhanced.Universal <- {
	function registerHooks( _mod )
	{
		_mod.hook("scripts/states/world_state", function(q)
		{
			q.onInitUI = @(__original) function()
			{
				__original();
				this.m.BandagesEnhancedScreen <- this.new("scripts/ui/screens/world/bandages_enhanced_screen");
				this.m.BandagesEnhancedScreen.setOnClosePressedListener(function()
				{
					if (this.m.BandagesEnhancedScreen.isVisible())
					{
						this.m.MenuStack.pop();
					}
				}.bindenv(this));
				this.m.BandagesEnhancedScreen.create();
				::BandagesEnhanced.Helpers.debugLog("world state treatment screen initialized");
			}

			q.onDestroyUI = @(__original) function()
			{
				if ("BandagesEnhancedScreen" in this.m && this.m.BandagesEnhancedScreen != null)
				{
					this.m.BandagesEnhancedScreen.destroy();
					this.m.BandagesEnhancedScreen = null;
					::BandagesEnhanced.Helpers.debugLog("world state treatment screen destroyed");
				}

				__original();
			}

			q.onUpdate = @(__original) function()
			{
				__original();
				::BandagesEnhanced.Compatibility.Reforged.tryMigrateExistingPlayerTrees();
			}
		});

		_mod.hook("scripts/ui/global/data_helper", function(q)
		{
			q.convertEntityToUIData = @(__original) function( _entity, _activeEntity )
			{
				return __original(_entity, _activeEntity);
			}
		});

		_mod.hook("scripts/skills/actives/bandage_ally_skill", function(q)
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

		_mod.hook("scripts/items/accessory/bandage_item", function(q)
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
					text = "With Bandages Enhanced, using key-binding default Shift+C to speed up recovery"
				});
				return result;
			}

			q.onUse = @(__original) function( _actor, _item = null )
			{
				::BandagesEnhanced.Helpers.debugLog("bandage item roster use actor=" + (_actor == null ? "<null>" : _actor.getName()));

				if (this.Tactical.isActive())
				{
					::BandagesEnhanced.Helpers.debugLog("bandage item roster use ignored during tactical; use active skill");
					return false;
				}

				if (!::BandagesEnhanced.Helpers.applyRosterBandage(_actor))
				{
					::BandagesEnhanced.Helpers.debugLog("bandage item roster use rejected by helper");
					return false;
				}

				if (this.m.Item != null && !this.m.Item.isNull())
				{
					this.m.Item.removeSelf();
				}

				::BandagesEnhanced.Helpers.debugLog("bandage item roster use applied and item consumed");
				return true;
			}
		});
	}
};