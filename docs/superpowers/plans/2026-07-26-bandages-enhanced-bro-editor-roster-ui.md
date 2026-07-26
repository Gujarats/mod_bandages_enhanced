# Bandages Enhanced Bro Editor Roster UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Change the `Shift+C` Bandages Enhanced treatment screen roster from text-only rows into Bro Editor-style character rows with portrait, background icon, name, HP, and treatment status.

**Architecture:** Keep the existing Bandages Enhanced screen, keybind, backend treatment flow, and apply behavior. Extend the row data produced by `::BandagesEnhanced.Helpers.getRosterTreatmentRows()` with the same visual fields used by `mod_bro_editor`, then render those fields in `ui/mods/bandages_enhanced_screen.js` using vanilla `ui-control list-entry` structure and scoped CSS.

**Tech Stack:** Battle Brothers Squirrel scripts, Battle Brothers Coherent UI JavaScript/CSS, vanilla `Path.PROCEDURAL`, vanilla `Path.GFX`, vanilla `createImage`, vanilla list-entry skin assets, `modbb`, PowerShell layout validator.

## Global Constraints

- Do not modify `data_001`.
- Do not modify community mods, including `mod_bro_editor`; use it only as a reference.
- Keep the current `Shift+C` world-map treatment screen behavior.
- Keep the current apply logic: only eligible actors with `perk.bandages_enhanced`, temporary injuries, and available stash bandages can be treated.
- Keep debug logging configurable through existing Bandages Enhanced settings.
- Build verification must use `modbb`; do not manually build the zip.
- If runtime behavior is assumed instead of proven, document it in `README.md`.

---

## Reference Pattern

Use `mod_bro_editor` as the visual reference:

- Squirrel data source: `mod_bro_editor/scripts/ui/screens/world/world_breditor_screen.nut`
- JS row builder: `mod_bro_editor/ui/mods/world_breditor_screen.js`, `WorldBreditorScreen.prototype.addListEntry`
- CSS layout: `mod_bro_editor/ui/mods/world_breditor_screen.css`
- Shared vanilla list skin: `data_001/ui/controls/list.css`

Important reference details:

- Bro portrait uses `Path.PROCEDURAL + ImagePath`.
- Portrait is centered with `centerImageWithinParent(imageOffsetX, imageOffsetY, 0.64)`.
- Background icon uses `Path.GFX + BackgroundImagePath`.
- Character name uses `title-font-normal font-bold font-color-brother-name`.
- Row skin comes from vanilla `.ui-control.list .list-entry`, especially `ui/skin/list_item_01.png`.

---

### Task 1: Extend Roster Row Visual Data

**Files:**
- Modify: `mod_bandages_enhanced/scripts/config/z_bandages_enhanced.nut`
- Modify: `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Consumes: existing `::BandagesEnhanced.Helpers.getRosterTreatmentRows()`
- Produces: each row object contains `ImagePath`, `ImageOffsetX`, `ImageOffsetY`, and `BackgroundImagePath`

- [ ] **Step 1: Add validator expectations before implementation**

In `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`, extend the `Require-Token 'scripts/config/z_bandages_enhanced.nut'` block to require these tokens:

```powershell
'ImagePath = actor.getImagePath()',
'ImageOffsetX = actor.getImageOffsetX()',
'ImageOffsetY = actor.getImageOffsetY()',
'BackgroundImagePath = actor.getBackground().getIconColored()'
```

- [ ] **Step 2: Run validator and confirm it fails**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\mod_bandages_enhanced\tools\test_bandages_enhanced_layout.ps1
```

Expected: fail with a missing token for `ImagePath = actor.getImagePath()`.

- [ ] **Step 3: Add Bro Editor-compatible fields to roster rows**

In `getRosterTreatmentRows()`, update the `rows.push({ ... })` object:

```squirrel
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
	CanUse = result.CanUse,
	Reason = result.Reason,
	Message = result.Message
});
```

- [ ] **Step 4: Run validator and confirm it passes this task**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\mod_bandages_enhanced\tools\test_bandages_enhanced_layout.ps1
```

Expected: no missing visual-data token errors. Later UI tokens may still fail after Task 2 validator changes.

---

### Task 2: Replace Text-Only Rows With Bro Editor-Style Rows

**Files:**
- Modify: `mod_bandages_enhanced/ui/mods/bandages_enhanced_screen.js`
- Modify: `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Consumes: row fields `ID`, `Name`, `ImagePath`, `ImageOffsetX`, `ImageOffsetY`, `BackgroundImagePath`, `Hitpoints`, `HitpointsMax`, `CanUse`, `Message`
- Produces: clickable `.bandages-enhanced-row .ui-control.list-entry` rows that still set `mSelectedActorID`, status text, and apply-button enabled state

- [ ] **Step 1: Add validator expectations for Bro Editor-style rendering**

In `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`, extend the `Require-Token 'ui/mods/bandages_enhanced_screen.js'` block to require these tokens:

```powershell
'var result = $(''<div class="bandages-enhanced-row l-row"/>'');',
'var entry = $(''<div class="ui-control list-entry"/>'');',
'Path.PROCEDURAL + rowData.ImagePath',
'centerImageWithinParent(imageOffsetX, imageOffsetY, 0.64',
'Path.GFX + rowData.BackgroundImagePath',
'title-font-normal font-bold font-color-brother-name',
'bandages-enhanced-row-bottom'
```

- [ ] **Step 2: Run validator and confirm it fails**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\mod_bandages_enhanced\tools\test_bandages_enhanced_layout.ps1
```

Expected: fail with missing JS Bro Editor-style row tokens.

- [ ] **Step 3: Update row construction in `loadFromData()`**

Replace the current row creation block inside the `for` loop with this structure:

```javascript
var result = $('<div class="bandages-enhanced-row l-row"/>');
var entry = $('<div class="ui-control list-entry"/>');
result.append(entry);

entry.data('actorID', rowData.ID);
entry.data('canUse', rowData.CanUse === true);
entry.data('message', rowData.Message);

var leftColumn = $('<div class="column is-left"/>');
entry.append(leftColumn);

var imageOffsetX = ('ImageOffsetX' in rowData ? rowData.ImageOffsetX : 0);
var imageOffsetY = ('ImageOffsetY' in rowData ? rowData.ImageOffsetY : 0);
leftColumn.createImage(Path.PROCEDURAL + rowData.ImagePath, function (_image)
{
	_image.centerImageWithinParent(imageOffsetX, imageOffsetY, 0.64);
	_image.removeClass('opacity-none');
}, null, 'opacity-none');

var rightColumn = $('<div class="column is-right"/>');
entry.append(rightColumn);

var topRow = $('<div class="row is-top"/>');
rightColumn.append(topRow);

var backgroundIcon = $('<img/>');
backgroundIcon.attr('src', Path.GFX + rowData.BackgroundImagePath);
topRow.append(backgroundIcon);

var name = $('<div class="name title-font-normal font-bold font-color-brother-name"/>');
name.text(rowData.Name);
topRow.append(name);

var bottomRow = $('<div class="row is-bottom bandages-enhanced-row-bottom"/>');
rightColumn.append(bottomRow);

bottomRow.append($('<div class="hp text-font-normal font-color-description"/>').text(rowData.Hitpoints + '/' + rowData.HitpointsMax + ' HP'));
bottomRow.append($('<div class="status text-font-normal"/>').text(rowData.Message));
```

Then keep the existing eligibility classes, click handler behavior, and append call, but apply them to the new elements:

```javascript
if (rowData.CanUse === true)
{
	result.addClass('is-eligible');
	entry.addClass('is-eligible');
}
else
{
	result.addClass('is-disabled');
	entry.addClass('is-disabled');
}

entry.on('click', function()
{
	self.mRows.find('.bandages-enhanced-row .list-entry').removeClass('is-selected');
	$(this).addClass('is-selected');
	self.mSelectedActorID = $(this).data('actorID');
	self.mStatus.text($(this).data('message'));
	self.mApplyButton.enableButton($(this).data('canUse') === true && bandageCount > 0);
});

this.mRows.append(result);
```

- [ ] **Step 4: Preserve apply flow after refresh**

In `notifyBackendApplyBandage`, keep existing behavior:

```javascript
if (_result && _result.Data)
{
	self.loadFromData(_result.Data);
	self.mStatus.text(_result.Message);
}
```

Do not preserve row selection after successful apply in this task. Reloading and clearing the selection is current behavior and prevents accidental double-use after stash count changes.

- [ ] **Step 5: Run validator and confirm JS tokens pass**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\mod_bandages_enhanced\tools\test_bandages_enhanced_layout.ps1
```

Expected: no missing JS Bro Editor row tokens. CSS tokens may still fail after Task 3 validator changes.

---

### Task 3: Scope CSS To Match Bro Editor Row Layout

**Files:**
- Modify: `mod_bandages_enhanced/ui/mods/bandages_enhanced_screen.css`
- Modify: `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`

**Interfaces:**
- Consumes: HTML structure from Task 2
- Produces: rows visually similar to Bro Editor while staying scoped to `.bandages-enhanced-screen`

- [ ] **Step 1: Add validator expectations for CSS layout**

In `mod_bandages_enhanced/tools/test_bandages_enhanced_layout.ps1`, extend the `Require-Token 'ui/mods/bandages_enhanced_screen.css'` block to require:

```powershell
'.bandages-enhanced-row.l-row',
'.bandages-enhanced-row .column.is-left',
'.bandages-enhanced-row .column.is-right',
'.bandages-enhanced-row .row.is-top > img',
'.bandages-enhanced-row .row.is-top .name',
'.bandages-enhanced-row-bottom .hp',
'.bandages-enhanced-row-bottom .status'
```

- [ ] **Step 2: Run validator and confirm it fails**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\mod_bandages_enhanced\tools\test_bandages_enhanced_layout.ps1
```

Expected: fail with missing CSS tokens.

- [ ] **Step 3: Replace old text-row CSS with Bro Editor-style scoped layout**

Remove the old simple row layout rules for:

```css
.bandages-enhanced-row
.bandages-enhanced-row:hover,
.bandages-enhanced-row.is-selected
.bandages-enhanced-row .name
.bandages-enhanced-row .hp
.bandages-enhanced-row .status
```

Add scoped layout:

```css
.bandages-enhanced-roster
{
	width: 100%;
	height: 39.0rem;
	overflow-y: auto;
}

.bandages-enhanced-row.l-row
{
	width: 46.5rem;
	height: 10.7rem;
	position: relative;
	margin-left: auto;
	margin-right: auto;
	margin-bottom: -0.1rem;
	overflow: hidden;
}

.bandages-enhanced-row .column
{
	height: 100%;
	position: absolute;
}

.bandages-enhanced-row .column.is-left
{
	top: 0;
	left: 0;
	width: 9.0rem;
	z-index: 2;
}

.bandages-enhanced-row .column.is-left > img
{
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	position: absolute;
	margin: auto;
	display: block;
}

.bandages-enhanced-row .column.is-right
{
	top: 0;
	left: 9.0rem;
	right: 0;
	z-index: 1;
}

.bandages-enhanced-row .row
{
	left: 0;
	right: 1.0rem;
	position: absolute;
}

.bandages-enhanced-row .row.is-top
{
	top: 1.0rem;
	height: 3.8rem;
}

.bandages-enhanced-row .row.is-top > img
{
	left: 0;
	bottom: 0.2rem;
	width: 2.6rem;
	height: 2.6rem;
	position: absolute;
	display: block;
}

.bandages-enhanced-row .row.is-top .name
{
	left: 3.4rem;
	right: 0;
	bottom: 0.2rem;
	height: 2.6rem;
	position: absolute;
	overflow: hidden;
	line-height: 3.0rem;
	text-overflow: ellipsis;
	white-space: nowrap;
}

.bandages-enhanced-row .row.is-bottom
{
	top: 5.0rem;
	height: 3.8rem;
}

.bandages-enhanced-row-bottom .hp
{
	left: 3.4rem;
	top: 0;
	width: 9.0rem;
	position: absolute;
	line-height: 2.0rem;
}

.bandages-enhanced-row-bottom .status
{
	left: 13.0rem;
	right: 0;
	top: 0;
	position: absolute;
	line-height: 2.0rem;
	overflow: hidden;
	white-space: nowrap;
	text-overflow: ellipsis;
}
```

Keep the existing status color rules, adjusted for the new element structure:

```css
.bandages-enhanced-row.is-eligible .status
{
	color: #6fbf6f;
}

.bandages-enhanced-row.is-disabled .status
{
	color: #b56a58;
}
```

- [ ] **Step 4: Confirm list-entry skin is inherited**

Do not add custom `background-image` for rows. The row background should come from vanilla:

```css
.ui-control.list .list-entry
```

The custom JS uses `class="ui-control list-entry"` so vanilla `list_item_01.png`, hovered, selected, and inactive skins apply.

- [ ] **Step 5: Run validator and confirm CSS tokens pass**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\mod_bandages_enhanced\tools\test_bandages_enhanced_layout.ps1
```

Expected: `Bandages Enhanced layout validation passed.`

---

### Task 4: Runtime Verification And Build

**Files:**
- Read: `C:\Users\gujar\Documents\Battle Brothers\log.html`
- No source modifications expected unless validation reveals a concrete issue.

**Interfaces:**
- Consumes: completed Tasks 1-3
- Produces: verified `modbb` build and log review notes

- [ ] **Step 1: Run layout validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\mod_bandages_enhanced\tools\test_bandages_enhanced_layout.ps1
```

Expected:

```text
Bandages Enhanced layout validation passed.
```

- [ ] **Step 2: Run mod build verification**

Run from `mod_bandages_enhanced`:

```powershell
modbb --game-data-dir dist\verify_game_data
```

Expected: build completes without script packaging errors.

- [ ] **Step 3: Manual in-game check**

In game:

1. Load a save with Bandages Enhanced enabled.
2. Press `Shift+C` on the world map.
3. Confirm the treatment screen opens.
4. Confirm each row shows a character portrait on the left.
5. Confirm each row shows the character background icon beside the name.
6. Confirm names use the gold Battle Brothers brother-name styling.
7. Select an eligible character and confirm `Apply Bandage` enables.
8. Apply a bandage and confirm the screen refreshes and stash count changes.

- [ ] **Step 4: Check runtime logs**

Read:

```powershell
C:\Users\gujar\Documents\Battle Brothers\log.html
```

Filter for:

```text
BandagesEnhanced
BandagesEnhancedScreen
Script Error
Failed to load
Exception
the index
UI
```

Expected:

- No `Script Error`.
- No `Failed to load`.
- Existing Bandages Enhanced treatment logs still appear.
- Any image-path issue must be visible as a UI/runtime error before claiming completion.

---

## Self-Review

- Spec coverage: The plan covers Bro Editor-compatible data fields, JS row rendering, scoped CSS layout, validation, build, and runtime log review.
- Placeholder scan: No placeholder tasks remain.
- Type consistency: Squirrel fields use `ImagePath`, `ImageOffsetX`, `ImageOffsetY`, `BackgroundImagePath`; JS consumes the same exact property names.
- Scope check: The plan does not change treatment rules, perk injection, keybind behavior, save data, or community mods.
