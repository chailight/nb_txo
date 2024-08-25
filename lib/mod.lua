
local mod = require 'core/mods'

if note_players == nil then
    note_players = {}
end

local time_ms = controlspec.def {
    min = 0,
    max = 2000.0,
    warp = 'lin',
    step = 0.00,
    default = 10.0,
    quantum = 1.0,
    wrap = false,
    units = 'ms'
}

local wave_id = controlspec.def {
    min = 0,
    max = 400.0,
    warp = 'lin',
    step = 0.00,
    default = 0.0,
    quantum = 1.0,
    wrap = false,
    units = ''
}

local function add_txo_player()
    local player = {
        count = 0
    }

    function player:note_on(note, vel)
        local v_vel = vel * 5 
        local v8 = (note - 0)/12        
        crow.ii.txo.cv(1,v_vel)
        crow.ii.txo.osc(1, v8)
        crow.ii.txo.env_trig(1,1)
        --crow.ii.txo.tr_pulse(1)
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

    function player:add_params()
        params:add_group("nb_txo", "txo", 4)

        params:add_option("nb_txo/env", "env", { "off", "on" }, 1)
        params:set_action("nb_txo/env", function(param)
            if param == "on" then
                crow.ii.txo.env_act(1,1)
            else
                crow.ii.txo.env_act(1,0)
            end
        end)

        params:add_control("nb_txo/attack", "attack", time_ms)
        params:set_action("nb_txo/attack", function(param)
            crow.ii.txo.env_att(1,param)
        end)

        params:add_control("nb_txo/decay", "decay", time_ms)
        params:set_action("nb_txo/decay", function(param)
            crow.ii.txo.env_dec(1,param)
        end)

        params:add_control("nb_txo/wave", "wave", wave_id)
        params:set_action("nb_txo/wave", function(param)
            crow.ii.txo.osc_wave(1,param)
        end)

        params:hide("nb_txo")
    end

    note_players["txo"] = player
end

-- cv_slew
-- cv_qt
-- cv_n
-- cv_scale
-- osc_qt
-- osc_n
-- osc_wave - done
-- osc_width
-- osc_scale
-- env_act - done
-- env_att - done
-- env_dec - done
-- env_trig - n/a



mod.hook.register("script_pre_init", "nb txo pre init", function()
    add_txo_player()
end)
