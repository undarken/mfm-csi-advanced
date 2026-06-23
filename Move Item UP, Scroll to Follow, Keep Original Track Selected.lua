reaper.PreventUIRefresh(1)

-- 1. Save currently selected tracks
local sel_tracks = {}
for i = 0, reaper.CountSelectedTracks(0) - 1 do
    table.insert(sel_tracks, reaper.GetSelectedTrack(0, i))
end

-- 2. Move selected items up one track
reaper.Main_OnCommand(40117, 0) 

-- 3. Scroll to the item's new track
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
    local item_track = reaper.GetMediaItem_Track(item)
    if item_track then
        reaper.SetOnlyTrackSelected(item_track)
        reaper.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
    end
end

-- 4. Restore the original track selection
reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks
for _, t in ipairs(sel_tracks) do
    reaper.SetTrackSelected(t, true)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

