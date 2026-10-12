
collectgarbage("generational")

Director = require("director")
Helpers = require("helpers")
local BTN = require("btn")

require("palette")
require("sprites")
require("skull")
require("letters")
require("bg")
require("database")

Frame = 0

Game = {
    state = "playing",
    keyboard = {
        letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        selected = 1,
        used = {}
    }
}

Game.skull = MakeSkull(Game, 66, 56)
Game.letters = MakeLetters(Game, 290, 52)
Game.bg = MakeBackground(Game, 0, 0)

local KEYBOARD = {
    x = 88,
    y = 125,
    key_width = 30,
    key_height = 22,
    gap = 4,
    rows = {
        {1, 10},
        {11, 20},
        {21, 26}
    }
}

local function update_keyboard()
    local selected = Game.keyboard.selected
    local row = math.ceil(selected / 10)
    local column = selected - (row - 1) * 10

    if ui.btnp(BTN.LEFT) then
        if column > 1 then
            selected = selected - 1
        end
    elseif ui.btnp(BTN.RIGHT) then
        local row_end = KEYBOARD.rows[row][2]

        if selected < row_end then
            selected = selected + 1
        end
    elseif ui.btnp(BTN.UP) then
        if row > 1 then
            selected = math.min(
                selected - 10,
                KEYBOARD.rows[row - 1][2]
            )
        end
    elseif ui.btnp(BTN.DOWN) then
        if row < #KEYBOARD.rows then
            selected = math.min(
                selected + 10,
                KEYBOARD.rows[row + 1][2]
            )
        end
    end

    Game.keyboard.selected = selected

    if ui.btnp(BTN.Z) then
        local letter = Game.keyboard.letters:sub(selected, selected)

        if not Game.keyboard.used[letter] then
            Game.keyboard.used[letter] = true
            Game.letters.try_letter(letter, Frame)
        end
    end
end

local function draw_keyboard()
    local letters = Game.keyboard.letters

    for row_index, row in ipairs(KEYBOARD.rows) do
        local first = row[1]
        local last = row[2]
        local row_width = (last - first + 1)
            * (KEYBOARD.key_width + KEYBOARD.gap)
            - KEYBOARD.gap

        local start_x = math.floor(
            (480 - row_width) / 2
        )

        local y = KEYBOARD.y
            + (row_index - 1)
            * (KEYBOARD.key_height + KEYBOARD.gap)

        for index = first, last do
            local column = index - first
            local x = start_x
                + column * (KEYBOARD.key_width + KEYBOARD.gap)

            local letter = letters:sub(index, index)
            local selected = index == Game.keyboard.selected
            local used = Game.keyboard.used[letter]

            local background = 0x2108
            local foreground = 0x7FFF

            if used then
                background = 0x0000
                foreground = 0x5294
            elseif selected then
                background = 0x41F0
                foreground = 0x0000
            end

            ui.rectfill(
                x,
                y,
                x + KEYBOARD.key_width,
                y + KEYBOARD.key_height,
                background
            )

            ui.rect(
                x,
                y,
                KEYBOARD.key_width,
                KEYBOARD.key_height,
                selected and 0x7FFF or 0x5294
            )

            ui.print(
                letter,
                x + 10,
                y + 7,
                foreground
            )
        end
    end

    ui.print(
        "SETAS: MOVER   Z: CONFIRMAR",
        135,
        208,
        0x7FFF
    )
end

local function draw_palette(brightness)
    for i = 1, #Palette do
        local color = Palette[i]
        local r = color & 0x1F
        local g = (color & 0x3E0) >> 5
        local b = (color & 0x7C00) >> 10

        r = math.floor(r * brightness)
        g = math.floor(g * brightness)
        b = math.floor(b * brightness)

        ui.palset(i - 1, r | (g << 5) | (b << 10))
    end
end

local function reset_game()
    Game.letters.reset()
    Game.skull.reset()

    Game.keyboard.selected = 1
    Game.keyboard.used = {}

    Director.fade_in(30)
    Game.state = "playing"
end

Director.fade_in(30)

function update()
    Frame = Frame + 1
    Director.update()

    ui.cls(1)
    ui.clip(0, 0, 480, 270)

    draw_palette(Director.get_brightness())

    Game.bg.draw(Frame)
    Game.skull.draw(Frame)
    Game.letters.draw(Frame)

    if Game.state == "playing" then
        update_keyboard()
        draw_keyboard()

        if Game.letters.is_word_guessed() then
            Game.state = "won"
            Game.state_start_frame = Frame
        elseif Game.letters.is_game_over() then
            Game.state = "lost"
            Game.state_start_frame = Frame
        end

    elseif Game.state == "won" or Game.state == "lost" then
        local elapsed = Frame - (Game.state_start_frame or Frame)
        local ease = Helpers.ease_out_cubic(elapsed / 25)

        local title_y = math.floor(-30 + 40 * ease)
        local sub_y = math.floor(285 - 35 * ease)

        if Game.state == "won" then
            Helpers.print_sine_centered(
                "ACERTOU!",
                title_y,
                Frame,
                0x313F,
                0x1063
            )

            Helpers.print_centered(
                "BTN_Z PARA JOGAR DE NOVO",
                sub_y,
                0x7FFF,
                0x0000
            )
        else
            Helpers.print_sine_centered(
                "OPS! ERROU!",
                title_y,
                Frame,
                0x6CA1,
                0x1063
            )

            Helpers.print_centered(
                "BTN_Z PARA TENTAR DE NOVO",
                sub_y,
                0x7FFF,
                0x0000
            )
        end

        if ui.btnp(BTN.Z) or ui.btnp(BTN.X) then
            Director.fade_out(30)
            Game.state = "fading_out"
        end

    elseif Game.state == "fading_out" then
        if not Director.is_fading() then
            reset_game()
        end
    end
end
