--- STEAMODDED HEADER
--- MOD_NAME: 10 Spades
--- MOD_ID: TenSpades
--- MOD_AUTHOR: [TamerSoup625]
--- MOD_DESCRIPTION: Simulate glitch seeds
--- PREFIX: ten_spades

----------------------------------------------
------------MOD CODE -------------------------


-- Constants
local RNG_LOCK_ESCAPE_KEY_PREFIX = "10spades_RNG_LOCK_SEED_ESCAPE_____"
local CHANCE_SEED_LOCK_OPTIONS = {"1 in 1", "1 in 1.5", "1 in 2", "1 in 3", "1 in 4", "1 in 6", "1 in 8"}
-- {Option in CHANCE_SEED_LOCK_OPTIONS = Index of that option}
local CHANCE_SEED_LOCK_OPTIONS_INVERSE = {[1] = 1, [1.5] = 2, [2] = 3, [3] = 4, [4] = 5, [6] = 6, [8] = 7}
local ten_spades_mod = SMODS.current_mod


-- Main atlas
SMODS.Atlas {
    key = "spades_ten_atlas",
    path = "deck.png",
    px = 71,
    py = 95
}


-- 10 Spades Deck
SMODS.Back{
	name = "10 Spades Deck",
	key = "ten_spades",
    atlas = "spades_ten_atlas",
	pos = {x = 0, y = 0},
    -- No config table so it syncs with mod config
	config = {},
	loc_txt = {
		name = "10 Spades Deck",
		text = {
			"Each RNG has a",
            "{C:green}1 in #1#{} chance",
            "to have {C:attention}constant outcome",
            "{C:inactive,s:0.85}Some RNGs reset each Ante",
		}
	},
	loc_vars = function(self)
		return { vars = { ten_spades_mod.config.chance_to_lock_rng_1_in_x }}
	end,
	apply = function(self)
        G.GAME.key_is_locked_map = {}
        G.GAME.rng_lock_chance = ten_spades_mod.config.chance_to_lock_rng_1_in_x
	end,
}


-- 10 Spades Sleeve
if CardSleeves then
    CardSleeves.Sleeve{
        key = "ten_spades",
        atlas = "spades_ten_atlas",
        pos = {x = 1, y = 0},
        loc_vars = function(self)
            local key, vars
            if self.get_current_deck_key() ~= "b_ten_spades_ten_spades" then
                key = self.key
                self.config = {rng_lock_chance = ten_spades_mod.config.chance_to_lock_rng_1_in_x}
                vars = {self.config.rng_lock_chance}
            else
                key = self.key .. "_alt"
                self.config = {showman_start = true}
                vars = {}
            end
            return { key = key, vars = vars }
        end,
        apply = function(self)
            G.GAME.key_is_locked_map = {}
            if self.config.rng_lock_chance then
                G.GAME.rng_lock_chance = self.config.rng_lock_chance
            else
                G.E_MANAGER:add_event(Event({
                    func = function()
                        if G.jokers then
                            local card = create_card("Joker", G.jokers, nil, nil, nil, nil, "j_ring_master")
                            card:add_to_deck()
                            card:set_edition({negative = true})
                            card:set_eternal(true)
                            card:start_materialize()
                            G.jokers:emplace(card)
                            return true
                        end
                    end,
                }))
            end
        end,
    }
end


-- Config
SMODS.current_mod.config_tab = function()
    return {n=G.UIT.ROOT, config = {align = "cm", minh = G.ROOM.T.h*0.25, padding = 0.0, r = 0.1, colour = G.C.CLEAR}, nodes = {
        create_option_cycle({
                label = "Chance for deck/sleeve effect", scale = 1, options = CHANCE_SEED_LOCK_OPTIONS,
                opt_callback = 'ten_spades_config_change_lock_chance',
                current_option = CHANCE_SEED_LOCK_OPTIONS_INVERSE[ten_spades_mod.config.chance_to_lock_rng_1_in_x]
        }),
    }}
end


G.FUNCS.ten_spades_config_change_lock_chance = function (args)
    -- "1 in 25" -> 25
    local value = tonumber(string.sub(args.to_val, 6))
    ten_spades_mod.config.chance_to_lock_rng_1_in_x = value
end


-- RNG lock logic
local pesudoseed_ref = pseudoseed
function pseudoseed(key, predict_seed)
    if (not G.GAME.rng_lock_chance) or key == "seed" or predict_seed or (string.sub(key, 0, string.len(RNG_LOCK_ESCAPE_KEY_PREFIX)) == RNG_LOCK_ESCAPE_KEY_PREFIX) then
        return pesudoseed_ref(key, predict_seed)
    end

    if G.GAME.key_is_locked_map[key] == nil then
        -- Decide whether to lock RNG or not
        G.GAME.key_is_locked_map[key] = pseudorandom(RNG_LOCK_ESCAPE_KEY_PREFIX .. key) < G.GAME.probabilities.normal/G.GAME.rng_lock_chance
    end

    if G.GAME.key_is_locked_map[key] == false then
        -- RNG is not locked
        return pesudoseed_ref(key, predict_seed)
    end

    if not G.GAME.pseudorandom[key] then
        -- RNG is locked, but not rolled
        -- Init pseudorandom
        G.GAME.pseudorandom[key] = pseudohash(key..(G.GAME.pseudorandom.seed or ''))
        ---@diagnostic disable-next-line: param-type-mismatch
        G.GAME.pseudorandom[key] = math.abs(tonumber(string.format("%.13f", (2.134453429141+G.GAME.pseudorandom[key]*1.72431234)%1)))
    end

    -- RNG is locked, use the value cached
    return (G.GAME.pseudorandom[key] + (G.GAME.pseudorandom.hashed_seed or 0))/2
end


----------------------------------------------
------------MOD CODE END----------------------
