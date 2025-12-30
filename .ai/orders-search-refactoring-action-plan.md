# Action Plan for Orders Search Refactoring

## Issue Description

The search functionality for manager orders currently exists within the `OrdersOverlay` widget, making it coupled with the import/export functionality. The goal is to:

1. **Separate the search functionality** into its own overlay widget (`OrdersSearchOverlay`)
2. **Make it independently controllable** via DFHack Control Panel (UI Overlays tab)
3. **Position it next to the existing overlay** so both can coexist
4. **Allow users to disable it separately** from import/export functionality

**Rationale:** The search feature is still in beta and needs testing. By separating it, users who experience issues can disable just the search while keeping import/export functionality.

## Quick Reference: Key Decisions

| Decision | Value |
|----------|-------|
| **Position** | To the right: `{x=97, y=-6}` |
| **Default Enabled** | `false` (opt-in for beta) |
| **Frame Size** | `{w=43, h=4}` |
| **Frame Style** | `gui.MEDIUM_FRAME` + `gui.CLEAR_PEN` |
| **Minimize Button** | Yes (click-only, no hotkey) |
| **Help Button** | No |
| **Hotkeys** | `CUSTOM_CTRL_F` (focus), `SELECT` (next match) |
| **Functional Coupling** | Complete independence from import/export |
| **Widget ID** | `search` in OVERLAY_WIDGETS table |

## Relevant Codebase Parts

### 1. **plugins/lua/orders.lua** (Primary Implementation File)

**Lines 11-180: Filter Helper Functions**
- `SEARCH_SYNONYMS` - Maps display names to internal names (e.g., "coffer" → "chest")
- `ITEMDEF_TYPES` - Lookup table for 14 item types with itemdefs
- `get_itemdef_name(order)` - Extracts item subtype name from order
- `get_material_category(mat)` - Determines material category (wood, metal, stone, etc.)
- `get_order_search_key(order)` - Generates searchable string from order data

**Why relevant:** These functions will be used by the new `OrdersSearchOverlay` and should remain at module level (shared between overlays).

**Lines 246-460: OrdersOverlay Class**
- Currently contains BOTH import/export AND search functionality
- Frame size: `{w=43, h=6}` (expanded for search widgets)
- Contains search UI: EditField, next match button, match counter
- Contains search state: `filter_text`, `matched_indices`, `current_match_idx`
- Contains search methods: `update_filter()`, `jump_to_next_match()`, `get_match_text()`, `has_matches()`

**Why relevant:** This is where we need to extract search functionality to create the new overlay.

**Lines 995-1003: OVERLAY_WIDGETS Table**
```lua
OVERLAY_WIDGETS = {
    recheck=RecheckOverlay,
    importexport=OrdersOverlay,
    skillrestrictions=SkillRestrictionOverlay,
    laborrestrictions=LaborRestrictionsOverlay,
    conditionsrightclick=ConditionsRightClickOverlay,
    conditionsquantityrightclick=ConditionsQuantityRightClickOverlay,
    quantityrightclick=QuantityRightClickOverlay,
}
```

**Why relevant:** New `OrdersSearchOverlay` must be registered here (e.g., `search=OrdersSearchOverlay`) to appear in DFHack Control Panel.

### 2. **Other Overlay Examples** (Reference)

**RecheckOverlay (lines 485-538)**
- Example of a separate, focused overlay on same screen
- Shows how to define `default_pos`, `viewscreens`, `frame`
- Demonstrates single-purpose overlay design pattern

**Why relevant:** Template for creating OrdersSearchOverlay structure.

### 3. **DFHack Overlay System** (Context)

The overlay system (`plugins/lua/overlay.lua`) allows:
- Multiple overlays on the same viewscreen
- Independent enable/disable via Control Panel
- Each overlay has its own position (default_pos)
- Overlays registered in OVERLAY_WIDGETS table appear in UI

**Why relevant:** Understanding this ensures proper implementation and user control.

## Git Commit History Analysis

### Recent Commits to plugins/lua/orders.lua

```
402162a72 (2025-11-28) pajawojciech - "Goblets, brew and meals"
64a4f839a (2025-11-28) pajawojciech - "coffer"
fac227d35 (2025-11-28) pajawojciech - "wood"
e7c521ec1 (2025-11-28) pajawojciech - "poc"
af8d055f1 (2025-01-11) Myk Taylor - "allow right click to cancel instead of exiting"
28f597000 (2024-12-25) Myk Taylor - "add prompt to orders export dialog"
```

### Key Findings

1. **Search implementation is brand new** - Added in last 4 commits by pajawojciech (user)
2. **Iterative development** - "poc" (proof of concept) → "wood" → "coffer" → "Goblets, brew and meals"
3. **Active improvements** - Search synonyms and material category matching added incrementally
4. **Myk Taylor maintains this plugin** - Primary contributor for orders.lua UI features
5. **Recent pattern: UI enhancements** - Right-click cancel, export prompts show focus on UX

### Pattern Analysis

The search feature was developed iteratively:
- Started with basic proof of concept
- Added material inference for generic items (wood)
- Added synonym support (coffer → chest)
- Added meal complexity and goblet/brew support

This iterative pattern suggests the feature is still evolving and needs user testing - supporting the decision to make it separately controllable.

## Root Cause Analysis

**This is NOT a bug - this is a refactoring task.**

### Current State

The `OrdersOverlay` class contains:
- **Import/export functionality** (stable, well-tested)
- **Sort/clear/recheck functionality** (stable, well-tested)
- **Search functionality** (new, needs beta testing)

All three are bundled into one overlay widget with `default_enabled=true`.

### Problem

Users cannot disable the search feature independently. If the search functionality has issues or performance problems, users must:
- Disable the entire `orders.importexport` overlay (losing import/export too)
- OR live with the buggy search feature

### Desired State

Two separate overlay widgets:
1. **`orders.importexport`** - Import, export, sort, clear, recheck (stable features)
2. **`orders.search`** - Search and filter functionality (beta feature)

Both independently controllable in DFHack Control Panel → UI Overlays tab.

### Implementation Approach

**Extract and Separate Pattern:**
1. Create new `OrdersSearchOverlay` class
2. Move search-related code from `OrdersOverlay` to `OrdersSearchOverlay`
3. Revert `OrdersOverlay` frame size back to `{w=43, h=4}` (original size)
4. Position `OrdersSearchOverlay` adjacent to `OrdersOverlay`
5. Register both in `OVERLAY_WIDGETS` table
6. Keep filter helper functions at module level (shared)

## Potential Contacts

### 1. **Myk Taylor (myk002)**
- **Role:** Primary maintainer of orders plugin
- **Expertise:** Overlay widgets, UI patterns, Lua API
- **Recent work:** Right-click cancel, export dialog prompts
- **Why contact:** For code review and approval of refactoring approach
- **When to contact:** Before creating PR, if uncertain about overlay positioning or conventions

### 2. **pajawojciech (you - the user)**
- **Role:** Implementer of search functionality
- **Expertise:** Orders search logic, material categorization
- **Recent work:** All search feature commits (poc, wood, coffer, goblets)
- **Why relevant:** You understand the search feature requirements best
- **When to reflect:** Consider what positioning makes most sense for users

### 3. **DFHack Community (GitHub Discussions / Discord)**
- **Role:** Beta testers and users
- **Why contact:** To gather feedback on search feature behavior
- **When to contact:** After refactoring is complete, to test independent enable/disable

## Investigation Questions

### Self-Reflection Questions (Before Implementation)

1. **What should the default position of OrdersSearchOverlay be?** ✅ ANSWERED
   - ~~Option A: Directly above OrdersOverlay (same x, different y)?~~
   - ~~Option B: To the left of OrdersOverlay (different x, same y)?~~
   - ~~Option C: Completely separate area?~~
   - **DECISION:** To the right of OrdersOverlay
   - **Position:** `{x=97, y=-6}` (OrdersOverlay is at `{x=53, y=-6}` with `{w=43}`, so 53+43+1=97)

2. **Should OrdersSearchOverlay be enabled by default?** ✅ ANSWERED
   - ~~Option A: `default_enabled=true` (make it opt-out for beta testing)~~
   - **DECISION:** `default_enabled=false` (opt-in since it's beta)
   - **Rationale:** Safer approach, only users who want beta features enable it

3. **What hotkeys should be preserved?** ✅ ANSWERED
   - `CUSTOM_CTRL_F` - Focus the search EditField ✅ KEEP
   - `SELECT` (Enter) - Jump to next match ✅ KEEP
   - These work only when overlay is enabled

4. **Should the search overlay have a minimize button?** ✅ ANSWERED
   - **DECISION:** Yes, add minimize button (click-only, no hotkey)
   - **Rationale:** Consistency with OrdersOverlay, but keep it simple with click-only control

5. **Should the search overlay have a help button?** ✅ ANSWERED
   - **DECISION:** No help button
   - **Rationale:** OrdersOverlay already has one, avoid duplication

6. **Should the search overlay have a frame/border?** ✅ ANSWERED
   - **DECISION:** Yes, use `gui.MEDIUM_FRAME` with `gui.CLEAR_PEN` background
   - **Rationale:** Consistent visual style with OrdersOverlay

7. **Should filter helper functions remain at module level?** ✅ ANSWERED
   - **DECISION:** Yes - they're pure functions with no state
   - **Benefit:** Could be reused by future features (e.g., export filtered orders)

### Questions for Code Review / Feedback

8. **Should there be any functional coupling?** ✅ ANSWERED
   - e.g., Should import/export respect current search filter?
   - **DECISION:** Complete independence - search and import/export don't interact
   - **Rationale:** Keep features modular and separately controllable

9. **Documentation updates needed?**
   - Update `docs/plugins/orders.rst` to document both overlays separately
   - Add changelog entry about refactoring

10. **Testing strategy?**
    - Test with both overlays enabled
    - Test with only importexport enabled
    - Test with only search enabled
    - Test with both disabled

## Next Steps

### Phase 1: Code Refactoring (2-3 hours)

#### Step 1: Create OrdersSearchOverlay Class Structure
**Rationale:** Establish the new overlay with proper attributes before moving code.

**Actions:**
1. After line 184 (after filter helper functions), create new class:
   ```lua
   OrdersSearchOverlay = defclass(OrdersSearchOverlay, overlay.OverlayWidget)
   OrdersSearchOverlay.ATTRS{
       desc='Adds search/filter functionality to the manager orders screen.',
       default_pos={x=97, y=-6},   -- Position to the right of OrdersOverlay
       default_enabled=false,      -- Opt-in for beta testing
       viewscreens='dwarfmode/Info/WORK_ORDERS/Default',
       frame={w=43, h=4},          -- Search UI only (matches OrdersOverlay height)
   }
   ```

2. Verify position doesn't conflict with vanilla UI elements
   - Test in-game with various terminal sizes
   - Position calculation: OrdersOverlay x=53 + width 43 + spacing 1 = 97

**Expected outcome:** Empty OrdersSearchOverlay class that loads without errors.

#### Step 2: Move Search UI Widgets to OrdersSearchOverlay:init()
**Rationale:** Transfer the search interface elements to the new overlay.

**Actions:**
1. Create `OrdersSearchOverlay:init()` method with `self.minimized = false`

2. Create main_panel with `gui.MEDIUM_FRAME` style and `gui.CLEAR_PEN` background

3. Copy search-related widgets from `OrdersOverlay:init()` to main_panel:
   - `widgets.EditField` with `view_id='filter'` (filter input)
   - `widgets.HotkeyLabel` with `view_id='next_match'` (next match button)
   - `widgets.Label` with `view_id='match_counter2'` (match counter)

4. Adjust frame positions (now starting from t=0/t=1 as before)

5. Add minimized panel (copy pattern from OrdersOverlay):
   - Click-only minimize button (no hotkey)
   - Same visual style as OrdersOverlay minimize

6. **Do NOT add help button** (keeping it minimal)

**Expected outcome:** OrdersSearchOverlay has complete search UI with minimize functionality.

#### Step 3: Move Search State and Methods to OrdersSearchOverlay
**Rationale:** Transfer the search logic and state management.

**Actions:**
1. Move instance variables from OrdersOverlay to OrdersSearchOverlay:
   - `self.filter_text = ''`
   - `self.matched_indices = {}`
   - `self.current_match_idx = 0`
   - `self.was_on_screen = false`

2. Move methods from OrdersOverlay to OrdersSearchOverlay:
   - `update_filter(text)`
   - `jump_to_next_match()`
   - `get_match_text()`
   - `has_matches()`

3. Move lifecycle hooks:
   - `onInput(keys)` - CUSTOM_CTRL_F handler
   - `onRenderFrame(dc, rect)` - Filter reset logic

4. Keep `render(dc)` method - check `mi.job_details.open`

**Expected outcome:** OrdersSearchOverlay is fully functional and independent.

#### Step 4: Clean Up OrdersOverlay (Revert to Original)
**Rationale:** Remove search code from the import/export overlay.

**Actions:**
1. Remove search-related widgets from `OrdersOverlay:init()`:
   - Delete EditField widget
   - Delete next match HotkeyLabel
   - Delete match counter Label

2. Revert frame positions for remaining buttons:
   - import: `frame={t=0, l=0}` (was t=2)
   - export: `frame={t=1, l=0}` (was t=3)
   - recheck: `frame={t=0, l=15}` (was t=2)
   - sort: `frame={t=1, l=15}` (was t=3)
   - clear: `frame={t=1, l=28}` (was t=3)

3. Change frame size back to `frame={w=43, h=4}` (was h=6)

4. Remove search state variables from init()

5. Remove search methods:
   - Delete `update_filter()`
   - Delete `jump_to_next_match()`
   - Delete `get_match_text()`
   - Delete `has_matches()`

6. Remove CUSTOM_CTRL_F handler from `onInput()`

7. Remove filter reset logic from `onRenderFrame()` (if it only exists for search)

**Expected outcome:** OrdersOverlay is back to its original pre-search state.

#### Step 5: Register OrdersSearchOverlay in OVERLAY_WIDGETS
**Rationale:** Make the new overlay visible in DFHack Control Panel.

**Actions:**
1. Modify OVERLAY_WIDGETS table (line 995):
   ```lua
   OVERLAY_WIDGETS = {
       recheck=RecheckOverlay,
       importexport=OrdersOverlay,
       search=OrdersSearchOverlay,  -- NEW
       skillrestrictions=SkillRestrictionOverlay,
       laborrestrictions=LaborRestrictionsOverlay,
       conditionsrightclick=ConditionsRightClickOverlay,
       conditionsquantityrightclick=ConditionsQuantityRightClickOverlay,
       quantityrightclick=QuantityRightClickOverlay,
   }
   ```

2. Verify naming convention: `search` (short and clear)

**Expected outcome:** Both `orders.importexport` and `orders.search` appear in DFHack Control Panel.

### Phase 2: Testing & Validation (1-2 hours)

#### Step 6: Build and Load Test
**Rationale:** Ensure code compiles and loads without errors.

**Actions:**
1. Build DFHack (if C++ changes required - not expected for this refactoring)
   ```bash
   ninja -C build
   ```

2. Launch Dwarf Fortress with DFHack

3. Check for Lua errors in DFHack console:
   ```
   :lua ~test
   ```

4. Navigate to manager orders screen (j → m)

5. Verify both overlays load and render

**Expected outcome:** No Lua errors, both overlays visible.

#### Step 7: Functional Testing - Search Overlay
**Rationale:** Verify search functionality still works after refactoring.

**Test cases:**
1. **Basic search:**
   - Press Ctrl+F, type "steel"
   - Verify match counter appears
   - Press Enter to jump to next match
   - Verify scroll position changes

2. **Empty filter:**
   - Clear search text
   - Verify match counter disappears

3. **No matches:**
   - Type nonsense text "zzzzz"
   - Verify "0 matches" or empty counter

4. **Synonym search:**
   - Type "coffer"
   - Verify it finds "chest" orders

5. **Material category search:**
   - Type "wood"
   - Verify it finds wooden items

6. **Hotkey focus:**
   - Press Ctrl+F
   - Verify EditField receives focus

7. **Screen transition:**
   - Enter job details
   - Return to main orders screen
   - Verify filter reset

**Expected outcome:** All search functionality works identically to before refactoring.

#### Step 8: Functional Testing - Import/Export Overlay
**Rationale:** Verify import/export functionality unchanged.

**Test cases:**
1. Press Ctrl+I - import dialog appears
2. Press Ctrl+E - export dialog appears
3. Press Ctrl+K - recheck conditions works
4. Press Ctrl+O - sort orders works
5. Press Ctrl+C - clear orders confirmation appears
6. Press Alt+M - overlay minimizes

**Expected outcome:** All import/export functionality unchanged.

#### Step 9: Independent Control Testing
**Rationale:** Verify overlays can be independently enabled/disabled.

**Test cases:**
1. **Both enabled (default):**
   - Both overlays visible and functional

2. **Disable search only:**
   - DFHack Control Panel → UI → orders.search → disable
   - Search overlay disappears
   - Import/export overlay still visible and functional
   - Ctrl+F does nothing (no error)

3. **Disable import/export only:**
   - Enable search, disable orders.importexport
   - Search overlay visible and functional
   - Import/export overlay disappears
   - Ctrl+I, Ctrl+E do nothing (no error)

4. **Both disabled:**
   - Neither overlay visible
   - No hotkeys captured

**Expected outcome:** Independent control works as expected.

#### Step 10: Position and Overlap Testing
**Rationale:** Ensure overlays don't interfere with each other or vanilla UI.

**Test cases:**
1. Test with default terminal size
2. Test with small terminal (minimum DF size)
3. Test with large terminal
4. Verify overlays don't overlap each other
5. Verify overlays don't obscure important vanilla UI elements
6. Test with both minimized states (if applicable)

**Expected outcome:** Clean layout with no visual conflicts.

### Phase 3: Documentation & Cleanup (30 minutes - 1 hour)

#### Step 11: Update Documentation
**Rationale:** Inform users about the new overlay structure.

**Actions:**
1. Create/update `.ai/orders-search-refactoring-action-plan.md` (this document)

2. Consider updating `docs/plugins/orders.rst` (if DFHack documentation update is needed):
   - Document `orders.importexport` overlay separately
   - Document `orders.search` overlay separately
   - Note that they can be independently controlled

3. Update `docs/changelog.txt`:
   ```
   - `orders`: split search functionality into separate overlay widget
   ```

**Expected outcome:** Clear documentation for users and developers.

#### Step 12: Code Review and Cleanup
**Rationale:** Ensure code quality before committing.

**Actions:**
1. Review all changes:
   - Check for commented-out code (remove if any)
   - Check for debug prints (remove if any)
   - Verify consistent indentation (2 spaces)
   - Add comments where needed

2. Verify filter helper functions are at module level (not inside a class)

3. Check that no functionality was lost in refactoring

4. Run any available linters/formatters

**Expected outcome:** Clean, production-ready code.

#### Step 13: Git Commit
**Rationale:** Record the refactoring with clear history.

**Actions:**
1. Stage changes:
   ```bash
   git add plugins/lua/orders.lua
   git add docs/changelog.txt  # if updated
   ```

2. Create commit with descriptive message:
   ```bash
   git commit -m "separate orders search into independent overlay

   Refactors the manager orders search functionality from OrdersOverlay
   into a new OrdersSearchOverlay widget. This allows users to
   independently enable/disable the search feature via the DFHack Control
   Panel (UI Overlays tab) without affecting import/export functionality.

   Changes:
   - Created OrdersSearchOverlay class with search UI and logic
   - Reverted OrdersOverlay to original size (h=4) and button positions
   - Registered search in OVERLAY_WIDGETS table
   - Positioned search overlay to the right of import/export overlay (x=97)
   - Search overlay default_enabled=false (opt-in for beta)
   - Added minimize button (click-only, no hotkey)
   - Filter helper functions remain at module level (shared)

   Rationale: Search feature is in beta and needs user testing. Separating
   it allows users experiencing issues to disable it while keeping stable
   import/export features enabled. Default disabled for safer rollout.
   "
   ```

**Expected outcome:** Clean git history with clear rationale.

### Phase 4: Optional - Beta Testing Feedback (Ongoing)

#### Step 14: Gather User Feedback
**Rationale:** Improve search functionality based on real-world usage.

**Actions:**
1. Announce the change to DFHack community (Discord / forums)
2. Request beta testers to try the search feature
3. Create GitHub issue for search feedback (if not already exists)
4. Monitor for bug reports related to search
5. Collect feature requests (additional search synonyms, search fields, etc.)

**Expected outcome:** Data to guide future search improvements.

#### Step 15: Iterate on Search Improvements
**Rationale:** Address issues found during beta testing.

**Future improvements to consider:**
1. Performance optimization for 500+ orders
2. Additional search synonyms based on user feedback
3. Search by order conditions (e.g., "when items < 10")
4. Search by workshop restriction
5. Regex support (advanced users)
6. Search history (remember last search)

**Expected outcome:** Mature, stable search feature ready for default enablement.

## Additional Notes

### Technical Constraints

1. **Overlay System Limitations:**
   - Both overlays on same viewscreen: `'dwarfmode/Info/WORK_ORDERS/Default'`
   - Must not overlap or conflict with vanilla UI
   - Each overlay has independent position, enable/disable state

2. **Shared Dependencies:**
   - Filter helper functions at module level (accessible to both overlays)
   - Both overlays access same DF structures: `df.global.world.manager_orders.all`
   - Both overlays check same condition: `mi.job_details.open`

3. **State Management:**
   - Search state (filter_text, matched_indices) lives in OrdersSearchOverlay instance
   - Import/export state lives in OrdersOverlay instance
   - No shared state between overlays (good for independence)

### Design Decisions

#### ✅ 1. Position of OrdersSearchOverlay
**Decision:** Place to the right of OrdersOverlay at `{x=97, y=-6}`

**Rationale:**
- OrdersOverlay is at `{x=53, y=-6}` with width `{w=43}`
- Calculation: 53 + 43 + 1 (spacing) = 97
- Side-by-side layout allows both to be visible simultaneously
- Clear visual relationship without vertical stacking

**Alternative considered:** Above or to the left - rejected in favor of right-side placement.

#### ✅ 2. Default Enabled State
**Decision:** `default_enabled=false` (opt-in for beta)

**Rationale:**
- Safer approach - avoids surprising users with beta features
- Only users who actively want to test will enable it
- Reduces risk of complaints about unstable functionality
- Users can easily enable via DFHack Control Panel → UI Overlays

**Future:** May change to `true` once feature is stable and well-tested.

#### ✅ 3. Minimize Button
**Decision:** Add minimize button with click-only control (no hotkey)

**Rationale:**
- Consistency with OrdersOverlay design
- Users can temporarily hide without disabling
- Click-only keeps it simple (no additional hotkey to remember)
- OrdersOverlay uses `CUSTOM_ALT_M`, search doesn't need a hotkey

**Implementation:** Copy minimized panel pattern from OrdersOverlay.

#### ✅ 4. Help Button
**Decision:** No help button on OrdersSearchOverlay

**Rationale:**
- OrdersOverlay already has help button pointing to orders documentation
- Avoid duplication of functionality
- Keep search overlay minimal and focused
- Users can access help from the main orders overlay

#### ✅ 5. Frame Style
**Decision:** Use `gui.MEDIUM_FRAME` with `gui.CLEAR_PEN` background

**Rationale:**
- Matches OrdersOverlay visual style
- Consistent user experience
- Clear visual boundary for the overlay
- Professional appearance matching DFHack conventions

#### ✅ 6. Hotkey Preservation
**Decision:** Keep `CUSTOM_CTRL_F` and `SELECT` (Enter) hotkeys in OrdersSearchOverlay

**Rationale:**
- Maintains user experience from before refactoring
- `CUSTOM_CTRL_F` focuses the search EditField
- `SELECT` (Enter) jumps to next match
- Clear, discoverable hotkeys with no conflicts

#### ✅ 7. Functional Coupling
**Decision:** Complete independence between search and import/export

**Rationale:**
- Search and import/export don't interact at all
- Export exports all orders (ignores filter)
- Import imports normally (doesn't affect filter)
- Modular design allows separate enable/disable

#### ✅ 8. Filter Helper Functions Location
**Decision:** Keep at module level (before any overlay classes)

**Rationale:**
- Pure functions with no state
- Could be reused by future features (e.g., export filtered orders)
- Clear separation of concerns (data transformation vs UI)
- Accessible to both overlays if needed

### Success Criteria

- [x] OrdersSearchOverlay class created and registered
- [ ] Search functionality works identically to before refactoring
- [ ] Import/export functionality unchanged
- [ ] Both overlays appear in DFHack Control Panel → UI → Overlays
- [ ] Can independently enable/disable each overlay
- [ ] No visual overlap or conflicts between overlays
- [ ] No Lua errors or crashes
- [ ] Clean git commit with clear rationale
- [ ] Code ready for review and potential PR to DFHack repository

### Risks and Mitigations

**Risk 1: Positioning conflicts with vanilla UI**
- Mitigation: Test with multiple terminal sizes, adjust default_pos if needed

**Risk 2: Breaking existing user workflows**
- Mitigation: Keep all hotkeys and behavior identical, just separated into different overlay

**Risk 3: Users confused by two overlays**
- Mitigation: Clear descriptions in overlay settings, update documentation

**Risk 4: Unintended state sharing between overlays**
- Mitigation: Ensure complete separation of state, test independently

### References and Resources

- **DFHack Overlay Framework:** `plugins/lua/overlay.lua`
- **Overlay Widget Examples:**
  - `RecheckOverlay` in orders.lua (lines 485-538) - Simple focused overlay
  - `buildingplan.lua` OVERLAY_WIDGETS - Multiple related overlays
- **DFHack Lua API:** https://docs.dfhack.org/en/stable/docs/dev/Lua%20API.html
- **Widget Library:** `library/lua/gui/widgets.lua`
- **Original Search Implementation Plan:** `.ai/manager-orders-filtering-action-plan.md`

### Future Considerations

1. **Search Feature Maturity:**
   - If search becomes stable and widely used, could merge back into OrdersOverlay
   - Or keep separate for modularity and user choice

2. **Additional Search Features:**
   - Search by workshop restriction
   - Search by order conditions
   - Export filtered orders to JSON
   - Batch operations on filtered orders

3. **Performance Monitoring:**
   - Track search performance with 500+ orders
   - Add caching or optimization if needed

4. **Accessibility:**
   - Consider adding help text to search overlay
   - Tooltips or hints for search syntax (synonyms, material categories)
