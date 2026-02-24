module 'aux.tabs.wppa'

local aux = require 'aux'
local scan_util = require 'aux.util.scan'
local search_tab = require 'aux.tabs.search'

local tab = aux.tab 'WPPA'

local query_list = {}
local current_index = 0
local is_running = false
local logout_when_finished = false

local shopping_list = {}
local shopping_index = 0
local is_shopping = false
local shopping_close_listener

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
                local max_qty = tonumber((aux.trim(parts[2])))
                local max_gold = tonumber((aux.trim(parts[3])))
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

    -- Clean up shopping state if the AH is closed mid-process
    shopping_close_listener = aux.event_listener('AUCTION_HOUSE_CLOSED', function(kill)
        kill()
        shopping_close_listener = nil
        if is_shopping then
            is_shopping = false
            update_status()
            run_button:Enable()
            run_logout_button:Enable()
            buy_button:Enable()
        end
    end)

    process_next_shopping_item()
end

function process_next_shopping_item()
    shopping_index = shopping_index + 1

    if shopping_index > getn(shopping_list) then
        if shopping_close_listener then
            aux.kill_listener(shopping_close_listener)
            shopping_close_listener = nil
        end
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

    local max_qty = item.max_qty
    local max_gold = item.max_gold

    -- Pass 1: Full scan via Search tab so all auctions are collected and progress is visible.
    -- The Search tab is activated automatically by search_tab.search().
    search_tab.search(item.name .. '/exact', function(records)
        -- Filter to auctions with a buyout that are not owned by the player
        local buyable = {}
        for _, auction in records do
            if auction.buyout_price > 0 and auction.owner ~= UnitName('player') then
                tinsert(buyable, auction)
            end
        end

        -- Sort by unit buyout price ascending (cheapest per item first)
        sort(buyable, function(a, b)
            return a.unit_buyout_price < b.unit_buyout_price
        end)

        local bought_qty = 0
        local spent_gold = 0
        local buy_index = 0

        -- No-op status bar passed to scan_util.find (UI updates not needed during buy phase)
        local noop_status_bar = {
            update_status = function() end,
            set_text = function() end,
        }

        local function on_abort_shopping()
            if shopping_close_listener then
                aux.kill_listener(shopping_close_listener)
                shopping_close_listener = nil
            end
            if is_shopping then
                is_shopping = false
                update_status()
                run_button:Enable()
                run_logout_button:Enable()
                buy_button:Enable()
            end
        end

        -- Pass 2: Walk the sorted list and buy each auction cheapest-first.
        local function buy_next()
            buy_index = buy_index + 1
            if buy_index > getn(buyable) or bought_qty >= max_qty then
                return process_next_shopping_item()
            end

            local auction = buyable[buy_index]

            local stack_size = auction.aux_quantity
            if bought_qty + stack_size > max_qty or spent_gold + auction.buyout_price > max_gold then
                return buy_next()
            end

            -- Locate the auction on its original page before buying
            scan_util.find(
                auction,
                noop_status_bar,
                on_abort_shopping,
                function() return buy_next() end,
                function(index)
                    aux.place_bid('list', index, auction.buyout_price, function()
                        bought_qty = bought_qty + stack_size
                        spent_gold = spent_gold + auction.buyout_price
                        buy_next()
                    end)
                end
            )
        end

        buy_next()
    end)
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
