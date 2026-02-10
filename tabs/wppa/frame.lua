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

    -- Create multiline edit box
    local scroll_frame = CreateFrame('ScrollFrame', nil, content)
    scroll_frame:SetPoint('TOPLEFT', content, 'TOPLEFT', 5, -5)
    scroll_frame:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -5, 40)

    edit_box = CreateFrame('EditBox', nil, scroll_frame)
    edit_box:SetMultiLine(true)
    edit_box:SetAutoFocus(false)
    edit_box:SetFontObject(GameFontHighlight)
    edit_box:SetWidth(scroll_frame:GetWidth())
    
    -- Create a background for the edit box
    local bg = edit_box:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.5)
    
    scroll_frame:SetScrollChild(edit_box)
    
    -- Enable scroll on mouse wheel
    scroll_frame:EnableMouseWheel(true)
    scroll_frame:SetScript('OnMouseWheel', function()
        local scroll_offset = scroll_frame:GetVerticalScroll()
        local scroll_step = 20
        if arg1 > 0 then
            scroll_offset = max(0, scroll_offset - scroll_step)
        else
            scroll_offset = scroll_offset + scroll_step
        end
        scroll_frame:SetVerticalScroll(scroll_offset)
    end)
    
    -- Set up text changed handler to update scroll child height
    edit_box:SetScript('OnTextChanged', function()
        local text = edit_box:GetText()
        local height = edit_box:GetHeight()
        edit_box:SetHeight(max(scroll_frame:GetHeight(), height))
    end)

    -- Status label at the bottom
    status_label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    status_label:SetPoint('BOTTOMLEFT', content, 'BOTTOMLEFT', 5, 5)
    status_label:SetText('Ready')

    -- Logout checkbox
    logout_checkbox = CreateFrame('CheckButton', nil, frame, 'UICheckButtonTemplate')
    logout_checkbox:SetPoint('BOTTOMLEFT', status_label, 'BOTTOMRIGHT', 10, -5)
    logout_checkbox:SetWidth(24)
    logout_checkbox:SetHeight(24)
    
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
