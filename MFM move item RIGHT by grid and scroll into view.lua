reaper.PreventUIRefresh(1)

-- 1. Correct Action ID: Move right by grid size
reaper.Main_OnCommand(40794, 0) 

-- 2. Scroll Arrange View if item goes off screen
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    
    -- Requires exactly 6 arguments, returns 2 values
    local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
    
    if start_time and end_time then
        local view_length = end_time - start_time
        local margin = view_length * 0.05 -- 5% visual padding
        
        -- If item is past the right edge
        if pos > end_time - margin then
            local new_start = math.max(0, pos - view_length + margin)
            reaper.GetSet_ArrangeView2(0, true, 0, 0, new_start, new_start + view_length)
            
        -- If item is somehow past the left edge
        elseif pos < start_time + margin then
            local new_start = math.max(0, pos - margin)
            reaper.GetSet_ArrangeView2(0, true, 0, 0, new_start, new_start + view_length)
        end
    end
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

