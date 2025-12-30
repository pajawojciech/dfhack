# Action Plan for Manager Orders Filtering Feature

## Issue Description

Add a filtering textbox to the manager orders screen that shows only orders containing the provided text. This enhancement will improve usability when dealing with many manager orders by allowing users to quickly find specific orders.

## Relevant Codebase Parts

### 1. `plugins/lua/orders.lua` (Primary Implementation Location)
**Lines 74-179: OrdersOverlay class**
- This overlay adds import/export/sort/clear/recheck functionality to the work orders screen
- Currently positioned at `{x=53,y=-6}` with frame `{w=43, h=4}`
- Uses `widgets.HotkeyLabel` for various operations
- Viewscreen: `'dwarfmode/Info/WORK_ORDERS/Default'`
- **Why relevant**: This is where the filtering UI widget and logic will be added

### 2. `plugins/orders.cpp` (C++ Backend - Reference Only)
**Lines 307-514: orders_export_command function**
- Iterates through `world->manager_orders.all` vector
- Shows how to access manager order data structures
- **Why relevant**: Demonstrates how to access and iterate manager orders, though filtering will be implemented in Lua

### 3. `library/xml/` (DF Structures - Submodule)
**df::manager_order structure**
- Contains fields like `id`, `job_type`, `reaction_name`, `item_type`, etc.
- **Why relevant**: Understanding order structure is needed to determine what fields to filter on

### 4. `plugins/lua/buildingplan/filterselection.lua` (Reference Implementation)
**Lines 100-105: EditField usage example**
```lua
widgets.EditField{
    view_id='search',
    frame={l=26, t=3},
    label_text='Search: ',
    on_char=function(ch) return ch:match('[%l -]') end,
}
```
- **Why relevant**: Shows proper EditField widget usage for search functionality

### 5. `docs/plugins/orders.rst` (Documentation)
**Lines 51-64: Overlays section**
- Documents current overlay functionality
- **Why relevant**: Will need to update documentation with new filtering feature

## Git Commit History Analysis

### plugins/lua/orders.lua (Last 10 commits)
- **2025-01-11**: Myk Taylor - "allow right click to cancel instead of exiting" - Recent UI enhancement
- **2024-12-25**: Myk Taylor - "add prompt to orders export dialog" - Recent feature addition
- **2024-09-09**: Christian Doczkal - "make can_set_labors public (for use by idle-crafting)" - API exposure
- **2024-08-13**: Christian Doczkal - "[orders] adapt to #4858" - Structural adaptation
- **2024-03-17**: Myk Taylor - "single click button to toggle labor" - UI improvement

**Key findings**:
- Active maintenance by Myk Taylor with focus on UI improvements
- Recent pattern of enhancing user interaction (right-click, export prompts)
- Christian Doczkal contributes to API and structural changes
- No major refactoring recently - stable codebase for enhancements

### plugins/orders.cpp (Last 10 commits)
- **2025-03-23**: Kelly Kinkade - "address another path/string confusion" - Maintenance
- **2025-02-08**: Myk Taylor - "update to great reorg structures" - Structure updates
- **2024-12-22**: Myk Taylor - "remove unneeded headers" - Code cleanup
- **2024-12-06**: Myk Taylor - "sort workshop-tied orders first" - Sorting logic enhancement

**Key findings**:
- Stable C++ backend - most changes are structure updates or maintenance
- Recent sorting enhancement shows willingness to improve order management
- No filtering-related work yet - green field for this feature

## Root Cause Analysis

**This is not a bug fix - this is a feature request.**

### Current State
The manager orders screen displays all orders without any filtering capability. Users must manually scroll through potentially hundreds of orders to find specific ones.

### Proposed Enhancement
Add a text filter that dynamically shows/hides orders based on whether they contain the filter text. This would match patterns seen in other DFHack overlays (e.g., import dialog already has `with_filter=true` in ListBox).

### Implementation Approach
The filtering needs to work within DFHack's overlay system constraints:
1. **Cannot modify vanilla DF's order list rendering directly**
2. **Must work as an overlay on top of existing screen**
3. **Two possible approaches**:
   - **Approach A (Recommended)**: Add EditField widget to OrdersOverlay and use search-based navigation (jump to matching orders)
   - **Approach B (Complex)**: Create a filtered overlay list that renders over vanilla list (similar to sort plugin approach)

## Potential Contacts

### 1. **Myk Taylor (myk002)**
- **Role**: Primary maintainer of orders plugin Lua components
- **Expertise**: Overlay widgets, UI enhancements, Lua API
- **Recent work**: Right-click cancel, export dialog prompt
- **Why contact**: Primary decision maker for orders plugin UI changes, recent pattern of UI improvements aligns with this feature request

### 2. **Christian Doczkal (chdoc)**
- **Role**: Contributor to orders plugin functionality
- **Expertise**: API exposure, structural adaptations
- **Recent work**: Labor restrictions, API improvements
- **Why contact**: For questions about orders plugin architecture or if API changes are needed

### 3. **Kelly Kinkade (ab9rf)**
- **Role**: Core library expert, release coordinator
- **Expertise**: Structure updates, C++ backend
- **Recent work**: Path handling, structure updates
- **Why contact**: Only if C++ changes are needed or if structure updates affect implementation

## Design Decisions (Answered Questions)

### ✅ 1. What fields from manager_order should be searchable?
**DECISION:** Search by item type/subtype, material, and job_type only.
- **Job type**: e.g., "forge", "construct", "make"
- **Item type/subtype**: e.g., "battle axe", "short sword", "armor"
- **Material**: e.g., "steel", "iron", "oak"
- **Match type**: Simple case-insensitive "contains" matching

**Examples:**
- Typing "steel" finds all steel orders
- Typing "battle axe" finds battle axe orders
- Typing "forge" finds all forge orders

### ✅ 2. Should filtering hide non-matching orders or just highlight matching ones?
**DECISION:** Highlight/jump to matching orders with indicator.
- Keep vanilla DF's order list visible (overlay constraint)
- Use navigation hotkeys to jump between matches (Next/Prev)
- Show match indicator: "Showing match 3 of 7" or "5 orders match 'steel'"
- Use vanilla selection cursor to highlight current match

**Rationale:** Cannot modify vanilla DF's rendered list directly, but can control selection cursor.

### ✅ 3. Where should the EditField widget be positioned in the overlay?
**DECISION:** Expand existing OrdersOverlay vertically (Option A).
- Increase frame height from `h=4` to `h=6` or `h=7`
- Add EditField on new top row
- Add navigation controls (Next/Prev match buttons/hotkeys)
- Show match count indicator
- Keep existing import/export/sort/clear buttons below

**Layout:**
```
┌─────────────────────────────────────────┐
│ Filter: [steel            ] (3/7 orders)│
│ [n]ext  [p]rev                          │
│ [i]mport        [k] recheck conditions  │
│ [e]xport        [o] sort    [c] clear   │
└─────────────────────────────────────────┘
```

### ✅ 4. How to access the manager orders list for filtering?
**DECISION:** Direct access on every keystroke (Option A).
- Access `df.global.world.manager_orders.all` directly
- Generate search keys on-the-fly when filter text changes
- No caching needed (order lists typically < 100 items)
- Simple and maintainable

**Search key generation:**
```lua
local function get_order_search_key(order)
    local parts = {}
    -- Job type
    table.insert(parts, df.job_type[order.job_type]:lower())
    -- Item type/subtype
    if order.item_type ~= df.item_type.NONE then
        table.insert(parts, df.item_type[order.item_type]:lower())
    end
    -- Material
    if order.mat_type ~= -1 then
        local mat = dfhack.matinfo.decode(order.mat_type, order.mat_index)
        if mat then
            table.insert(parts, mat:toString():lower())
        end
    end
    return table.concat(parts, ' ')
end
```

### ✅ 5. Should this work with existing sort functionality?
**DECISION:** Filter works independently of sort order.
- Sort physically reorders `world->manager_orders.all` vector
- Filter navigates through matches in whatever order they currently appear
- No conflict - they're orthogonal operations
- User can sort first, then filter (or vice versa)

### ✅ 6. Performance considerations?
**DECISION:** Filter on every keystroke, no debouncing.
- Immediate feedback as user types
- Simple implementation
- Typical order counts (< 100) won't have performance issues
- Can add optimization later if needed for 500+ orders

### ✅ 7. What hotkey should trigger the filter textbox focus?
**DECISION:** Explicit focus with CUSTOM_CTRL_F, next match with Enter (SELECT).
- `CUSTOM_CTRL_F` - Focus the filter EditField
- `SELECT` (Enter key) - Jump to next match
- **No previous match** - only next navigation
- **Not always active** - filter only captures input when focused
- Prevents accidental filtering when using other hotkeys

**Implementation note:** Changed from CUSTOM_CTRL_N to SELECT during testing for better UX.

### ✅ 8. Should the filter state persist between screen visits?
**DECISION:** Reset filter when leaving screen.
- Filter text clears when user navigates away from manager orders screen
- Clean slate on each screen visit
- Simple and predictable behavior
- User can easily re-filter if needed

### ✅ 9. Interaction with job_details.open - should filter be hidden when details open?
**DECISION:** Hide filter with the rest of overlay.
- Follow existing overlay pattern: hide when `mi.job_details.open`
- Consistent with current overlay behavior
- Job details screen doesn't show orders list, so filter not useful there

### ✅ 10. Should there be visual feedback for "no matches"?
**DECISION:** Show match counter as "X/Y orders" format.
- Display format: "5/50 orders" (5 matches out of 50 total)
- When no matches: "0/50 orders"
- No special message or color change
- Simple and clean

### ✅ 11. When should the match counter display?
**DECISION:** Show counter only when filter has text.
- Empty filter: no counter displayed
- Filter with text: show "X/Y orders"
- Clear indication of active filtering
- No clutter when not filtering

## Implementation Specifications (Ready to Code)

Based on all decisions above, here are the complete implementation specs:

### UI Layout
```
┌─────────────────────────────────────────┐
│ Filter: [                ] (5/50 orders)│ ← New row
│ [n]ext match                            │ ← New row
│ [i]mport        [k] recheck conditions  │
│ [e]xport        [o] sort    [c] clear   │
└─────────────────────────────────────────┘
```

### Widget Specifications

**1. EditField (Filter Input)**
- `view_id='filter'`
- `frame={t=0, l=8}` (after "Filter: " label)
- `label_text='Filter: '`
- `on_char=function(ch) return ch:match('[%w%s-]') end` (alphanumeric, space, dash)
- `on_change=self:callback('update_filter')` (triggers on every keystroke)
- Focus with `CUSTOM_CTRL_F` hotkey

**2. Match Counter Label**
- `view_id='match_counter'`
- `frame={t=0, r=1}` (right side of first row)
- `text=function() return self:get_match_text() end`
- Format: "X/Y orders" (only shown when filter has text)

**3. Next Match Button**
- `view_id='next_match'`
- `frame={t=1, l=0}`
- `label='next match'`
- `key='CUSTOM_CTRL_N'`
- `on_activate=self:callback('jump_to_next_match')`
- `enabled=function() return self:has_matches() end`

**4. Focus Filter Button/Hotkey**
- `key='CUSTOM_CTRL_F'`
- Action: `self.subviews.filter:setFocus(true)`
- Can be HotkeyLabel or just hotkey in onInput

### Frame Adjustments
- Change `frame={w=43, h=4}` to `frame={w=43, h=6}`
- Shift existing buttons down by 2 rows (t=0→t=2, t=1→t=3)

### Data Structures

**Filter State (instance variables)**
```lua
self.filter_text = ''  -- Current filter string (lowercase)
self.matched_indices = {}  -- Array of indices into world.manager_orders.all
self.current_match_idx = 0  -- Index into matched_indices (0 = none)
```

### Core Functions

**1. get_order_search_key(order)** ✅ COMPLETE IMPLEMENTATION
```lua
-- Complete itemdef lookup table for ALL 14 item types with itemdefs
-- Matches orders.cpp export function (lines 273-304)
local ITEMDEF_TYPES = {
    [df.item_type.AMMO] = df.itemdef_ammost,              -- arrows, bolts
    [df.item_type.ARMOR] = df.itemdef_armorst,            -- breastplate, mail shirt
    [df.item_type.FOOD] = df.itemdef_foodst,              -- prepared meals
    [df.item_type.GLOVES] = df.itemdef_glovesst,          -- gloves, gauntlets
    [df.item_type.HELM] = df.itemdef_helmst,              -- helmets, caps
    [df.item_type.INSTRUMENT] = df.itemdef_instrumentst,  -- musical instruments
    [df.item_type.PANTS] = df.itemdef_pantsst,            -- pants, greaves
    [df.item_type.SHIELD] = df.itemdef_shieldst,          -- shields
    [df.item_type.SHOES] = df.itemdef_shoesst,            -- shoes, boots
    [df.item_type.SIEGEAMMO] = df.itemdef_siegeammost,    -- ballista arrows
    [df.item_type.TOOL] = df.itemdef_toolst,              -- tools
    [df.item_type.TOY] = df.itemdef_toyst,                -- toys
    [df.item_type.TRAPCOMP] = df.itemdef_trapcompst,      -- trap components
    [df.item_type.WEAPON] = df.itemdef_weaponst,          -- swords, axes
}

local function get_itemdef_name(order)
    if order.item_subtype == -1 then return nil end

    local item_type = order.item_type
    if item_type == df.item_type.NONE then
        item_type = df.job_type.attrs[order.job_type].item
    end

    if not item_type or item_type == df.item_type.NONE then return nil end

    -- Simple table lookup instead of if-else chain
    local itemdef_class = ITEMDEF_TYPES[item_type]
    if itemdef_class then
        local itemdef = itemdef_class.find(order.item_subtype)
        return itemdef and itemdef.name or nil
    end

    return nil
end

local function get_order_search_key(order)
    local parts = {}

    -- Job type (e.g., "makeweapon", "constructbed")
    table.insert(parts, df.job_type[order.job_type]:lower())

    -- Item type (e.g., "weapon", "armor")
    local item_type = order.item_type
    if item_type == df.item_type.NONE then
        item_type = df.job_type.attrs[order.job_type].item
    end
    if item_type and item_type ~= df.item_type.NONE then
        table.insert(parts, df.item_type[item_type]:lower())
    end

    -- Item subtype name (e.g., "battle axe", "breastplate")
    local itemdef_name = get_itemdef_name(order)
    if itemdef_name then
        table.insert(parts, itemdef_name:lower())
    end

    -- Material (e.g., "iron", "steel", "oak")
    if order.mat_type ~= -1 then
        local mat = dfhack.matinfo.decode(order.mat_type, order.mat_index)
        if mat then
            table.insert(parts, mat:toString():lower())
        end
    end

    return table.concat(parts, ' ')
end
```

**2. update_filter()**
```lua
function OrdersOverlay:update_filter(text)
    self.filter_text = text:lower()
    self.matched_indices = {}
    self.current_match_idx = 0

    if self.filter_text == '' then
        return  -- No filtering
    end

    local orders = df.global.world.manager_orders.all
    for idx, order in ipairs(orders) do
        local search_key = get_order_search_key(order)
        if search_key:find(self.filter_text, 1, true) then  -- plain text search
            table.insert(self.matched_indices, idx)
        end
    end
end
```

**3. jump_to_next_match()**
```lua
function OrdersOverlay:jump_to_next_match()
    if #self.matched_indices == 0 then return end

    self.current_match_idx = self.current_match_idx + 1
    if self.current_match_idx > #self.matched_indices then
        self.current_match_idx = 1  -- Wrap around
    end

    -- Get the order index (1-based in matched_indices array)
    local order_idx = self.matched_indices[self.current_match_idx]

    -- Scroll so matching order appears at top of visible area
    -- scroll_position_work_orders is 0-based, order_idx is 1-based
    local mi = df.global.game.main_interface
    mi.info.work_orders.scroll_position_work_orders = order_idx - 1
end
```

**4. get_match_text()**
```lua
function OrdersOverlay:get_match_text()
    if self.filter_text == '' then
        return ''
    end

    local total = #df.global.world.manager_orders.all
    local matches = #self.matched_indices

    return string.format('(%d/%d orders)', matches, total)
end
```

**5. has_matches()**
```lua
function OrdersOverlay:has_matches()
    return #self.matched_indices > 0
end
```

### Lifecycle Hooks

**onRenderFrame() or preUpdateLayout()**
- Reset filter state if screen changed (detect viewscreen change)
- Clear `self.filter_text`, `self.matched_indices`, `self.current_match_idx`

### Research Needed

**1. How to programmatically set the selection in manager orders list** ✅ COMPLETED

**Research findings:**
- Manager orders screen state: `mi.info.work_orders` (where `mi = df.global.game.main_interface`)
- Structure type: `work_orders_interfacest`
- Created inspection script: `inspect_work_orders.lua`

**✅ CONFIRMED FIELD:** `mi.info.work_orders.scroll_position_work_orders`
- Note: plural "orders" at the end
- This controls **scroll position**, not selection
- **Behavior**: Sets which order appears at TOP of visible area
- Index is 0-based (0 = first order at top)

**Tested and verified:**
```lua
-- Scroll so order at index appears at top of screen
local order_idx = self.matched_indices[self.current_match_idx]
mi.info.work_orders.scroll_position_work_orders = order_idx - 1  -- 0-based index
```

**Important distinction:**
- Does NOT change which order is selected/highlighted
- DOES scroll the view so the order is visible at the top
- This is perfect for our filtering use case - user sees the match clearly

---

**2. How to get item_subtype name** ✅ COMPLETED

**Tested and verified approach:**
```lua
local function get_itemdef_name(order)
    if order.item_subtype == -1 then
        return nil
    end

    -- Get item_type - either from order or from job_type
    local item_type = order.item_type
    if item_type == df.item_type.NONE then
        item_type = df.job_type.attrs[order.job_type].item
    end

    if not item_type or item_type == df.item_type.NONE then
        return nil
    end

    -- Map item type to itemdef finder
    local itemdef = nil
    if item_type == df.item_type.WEAPON then
        itemdef = df.itemdef_weaponst.find(order.item_subtype)
    elseif item_type == df.item_type.ARMOR then
        itemdef = df.itemdef_armorst.find(order.item_subtype)
    elseif item_type == df.item_type.SHIELD then
        itemdef = df.itemdef_shieldst.find(order.item_subtype)
    elseif item_type == df.item_type.HELM then
        itemdef = df.itemdef_helmst.find(order.item_subtype)
    elseif item_type == df.item_type.GLOVES then
        itemdef = df.itemdef_glovesst.find(order.item_subtype)
    elseif item_type == df.item_type.SHOES then
        itemdef = df.itemdef_shoesst.find(order.item_subtype)
    elseif item_type == df.item_type.PANTS then
        itemdef = df.itemdef_pantsst.find(order.item_subtype)
    elseif item_type == df.item_type.TOOL then
        itemdef = df.itemdef_toolst.find(order.item_subtype)
    -- Add more as needed
    end

    -- Return readable name (e.g., "battle axe", "breastplate")
    return itemdef and itemdef.name or nil
end
```

**Test results:**
- ✅ Weapons: "battle axe" (from ITEM_WEAPON_AXE_BATTLE)
- ✅ Armor: "breastplate" (from ITEM_ARMOR_BREASTPLATE)
- ✅ Shields: "shield" (from ITEM_SHIELD_SHIELD)
- ✅ Materials: "iron", "steel" (via dfhack.matinfo.decode)

**Key finding:** Use `itemdef.name` (not `itemdef.id`) for user-friendly search text

## Next Steps

### Phase 1: Research & Design (1-2 hours)

1. **Study the manager orders screen in-game**
   - Launch DF with DFHack
   - Open manager orders screen (j → m)
   - Note screen layout, order display format
   - Document available space for filter widget
   - Test with 10+ orders to understand scrolling behavior

2. **Examine df::manager_order structure**
   - Read `library/include/df/manager_order.h` (if available locally)
   - Or examine `plugins/orders.cpp` lines 316-504 to see all exported fields
   - Document which fields contain user-visible text
   - Priority fields: job_type, reaction_name, item_type, material

3. **Study FilteredList widget implementation**
   - Read `library/lua/gui/widgets/filtered_list.lua`
   - Understand filtering mechanism and search key generation
   - Note performance patterns

4. **Review sort plugin's approach**
   - Examine `plugins/lua/sort/info.lua` work_details_search function (lines 63-71)
   - See how they hook into game state for filtering
   - Understand search key generation patterns

### Phase 2: Prototype Implementation (2-4 hours)

5. **Create feature branch**
   ```bash
   git checkout -b feature/manager-orders-filter
   ```

6. **Implement basic EditField widget in OrdersOverlay**
   - Add EditField to OrdersOverlay:init() subviews
   - Position it appropriately (likely expand frame height to h=5 or h=6)
   - Add view_id='filter'
   - Implement on_char validation (alphanumeric + space)

7. **Implement order-to-string conversion function**
   - Create `get_order_search_key(order)` function
   - Include: job_type enum name, reaction_name, item_type, material token
   - Test with various order types

8. **Implement filtering logic**
   - On EditField text change, iterate `world->manager_orders.all`
   - Generate search keys for each order
   - Store filtered indices
   - **Decision point**: Choose implementation approach:
     - A) Use game's selection mechanism to jump to matching order
     - B) Create overlay list (more complex)

9. **Add visual feedback**
   - Show count of matching orders: "Showing X/Y orders"
   - Clear button to reset filter
   - Indicator when filter is active

### Phase 3: Testing & Refinement (2-3 hours)

10. **Test with various scenarios**
    - Empty filter (show all)
    - Single character filter
    - Filter matching no orders
    - Filter matching all orders
    - Case sensitivity (should be case-insensitive)
    - Special characters in filter text

11. **Performance testing**
    - Test with 100+ manager orders
    - Measure filter update time on keystroke
    - Add debouncing if needed (unlikely with Lua)

12. **Integration testing**
    - Test with import/export/sort/clear operations
    - Verify filter doesn't interfere with existing hotkeys
    - Test minimized mode (CUSTOM_ALT_M)
    - Test with job_details open (filter should hide)

13. **Cross-platform testing**
    - Test on Windows (primary development platform)
    - If possible, test on Linux
    - Verify UI rendering with different terminal sizes

### Phase 4: Documentation & Submission (1 hour)

14. **Update documentation**
    - Edit `docs/plugins/orders.rst`
    - Add section under "Overlays" describing filter functionality
    - Document hotkey (if added) and usage
    - Update changelog: `docs/changelog.txt`
    - Example entry: `- `orders`: added text filter to manager orders overlay`

15. **Code cleanup**
    - Remove debug prints
    - Add code comments explaining filter logic
    - Ensure consistent code style (2-space indentation)
    - Run any linters/formatters

16. **Create commit**
    ```bash
    # Stage Lua implementation
    git add plugins/lua/orders.lua

    # Stage documentation
    git add docs/plugins/orders.rst docs/changelog.txt

    # Commit with descriptive message
    git commit -m "add text filter to manager orders overlay

Adds an EditField widget to the orders overlay that filters the
manager orders list to show only orders matching the provided text.
Searches job type, reaction name, item type, and materials.

Closes #XXXX (if there's a GitHub issue)"
    ```

17. **Test before PR**
    - Build clean: `ninja -C build clean && ninja -C build`
    - Launch DF, verify overlay loads without errors
    - Test all functionality one final time

18. **Create Pull Request**
    - Push branch to fork
    - Create PR on DFHack/dfhack repository
    - Reference this action plan in PR description
    - Tag Myk Taylor for review (@myk002)
    - Wait for feedback and iterate

## Additional Notes

### Technical Constraints

1. **Overlay System Limitations**
   - Cannot directly manipulate vanilla DF's order list widget
   - Must work within overlay framework constraints
   - Position carefully to not obscure important information

2. **DF Structure Access**
   - Manager orders are in `df.global.world.manager_orders.all`
   - This is a vector of df::manager_order pointers
   - Access is read-only from Lua (no need to modify)

3. **Performance Considerations**
   - Lua is fast enough for filtering hundreds of orders
   - Re-filter on every keystroke should be fine
   - Search key caching probably not needed unless 500+ orders

### UI/UX Considerations

1. **Discoverability**
   - Filter should be visible by default (not hidden in menu)
   - Label clearly: "Filter: " prefix
   - Maybe add help text: "Filter orders (Ctrl+F to focus)"

2. **Feedback**
   - Show "X/Y orders" count when filter active
   - Clear indicator when no matches found
   - Easy way to clear filter (Escape key, clear button)

3. **Accessibility**
   - Case-insensitive search
   - Partial match (not just prefix)
   - Search multiple fields (job, item, material)

### Alternative Approaches (If Main Approach Blocked)

**If overlay filtering proves too complex:**
1. **Console command approach**: `orders filter <text>` that modifies the list
   - Pros: Easier to implement, no UI complexity
   - Cons: Less user-friendly, requires typing commands

2. **Separate screen approach**: `gui/orders-filter` custom screen with full list
   - Pros: Complete control, can use FilteredList widget directly
   - Cons: Not integrated, requires switching screens

3. **Highlight-only approach**: Filter doesn't hide, just highlights matches
   - Pros: Simpler, keeps all orders visible
   - Cons: Less useful with many orders

### Resources & References

- **DFHack Lua API docs**: https://docs.dfhack.org/en/stable/docs/dev/Lua%20API.html
- **Widget library**: `library/lua/gui/widgets.lua` and submodules
- **Overlay framework**: `plugins/lua/overlay.lua`
- **Similar implementations**:
  - `plugins/lua/sort/` - Filtering and sorting overlays
  - `plugins/lua/buildingplan/filterselection.lua` - EditField usage
  - `plugins/lua/zone.lua` - Animal filtering example
- **Testing orders**: Use `orders import library/basic` to get test data

### Success Criteria

- [ ] EditField widget appears in manager orders overlay
- [ ] Typing filter text shows only matching orders
- [ ] Filter is case-insensitive
- [ ] Filter searches job type, reaction, item type, and material
- [ ] Clear way to reset filter (Escape or clear button)
- [ ] Performance is acceptable with 100+ orders
- [ ] Documentation updated
- [ ] No regressions in existing orders plugin functionality
- [ ] PR approved and merged by maintainers
