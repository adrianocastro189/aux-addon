module 'aux.util.export'

local aux = require 'aux'
local info = require 'aux.util.info'

function M.export_search_results(search_records)
    if not _G.aux_export then
        _G.aux_export = {}
    end
    
    -- Group records by item name
    local items_map = {}
    for _, record in ipairs(search_records) do
        local item_name = record.name
        if not items_map[item_name] then
            items_map[item_name] = {}
        end
        tinsert(items_map[item_name], record)
    end
    
    -- Clear previous export data and export each item's records
    _G.aux_export = {}
    
    for item_name, records in pairs(items_map) do
        _G.aux_export[item_name] = {}
        
        for _, record in ipairs(records) do
            local export_record = {
                auctions = 1, -- Each record represents one auction
                stack_size = record.aux_quantity,
                time_left = record.duration,
                seller = record.owner or '?',
                auction_bid_per_item = ceil(record.unit_bid_price),
                auction_buyout_per_item = ceil(record.unit_buyout_price),
            }
            
            tinsert(_G.aux_export[item_name], export_record)
        end
    end
end

