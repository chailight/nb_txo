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

local detune_cents = controlspec.def {
    min = 0,
    max = 100.0,
    warp = 'lin',
    step = 0.00,
    default = 0.0,
    quantum = 0.01,
    wrap = false,
    units = 'c'
}

local function note_to_v8(note)
    return (note - 0) / 12
end

local function vel_to_cv(vel)
    return vel * 5
end

local function apply_timbre_to_ports(prefix, n)
    local env_on = params:get(prefix .. "/env") == 2
    local att = params:get(prefix .. "/attack")
    local dec = params:get(prefix .. "/decay")
    local wtype = params:get(prefix .. "/wave_type")
    local blend = params:get(prefix .. "/wave_blend")
    local wave = wtype * 100 + blend
    for i = 1, n do
        crow.ii.txo.env_act(i, env_on and 1 or 0)
        crow.ii.txo.env_att(i, att)
        crow.ii.txo.env_dec(i, dec)
        crow.ii.txo.osc_wave(i, wave)
    end
end

local function silence_ports(n)
    for i = 1, n do
        crow.ii.txo.env(i, 0)
        crow.ii.txo.cv(i, 0)
    end
end

local function add_shared_timbre_params(prefix, player, voice_count_id)
    params:add_option(prefix .. "/env", "env", { "off", "on" }, 1)
    params:set_action(prefix .. "/env", function()
        if not player.is_active then return end
        apply_timbre_to_ports(prefix, params:get(voice_count_id))
    end)

    params:add_control(prefix .. "/attack", "attack", time_ms)
    params:set_action(prefix .. "/attack", function()
        if not player.is_active then return end
        apply_timbre_to_ports(prefix, params:get(voice_count_id))
    end)

    params:add_control(prefix .. "/decay", "decay", time_ms)
    params:set_action(prefix .. "/decay", function()
        if not player.is_active then return end
        apply_timbre_to_ports(prefix, params:get(voice_count_id))
    end)

    params:add_control(prefix .. "/wave_type", "wave type", wave_type)
    params:set_action(prefix .. "/wave_type", function()
        if not player.is_active then return end
        apply_timbre_to_ports(prefix, params:get(voice_count_id))
    end)

    params:add_control(prefix .. "/wave_blend", "wave blend", wave_blend)
    params:set_action(prefix .. "/wave_blend", function()
        if not player.is_active then return end
        apply_timbre_to_ports(prefix, params:get(voice_count_id))
    end)
end

local function bang_timbre_params(prefix)
    for _, p in ipairs({
        prefix .. "/env",
        prefix .. "/attack",
        prefix .. "/decay",
        prefix .. "/wave_type",
        prefix .. "/wave_blend",
    }) do
        params:lookup_param(p):bang()
    end
end

local function schedule_active(player)
    player.is_active = true
    player.active_routine = clock.run(function()
        clock.sleep(1)
        if player.is_active then
            player:delayed_active()
        end
        player.active_routine = nil
    end)
end

local function cancel_active(player)
    player.is_active = false
    if player.active_routine ~= nil then
        clock.cancel(player.active_routine)
        player.active_routine = nil
    end
end

local function voice_on_trigger(port, v8, v_vel)
    crow.ii.txo.osc(port, v8)
    crow.ii.txo.cv(port, v_vel)
    crow.ii.txo.env_trig(port, 1)
end

local function voice_on_gate(port, v8, v_vel, env_on)
    crow.ii.txo.osc(port, v8)
    crow.ii.txo.cv(port, v_vel)
    if env_on then
        crow.ii.txo.env(port, 1)
    end
end

local function voice_off_gate(port, env_on)
    if env_on then
        crow.ii.txo.env(port, 0)
    end
    crow.ii.txo.cv(port, 0)
end

local function add_mono_player(idx)
    local player = {
        count = 0,
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
        local v_vel = vel_to_cv(vel)
        local v8 = note_to_v8(note)
        crow.ii.txo.cv(idx,v_vel)
        crow.ii.txo.osc(idx, v8)
        crow.ii.txo.env_trig(idx,1)
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
        silence_ports(4)
    end

    function player:active()
        schedule_active(self)
    end

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

    function player:inactive()
        cancel_active(self)
        params:hide("nb_txo_"..idx)
        _menu.rebuild_params()
    end
    note_players["txo "..idx] = player
end

local function add_poly_player()
    local prefix = "nb_txo_poly"
    local player = {
        voice_count = 4,
        last_voice = 1,
        release_fn = {},
        notes = {},
        channel_map = {0, 0, 0, 0},
        allocator = Voice.new(4, Voice.LRU),
        alloc_modes = { "rotate", "random", "lru" },
        trigger_modes = { "gate", "trigger" },
    }

    local function rebuild_allocator(n)
        player.voice_count = n
        player.allocator = Voice.new(n, Voice.LRU)
        player.channel_map = {}
        for i = 1, n do
            player.channel_map[i] = 0
        end
        player.notes = {}
        player.release_fn = {}
        if player.last_voice > n then
            player.last_voice = n
        end
    end

    local function env_on()
        return params:get(prefix .. "/env") == 2
    end

    local function is_trigger_mode()
        return player.trigger_modes[params:get(prefix .. "/trigger_mode")] == "trigger"
    end

    local function alloc_mode()
        return player.alloc_modes[params:get(prefix .. "/alloc_mode")]
    end

    local function silence_port(port)
        voice_off_gate(port, env_on())
    end

    function player:add_params()
        params:add_group(prefix, "txo poly", 8)

        params:add_number(prefix .. "/voice_count", "voice count", 1, 4, 4)
        params:set_action(prefix .. "/voice_count", function(value)
            rebuild_allocator(value)
            if self.is_active then
                apply_timbre_to_ports(prefix, value)
            end
        end)

        params:add_option(prefix .. "/alloc_mode", "alloc mode", self.alloc_modes, 1)
        params:add_option(prefix .. "/trigger_mode", "trigger mode", self.trigger_modes, 1)

        add_shared_timbre_params(prefix, self, prefix .. "/voice_count")

        params:hide(prefix)
    end

    function player:note_on(note, vel)
        local v8 = note_to_v8(note)
        local v_vel = vel_to_cv(vel)
        local n = params:get(prefix .. "/voice_count")
        local mode = alloc_mode()
        local trigger = is_trigger_mode()
        local use_env = env_on()
        local port

        if mode == "lru" then
            local slot = self.allocator:get()
            self.notes[note] = slot
            local index = self.channel_map[slot.id] + 1
            self.channel_map[slot.id] = index
            port = slot.id
            if not trigger then
                slot.on_release = function(s)
                    if self.channel_map[s.id] == index then
                        silence_port(s.id)
                    end
                end
            end
        elseif mode == "rotate" then
            port = self.last_voice % n + 1
            self.last_voice = port
            if not trigger then
                self.release_fn[note] = function()
                    silence_port(port)
                end
            end
        else -- random
            port = math.random(n)
            if not trigger then
                self.release_fn[note] = function()
                    silence_port(port)
                end
            end
        end

        if trigger then
            voice_on_trigger(port, v8, v_vel)
        else
            voice_on_gate(port, v8, v_vel, use_env)
        end
    end

    function player:note_off(note)
        if alloc_mode() == "lru" then
            local slot = self.notes[note]
            if slot then
                if is_trigger_mode() then
                    slot.on_release = nil
                end
                self.allocator:release(slot)
            end
            self.notes[note] = nil
            return
        end

        if is_trigger_mode() then
            return
        end

        if self.release_fn[note] then
            self.release_fn[note]()
            self.release_fn[note] = nil
        end
    end

    function player:describe()
        return {
            name = "txo poly",
            supports_bend = false,
            supports_slew = false,
            modulate_description = "unsupported",
        }
    end

    function player:stop_all()
        silence_ports(params:get(prefix .. "/voice_count"))
        self.notes = {}
        self.release_fn = {}
    end

    function player:active()
        schedule_active(self)
    end

    function player:delayed_active()
        params:show(prefix)
        bang_timbre_params(prefix)
        apply_timbre_to_ports(prefix, params:get(prefix .. "/voice_count"))
        _menu.rebuild_params()
    end

    function player:inactive()
        cancel_active(self)
        params:hide(prefix)
        _menu.rebuild_params()
    end

    note_players["txo poly"] = player
end

local function add_unison_player()
    local prefix = "nb_txo_unison"
    local player = {
        count = 0,
        detune_modes = { "random", "spread" },
    }

    local function detune_offset_volts(i, n, amount, mode)
        if amount == 0 then
            return 0
        end
        local cents
        if mode == "random" then
            cents = (math.random() - 0.5) * amount
        else -- spread
            if n == 1 then
                cents = 0
            else
                cents = -amount / 2 + (i - 1) * (amount / (n - 1))
            end
        end
        return cents / 1200
    end

    function player:add_params()
        params:add_group(prefix, "txo unison", 8)

        params:add_number(prefix .. "/voice_count", "voice count", 2, 4, 4)
        params:set_action(prefix .. "/voice_count", function(value)
            if self.is_active then
                apply_timbre_to_ports(prefix, value)
            end
        end)

        params:add_control(prefix .. "/detune", "detune", detune_cents)
        params:add_option(prefix .. "/detune_mode", "detune mode", self.detune_modes, 1)

        add_shared_timbre_params(prefix, self, prefix .. "/voice_count")

        params:hide(prefix)
    end

    function player:note_on(note, vel)
        self.count = self.count + 1
        local v8 = note_to_v8(note)
        local v_vel = vel_to_cv(vel) / 2
        local n = params:get(prefix .. "/voice_count")
        local amount = params:get(prefix .. "/detune")
        local mode = self.detune_modes[params:get(prefix .. "/detune_mode")]
        for i = 1, n do
            local offset = detune_offset_volts(i, n, amount, mode)
            voice_on_trigger(i, v8 + offset, v_vel)
        end
    end

    function player:note_off(note)
        self.count = self.count - 1
        if self.count < 0 then self.count = 0 end
        if self.count == 0 then
            silence_ports(params:get(prefix .. "/voice_count"))
        end
    end

    function player:describe()
        return {
            name = "txo unison",
            supports_bend = false,
            supports_slew = false,
            modulate_description = "unsupported",
        }
    end

    function player:stop_all()
        self.count = 0
        silence_ports(params:get(prefix .. "/voice_count"))
    end

    function player:active()
        schedule_active(self)
    end

    function player:delayed_active()
        params:show(prefix)
        bang_timbre_params(prefix)
        apply_timbre_to_ports(prefix, params:get(prefix .. "/voice_count"))
        _menu.rebuild_params()
    end

    function player:inactive()
        cancel_active(self)
        params:hide(prefix)
        _menu.rebuild_params()
    end

    note_players["txo unison"] = player
end

mod.hook.register("script_pre_init", "nb txo pre init", function()
    for n = 1, 4 do
        add_mono_player(n)
    end
    add_poly_player()
    add_unison_player()
end)
