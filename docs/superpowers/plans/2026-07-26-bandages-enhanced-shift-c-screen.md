# Bandages Enhanced Shift+C Treatment Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a proven world-map shortcut flow where `Shift+C` opens a Bandages Enhanced treatment screen showing roster members, bandage count, eligibility reasons, and an Apply action.

**Architecture:** Use the custom screen pattern proven by `mod_spawn_item_main` and `mod_bro_editor`: register JS/CSS, create a Squirrel screen object during `world_state.onInitUI`, connect it with `UI.connect`, open it through an MSU world keybind, hide the world screen, and close through `MenuStack`. Treatment logic stays in `::BandagesEnhanced.Helpers`; the new screen only queries roster/stash state and invokes helper functions.

**Tech Stack:** Battle Brothers Squirrel, Modern Hooks, MSU keybinds/UI screen patterns, vanilla UI JS/CSS controls, `modbb`, PowerShell static validation.

## Global Constraints

- Do not modify `data_001`.
- Do not modify community mods; use `mod_spawn_item_main`, `mod_bro_editor`, and `mod_legends` only as references.
- Keep debug logs programmatic and controlled by the existing Debug Logging setting.
- Default debug logging remains enabled for the first version.
- Use `modbb` for build verification; do not manually build the zip.
- Runtime assumptions must be documented in `README.md`.
- Do not change save IDs for this feature.
- Keybind should be registered with MSU so the user can rebind it if `Shift+C` conflicts.
- The treatment screen is world-map only; combat bandage behavior remains unchanged.

---

## File Structure

- Modify: `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`
  - Register the new screen JS/CSS.
  - Hook `states/world_state` for screen lifecycle.
  - Register the MSU `Shift+C` keybind.
  - Keep existing combat bandage hooks intact.

- Modify: `scripts/config/z_bandages_enhanced.nut`
  - Add roster query helpers used by the screen.
  - Add stash bandage counting and consuming helpers.
  - Reuse existing `getRosterBandageUseResult(_actor)` and `applyRosterBandage(_actor)`.

- Create: `scripts/ui/screens/world/bandages_enhanced_screen.nut`
  - Squirrel UI screen backend.
  - Owns `JSHandle`, visible/animating state, `show`, `hide`, close callback, roster data query, and apply callback.

- Create: `ui/mods/bandages_enhanced_screen.js`
  - Custom world-map screen frontend.
  - Shows bandage count, roster rows, selected brother detail, Apply, Refresh, and Close buttons.
  - Calls backend through `SQ.call`.

- Create: `ui/mods/bandages_enhanced_screen.css`
  - Screen layout and readable status styling.

- Modify: `ui/mods/bandages_enhanced.js`
  - Keep perk tree compatibility hook.
  - Remove or leave unused character-screen popup bridge only after runtime validation; first implementation can leave it in place as a fallback.

- Modify: `README.md`
  - Document `Shift+C`, world-map-only behavior, and keybind rebindability through MSU.
  - Document that the screen uses a custom UI pattern based on proven mod references.

- Modify: `tools/test_bandages_enhanced_layout.ps1`
  - Require all new screen files.
  - Require key tokens for UI lifecycle, keybind registration, backend callbacks, JS registration, and debug logs.

---

### Task 1: Static Contract for New Screen Files

**Files:**
- Modify: `tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Consumes: none.
- Produces: validator expectations for files and tokens created in later tasks.

- [ ] **Step 1: Add required files to validator**

Add these `Require-File` entries:

```powershell
Require-File 'scripts/ui/screens/world/bandages_enhanced_screen.nut'
Require-File 'ui/mods/bandages_enhanced_screen.js'
Require-File 'ui/mods/bandages_enhanced_screen.css'
```

- [ ] **Step 2: Add loader token checks**

Extend the loader `Require-Token` list with:

```powershell
'::Hooks.registerJS("ui/mods/bandages_enhanced_screen.js");',
'::Hooks.registerCSS("ui/mods/bandages_enhanced_screen.css");',
'::BandagesEnhanced.registerKeybinds();',
'this.m.BandagesEnhancedScreen <- this.new("scripts/ui/screens/world/bandages_enhanced_screen");',
'this.m.BandagesEnhancedScreen.destroy();',
'::BandagesEnhanced.Helpers.debugLog("opening treatment screen from keybind");'
```

- [ ] **Step 3: Add config helper token checks**

Extend the `scripts/config/z_bandages_enhanced.nut` token list with:

```powershell
'function getRosterTreatmentRows()',
'function countBandagesInStash()',
'function consumeBandageFromStash()',
'function applyRosterBandageByActorID( _actorID )'
```

- [ ] **Step 4: Add Squirrel screen token checks**

Add a new `Require-Token 'scripts/ui/screens/world/bandages_enhanced_screen.nut' @(...)` block:

```powershell
Require-Token 'scripts/ui/screens/world/bandages_enhanced_screen.nut' @(
    'this.bandages_enhanced_screen <- {',
    'JSHandle = null',
    'function create()',
    'this.m.JSHandle = this.UI.connect("BandagesEnhancedScreen", this);',
    'function show()',
    'this.m.JSHandle.asyncCall("show", this.queryData());',
    'function hide()',
    'function queryData()',
    'function onApplyBandage( _data )',
    '::BandagesEnhanced.Helpers.applyRosterBandageByActorID(actorID)',
    'function onCloseButtonPressed()'
)
```

- [ ] **Step 5: Add JS screen token checks**

Add a new `Require-Token 'ui/mods/bandages_enhanced_screen.js' @(...)` block:

```powershell
Require-Token 'ui/mods/bandages_enhanced_screen.js' @(
    'var BandagesEnhancedTreatmentScreen = function()',
    'BandagesEnhancedTreatmentScreen.prototype.onConnection = function (_handle)',
    'BandagesEnhancedTreatmentScreen.prototype.show = function (_data)',
    'BandagesEnhancedTreatmentScreen.prototype.hide = function ()',
    'BandagesEnhancedTreatmentScreen.prototype.loadFromData = function (_data)',
    'BandagesEnhancedTreatmentScreen.prototype.notifyBackendApplyBandage = function (_actorID)',
    'SQ.call(this.mSQHandle, ''onApplyBandage'', _actorID',
    'SQ.call(this.mSQHandle, ''onCloseButtonPressed'')',
    'registerScreen("BandagesEnhancedScreen", new BandagesEnhancedTreatmentScreen());'
)
```

- [ ] **Step 6: Run validator and confirm it fails**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fails on missing `scripts/ui/screens/world/bandages_enhanced_screen.nut`.

---

### Task 2: Backend Query and Apply Helpers

**Files:**
- Modify: `scripts/config/z_bandages_enhanced.nut`

**Interfaces:**
- Consumes: existing `debugLog(_message)`, `getRosterBandageUseResult(_actor)`, `applyRosterBandage(_actor)`.
- Produces:
  - `countBandagesInStash() -> integer`
  - `consumeBandageFromStash() -> bool`
  - `getRosterTreatmentRows() -> array<table>`
  - `applyRosterBandageByActorID(_actorID: integer) -> table`

- [ ] **Step 1: Add bandage stash counter**

Inside `::BandagesEnhanced.Helpers <- { ... }`, add:

```nut
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
```

- [ ] **Step 2: Add bandage consumer**

Add:

```nut
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
```

- [ ] **Step 3: Add roster row query**

Add:

```nut
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
        rows.push({
            ID = actor.getID(),
            Name = actor.getName(),
            Level = actor.getLevel(),
            Hitpoints = actor.getHitpoints(),
            HitpointsMax = actor.getHitpointsMax(),
            HasPerk = this.hasBandagesEnhancedPerk(actor),
            HasTemporaryInjury = actor.getSkills().hasSkillOfType(::Const.SkillType.TemporaryInjury),
            HasPermanentInjury = actor.getSkills().hasSkillOfType(::Const.SkillType.PermanentInjury),
            CanUse = result.CanUse,
            Reason = result.Reason,
            Message = result.Message
        });
    }

    this.debugLog("roster treatment query rows=" + rows.len());
    return rows;
}
```

- [ ] **Step 4: Add actor lookup and apply wrapper**

Add:

```nut
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
```

- [ ] **Step 5: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: still fails because screen files do not exist yet, but config helper tokens pass.

---

### Task 3: Squirrel UI Screen Backend

**Files:**
- Create: `scripts/ui/screens/world/bandages_enhanced_screen.nut`

**Interfaces:**
- Consumes:
  - `::BandagesEnhanced.Helpers.getRosterTreatmentRows() -> array<table>`
  - `::BandagesEnhanced.Helpers.countBandagesInStash() -> integer`
  - `::BandagesEnhanced.Helpers.applyRosterBandageByActorID(_actorID) -> table`
- Produces:
  - `bandages_enhanced_screen.create()`
  - `bandages_enhanced_screen.destroy()`
  - `bandages_enhanced_screen.show()`
  - `bandages_enhanced_screen.hide(_withSlideAnimation = false)`
  - `bandages_enhanced_screen.queryData() -> table`
  - `bandages_enhanced_screen.onApplyBandage(_data) -> table`

- [ ] **Step 1: Create screen object**

Create the file with:

```nut
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
    },

    function isAnimating()
    {
        return this.m.Animating != null && this.m.Animating == true;
    },

    function setOnClosePressedListener( _listener )
    {
        this.m.OnClosePressedListener = _listener;
    },

    function create()
    {
        this.m.Visible = false;
        this.m.Animating = false;
        this.m.JSHandle = this.UI.connect("BandagesEnhancedScreen", this);
        ::BandagesEnhanced.Helpers.debugLog("treatment screen created");
    },

    function destroy()
    {
        this.m.OnClosePressedListener = null;
        this.m.JSHandle = this.UI.disconnect(this.m.JSHandle);
        ::BandagesEnhanced.Helpers.debugLog("treatment screen destroyed");
    },

    function show()
    {
        if (this.m.JSHandle != null)
        {
            this.Tooltip.hide();
            ::BandagesEnhanced.Helpers.debugLog("treatment screen show");
            this.m.JSHandle.asyncCall("show", this.queryData());
        }
    },

    function hide( _withSlideAnimation = false )
    {
        if (this.m.JSHandle != null)
        {
            this.Tooltip.hide();
            ::BandagesEnhanced.Helpers.debugLog("treatment screen hide");
            this.m.JSHandle.asyncCall("hide", _withSlideAnimation);
        }
    },

    function queryData()
    {
        return {
            BandageCount = ::BandagesEnhanced.Helpers.countBandagesInStash(),
            Rows = ::BandagesEnhanced.Helpers.getRosterTreatmentRows()
        };
    },

    function onApplyBandage( _data )
    {
        local actorID = typeof _data == "array" ? _data[0] : _data;
        ::BandagesEnhanced.Helpers.debugLog("treatment screen apply requested actorID=" + actorID);

        local result = ::BandagesEnhanced.Helpers.applyRosterBandageByActorID(actorID);
        result.Data <- this.queryData();
        return result;
    },

    function onCloseButtonPressed()
    {
        ::BandagesEnhanced.Helpers.debugLog("treatment screen close requested");
        if (this.m.OnClosePressedListener != null)
        {
            this.m.OnClosePressedListener();
        }
    },

    function onScreenConnected()
    {
    },

    function onScreenDisconnected()
    {
    },

    function onScreenShown()
    {
        this.m.Visible = true;
        this.m.Animating = false;
        ::BandagesEnhanced.Helpers.debugLog("treatment screen shown");
    },

    function onScreenHidden()
    {
        this.m.Visible = false;
        this.m.Animating = false;
        ::BandagesEnhanced.Helpers.debugLog("treatment screen hidden");
    },

    function onScreenAnimating()
    {
        this.m.Animating = true;
    }
};
```

- [ ] **Step 2: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fails because JS/CSS files and loader wiring are still missing.

---

### Task 4: World State Lifecycle and MSU Keybind

**Files:**
- Modify: `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`

**Interfaces:**
- Consumes: `scripts/ui/screens/world/bandages_enhanced_screen.nut`.
- Produces:
  - `::BandagesEnhanced.registerKeybinds()`
  - `::BandagesEnhanced.openTreatmentScreen()`
  - `World.State.m.BandagesEnhancedScreen`

- [ ] **Step 1: Register new JS/CSS assets**

Near existing `::Hooks.registerJS("ui/mods/bandages_enhanced.js");`, add:

```nut
::Hooks.registerJS("ui/mods/bandages_enhanced_screen.js");
::Hooks.registerCSS("ui/mods/bandages_enhanced_screen.css");
```

- [ ] **Step 2: Add open screen helper before the hook queue**

After mod metadata registration and before `HookMod.queue`, add:

```nut
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
```

- [ ] **Step 3: Add keybind registration**

After `openTreatmentScreen`, add:

```nut
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
```

- [ ] **Step 4: Call keybind registration inside the MSU queue**

After `::BandagesEnhanced.configureDebugLogging();`, add:

```nut
::BandagesEnhanced.registerKeybinds();
```

- [ ] **Step 5: Hook world state UI lifecycle**

Inside the queue, add:

```nut
mod.hook("scripts/states/world_state", function(q)
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
});
```

- [ ] **Step 6: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fails only because JS/CSS screen files are missing.

---

### Task 5: JS Treatment Screen

**Files:**
- Create: `ui/mods/bandages_enhanced_screen.js`

**Interfaces:**
- Consumes backend methods:
  - `onApplyBandage(actorID: integer) -> table { Success, Reason, Message, Data }`
  - `onCloseButtonPressed()`
- Produces frontend methods:
  - `BandagesEnhancedTreatmentScreen.prototype.show(_data)`
  - `BandagesEnhancedTreatmentScreen.prototype.hide()`
  - `BandagesEnhancedTreatmentScreen.prototype.loadFromData(_data)`

- [ ] **Step 1: Create JS screen object**

Create:

```js
"use strict";

var BandagesEnhancedTreatmentScreen = function()
{
    this.mSQHandle = null;
    this.mContainer = null;
    this.mDialog = null;
    this.mRows = null;
    this.mSelectedActorID = null;
    this.mStatus = null;
    this.mBandageCount = null;
    this.mApplyButton = null;
};

BandagesEnhancedTreatmentScreen.prototype.isConnected = function()
{
    return this.mSQHandle !== null;
};

BandagesEnhancedTreatmentScreen.prototype.onConnection = function(_handle)
{
    this.mSQHandle = _handle;
    this.register($('.root-screen'));
};

BandagesEnhancedTreatmentScreen.prototype.onDisconnection = function()
{
    this.mSQHandle = null;
    this.unregister();
};
```

- [ ] **Step 2: Add DOM creation**

Append:

```js
BandagesEnhancedTreatmentScreen.prototype.register = function(_parentDiv)
{
    if (this.mContainer !== null)
    {
        return;
    }

    this.mContainer = $('<div class="bandages-enhanced-screen display-none opacity-none"/>');
    _parentDiv.append(this.mContainer);

    this.mDialog = $('<div class="bandages-enhanced-dialog"/>');
    this.mContainer.append(this.mDialog);

    var header = $('<div class="bandages-enhanced-header"/>');
    this.mDialog.append(header);
    header.append($('<div class="title title-font-big font-bold font-color-title">Bandages Enhanced</div>'));
    this.mBandageCount = $('<div class="bandage-count text-font-normal font-color-label"/>');
    header.append(this.mBandageCount);

    this.mRows = $('<div class="bandages-enhanced-roster"/>');
    this.mDialog.append(this.mRows);

    this.mStatus = $('<div class="bandages-enhanced-status text-font-normal font-color-description"/>');
    this.mDialog.append(this.mStatus);

    var footer = $('<div class="bandages-enhanced-footer"/>');
    this.mDialog.append(footer);

    var self = this;
    this.mApplyButton = footer.createTextButton('Apply Bandage', function()
    {
        if (self.mSelectedActorID !== null)
        {
            self.notifyBackendApplyBandage(self.mSelectedActorID);
        }
    }, '', 1);

    footer.createTextButton('Close', function()
    {
        self.notifyBackendClose();
    }, '', 1);
};

BandagesEnhancedTreatmentScreen.prototype.unregister = function()
{
    if (this.mContainer === null)
    {
        return;
    }

    this.mContainer.empty();
    this.mContainer.remove();
    this.mContainer = null;
};
```

- [ ] **Step 3: Add row rendering**

Append:

```js
BandagesEnhancedTreatmentScreen.prototype.loadFromData = function(_data)
{
    var self = this;
    this.mSelectedActorID = null;
    this.mRows.empty();
    this.mBandageCount.text('Bandages in stash: ' + (_data.BandageCount || 0));
    this.mStatus.text('Select a character to treat.');

    if (!_data.Rows || _data.Rows.length === 0)
    {
        this.mStatus.text('No roster members are available.');
        this.mApplyButton.enableButton(false);
        return;
    }

    for (var i = 0; i < _data.Rows.length; i++)
    {
        var rowData = _data.Rows[i];
        var row = $('<div class="bandages-enhanced-row"/>');
        row.data('actorID', rowData.ID);
        row.data('canUse', rowData.CanUse === true);
        row.data('message', rowData.Message);

        row.append($('<div class="name text-font-normal font-bold font-color-label"/>').text(rowData.Name));
        row.append($('<div class="hp text-font-normal font-color-description"/>').text(rowData.Hitpoints + '/' + rowData.HitpointsMax + ' HP'));
        row.append($('<div class="status text-font-normal"/>').text(rowData.Message));

        if (rowData.CanUse === true)
        {
            row.addClass('is-eligible');
        }
        else
        {
            row.addClass('is-disabled');
        }

        row.on('click', function()
        {
            self.mRows.find('.bandages-enhanced-row').removeClass('is-selected');
            $(this).addClass('is-selected');
            self.mSelectedActorID = $(this).data('actorID');
            self.mStatus.text($(this).data('message'));
            self.mApplyButton.enableButton($(this).data('canUse') === true && (_data.BandageCount || 0) > 0);
        });

        this.mRows.append(row);
    }

    this.mApplyButton.enableButton(false);
};
```

- [ ] **Step 4: Add show/hide and backend calls**

Append:

```js
BandagesEnhancedTreatmentScreen.prototype.show = function(_data)
{
    var self = this;
    this.loadFromData(_data);
    this.mContainer.velocity("finish", true).velocity({ opacity: 1 },
    {
        duration: Constants.SCREEN_FADE_IN_OUT_DELAY,
        easing: 'swing',
        begin: function()
        {
            $(this).removeClass('display-none').addClass('display-block');
            self.notifyBackendOnAnimating();
        },
        complete: function()
        {
            self.notifyBackendOnShown();
        }
    });
};

BandagesEnhancedTreatmentScreen.prototype.hide = function()
{
    var self = this;
    this.mContainer.velocity("finish", true).velocity({ opacity: 0 },
    {
        duration: Constants.SCREEN_FADE_IN_OUT_DELAY,
        easing: 'swing',
        begin: function()
        {
            self.notifyBackendOnAnimating();
        },
        complete: function()
        {
            $(this).removeClass('display-block').addClass('display-none');
            self.notifyBackendOnHidden();
        }
    });
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendApplyBandage = function(_actorID)
{
    var self = this;
    SQ.call(this.mSQHandle, 'onApplyBandage', _actorID, function(_result)
    {
        if (_result && _result.Message)
        {
            self.mStatus.text(_result.Message);
        }

        if (_result && _result.Data)
        {
            self.loadFromData(_result.Data);
            self.mStatus.text(_result.Message);
        }
    });
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendClose = function()
{
    SQ.call(this.mSQHandle, 'onCloseButtonPressed');
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendOnShown = function()
{
    SQ.call(this.mSQHandle, 'onScreenShown');
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendOnHidden = function()
{
    SQ.call(this.mSQHandle, 'onScreenHidden');
};

BandagesEnhancedTreatmentScreen.prototype.notifyBackendOnAnimating = function()
{
    SQ.call(this.mSQHandle, 'onScreenAnimating');
};

registerScreen("BandagesEnhancedScreen", new BandagesEnhancedTreatmentScreen());
```

- [ ] **Step 5: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: fails because CSS file is missing.

---

### Task 6: CSS Treatment Screen Layout

**Files:**
- Create: `ui/mods/bandages_enhanced_screen.css`

**Interfaces:**
- Consumes DOM classes from Task 5.
- Produces visible modal-like custom screen.

- [ ] **Step 1: Add screen and dialog layout**

Create:

```css
.bandages-enhanced-screen
{
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.65);
    z-index: 10;
}

.bandages-enhanced-dialog
{
    position: absolute;
    left: 50%;
    top: 50%;
    width: 78.0rem;
    height: 58.0rem;
    margin-left: -39.0rem;
    margin-top: -29.0rem;
    padding: 2.0rem;
    background-image: url("coui://gfx/ui/skin/dialog_background_01.png");
    background-size: 100% 100%;
}

.bandages-enhanced-header
{
    width: 100%;
    height: 6.0rem;
}

.bandages-enhanced-header .title
{
    float: left;
    line-height: 4.0rem;
}

.bandages-enhanced-header .bandage-count
{
    float: right;
    line-height: 4.0rem;
}
```

- [ ] **Step 2: Add roster row styling**

Append:

```css
.bandages-enhanced-roster
{
    width: 100%;
    height: 39.0rem;
    overflow-y: auto;
}

.bandages-enhanced-row
{
    width: 100%;
    height: 4.6rem;
    margin-bottom: 0.4rem;
    padding: 0.6rem 0.8rem;
    background-color: rgba(20, 16, 12, 0.88);
    border: 1px solid rgba(90, 70, 45, 0.9);
}

.bandages-enhanced-row:hover,
.bandages-enhanced-row.is-selected
{
    background-color: rgba(54, 42, 24, 0.95);
    border-color: rgba(190, 150, 85, 1.0);
}

.bandages-enhanced-row .name
{
    float: left;
    width: 20.0rem;
    line-height: 3.0rem;
}

.bandages-enhanced-row .hp
{
    float: left;
    width: 10.0rem;
    line-height: 3.0rem;
}

.bandages-enhanced-row .status
{
    float: left;
    width: 41.0rem;
    line-height: 3.0rem;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
}

.bandages-enhanced-row.is-eligible .status
{
    color: #6fbf6f;
}

.bandages-enhanced-row.is-disabled .status
{
    color: #b56a58;
}
```

- [ ] **Step 3: Add footer/status styling**

Append:

```css
.bandages-enhanced-status
{
    width: 100%;
    height: 5.0rem;
    padding-top: 1.0rem;
    text-align: center;
    line-height: 2.0rem;
}

.bandages-enhanced-footer
{
    width: 100%;
    height: 5.0rem;
    text-align: center;
}

.bandages-enhanced-footer .l-button
{
    display: inline-block;
    margin-left: 0.6rem;
    margin-right: 0.6rem;
}
```

- [ ] **Step 4: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: passes if all token checks are aligned.

---

### Task 7: Runtime Behavior Cleanup

**Files:**
- Modify: `scripts/!mods_preload/mod_bandages_enhanced_loader.nut`
- Modify: `README.md`
- Optionally modify: `ui/mods/bandages_enhanced.js`
- Optionally modify: `ui/mods/bandages_enhanced.css`

**Interfaces:**
- Consumes: working `Shift+C` screen.
- Produces: stable UX that no longer depends on character-screen popup.

- [ ] **Step 1: Decide character-screen roster use behavior**

Keep combat bandage behavior unchanged. For outside-combat `bandage_item.onUse`, choose the conservative first implementation:

```nut
showRosterBandagePopup("Use Shift+C on the world map to open Bandages Enhanced treatment.");
return false;
```

This prevents accidental item consumption and directs the user to the proven screen flow.

- [ ] **Step 2: Keep popup fallback only if it does not break**

If runtime testing confirms the character-screen popup still only dims the screen, remove `CharacterScreen.prototype.showBandagesEnhancedPopup` from `ui/mods/bandages_enhanced.js` and remove `bandages-enhanced-popup` CSS from `ui/mods/bandages_enhanced.css`.

If runtime testing shows it works after the screen changes, leave it only as informational fallback and document that `Shift+C` is primary.

- [ ] **Step 3: Update README**

Add under Behavior:

```markdown
- Outside combat, press `Shift+C` on the world map to open the Bandages Enhanced treatment screen.
- The treatment screen shows all roster members, their eligibility, the reason treatment is unavailable, and the current stash bandage count.
- Right-clicking bandages outside combat does not consume a bandage; use the treatment screen to choose the target.
```

Add under Runtime assumptions:

```markdown
- The treatment screen uses the proven custom world-screen pattern used by Item Spawner and Bro Editor: a Squirrel UI screen, registered JS/CSS, `UI.connect`, and a world-map MSU keybind.
- The default keybind is `Shift+C` and can be rebound through MSU keybind settings if another mod conflicts.
```

- [ ] **Step 4: Update validator README tokens**

Extend `README.md` token checks:

```powershell
'press `Shift+C` on the world map',
'current stash bandage count',
'can be rebound through MSU keybind settings'
```

- [ ] **Step 5: Run validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected: passes.

---

### Task 8: Build and In-Game Verification

**Files:**
- No source edits unless verification finds a concrete issue.

**Interfaces:**
- Consumes: all earlier tasks.
- Produces: verified build and runtime log evidence.

- [ ] **Step 1: Run local validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test_bandages_enhanced_layout.ps1
```

Expected:

```text
Bandages Enhanced layout validation passed.
```

- [ ] **Step 2: Build with writable output**

Run:

```powershell
$out = Join-Path (Get-Location) 'dist\verify_game_data'
New-Item -ItemType Directory -Force -Path $out | Out-Null
modbb --game-data-dir $out
```

Expected:

```text
Building Battle Brothers Mod Bandages Enhanced 0.0.1
Deployed mod_bandages_enhanced.zip to E:\Battle Brother extract code\mod_bandages_enhanced\dist\verify_game_data
Game launch not requested; skipping.
```

- [ ] **Step 3: Runtime test in game**

Manual steps:

1. Install the built zip through the normal mod workflow.
2. Load a world-map save.
3. Press `Shift+C`.
4. Confirm the world screen hides and Bandages Enhanced screen appears.
5. Confirm roster rows appear.
6. Confirm bandage count matches stash bandage count.
7. Select an ineligible brother without the perk and confirm Apply is disabled or explains the reason.
8. Select an eligible brother with a temporary injury and the perk.
9. Click Apply.
10. Confirm one bandage is consumed and the treatment result appears in the screen.
11. Press Close or Escape/back and confirm world screen returns.

- [ ] **Step 4: Check runtime log**

Run:

```powershell
Select-String -Path 'C:\Users\gujar\Documents\Battle Brothers\log.html' -Pattern 'BandagesEnhanced|Script Error|Exception|Failed to load|UI' | Select-Object -Last 160
```

Expected log examples:

```text
[BandagesEnhanced] world state treatment screen initialized
[BandagesEnhanced] opening treatment screen from keybind
[BandagesEnhanced] treatment screen show
[BandagesEnhanced] roster treatment query rows=
[BandagesEnhanced] treatment screen apply requested actorID=
[BandagesEnhanced] screen apply success actor=
```

No expected `Script Error`, missing JS, missing CSS, or failed UI screen registration errors.

---

## Self-Review

- Spec coverage: This plan covers a `Shift+C` MSU keybind, proven custom world-screen architecture, roster display, bandage count, eligibility reasons, apply action, debug logging, README documentation, validator updates, and `modbb` build verification.
- Placeholder scan: No task uses `TBD`, `TODO`, “implement later”, or undefined future work as a requirement.
- Type consistency: Screen backend methods match JS calls: `show`, `hide`, `onApplyBandage`, `onCloseButtonPressed`, `onScreenShown`, `onScreenHidden`, and `onScreenAnimating`.
- Risk called out: The plan avoids relying on the character-screen popup. Outside-combat item right-click becomes an informational path, while `Shift+C` is the primary proven flow.
