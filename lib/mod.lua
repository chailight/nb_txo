
local mod = require 'core/mods'

if note_players == nil then
    note_players = {}
end

local function add_txo_player()
    local player = {
        count = 0
    }

    function player:note_on(note, vel)
        local v_vel = vel * 10
        local v8 = (note - 60)/12        
        crow.ii.txo.osc(1 v8)
        crow.ii.txo.tr_pulse(1)
    end

    function player:note_off(note)
        crow.ii.txo.cv(1,0)
    end

    function player:describe()
        return {
            name = "txo",
            supports_bend = false,
            supports_slew = false,
            modulate_description = "unsupported",
        }
    end

    function player:stop_all()
        crow.ii.txo.cv(1,0)
        crow.ii.txo.cv(2,0)
        crow.ii.txo.cv(3,0)
        crow.ii.txo.cv(4,0)
    end

    note_players["txo"] = player
end

mod.hook.register("script_pre_init", "nb txo pre init", function()
    add_txo_player()
end)
