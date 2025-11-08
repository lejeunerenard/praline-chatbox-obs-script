local version = '1.0.0'

-- Convert int color to BGR
function colorIntToBGR(color)
  return color - 4278190080
end

-- Convert from int BGR to hex RGB
function bgrToRGBHex(colorIntBGR)
  local b = math.floor(colorIntBGR / (256 ^ 2))
  local g = math.floor((colorIntBGR - b * 256 ^ 2) / (256))
  local r = math.floor((colorIntBGR - b * 256 ^ 2 - g * 256))

  return '#' .. string.format('%02x', r) .. string.format('%02x', g) .. string.format('%02x', b)
end

-- This function is necessary to tell OBS it is a script
function script_description()
  local description = [[
  <p>
    Customize Praline Chatbox theme chat CSS in OBS. Theme can be purchased <a href="https://ko-fi.com/s/7e30e8500e">here</a>.
  </p>
  <p>Version:  %s</p>
  ]]
  return string.format(description, version)
end

-- Called upon settings initialization and modification
lrj_chat_settings = nil
function script_update(settings)
  -- Keep track of current settings
  lrj_chat_settings = settings

  -- Set color in css
  if lrj_chat_settings ~= nil then
    local color = obslua.obs_data_get_int(lrj_chat_settings, "chatmsgbg")
    if color ~= 0 then -- Setting hasn't been set TODO Fix when first loading script
      local colorHex = bgrToRGBHex(colorIntToBGR(color))

      local sourceName = obslua.obs_data_get_string(lrj_chat_settings, "source")
      local source = obslua.obs_get_source_by_name(sourceName)
      if source ~= nil then
        local settings = obslua.obs_source_get_settings(source)
        local css = obslua.obs_data_get_string(settings, "css")
        local BOOKEND = '/* LJR : OBS Praline CSS */\n'

        -- Remove any existing script styles
        local BOOKEND_ESC = BOOKEND:gsub('%*', '%%%*')
        css = css:gsub('\n' .. BOOKEND_ESC .. '.*' .. BOOKEND_ESC, '')

        -- Add updated styles
        local chatmsgbgCSS = "--color-message-bg: " .. colorHex .. ";\n"
        local newStyles = "\n" .. BOOKEND .. "yt-live-chat-renderer {\n" .. chatmsgbgCSS .. "}\n" .. BOOKEND
        obslua.obs_data_set_string(settings, "css", css .. newStyles)
        obslua.obs_source_update(source, settings)
        obslua.obs_data_release(settings)
      end
      obslua.obs_source_release(source)
    end
  end
end

-- Displays a list of properties
function script_properties()

  local properties = obslua.obs_properties_create()

  local p = obslua.obs_properties_add_list(properties, "source", "Browser Source", obslua.OBS_COMBO_TYPE_EDITABLE, obslua.OBS_COMBO_FORMAT_STRING)
  local sources = obslua.obs_enum_sources()

  -- As long as the sources are not empty, then
  if sources ~= nil then
    -- iterate over all the sources
    for _, source in ipairs(sources) do
      source_id = obslua.obs_source_get_id(source)
      -- Only show browser sources
      if source_id == "browser_source" then
        local name = obslua.obs_source_get_name(source)
        obslua.obs_property_list_add_string(p, name, name)
      end
    end
  end

  obslua.source_list_release(sources)

  -- Color option For Message Background
  obslua.obs_properties_add_color(properties, "chatmsgbg", "Chat Message Background")

  -- Calls the callback once to set-up current visibility
  obslua.obs_properties_apply_settings(properties, lrj_chat_settings)
 
  return properties
end
