module 'aux.tabs.wppa'

local aux = require 'aux'
local filter_util = require 'aux.util.filter'
local scan = require 'aux.core.scan'

local tab = aux.tab 'WPPA'

local query_list = {}
local current_index = 0
local is_running = false
local logout_when_finished = false

local shopping_list = {}
local shopping_index = 0
local is_shopping = false

-- Forward declarations
local update_status
local process_next_query
local process_next_shopping_item

function tab.OPEN()
    frame:Show()
end

function tab.CLOSE()
    frame:Hide()
end

function M.start_queries(should_logout)
    if is_running or is_shopping then return end
    
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
    logout_when_finished = should_logout
    
    -- Start processing
    is_running = true
    current_index = 0
    update_status()
    run_button:Disable()
    run_logout_button:Disable()
    buy_button:Disable()
    
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
        run_logout_button:Enable()
        buy_button:Enable()
        
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

function M.start_shopping_list()
    if is_running or is_shopping then return end

    local text = edit_box:GetText()
    local lines = aux.split(text, '\n')

    shopping_list = {}

    for _, line in ipairs(lines) do
        local trimmed = aux.trim(line)
        if trimmed ~= '' then
            -- Parse format: name;quantity;max_gold (max_gold in copper)
            local parts = aux.split(trimmed, ';')
            if getn(parts) == 3 then
                local name = aux.trim(parts[1])
                local max_qty = tonumber(aux.trim(parts[2]))
                local max_gold = tonumber(aux.trim(parts[3]))
                if name ~= '' and max_qty and max_qty > 0 and max_gold and max_gold > 0 then
                    tinsert(shopping_list, {name=name, max_qty=max_qty, max_gold=max_gold})
                else
                    aux.print('WPPA: Invalid shopping list entry: ' .. trimmed)
                end
            else
                aux.print('WPPA: Invalid format (expected name;qty;maxgold): ' .. trimmed)
            end
        end
    end

    if getn(shopping_list) == 0 then
        aux.print('WPPA: No valid items in shopping list')
        return
    end

    is_shopping = true
    shopping_index = 0
    update_status()
    run_button:Disable()
    run_logout_button:Disable()
    buy_button:Disable()

    process_next_shopping_item()
end

function process_next_shopping_item()
    shopping_index = shopping_index + 1

    if shopping_index > getn(shopping_list) then
        is_shopping = false
        update_status()
        run_button:Enable()
        run_logout_button:Enable()
        buy_button:Enable()
        aux.print('WPPA: Shopping list complete')
        return
    end

    local item = shopping_list[shopping_index]
    update_status()

    local queries, error = filter_util.queries(item.name .. '/exact')
    if not queries then
        aux.print('WPPA: Invalid item name: ' .. item.name .. ' (' .. (error or 'unknown error') .. ')')
        process_next_shopping_item()
        return
    end

    -- Stateful tracking for this item's purchase
    local bought_qty = 0
    local spent_gold = 0
    local max_qty = item.max_qty
    local max_gold = item.max_gold

    local function shopping_validator(auction_info)
        if auction_info.buyout_price <= 0 then return false end
        local stack_size = auction_info.aux_quantity
        -- Buy only if this stack fits within remaining quantity and gold limits
        if bought_qty + stack_size <= max_qty and spent_gold + auction_info.buyout_price <= max_gold then
            bought_qty = bought_qty + stack_size
            spent_gold = spent_gold + auction_info.buyout_price
            return true
        end
        return false
    end

    scan.start{
        type = 'list',
        queries = queries,
        auto_buy_validator = shopping_validator,
        on_complete = function()
            process_next_shopping_item()
        end,
        on_abort = function()
            is_shopping = false
            update_status()
            run_button:Enable()
            run_logout_button:Enable()
            buy_button:Enable()
        end,
    }
end

function update_status()
    if is_running then
        status_label:SetText(format('Processing: %d / %d', current_index, getn(query_list)))
    elseif is_shopping then
        status_label:SetText(format('Buying: %d / %d', shopping_index, getn(shopping_list)))
    else
        status_label:SetText('Ready')
    end
end

function M.is_running()
    return is_running or is_shopping
end
