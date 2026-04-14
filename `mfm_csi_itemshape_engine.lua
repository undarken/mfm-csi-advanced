local PLUGIN_NAME = "JSCSI_ItemShape"

-- Store previous values to detect MCU movement
local last_jsfx = {}
for i = 0, 28 do last_jsfx[i] = -1 end

local last_item_ptr = nil
local last_item_vals = {}
for i = 0, 28 do last_item_vals[i] = -1 end

function loop()
    local num_sel = reaper.CountSelectedMediaItems(0)
    
    if num_sel > 0 then
        local first_item = reaper.GetSelectedMediaItem(0, 0)
        local track = reaper.GetMediaItem_Track(first_item)
        
        if track then
            local fx_idx = -1
            for i = 0, reaper.TrackFX_GetCount(track) - 1 do
                local _, fx_name = reaper.TrackFX_GetFXName(track, i, "")
                if fx_name:find(PLUGIN_NAME) then
                    fx_idx = i
                    break
                end
            end
            
            if fx_idx >= 0 then
                local take = reaper.GetActiveTake(first_item)
                local item_len = reaper.GetMediaItemInfo_Value(first_item, "D_LENGTH")
                
                -- Re-sync arrays if a new item is clicked
                if first_item ~= last_item_ptr then
                    for i = 0, 28 do
                        last_jsfx[i] = reaper.TrackFX_GetParamNormalized(track, fx_idx, i)
                        last_item_vals[i] = -1
                    end
                    last_item_ptr = first_item
                end
                
                -- READ ALL 29 MCU SLIDERS
                local jsfx = {}
                for i = 0, 28 do
                    jsfx[i] = reaper.TrackFX_GetParamNormalized(track, fx_idx, i)
                end
                
                -- READ NATIVE ITEM VALUES
                local i_pitch = take and reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH") or 0
                local i_playrate = take and reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") or 1.0
                local i_pan = take and reaper.GetMediaItemTakeInfo_Value(take, "D_PAN") or 0.0
                local i_fadein = reaper.GetMediaItemInfo_Value(first_item, "D_FADEINLEN")
                local i_fadeout = reaper.GetMediaItemInfo_Value(first_item, "D_FADEOUTLEN")
                local i_inshape = reaper.GetMediaItemInfo_Value(first_item, "C_FADEINSHAPE")
                local i_outshape = reaper.GetMediaItemInfo_Value(first_item, "C_FADEOUTSHAPE")
                local i_vol = reaper.GetMediaItemInfo_Value(first_item, "D_VOL")
                
                -- NORMALIZE ITEM VALUES FOR MCU (0.0 to 1.0)
                -- Pitch: -12 to +12 (Range of 24)
                local calc_pitch = (i_pitch + 12) / 24
                if calc_pitch < 0 then calc_pitch = 0 elseif calc_pitch > 1 then calc_pitch = 1 end
                
                -- Playrate: 0.1 to 4.0
                local calc_playrate = (i_playrate - 0.1) / 3.9
                if calc_playrate < 0 then calc_playrate = 0 elseif calc_playrate > 1 then calc_playrate = 1 end
                
                -- Pan: -1.0 (L) to 1.0 (R)
                local calc_pan = (i_pan + 1.0) / 2.0
                
                -- Fades and Volume
                local calc_fadein = item_len > 0 and (i_fadein / item_len) or 0
                local calc_fadeout = item_len > 0 and (i_fadeout / item_len) or 0
                local calc_inshape = i_inshape / 6
                local calc_outshape = i_outshape / 6
                local calc_vol = math.min(i_vol / 2.0, 1.0)

                -- ==========================================
                -- APPLY MCU CHANGES TO ALL SELECTED ITEMS
                -- ==========================================
                local needs_update = false
                
                -- CH 1: PITCH (Coarse, Fine, Stepped all map to param 0, 1, 2)
                if math.abs(jsfx[0] - last_jsfx[0]) > 0.001 or math.abs(jsfx[1] - last_jsfx[1]) > 0.001 or math.abs(jsfx[2] - last_jsfx[2]) > 0.001 then
                    -- Use the param that actually moved
                    local active_pitch_norm = jsfx[0]
                    if math.abs(jsfx[1] - last_jsfx[1]) > 0.001 then active_pitch_norm = jsfx[1] end
                    if math.abs(jsfx[2] - last_jsfx[2]) > 0.001 then active_pitch_norm = jsfx[2] end
                    
                    local new_pitch = (active_pitch_norm * 24) - 12
                    for i = 0, num_sel - 1 do
                        local t = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))
                        if t then reaper.SetMediaItemTakeInfo_Value(t, "D_PITCH", new_pitch) end
                    end
                    needs_update = true
                    last_jsfx[0], last_jsfx[1], last_jsfx[2] = active_pitch_norm, active_pitch_norm, active_pitch_norm
                    last_item_vals[0] = active_pitch_norm
                elseif math.abs(calc_pitch - last_item_vals[0]) > 0.001 then
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 0, calc_pitch)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 1, calc_pitch)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 2, calc_pitch)
                    last_jsfx[0], last_jsfx[1], last_jsfx[2] = calc_pitch, calc_pitch, calc_pitch
                    last_item_vals[0] = calc_pitch
                end

                -- CH 2: PLAYRATE (Param 3, 4, 5)
                if math.abs(jsfx[3] - last_jsfx[3]) > 0.001 or math.abs(jsfx[4] - last_jsfx[4]) > 0.001 or math.abs(jsfx[5] - last_jsfx[5]) > 0.001 then
                    local active_rate_norm = jsfx[3]
                    if math.abs(jsfx[4] - last_jsfx[4]) > 0.001 then active_rate_norm = jsfx[4] end
                    if math.abs(jsfx[5] - last_jsfx[5]) > 0.001 then active_rate_norm = jsfx[5] end
                    
                    local new_rate = (active_rate_norm * 3.9) + 0.1
                    for i = 0, num_sel - 1 do
                        local t = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))
                        if t then reaper.SetMediaItemTakeInfo_Value(t, "D_PLAYRATE", new_rate) end
                    end
                    needs_update = true
                    last_jsfx[3], last_jsfx[4], last_jsfx[5] = active_rate_norm, active_rate_norm, active_rate_norm
                    last_item_vals[3] = active_rate_norm
                elseif math.abs(calc_playrate - last_item_vals[3]) > 0.001 then
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 3, calc_playrate)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 4, calc_playrate)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 5, calc_playrate)
                    last_jsfx[3], last_jsfx[4], last_jsfx[5] = calc_playrate, calc_playrate, calc_playrate
                    last_item_vals[3] = calc_playrate
                end

                -- CH 3: PAN (Param 6, 7, 8)
                if math.abs(jsfx[6] - last_jsfx[6]) > 0.001 or math.abs(jsfx[7] - last_jsfx[7]) > 0.001 or math.abs(jsfx[8] - last_jsfx[8]) > 0.001 then
                    local active_pan_norm = jsfx[6]
                    if math.abs(jsfx[7] - last_jsfx[7]) > 0.001 then active_pan_norm = jsfx[7] end
                    if math.abs(jsfx[8] - last_jsfx[8]) > 0.001 then active_pan_norm = jsfx[8] end
                    
                    local new_pan = (active_pan_norm * 2.0) - 1.0
                    for i = 0, num_sel - 1 do
                        local t = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))
                        if t then reaper.SetMediaItemTakeInfo_Value(t, "D_PAN", new_pan) end
                    end
                    needs_update = true
                    last_jsfx[6], last_jsfx[7], last_jsfx[8] = active_pan_norm, active_pan_norm, active_pan_norm
                    last_item_vals[6] = active_pan_norm
                elseif math.abs(calc_pan - last_item_vals[6]) > 0.001 then
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 6, calc_pan)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 7, calc_pan)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 8, calc_pan)
                    last_jsfx[6], last_jsfx[7], last_jsfx[8] = calc_pan, calc_pan, calc_pan
                    last_item_vals[6] = calc_pan
                end

                -- CH 6: FADE IN LENGTH (Param 18, 19)
                if math.abs(jsfx[18] - last_jsfx[18]) > 0.001 or math.abs(jsfx[19] - last_jsfx[19]) > 0.001 then
                    local active_fadein = jsfx[18]
                    if math.abs(jsfx[19] - last_jsfx[19]) > 0.001 then active_fadein = jsfx[19] end
                    
                    for i = 0, num_sel - 1 do
                        local itm = reaper.GetSelectedMediaItem(0, i)
                        reaper.SetMediaItemInfo_Value(itm, "D_FADEINLEN", active_fadein * reaper.GetMediaItemInfo_Value(itm, "D_LENGTH"))
                    end
                    needs_update = true
                    last_jsfx[18], last_jsfx[19] = active_fadein, active_fadein
                    last_item_vals[18] = active_fadein
                elseif math.abs(calc_fadein - last_item_vals[18]) > 0.001 then
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 18, calc_fadein)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 19, calc_fadein)
                    last_jsfx[18], last_jsfx[19] = calc_fadein, calc_fadein
                    last_item_vals[18] = calc_fadein
                end

                -- CH 6: FADE IN SHAPE (Param 20, 21)
                if math.abs(jsfx[20] - last_jsfx[20]) > 0.001 or math.abs(jsfx[21] - last_jsfx[21]) > 0.001 then
                    local active_inshape = jsfx[20]
                    if math.abs(jsfx[21] - last_jsfx[21]) > 0.001 then active_inshape = jsfx[21] end
                    
                    local mapped_shape = math.floor((active_inshape * 6) + 0.5)
                    for i = 0, num_sel - 1 do
                        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "C_FADEINSHAPE", mapped_shape)
                    end
                    needs_update = true
                    last_jsfx[20], last_jsfx[21] = active_inshape, active_inshape
                    last_item_vals[20] = active_inshape
                elseif math.abs(calc_inshape - last_item_vals[20]) > 0.001 then
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 20, calc_inshape)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 21, calc_inshape)
                    last_jsfx[20], last_jsfx[21] = calc_inshape, calc_inshape
                    last_item_vals[20] = calc_inshape
                end

                -- CH 7: FADE OUT LENGTH (Param 22, 23)
                if math.abs(jsfx[22] - last_jsfx[22]) > 0.001 or math.abs(jsfx[23] - last_jsfx[23]) > 0.001 then
                    local active_fadeout = jsfx[22]
                    if math.abs(jsfx[23] - last_jsfx[23]) > 0.001 then active_fadeout = jsfx[23] end
                    
                    for i = 0, num_sel - 1 do
                        local itm = reaper.GetSelectedMediaItem(0, i)
                        reaper.SetMediaItemInfo_Value(itm, "D_FADEOUTLEN", active_fadeout * reaper.GetMediaItemInfo_Value(itm, "D_LENGTH"))
                    end
                    needs_update = true
                    last_jsfx[22], last_jsfx[23] = active_fadeout, active_fadeout
                    last_item_vals[22] = active_fadeout
                elseif math.abs(calc_fadeout - last_item_vals[22]) > 0.001 then
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 22, calc_fadeout)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 23, calc_fadeout)
                    last_jsfx[22], last_jsfx[23] = calc_fadeout, calc_fadeout
                    last_item_vals[22] = calc_fadeout
                end

                -- CH 7: FADE OUT SHAPE (Param 24, 25)
                if math.abs(jsfx[24] - last_jsfx[24]) > 0.001 or math.abs(jsfx[25] - last_jsfx[25]) > 0.001 then
                    local active_outshape = jsfx[24]
                    if math.abs(jsfx[25] - last_jsfx[25]) > 0.001 then active_outshape = jsfx[25] end
                    
                    local mapped_shape = math.floor((active_outshape * 6) + 0.5)
                    for i = 0, num_sel - 1 do
                        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "C_FADEOUTSHAPE", mapped_shape)
                    end
                    needs_update = true
                    last_jsfx[24], last_jsfx[25] = active_outshape, active_outshape
                    last_item_vals[24] = active_outshape
                elseif math.abs(calc_outshape - last_item_vals[24]) > 0.001 then
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 24, calc_outshape)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 25, calc_outshape)
                    last_jsfx[24], last_jsfx[25] = calc_outshape, calc_outshape
                    last_item_vals[24] = calc_outshape
                end

                -- CH 8: VOLUME (Param 26, 27, 28)
                if math.abs(jsfx[26] - last_jsfx[26]) > 0.001 or math.abs(jsfx[27] - last_jsfx[27]) > 0.001 or math.abs(jsfx[28] - last_jsfx[28]) > 0.001 then
                    local active_vol = jsfx[26]
                    if math.abs(jsfx[27] - last_jsfx[27]) > 0.001 then active_vol = jsfx[27] end
                    if math.abs(jsfx[28] - last_jsfx[28]) > 0.001 then active_vol = jsfx[28] end
                    
                    for i = 0, num_sel - 1 do
                        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "D_VOL", active_vol * 2.0)
                    end
                    needs_update = true
                    last_jsfx[26], last_jsfx[27], last_jsfx[28] = active_vol, active_vol, active_vol
                    last_item_vals[26] = active_vol
                elseif math.abs(calc_vol - last_item_vals[26]) > 0.001 then
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 26, calc_vol)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 27, calc_vol)
                    reaper.TrackFX_SetParamNormalized(track, fx_idx, 28, calc_vol)
                    last_jsfx[26], last_jsfx[27], last_jsfx[28] = calc_vol, calc_vol, calc_vol
                    last_item_vals[26] = calc_vol
                end

                if needs_update then
                    for i = 0, num_sel - 1 do
                        reaper.UpdateItemInProject(reaper.GetSelectedMediaItem(0, i))
                    end
                end
            end
        end
    end
    reaper.defer(loop)
end

loop()
