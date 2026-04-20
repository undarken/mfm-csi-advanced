local engine_path = "./`mfm_csi_itemshape_engine.lua"

local state = {
  params = {},
  items = {
    {
      ptr = "item_1",
      len = 10.0,
      take = { pitch = 0.0, playrate = 1.0, pan = 0.0 },
      fadein = 0.0,
      fadeout = 0.0,
      inshape = 0,
      outshape = 0,
      vol = 1.0
    },
    {
      ptr = "item_2",
      len = 8.0,
      take = { pitch = 0.0, playrate = 1.0, pan = 0.0 },
      fadein = 0.0,
      fadeout = 0.0,
      inshape = 0,
      outshape = 0,
      vol = 1.0
    }
  },
  defer_count = 0,
  update_count = 0
}

for i = 0, 28 do
  state.params[i] = 0.5
end

local function assert_close(actual, expected, eps, label)
  if math.abs(actual - expected) > eps then
    error(label .. " expected " .. tostring(expected) .. " got " .. tostring(actual))
  end
end

local reaper = {}

function reaper.CountSelectedMediaItems(_)
  return #state.items
end

function reaper.GetSelectedMediaItem(_, idx)
  return state.items[idx + 1]
end

function reaper.GetMediaItem_Track(_)
  return "track_1"
end

function reaper.TrackFX_GetCount(_)
  return 1
end

function reaper.TrackFX_GetFXName(_, _, _)
  return true, "JSCSI_ItemShape"
end

function reaper.TrackFX_GetParamNormalized(_, _, param)
  return state.params[param]
end

function reaper.TrackFX_SetParamNormalized(_, _, param, value)
  state.params[param] = value
end

function reaper.GetActiveTake(item)
  return item.take
end

function reaper.GetMediaItemInfo_Value(item, key)
  if key == "D_LENGTH" then return item.len end
  if key == "D_FADEINLEN" then return item.fadein end
  if key == "D_FADEOUTLEN" then return item.fadeout end
  if key == "C_FADEINSHAPE" then return item.inshape end
  if key == "C_FADEOUTSHAPE" then return item.outshape end
  if key == "D_VOL" then return item.vol end
  error("Unhandled media item key: " .. key)
end

function reaper.SetMediaItemInfo_Value(item, key, value)
  if key == "D_FADEINLEN" then item.fadein = value; return end
  if key == "D_FADEOUTLEN" then item.fadeout = value; return end
  if key == "C_FADEINSHAPE" then item.inshape = value; return end
  if key == "C_FADEOUTSHAPE" then item.outshape = value; return end
  if key == "D_VOL" then item.vol = value; return end
  error("Unhandled media item set key: " .. key)
end

function reaper.GetMediaItemTakeInfo_Value(take, key)
  if key == "D_PITCH" then return take.pitch end
  if key == "D_PLAYRATE" then return take.playrate end
  if key == "D_PAN" then return take.pan end
  error("Unhandled take key: " .. key)
end

function reaper.SetMediaItemTakeInfo_Value(take, key, value)
  if key == "D_PITCH" then take.pitch = value; return end
  if key == "D_PLAYRATE" then take.playrate = value; return end
  if key == "D_PAN" then take.pan = value; return end
  error("Unhandled take set key: " .. key)
end

function reaper.UpdateItemInProject(_)
  state.update_count = state.update_count + 1
end

function reaper.defer(fn)
  state.defer_count = state.defer_count + 1
  if state.defer_count == 1 then
    state.params[0] = 0.75
    fn()
  end
end

_G.reaper = reaper

local engine_chunk, err = loadfile(engine_path)
if not engine_chunk then
  error("Failed to load engine script: " .. tostring(err))
end

engine_chunk()

assert_close(state.items[1].take.pitch, 6.0, 0.0001, "First item pitch")
assert_close(state.items[2].take.pitch, 6.0, 0.0001, "Second item pitch")

if state.update_count < 1 then
  error("Expected at least one UpdateItemInProject call")
end

print("Smoke test passed: engine loop updated selected items via mocked REAPER API.")
