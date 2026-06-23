-- Move Item LEFT by Grid (Scroll Follow)
reaper.PreventUIRefresh(1)

-- 1. Move selected items left by grid size
reaper.Main_OnCommand(40119, 0) -- 40119 is strictly "Move Left"

-- 2. Scroll Arrange View if item goes off screen
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    
    -- Read current arrange view (requires exactly 4 arguments)
    local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    
    -- Failsafe to prevent "nil" math errors
    if start_time and end_time then
        local view_length = end_time - start_time
        local margin = view_length * 0.05 -- 5% visual padding
        
        -- If item is past the left edge
        if pos < start_time + margin then
            local new_start = math.max(0, pos - margin)
            -- Write new arrange view (requires exactly 6 arguments)
            reaper.GetSet_ArrangeView2(0, true, 0, 0, new_start, new_start + view_length)
            
        -- If item is somehow past the right edge
        elseif pos > end_time - margin then
            local new_start = math.max(0, pos - view_length + margin)
            reaper.GetSet_ArrangeView2(0, true, 0, 0, new_start, new_start + view_length)
        end
    end
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

