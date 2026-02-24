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
    local scroll_frame = CreateFrame('ScrollFrame', nil, content)
    scroll_frame:SetPoint('TOPLEFT', content, 'TOPLEFT', 5, -35)
    scroll_frame:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -5, 35)
    scroll_frame:EnableMouse(true)
    scroll_frame:EnableMouseWheel(true)
    scroll_frame:SetScript('OnMouseWheel', function()
        local current_scroll = this:GetVerticalScroll()
        local scroll_step = 20
        if arg1 > 0 then
            current_scroll = max(0, current_scroll - scroll_step)
        else
            current_scroll = current_scroll + scroll_step
        end
        this:SetVerticalScroll(current_scroll)
    end)
    gui.set_content_style(scroll_frame)

    edit_box = CreateFrame('EditBox', nil, scroll_frame)
    edit_box:SetMultiLine(true)
    edit_box:SetAutoFocus(false)
    edit_box:SetFontObject(GameFontHighlight)
    edit_box:SetWidth(scroll_frame:GetWidth() - 10)
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
    status_label:SetPoint('BOTTOMLEFT', content, 'BOTTOMLEFT', 5, 10)
    status_label:SetText('Ready')

    -- Run button (without logout)
    run_button = gui.button(frame)
    run_button:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -5, -5)
    gui.set_size(run_button, 80, 24)
    run_button:SetText('Run')
    run_button:SetScript('OnClick', function() start_queries(false) end)
    
    -- Run with logout button
    run_logout_button = gui.button(frame)
    run_logout_button:SetPoint('TOPRIGHT', run_button, 'TOPLEFT', -5, 0)
    gui.set_size(run_logout_button, 160, 24)
    run_logout_button:SetText('Run (logoff when done)')
    run_logout_button:SetScript('OnClick', function() start_queries(true) end)

    -- Buy Shopping List button
    buy_button = gui.button(frame)
    buy_button:SetPoint('TOPRIGHT', run_logout_button, 'TOPLEFT', -5, 0)
    gui.set_size(buy_button, 130, 24)
    buy_button:SetText('Buy Shopping List')
    buy_button:SetScript('OnClick', function() start_shopping_list() end)
end
