module 'aux.tabs.wppa'

local aux = require 'aux'

local tab = aux.tab 'WPPA'

local query_list = {}
local current_index = 0
local is_running = false
local logout_when_finished = false

-- Forward declarations
local update_status
local process_next_query

function tab.OPEN()
    frame:Show()
end

function tab.CLOSE()
    frame:Hide()
end

function M.start_queries()
    if is_running then return end
    
    local text = edit_box:GetText()
    local lines = aux.split(text, '\n')
    
    -- Clear the query list
    query_list = {}
    
    -- Process each line: trim and ignore empty lines
    for _, line in ipairs(lines) do
        local trimmed = aux.trim(line)
        if trimmed ~= '' then
            tinsert(query_list, trimmed)
        end
    end
    
    if getn(query_list) == 0 then
        aux.print('WPPA: No items to search')
        return
    end
    
    -- Store logout preference
    logout_when_finished = logout_checkbox:GetChecked()
    
    -- Start processing
    is_running = true
    current_index = 0
    update_status()
    run_button:Disable()
    
    -- Start the first query
    process_next_query()
end

function process_next_query()
    current_index = current_index + 1
    
    if current_index > getn(query_list) then
        -- All queries complete
        is_running = false
        update_status()
        run_button:Enable()
        
        aux.print('WPPA: All queries complete')
        
        -- Logout if requested
        if logout_when_finished then
            aux.print('WPPA: Logging out...')
            Logout()
        end
        return
    end
    
    -- Get the current query
    local query = query_list[current_index]
    update_status()
    
    -- Execute search with callback for next query
    Aux_Search(query .. '/exact', function()
        -- This callback is called when the search completes
        -- Process the next query sequentially
        process_next_query()
    end)
end

function update_status()
    if is_running then
        status_label:SetText(format('Processing: %d / %d', current_index, getn(query_list)))
    else
        status_label:SetText('Ready')
    end
end

function M.is_running()
    return is_running
end
