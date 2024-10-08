local Voice = require("lib/voice")
local music = require 'musicutil'
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
    quantum = 0.01,
    wrap = false,
    units = 'ms'
}

local wave_type = controlspec.def {
    min = 0,
    max = 327.0,
    warp = 'lin',
    step = 0.00,
    default = 0.0,
    quantum = 0.0030581,
    wrap = false,
    units = ''
}

local wave_blend = controlspec.def {
    min = -50,
    max = 50.0,
    warp = 'lin',
    step = 0.00,
    default = 0.0,
    quantum = 0.01,
    wrap = false,
    units = ''
}

local function add_mono_player(idx)
    -- local player = {
    --    allocator = Voice.new(4, Voice.LRU),
    --    is_active = false,
    --    notes = {},
    --    modulation = 0,
    --    channel_map = {0,0,0,0}
    --}

    local player = {
        count = 0,
        -- bend = 0,
        note = nil
    }

    function player:add_params()
        params:add_group("nb_txo_"..idx, "txo "..idx, 5)

        params:add_option("nb_txo_"..idx.."/env", "env", { "off", "on" }, 1)
        params:set_action("nb_txo_"..idx.."/env", function(param)
            if param == 2 then  -- if env set to on
                crow.ii.txo.env_act(idx,1)
            else
                crow.ii.txo.env_act(idx,0)
            end
        end)

        params:add_control("nb_txo_"..idx.."/attack", "attack", time_ms)
        params:set_action("nb_txo_"..idx.."/attack", function(param)
            crow.ii.txo.env_att(idx,param)
        end)

        params:add_control("nb_txo_"..idx.."/decay", "decay", time_ms)
        params:set_action("nb_txo_"..idx.."/decay", function(param)
            crow.ii.txo.env_dec(idx,param)
        end)

        params:add_control("nb_txo_"..idx.."/wave_type", "wave type", wave_type)
        params:set_action("nb_txo_"..idx.."/wave_type", function(param)
            local blend = params:get("nb_txo_"..idx.."/wave_blend")
            crow.ii.txo.osc_wave(idx,param*100+blend)
        end)

        params:add_control("nb_txo_"..idx.."/wave_blend", "wave blend", wave_blend)
        params:set_action("nb_txo_"..idx.."/wave_blend", function(param)
            local type = params:get("nb_txo_"..idx.."/wave_type")
            crow.ii.txo.osc_wave(idx,type*100+param)
        end)

        params:hide("nb_txo_"..idx)
    end

    function player:note_on(note, vel)
        local v_vel = vel * 5 
        local v8 = (note - 0)/12        
        crow.ii.txo.cv(idx,v_vel)
        crow.ii.txo.osc(idx, v8)
        crow.ii.txo.env_trig(idx,1)
        --crow.ii.txo.tr_pulse(idx)
    end

    function player:note_off(note)
        crow.ii.txo.cv(idx,0)
    end

    function player:describe()
        return {
            name = "txo "..idx,
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

    function player:active()
        self.is_active = true
        self.active_routine = clock.run(function()
            clock.sleep(1)
            if self.is_active then
                self:delayed_active()
            end
            self.active_routine = nil
        end)
    end

    -- Optional. Callback for when a voice is slected for more than one second.
    -- This is where you want to change modes on external devices or whatever.
    function player:delayed_active()
        params:show("nb_txo_"..idx)
        for _, p in ipairs({
            "nb_txo_"..idx.."/osc_wave",
            "nb_txo_"..idx.."/env_act",
            "nb_txo_"..idx.."/env_att",
            "nb_txo_"..idx.."/env_dec"}) do
                local prm = params:lookup_param(p)
                prm:bang()
        end
        _menu.rebuild_params()
    end

    -- Optional. Callback for when a voice is no longer used. Useful for hiding
    -- parameters or whatnot.
    function player:inactive()
        self.is_active = false
        if self.active_routine ~= nil then
            clock.cancel(self.active_routine)
        end
        params:hide("nb_txo_"..idx)
        _menu.rebuild_params()
    end
    note_players["txo "..idx] = player
end

-- local function add_txo_player()
--    local player = {
--        count = 0
--    }
    
--    note_players["txo"] = player
-- end

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
    for n=1,4 do
        add_mono_player(n)
    end
   -- note_players["txo"] = player 
end)

