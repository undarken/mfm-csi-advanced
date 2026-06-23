local num_sel = reaper.CountSelectedMediaItems(0)
if num_sel == 0 then return end

-- Boundary Guard: Prevent moving past the last track
local total_tracks = reaper.CountTracks(0)
local last_track = reaper.GetTrack(0, total_tracks - 1)

for i = 0, num_sel - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    if track == last_track then
        return -- Abort silently; do not create a new track
    end
end

-- 1. Save currently selected tracks
local sel_tracks = {}
for i = 0, reaper.CountSelectedTracks(0) - 1 do
    sel_tracks[i+1] = reaper.GetSelectedTrack(0, i)
end

-- 2. Move item down one track
reaper.Main_OnCommand(40118, 0) 

-- 3. Temporarily select the item's new track and scroll to it
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
    local new_track = reaper.GetMediaItem_Track(item)
    if new_track then
        reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
        reaper.SetTrackSelected(new_track, true)
        reaper.Main_OnCommand(40913, 0) -- Vertical scroll selected tracks into view
    end
end

-- 4. Restore original track selection AFTER the UI updates
local function RestoreSelection()
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    for i = 1, #sel_tracks do
        reaper.SetTrackSelected(sel_tracks[i], true)
    end
end

reaper.defer(RestoreSelection)
