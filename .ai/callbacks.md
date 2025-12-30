# DFHack Widget Callback Reference

Complete reference of available callback methods for DFHack widgets.

## EditField Callbacks

- **`on_char`** - Called when a character is typed in the field.
  - Signature: `function(char, current_text) -> bool`
  - Return `false` to reject the input character

- **`on_change`** - Called whenever the text content changes.
  - Signature: `function(new_text, old_text)`

- **`on_submit`** - Called when the user presses SELECT (Enter).
  - Signature: `function(text)`

- **`on_submit2`** - Called when the user presses SELECT_ALL (Shift+Enter).
  - Signature: `function(text)`

## TextArea Callbacks

- **`on_text_change`** - Called when text content changes.
  - Signature: `function(new_text, old_text)`

- **`on_cursor_change`** - Called when the cursor position changes.
  - Signature: `function(new_cursor, old_cursor)`

## List Callbacks

- **`on_select`** - Called when the selected item changes.
  - Signature: `function(selected_item)`

- **`on_submit`** - Called when SELECT is pressed on a list item.
  - Signature: `function(selected_item)`

- **`on_submit2`** - Called when SELECT_ALL is pressed on a list item.
  - Signature: `function(selected_item)`

- **`on_double_click`** - Called on double-click with the primary button.
  - Signature: `function(selected_item)`

- **`on_double_click2`** - Called on double-click with the secondary button.
  - Signature: `function(selected_item)`

## FilteredList Callbacks

All List callbacks above, plus:

- **`edit_on_char`** - Called when a character is typed in the filter field.
  - Signature: `function(char, current_text) -> bool`

- **`edit_on_change`** - Called when the filter text changes.
  - Signature: `function(text)`

## Slider Callbacks

- **`on_change`** - Called when the slider position changes.
  - Signature: `function(new_index)`

## RangeSlider Callbacks

- **`on_left_change`** - Called when the left handle moves.
  - Signature: `function(new_index)`

- **`on_right_change`** - Called when the right handle moves.
  - Signature: `function(new_index)`

## Scrollbar Callbacks

- **`on_scroll`** - Called when the scrollbar position changes.
  - Signature: `function(new_top_elem)`

## HotkeyLabel Callbacks

- **`on_activate`** - Called when the hotkey is pressed or the label is clicked.
  - Signature: `function()`

## CycleHotkeyLabel Callbacks

- **`on_change`** - Called when the option cycles.
  - Signature: `function(new_value, new_index, old_value, old_index)`

## Tab Callbacks

- **`on_select`** - Called when a tab is clicked.
  - Signature: `function(tab_id)`

## TabBar Callbacks

- **`on_select`** - Called when a tab is selected.
  - Signature: `function(tab_index)`

## TextButton / Label Callbacks

- **`on_activate`** - Called when the button/label is activated via hotkey or click.
  - Signature: `function()`

## Common Widget Input Callbacks

Some widgets may also support mouse and input callbacks through their parent `gui.View` class:

- **`on_click`** - Mouse click handling (token-level in Labels)
- **`on_rclick`** - Right-click handling (token-level in Labels)

## Key Files

Widget implementations can be found in:

- **EditField**: `/library/lua/gui/widgets/edit_field.lua`
- **List**: `/library/lua/gui/widgets/list.lua`
- **FilteredList**: `/library/lua/gui/widgets/filtered_list.lua`
- **TextArea**: `/library/lua/gui/widgets/text_area.lua`
- **Slider/RangeSlider**: `/library/lua/gui/widgets/slider.lua`, `/library/lua/gui/widgets/range_slider.lua`
- **Scrollbar**: `/library/lua/gui/widgets/scrollbar.lua`
- **HotkeyLabel/CycleHotkeyLabel**: `/library/lua/gui/widgets/labels/hotkey_label.lua`, `/library/lua/gui/widgets/labels/cycle_hotkey_label.lua`
- **TabBar**: `/library/lua/gui/widgets/tab_bar.lua`

## Notes

- Return values from callbacks (like `on_char`) can control input behavior (false rejects input)
- Most callbacks receive the current/new value as the first parameter
- Change callbacks typically receive both the new and old values for comparison
- Callbacks are optional attributes and default to `DEFAULT_NIL`
- Some widgets extend others (e.g., ToggleHotkeyLabel extends CycleHotkeyLabel and inherits its callbacks)

## Usage Example

```lua
widgets.EditField{
    view_id='search',
    on_char=function(char, text)
        -- Validate input, return false to reject
        if char == '@' then return false end
        return true
    end,
    on_change=function(new_text, old_text)
        -- React to text changes
        self:update_search(new_text)
    end,
    on_submit=function(text)
        -- Handle Enter key
        self:perform_search(text)
    end,
    on_submit2=function(text)
        -- Handle Shift+Enter
        self:perform_advanced_search(text)
    end,
}
```
