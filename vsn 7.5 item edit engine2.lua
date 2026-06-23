-- mfm_csi_itemshape_engine.lua
-- VERSION: 8.2g - MATCH FADE POINT, PREVENT FADE-IN/OUT DRIFT
-- Based directly on the original 8.2 bias model.
-- Center is derived from the actual fade point, not just fade-out length.
-- On every center move, existing fade-in/out values are cleared and rebuilt from the overlap,
-- so it does not drift into independent fade-in/fade-out behavior.

local PLUGIN_NAME = "JSCSI_ItemShape"
local last_jsfx = {}
for i=0,45 do last_jsfx[i] = -1 end
local last_ptr = nil
local XFADE_EPS = 0.001

local function clamp(v,a,b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function get_fx_idx(trk)
  for i=0, reaper.TrackFX_GetCount(trk)-1 do
    local _, fn = reaper.TrackFX_GetFXName(trk, i, "")
    if fn and fn:find(PLUGIN_NAME) then return i end
  end
  return -1
end

local function shape_from_norm(v)
  return math.floor(clamp(v,0,1) * 6 + 0.5)
end

local function norm_from_shape(s)
  return clamp((s or 0) / 6, 0, 1)
end

local function item_len(i) return reaper.GetMediaItemInfo_Value(i, "D_LENGTH") end
local function item_pos(i) return reaper.GetMediaItemInfo_Value(i, "D_POSITION") end
local function item_right(i) return item_pos(i) + item_len(i) end

local function next_item_on_track(trk, item)
  local n = reaper.CountTrackMediaItems(trk)
  local best, best_pos = nil, math.huge
  local cur_pos = item_pos(item)
  for i=0,n-1 do
    local it = reaper.GetTrackMediaItem(trk, i)
    if it ~= item then
      local pos = item_pos(it)
      if pos > cur_pos and pos < best_pos then
        best = it
        best_pos = pos
      end
    end
  end
  return best
end

local function set_item_fade(item, which, len, shape)
  len = math.max(0, len)
  if which == 'in' then
    reaper.SetMediaItemInfo_Value(item, 'D_FADEINLEN', 0)
    reaper.SetMediaItemInfo_Value(item, 'D_FADEINLEN_AUTO', len)
    reaper.SetMediaItemInfo_Value(item, 'C_FADEINSHAPE', shape)
  else
    reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', 0)
    reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN_AUTO', len)
    reaper.SetMediaItemInfo_Value(item, 'C_FADEOUTSHAPE', shape)
  end
end

local function get_pitch_norm(t)
  return t and clamp((reaper.GetMediaItemTakeInfo_Value(t, "D_PITCH") + 12) / 24, 0, 1) or 0.5
end
local function set_pitch_norm(t, v)
  if t then reaper.SetMediaItemTakeInfo_Value(t, "D_PITCH", clamp(v,0,1) * 24 - 12) end
end

local function get_rate_norm(t)
  return t and clamp((reaper.GetMediaItemTakeInfo_Value(t, "D_PLAYRATE") - 0.1) / 3.9, 0, 1) or 0
end
local function set_rate_norm(t, v)
  if t then reaper.SetMediaItemTakeInfo_Value(t, "D_PLAYRATE", clamp(v,0,1) * 3.9 + 0.1) end
end

local function get_pan_norm(t)
  return t and clamp((reaper.GetMediaItemTakeInfo_Value(t, "D_PAN") + 1) / 2, 0, 1) or 0.5
end
local function set_pan_norm(t, v)
  if t then reaper.SetMediaItemTakeInfo_Value(t, "D_PAN", clamp(v,0,1) * 2 - 1) end
end

local function get_fadein_len_norm(i)
  local l = math.max(item_len(i), 0.000001)
  local v = reaper.GetMediaItemInfo_Value(i, "D_FADEINLEN_AUTO")
  if v < 0 then v = reaper.GetMediaItemInfo_Value(i, "D_FADEINLEN") end
  return clamp(v / l, 0, 1)
end
local function set_fadein_len_norm(i, v)
  reaper.SetMediaItemInfo_Value(i, "D_FADEINLEN_AUTO", clamp(v,0,1) * item_len(i))
end

local function get_fadeout_len_norm(i)
  local l = math.max(item_len(i), 0.000001)
  local v = reaper.GetMediaItemInfo_Value(i, "D_FADEOUTLEN_AUTO")
  if v < 0 then v = reaper.GetMediaItemInfo_Value(i, "D_FADEOUTLEN") end
  return clamp(v / l, 0, 1)
end
local function set_fadeout_len_norm(i, v)
  reaper.SetMediaItemInfo_Value(i, "D_FADEOUTLEN_AUTO", clamp(v,0,1) * item_len(i))
end

local function get_fadein_shape_norm(i)
  return norm_from_shape(reaper.GetMediaItemInfo_Value(i, "C_FADEINSHAPE"))
end
local function set_fadein_shape_norm(i, v)
  reaper.SetMediaItemInfo_Value(i, "C_FADEINSHAPE", shape_from_norm(v))
end

local function get_fadeout_shape_norm(i)
  return norm_from_shape(reaper.GetMediaItemInfo_Value(i, "C_FADEOUTSHAPE"))
end
local function set_fadeout_shape_norm(i, v)
  reaper.SetMediaItemInfo_Value(i, "C_FADEOUTSHAPE", shape_from_norm(v))
end

local function get_vol_norm(i)
  return clamp(reaper.GetMediaItemInfo_Value(i, "D_VOL") / 2, 0, 1)
end
local function set_vol_norm(i, v)
  reaper.SetMediaItemInfo_Value(i, "D_VOL", clamp(v,0,1) * 2)
end

local function get_crossfade_pair(item)
  local trk = reaper.GetMediaItem_Track(item)
  if not trk then return nil, nil end
  local right = next_item_on_track(trk, item)
  if not right then return nil, nil end
  return item, right
end

local function get_overlap_info(left, right)
  local lpos, rpos = item_pos(left), item_pos(right)
  local lend, rend = item_right(left), item_right(right)
  local startp = math.max(lpos, rpos)
  local endp = math.min(lend, rend)
  local overlap = math.max(0, endp - startp)
  local center = startp + overlap * 0.5
  return startp, endp, overlap, center
end

local function has_real_crossfade(left, right)
  if not left or not right then return false end
  local _, _, overlap = get_overlap_info(left, right)
  return overlap > XFADE_EPS
end

local function get_xfade_len_norm(left, right)
  local _, _, overlap = get_overlap_info(left, right)
  local basis = math.max(math.min(item_len(left), item_len(right)), 0.000001)
  return clamp(overlap / basis, 0, 1)
end

local function set_crossfade_fades_for_overlap(left, right, overlap, bias)
  overlap = math.max(0.000001, math.min(overlap, item_len(left), item_len(right)))
  bias = clamp(bias, 0, 1)

  local left_out = overlap * (1 - bias * 0.5)
  local right_in = overlap * (0.5 + bias * 0.5)

  left_out = clamp(left_out, 0.000001, item_len(left))
  right_in = clamp(right_in, 0.000001, item_len(right))

  local shapeL = reaper.GetMediaItemInfo_Value(left, 'C_FADEOUTSHAPE')
  local shapeR = reaper.GetMediaItemInfo_Value(right, 'C_FADEINSHAPE')
  set_item_fade(left, 'out', left_out, shapeL)
  set_item_fade(right, 'in', right_in, shapeR)
end

local function set_xfade_len_norm(left, right, v)
  local _, _, old_overlap = get_overlap_info(left, right)
  local basis = math.max(math.min(item_len(left), item_len(right)), 0.000001)
  local new_overlap = clamp(v,0,1) * basis
  local lend = item_right(left)
  local new_rpos
  if old_overlap > XFADE_EPS then
    local _, _, _, old_center = get_overlap_info(left, right)
    new_rpos = old_center - new_overlap * 0.5
  else
    new_rpos = lend - new_overlap
  end
  reaper.SetMediaItemInfo_Value(right, "D_POSITION", new_rpos)
  set_crossfade_fades_for_overlap(left, right, new_overlap, 0.5)
end

local function get_xfade_center_norm(left, right)
  if not has_real_crossfade(left, right) then return 0.5 end
  local fade_out = reaper.GetMediaItemInfo_Value(left, "D_FADEOUTLEN_AUTO")
  if fade_out < 0 then fade_out = reaper.GetMediaItemInfo_Value(left, "D_FADEOUTLEN") end
  local fade_in = reaper.GetMediaItemInfo_Value(right, "D_FADEINLEN_AUTO")
  if fade_in < 0 then fade_in = reaper.GetMediaItemInfo_Value(right, "D_FADEINLEN") end
  local sum = fade_out + fade_in
  if sum <= XFADE_EPS then return 0.5 end
  local norm = (fade_in / sum - 0.5) * 2
  return clamp(norm, 0, 1)
end

local function set_xfade_center_norm(left, right, v)
  if not has_real_crossfade(left, right) then return false end
  local _, _, overlap = get_overlap_info(left, right)
  set_crossfade_fades_for_overlap(left, right, overlap, clamp(v,0,1))
  return true
end

local function get_xfade_shape_norm(left, right)
  return norm_from_shape(reaper.GetMediaItemInfo_Value(left, "C_FADEOUTSHAPE"))
end
local function set_xfade_shape_norm(left, right, v)
  local s = shape_from_norm(v)
  reaper.SetMediaItemInfo_Value(left, "C_FADEOUTSHAPE", s)
  reaper.SetMediaItemInfo_Value(right, "C_FADEINSHAPE", s)
end

local GROUPS = {
  pitch = {coarse=0, fine=1, step=2, lock=29},
  rate = {coarse=3, fine=4, step=5, lock=30},
  pan = {coarse=6, fine=7, step=8, lock=31},
  xctr = {coarse=9, fine=10, shape1=11, shape2=12, lock=32},
  xlen = {coarse=13, fine=14, step=17, shape1=15, shape2=16, lock=33},
  fin  = {coarse=18, fine=19, step=18, shape1=20, shape2=21, lock=34},
  fout = {coarse=22, fine=23, step=22, shape1=24, shape2=25, lock=35},
  vol  = {coarse=26, fine=27, step=28, lock=36},
}

local FINE_SCALE = {
  pitch = 0.03,
  rate  = 0.015,
  pan   = 0.015,
  xctr  = 0.01,
  xlen  = 0.01,
  fin   = 0.01,
  fout  = 0.01,
  vol   = 0.015,
}

local function moved(js, idx)
  if not idx then return false, 0 end
  local d = js[idx] - last_jsfx[idx]
  return math.abs(d) > 0.0005, d
end

local function sync_param(trk, fx_idx, idx, value)
  if idx then
    value = clamp(value,0,1)
    reaper.TrackFX_SetParamNormalized(trk, fx_idx, idx, value)
    last_jsfx[idx] = value
  end
end

function loop()
  local n_sel = reaper.CountSelectedMediaItems(0)
  if n_sel > 0 then
    local first_itm = reaper.GetSelectedMediaItem(0, 0)
    local trk = reaper.GetMediaItem_Track(first_itm)
    if trk then
      local fx_idx = get_fx_idx(trk)
      if fx_idx >= 0 then
        local js = {}
        for i=0,45 do js[i] = reaper.TrackFX_GetParamNormalized(trk, fx_idx, i) end

        if first_itm ~= last_ptr then
          for i=0,45 do last_jsfx[i] = js[i] end
          last_ptr = first_itm
        end

        local tk = reaper.GetActiveTake(first_itm)
        local upd = false
        local left, right = get_crossfade_pair(first_itm)

        do local g=GROUPS.pitch
          if js[g.lock] <= 0.5 then
            local m,d = moved(js,g.fine)
            if m then local v = clamp(get_pitch_norm(tk) + d * FINE_SCALE.pitch, 0, 1); for i=0,n_sel-1 do set_pitch_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.fine,js[g.fine]); upd=true
            else local mc = moved(js,g.coarse)
              if mc then local v=js[g.coarse]; for i=0,n_sel-1 do set_pitch_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.coarse,v); upd=true
              else local ms = moved(js,g.step)
                if ms then local v=js[g.step]; for i=0,n_sel-1 do set_pitch_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.step,v); upd=true end
              end
            end
          end
        end

        do local g=GROUPS.rate
          if js[g.lock] <= 0.5 then
            local m,d = moved(js,g.fine)
            if m then local v = clamp(get_rate_norm(tk) + d * FINE_SCALE.rate, 0, 1); for i=0,n_sel-1 do set_rate_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.fine,js[g.fine]); upd=true
            else local mc = moved(js,g.coarse)
              if mc then local v=js[g.coarse]; for i=0,n_sel-1 do set_rate_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.coarse,v); upd=true
              else local ms = moved(js,g.step)
                if ms then local v=js[g.step]; for i=0,n_sel-1 do set_rate_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.step,v); upd=true end
              end
            end
          end
        end

        do local g=GROUPS.pan
          if js[g.lock] <= 0.5 then
            local m,d = moved(js,g.fine)
            if m then local v = clamp(get_pan_norm(tk) + d * FINE_SCALE.pan, 0, 1); for i=0,n_sel-1 do set_pan_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.fine,js[g.fine]); upd=true
            else local mc = moved(js,g.coarse)
              if mc then local v=js[g.coarse]; for i=0,n_sel-1 do set_pan_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.coarse,v); upd=true
              else local ms = moved(js,g.step)
                if ms then local v=js[g.step]; for i=0,n_sel-1 do set_pan_norm(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0,i)), v) end; sync_param(trk,fx_idx,g.step,v); upd=true end
              end
            end
          end
        end

        do local g=GROUPS.xctr
          if left and right and js[g.lock] <= 0.5 then
            local m,d = moved(js,g.fine)
            if m then
              if has_real_crossfade(left,right) then
                local v = clamp(get_xfade_center_norm(left,right) + d * FINE_SCALE.xctr, 0, 1)
                if set_xfade_center_norm(left,right,v) then upd=true end
              end
              sync_param(trk,fx_idx,g.fine,js[g.fine])
            else
              local mc = moved(js,g.coarse)
              if mc then
                if has_real_crossfade(left,right) then
                  if set_xfade_center_norm(left,right,js[g.coarse]) then upd=true end
                end
                sync_param(trk,fx_idx,g.coarse,js[g.coarse])
              else
                local ms1 = moved(js,g.shape1)
                if ms1 then local v=js[g.shape1]; set_xfade_shape_norm(left,right,v); sync_param(trk,fx_idx,g.shape1,v); upd=true
                else local ms2 = moved(js,g.shape2)
                  if ms2 then local v=js[g.shape2]; set_xfade_shape_norm(left,right,v); sync_param(trk,fx_idx,g.shape2,v); upd=true end
                end
              end
            end
          end
        end

        do local g=GROUPS.xlen
          if left and right and js[g.lock] <= 0.5 then
            local m,d = moved(js,g.fine)
            if m then local v = clamp(get_xfade_len_norm(left,right) + d * FINE_SCALE.xlen, 0, 1); set_xfade_len_norm(left,right,v); sync_param(trk,fx_idx,g.fine,js[g.fine]); upd=true
            else local mc = moved(js,g.coarse)
              if mc then local v=js[g.coarse]; set_xfade_len_norm(left,right,v); sync_param(trk,fx_idx,g.coarse,v); upd=true
              else local mst = moved(js,g.step)
                if mst then local v=js[g.step]; set_xfade_len_norm(left,right,v); sync_param(trk,fx_idx,g.step,v); upd=true
                else local ms1 = moved(js,g.shape1)
                  if ms1 then local v=js[g.shape1]; set_xfade_shape_norm(left,right,v); sync_param(trk,fx_idx,g.shape1,v); upd=true
                  else local ms2 = moved(js,g.shape2)
                    if ms2 then local v=js[g.shape2]; set_xfade_shape_norm(left,right,v); sync_param(trk,fx_idx,g.shape2,v); upd=true end
                  end
                end
              end
            end
          end
        end

        do local g=GROUPS.fin
          if js[g.lock] <= 0.5 then
            local m,d = moved(js,g.fine)
            if m then for i=0,n_sel-1 do local it=reaper.GetSelectedMediaItem(0,i); set_fadein_len_norm(it, clamp(get_fadein_len_norm(it)+d*FINE_SCALE.fin,0,1)) end; sync_param(trk,fx_idx,g.fine,js[g.fine]); upd=true
            else local mc = moved(js,g.coarse)
              if mc then local v=js[g.coarse]; for i=0,n_sel-1 do set_fadein_len_norm(reaper.GetSelectedMediaItem(0,i), v) end; sync_param(trk,fx_idx,g.coarse,v); upd=true
              else local ms1 = moved(js,g.shape1)
                if ms1 then local v=js[g.shape1]; for i=0,n_sel-1 do set_fadein_shape_norm(reaper.GetSelectedMediaItem(0,i), v) end; sync_param(trk,fx_idx,g.shape1,v); upd=true
                else local ms2 = moved(js,g.shape2)
                  if ms2 then local v=js[g.shape2]; for i=0,n_sel-1 do set_fadein_shape_norm(reaper.GetSelectedMediaItem(0,i), v) end; sync_param(trk,fx_idx,g.shape2,v); upd=true end
                end
              end
            end
          end
        end

        do local g=GROUPS.fout
          if js[g.lock] <= 0.5 then
            local m,d = moved(js,g.fine)
            if m then for i=0,n_sel-1 do local it=reaper.GetSelectedMediaItem(0,i); set_fadeout_len_norm(it, clamp(get_fadeout_len_norm(it)+d*FINE_SCALE.fout,0,1)) end; sync_param(trk,fx_idx,g.fine,js[g.fine]); upd=true
            else local mc = moved(js,g.coarse)
              if mc then local v=js[g.coarse]; for i=0,n_sel-1 do set_fadeout_len_norm(reaper.GetSelectedMediaItem(0,i), v) end; sync_param(trk,fx_idx,g.coarse,v); upd=true
              else local ms1 = moved(js,g.shape1)
                if ms1 then local v=js[g.shape1]; for i=0,n_sel-1 do set_fadeout_shape_norm(reaper.GetSelectedMediaItem(0,i), v) end; sync_param(trk,fx_idx,g.shape1,v); upd=true
                else local ms2 = moved(js,g.shape2)
                  if ms2 then local v=js[g.shape2]; for i=0,n_sel-1 do set_fadeout_shape_norm(reaper.GetSelectedMediaItem(0,i), v) end; sync_param(trk,fx_idx,g.shape2,v); upd=true end
                end
              end
            end
          end
        end

        do local g=GROUPS.vol
          if js[g.lock] <= 0.5 then
            local m,d = moved(js,g.fine)
            if m then for i=0,n_sel-1 do local it=reaper.GetSelectedMediaItem(0,i); set_vol_norm(it, clamp(get_vol_norm(it)+d*FINE_SCALE.vol,0,1)) end; sync_param(trk,fx_idx,g.fine,js[g.fine]); upd=true
            else local mc = moved(js,g.coarse)
              if mc then local v=js[g.coarse]; for i=0,n_sel-1 do set_vol_norm(reaper.GetSelectedMediaItem(0,i), v) end; sync_param(trk,fx_idx,g.coarse,v); upd=true
              else local ms = moved(js,g.step)
                if ms then local v=js[g.step]; for i=0,n_sel-1 do set_vol_norm(reaper.GetSelectedMediaItem(0,i), v) end; sync_param(trk,fx_idx,g.step,v); upd=true end
              end
            end
          end
        end

        if upd then
          for i=0,n_sel-1 do reaper.UpdateItemInProject(reaper.GetSelectedMediaItem(0, i)) end
        end
      end
    end
  end
  reaper.defer(loop)
end
loop()

