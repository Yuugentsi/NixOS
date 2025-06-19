require 'mp'
require 'mp.msg'

local times_accumulated = {}
local subtitle_index = 1

local function seconds_to_srt_time(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local millis = math.floor((seconds - math.floor(seconds)) * 1000)
    return string.format("%02d:%02d:%02d,%03d", hours, minutes, secs, millis)
end

local function save_srt_block(start_sec, end_sec, index)
    local file_name = "file.txt"
    local file = io.open(file_name, "a")
    if not file then
        mp.osd_message("Failed to open " .. file_name)
        return false
    end

    local start_time = seconds_to_srt_time(start_sec)
    local end_time = seconds_to_srt_time(end_sec)
    local text = "Legenda" -- pode mudar o texto aqui

    file:write(string.format("%d\n%s --> %s\n%s\n\n", index, start_time, end_time, text))
    file:close()
    mp.osd_message("Saved subtitle block #" .. index)
    return true
end

local function copy_time_accumulate()
    local time_pos = mp.get_property_number("time-pos")
    table.insert(times_accumulated, time_pos)

    local times_strs = {}
    for _, t in ipairs(times_accumulated) do
        local s = seconds_to_srt_time(t):gsub(",", ".")
        table.insert(times_strs, s)
    end

    local text_to_copy = table.concat(times_strs, " ")

    -- Função para copiar para clipboard, depende do sistema
    local success = false
    local platform = package.cpath:match("%p[\\|/]?%p(%a+)")
    if platform == "dll" then
        success = mp.commandv("run", "powershell", "-command", "Set-Clipboard -Value '" .. text_to_copy .. "'") == true
    else
        local function command_exists(cmd)
            local pipe = io.popen("command -v " .. cmd .. " >/dev/null 2>&1 && echo yes || echo no")
            local result = pipe:read("*a")
            pipe:close()
            return result:match("yes")
        end

        local function copy_with(cmd)
            local pipe = io.popen(cmd, "w")
            if pipe then
                pipe:write(text_to_copy)
                pipe:close()
                return true
            else
                return false
            end
        end

        if command_exists("wl-copy") then
            success = copy_with("wl-copy")
        elseif command_exists("xclip") then
            success = copy_with("xclip -selection clipboard")
        elseif command_exists("pbcopy") then
            success = copy_with("pbcopy")
        else
            success = false
        end
    end

    if success then
        mp.osd_message("Copied times: " .. text_to_copy .. "\nPressione 's' para salvar no file.txt")
    else
        mp.osd_message("Failed to copy times to clipboard")
    end
end

local function save_if_ready()
    if #times_accumulated >= 2 then
        local ok = save_srt_block(times_accumulated[1], times_accumulated[2], subtitle_index)
        if ok then
            subtitle_index = subtitle_index + 1
            times_accumulated = {}
        end
    else
        mp.osd_message("Precisa de 2 tempos acumulados para salvar.")
    end
end

mp.add_key_binding("c", "copy_time_accumulate", copy_time_accumulate)
mp.add_key_binding("s", "save_subtitle_block", save_if_ready)
