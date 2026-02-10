module 'aux.tabs.wppa'

local aux = require 'aux'
local gui = require 'aux.gui'

function aux.handle.INIT_UI()
    frame = CreateFrame('Frame', nil, aux.frame)
    frame:SetAllPoints()
    frame:Hide()

    -- Create the main content panel
    local content = gui.panel(frame)
    content:SetAllPoints(aux.frame.content)

    -- Create multiline edit box with scrollable area
    local scroll_frame = CreateFrame('ScrollFrame', nil, content, 'UIPanelScrollFrameTemplate')
    scroll_frame:SetPoint('TOPLEFT', content, 'TOPLEFT', 5, -5)
    scroll_frame:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -25, 40)

    edit_box = CreateFrame('EditBox', nil, scroll_frame)
    edit_box:SetMultiLine(true)
    edit_box:SetAutoFocus(false)
    edit_box:SetFontObject(GameFontHighlight)
    edit_box:SetWidth(scroll_frame:GetWidth())
    edit_box:SetScript('OnEscapePressed', function() this:ClearFocus() end)
    edit_box:SetScript('OnTextChanged', function()
        -- Adjust height based on content
        local _, font_height = this:GetFont()
        local num_lines = 1
        local text = this:GetText()
        for _ in string.gfind(text, '\n') do
            num_lines = num_lines + 1
        end
        local height = max(scroll_frame:GetHeight(), num_lines * (font_height + 2) + 10)
        this:SetHeight(height)
    end)
    
    scroll_frame:SetScrollChild(edit_box)

    -- Status label at the bottom
    status_label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    status_label:SetPoint('BOTTOMLEFT', content, 'BOTTOMLEFT', 5, 5)
    status_label:SetText('Ready')

    -- Logout checkbox
    logout_checkbox = gui.checkbox(frame)
    logout_checkbox:SetPoint('BOTTOMLEFT', status_label, 'BOTTOMRIGHT', 10, -5)
    
    local logout_label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    logout_label:SetPoint('LEFT', logout_checkbox, 'RIGHT', 0, 0)
    logout_label:SetText('Logout when finished')

    -- Run button
    run_button = gui.button(frame)
    run_button:SetPoint('LEFT', logout_label, 'RIGHT', 10, 0)
    gui.set_size(run_button, 60, 24)
    run_button:SetText('Run')
    run_button:SetScript('OnClick', start_queries)
end
