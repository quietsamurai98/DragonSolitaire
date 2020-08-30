# $gtk.define_singleton_method(:production) { true } #shhhhhhh

COLORS = {
    red: {r: 217, g: 95, b: 2},
    green: {r: 27, g: 158, b: 119},
    blue: {r: 117, g: 112, b: 179},
    white: {r: 255, g: 255, b: 255}
}

LOG_LEVELS = {
    trace: {str: "[TRACE] ", level: 0},
    debug: {str: "[DEBUG] ", level: 1},
    info: {str: "[INFO]  ", level: 2},
    warn: {str: "[WARN]  ", level: 3},
    err: {str: "[ERROR] ", level: 4},
    fatal: {str: "[FATAL] ", level: 5},
}
MIN_LOG_LEVEL = LOG_LEVELS[:debug]


# @param [String, #to_s] msg The message to log
# @param [Symbol, nil] level The level at which to log msg
# @param [#to_s] line Just pass in `__LINE__`.
# @return [Time, Float] Amount of time it took to log the message
def clog(msg, level = nil, line = '???')
  start_time = Time.now
  level ||= :info
  level = LOG_LEVELS[level]
  if MIN_LOG_LEVEL[:level] <= level[:level]
    puts "#{level[:str]}[L\##{line}]  #{msg}"
  end
  Time.now - start_time
end

# Name is misleading. Only allows a foreground colored mask sprite and a background sprite.
class AbstractMultiSprite
  attr_accessor :background
  attr_sprite

end

class ButtonMultiSprite < AbstractMultiSprite
  attr_accessor :background
  attr_sprite

  def initialize(params = {})
    @x = params[:x] || 0
    @y = params[:y] || 0
    @w = 48
    @h = 48
    @path = nil
    @background = {x: x, y: y, w: @w, h: @h, path: "sprites/button_bg_dim.png"}
  end

  def set_color(color)
    @r = color[:r]
    @g = color[:g]
    @b = color[:b]
  end

  def set_img(suit, state)
    @path = "sprites/button_icon_#{suit.to_s}.png"
    @background.path = "sprites/button_bg_#{state.to_s}.png"
    set_color(COLORS[suit])
  end

  def set_pos(params = {})
    @x = params[:x] || @x
    @background.x = params[:x] || @x
    @y = params[:y] || @y
    @background.y = params[:y] || @y
  end

  def list
    [@background, self]
  end

  def center
    {x: @x + (@w / 2), y: @y + (@h / 2)}
  end
end

class Button
  attr_accessor :suit, :state, :x, :y, :z, :id

  def serialize
    {suit: suit, state: state, x: x, y: y, z: z, id: id}
  end

  # 2. Override the inspect method and return ~serialize.to_s~.
  def inspect
    serialize.to_s
  end

  # 3. Override to_s and return ~serialize.to_s~.
  def to_s
    serialize.to_s
  end

  # @return [ButtonMultiSprite]
  def sprite
    update_sprite_pos
    update_sprite_img
    @sprite
  end

  # constructor
  def initialize(params = {})
    @suit = params[:suit] || :misc
    @state = params[:state] || :dim
    @x = params[:x] || 0
    @y = params[:y] || 0
    @z = params[:z] || 0 #Z Layer - Lower layers are covered by higher layers
    @id = params[:id] || 0
    @sprite = ButtonMultiSprite.new
  end

  # @param [Hash] params
  # @option params [integer] x The sprite's lower left corner x position
  # @option params [integer] y The sprite's lower left corner y position
  # @option params [integer] z The sprite's draw layer. -oo = background, +oo = foreground
  def set_pos(params = {})
    @x = params[:x] || @x
    @y = params[:y] || @y
    @z = params[:z] || @z
  end

  def update_sprite_pos
    @sprite.set_pos({x: @x, y: @y})
  end

  def update_sprite_img
    @sprite.set_img(@suit, @state)
  end

  def contains_point(x, y)
    # Since buttons are circles, we can't just do a simple bbox intersect test
    dist_sq = ((x - self.sprite.center[:x]) ** 2) + ((y - self.sprite.center[:y]) ** 2)
    r_sq = (self.sprite.w / 2) ** 2
    dist_sq < r_sq
  end
end

class CardMultiSprite
  attr_accessor :background
  attr_sprite

  def initialize(params = {})
    @x = params[:x] || 0
    @y = params[:y] || 0
    @w = 128
    @h = 180
    @path = nil
    @background = {x: x, y: y, w: @w, h: @h, path: "sprites/card_bg.png"}
  end

  def set_color(color)
    @r = color[:r]
    @g = color[:g]
    @b = color[:b]
  end

  def set_img(suit, value)
    if value == 0 or suit == :misc
      #Card has a special sprite
      if suit == :misc and value == 0
        set_color(COLORS[:white])
        @path = "sprites/card_flower.png"
      else
        if suit != :misc
          set_color(COLORS[suit])
          @path = "sprites/card_dragon_#{suit.to_s}.png"
        end
      end
    else
      #Card has a numbered sprite
      @path = "sprites/card_#{value.to_s}.png"
      set_color(COLORS[suit])
    end
  end

  def set_pos(params = {})
    @x = params[:x] || @x
    @background.x = params[:x] || @x
    @y = params[:y] || @y
    @background.y = params[:y] || @y
  end

  def list
    [@background, self]
  end

  def center
    {x: @x + (@w / 2), y: @y + (@h / 2)}
  end
end

class Card
  attr_accessor :suit, :value, :x, :y, :z, :id, :rank, :file

  def serialize
    {suit: suit, value: value, x: x, y: y, z: z, id: id, rank: rank, file: file}
  end

  # 2. Override the inspect method and return ~serialize.to_s~.
  def inspect
    serialize.to_s
  end

  # 3. Override to_s and return ~serialize.to_s~.
  def to_s
    serialize.to_s
  end

  # @return [CardMultiSprite]
  def sprite
    update_sprite_pos
    update_sprite_img
    @sprite
  end

  # constructor
  def initialize(params = {})
    @suit = params[:suit] || :misc
    @value = params[:value] || 0
    @x = params[:x] || 0
    @y = params[:y] || 0
    @z = params[:z] || 0 #Z Layer - Lower layers are covered by higher layers
    @id = params[:id] || 0
    @rank = params[:rank] || 0
    @file = params[:file] || 0
    @sprite = CardMultiSprite.new
  end

  # @param [Hash] params
  # @option params [integer] x The sprite's lower left corner x position
  # @option params [integer] y The sprite's lower left corner y position
  # @option params [integer] z The sprite's draw layer. -oo = background, +oo = foreground
  def set_pos(params = {})
    @x = params[:x] || @x
    @y = params[:y] || @y
    @z = params[:z] || @z
  end

  def update_sprite_pos
    @sprite.set_pos({x: @x, y: @y})
  end

  def update_sprite_img
    @sprite.set_img(@suit, @value)
  end

  def contains_point(x, y)
    x1 = @x
    x2 = @x + @sprite.w
    y1 = @y
    y2 = @y + @sprite.h
    x1 < x and x < x2 and y1 < y and y < y2
  end


  # @param [Hash{Symbol=>Integer}] params
  # @option params [integer] rank The vertical rank of the card. -1 = special
  # @option params [integer] file The horizontal file of the card
  # @return [Hash{Symbol=>Integer}] Coord hash of form {x:Integer,y:Integer,z:Integer}
  def calculate_snap_position(params = {})
    rank = params[:rank] || self.rank
    file = params[:file] || self.file
    x = 160 * file + 16
    y = -32 * rank + (rank == -1 ? 492 : 312)
    z = (rank == -1) ? self.value : rank
    {x: x, y: y, z: z}
  end
end

class StableState
  attr_accessor :holding_cards, :mouse_down_pos, :held_cards, :entities, :buttons, :cards

  def initialize
    $gtk.set_window_title "Dragon Solitaire"
    #@type [Boolean]
    @holding_cards = false
    #@type [Hash]
    @mouse_down_pos = nil
    #@type [Array<Card>]
    @held_cards = nil
    #@type [Array<Entity>]
    @entities = []
    @buttons = [
        Button.new({suit: :red, state: :dim, x: 536, y: 647}),
        Button.new({suit: :green, state: :dim, x: 536, y: 590}),
        Button.new({suit: :blue, state: :dim, x: 536, y: 533})
    ]
    @entities += @buttons
    @cards = []
    # The next line generates an array of {s: suit, v: value} hashes that represents all cards in the deck.
    card_data = ((%i{red green blue}).flat_map { |s| ((1..9).to_a + [0, 0, 0, 0]).map { |v| {s: s, v: v} } } << {s: :misc, v: 0})
    # Dragon cards omitted for debugging
    # card_data = ((%i{red green blue}).flat_map { |s| ((0..9).to_a).map { |v| {s: s, v: v} } } << {s: :misc, v: 0} << {s: :misc, v: 0}).shuffle
    card_data.each_with_index { |card_datum, idx|
      card = Card.new({
                          suit: card_datum[:s],
                          value: card_datum[:v],
                          file: (idx % 8),
                          rank: (idx / 8).to_i,
                          z: idx,
                          id: idx
                      })
      #clog "#{card.suit.to_s}_#{card.value.to_s} at rank #{card.rank} and file #{card.file}", :trace, __LINE__
      card.set_pos(card.calculate_snap_position)
      @cards << card
    }
    @entities += @cards
    light_buttons
  end
end

class Game
  attr_gtk
  attr_reader :stable_state

  def initialize
    @stable_state = StableState.new
  end

  # Reset the game

  # Render everything
  def render
    outputs.sprites << [0, 0, 1280, 720, "sprites/background.png"]
    outputs.sprites << stable_state.entities.sort_by { |ent| ent.z }.map { |ent| ent.sprite.list }
  end

  # Determine the entity the user clicked on
  def get_clicked_entity
    stable_state.entities
        .sort_by { |ent| -ent.z }
        .find { |ent| ent.contains_point(inputs.mouse.down.x, inputs.mouse.down.y) }
  end

  # Lists the cards that should be picked up along with a base card
  # @param [Card] base_card
  # @return [Array<Card>]
  def list_cards_to_grab(base_card)
    # @type [Array<Card>]
    cards = stable_state.cards
    if base_card.rank == -1
      if base_card.file > 2 or (base_card.suit == :misc and base_card.value != 0)
        return []
      else
        return [base_card]
      end
    end
    grabbed_cards = [base_card] + cards.find_all { |card| card.file == base_card.file and card.rank > base_card.rank }.sort_by { |card| card.rank }
    valid = true
    (0..grabbed_cards.length - 2).each { |idx|
      clog "#{grabbed_cards[idx].suit.to_s[0]}#{grabbed_cards[idx].value}", :debug, __LINE__
      valid &= ((grabbed_cards[idx].value == (grabbed_cards[idx + 1].value + 1)) and (grabbed_cards[idx].suit != grabbed_cards[idx + 1].suit))
    }
    unless valid
      return []
    end
    grabbed_cards
  end

  # Pick up a partial file of cards
  def grab_cards(base_card)
    # clog "#{base_card.suit.to_s}_#{base_card.value.to_s} clicked", :trace, __LINE__
    grab_list = list_cards_to_grab(base_card)
    if grab_list.length != 0
      stable_state.mouse_down_pos = {x: inputs.mouse.down.x, y: inputs.mouse.down.y}
      stable_state.held_cards = grab_list
      stable_state.held_cards.each { |held_card| held_card.z += stable_state.tick_count }
      stable_state.holding_cards = true
    end
  end

  # See what the user clicked on, then respond appropriately
  def process_mouse_down
    clicked_ent = get_clicked_entity
    if clicked_ent == nil
      clog('NIL CLICKED', :trace, __LINE__)
    else
      if stable_state.cards.include?(clicked_ent)
        dim_buttons
        grab_cards(clicked_ent)
      elsif stable_state.buttons.include?(clicked_ent)
        clog("CLICKED #{clicked_ent.suit.to_s} BUTTON", :trace, __LINE__)
      end
    end
  end

  # Update the positions of the held cards so they follow the mouse
  def drag_cards
    dx = inputs.mouse.x - stable_state.mouse_down_pos[:x]
    dy = inputs.mouse.y - stable_state.mouse_down_pos[:y]
    stable_state.held_cards.each do |held_card|
      pos = held_card.calculate_snap_position
      held_card.set_pos({x: pos[:x] + dx, y: pos[:y] + dy})
    end
  end

  def get_rank_file(params = {})
    x = params[:x] #Note: CENTER OF SPRITE, not corner!
    y = params[:y]
    rank = if y >= 508
             -1
           elsif y >= 386
             0
           else
             (417 - y) / 32
           end
    file = (x / 160).to_i
    {rank: rank.to_i, file: file.to_i}
  end

  # @param [Integer] file
  # @return [Array<Card>]
  def cards_in_file(file)
    stable_state.cards.find_all { |card| card.file == file and not ((stable_state.held_cards || []).include? card) }.sort_by { |card| card.rank }
  end

  # @return [Array<Card>]
  def cards_in_play
    stable_state.cards.find_all { |card| card.rank != -1 }.sort_by { |card| card.rank }
  end

  # @return [Array<Card>]
  def cards_on_top
    cards = []
    (0..7).each { |file|
      card = cards_in_file(file).find_all { |card| card.rank != -1 }.sort_by { |card| -card.rank }[0]
      if card != nil
        cards << card
      end
    }
    cards
  end

  # @return [Array<Card>]
  def cards_in_bank
    stable_state.cards.find_all { |card|
      (card.rank == -1) and
          (card.file < 3) and
          (not (stable_state.held_cards || []).include? card) and
          (not card.suit == :misc)
    }.sort_by { |card| card.file }
  end

  # Drops the currently held cards
  # Abandon hope, all ye who debug here
  def drop_cards
    start_time = Time.now
    skip_dur = 0

    droppable = false
    #@type [Array<Card>]
    held_cards = stable_state.held_cards
    #@type [Card]
    base_card = held_cards[0]
    base_rf = get_rank_file(base_card.sprite.center)
    file = base_rf[:file]
    if base_rf[:rank] == -1 and held_cards.length == 1 # Special top row
      if file < 3 # Bank spaces
        droppable = not(cards_in_file(file).any? { |card| card.rank == -1 })
      elsif file == 4 # Flower space
        droppable = (base_card.suit == :misc and base_card.value == 0) # Only one flower, no need to check if occupied
      elsif file > 4 # Discard space
        card = cards_in_file(file).find_all { |card| card.rank == -1 }.sort_by { |card| card.value }[-1]
        droppable = card == nil ? base_card.value == 1 : ((base_card.value == (card.value + 1)) and (base_card.suit == card.suit))
      end
      if droppable
        base_rf[:rank] = -1
      end
    elsif (file == base_card.file) and ((base_rf[:rank] == -1) == (base_card.rank == -1))
      droppable = false # This is misleading. You CAN drop cards back in their original file. In fact, that's exactly what happens when droppable is false.
    elsif base_rf[:rank] >= 0 # Normal play area
      file_card = cards_in_file(file).find_all { |card| card.rank >= 0 }[-1]
      if file_card == nil
        droppable = true
        base_rf[:rank] = 0
      else
        droppable = ((file_card.suit != base_card.suit) and (file_card.value - 1 == base_card.value) and (base_card.value > 0))
        base_rf[:rank] = file_card.rank + 1
      end
    end
    unless droppable
      base_rf = {rank: base_card.rank, file: base_card.file}
    end
    idx = 0
    held_cards.each do |held_card|
      # @type [Card]
      card = held_card
      card.rank = base_rf[:rank] + idx
      idx += 1
      card.file = base_rf[:file]
      card.set_pos(card.calculate_snap_position)
    end
    stable_state.mouse_down_pos = nil
    stable_state.held_cards = nil
    stable_state.mouse_down_pos = nil

    end_time = Time.now
    clog "Card dropping took #{end_time - start_time - skip_dur} seconds!", :debug, __LINE__
    clog "Logging took #{skip_dur} seconds!", :debug, __LINE__
  end

  def dim_buttons
    stable_state.buttons.each { |btn|
      btn.state == :dim if btn.state == :on
    }
  end

  # @return [Integer, nil]
  def get_bank_file_for_dragon(suit)
    #@type [Array<Card>]
    bank_cards = cards_in_bank
    if bank_cards.length == 3
      tmp = bank_cards.first { |card| card.suit == suit and card.value == 0 }
      tmp = tmp.file if tmp != nil
      tmp
    elsif bank_cards.length == 0
      return 0
    else
      (0..2).first { |file| bank_cards.none? { |card| card.file == file } }
    end
  end

  def light_buttons
    start_time = Time.now
    skip_dur = 0
    stable_state.buttons.find_all { |button|
      skip_dur += clog "Testing #{button.suit} button...", :trace, __LINE__
      #@type [Button]
      btn = button
      dim_test = button.state != :off
      bank_test = (dim_test and get_bank_file_for_dragon(btn.suit) != nil)
      access_test = (bank_test and (4 == (cards_in_bank + cards_on_top).count { |card| (card.suit == btn.suit and card.value == 0) }))

      (dim_test and bank_test and access_test)
    }.each do |button|
      button.state = :on
      skip_dur += clog "Lighting #{button.suit} button", __LINE__
    end
    end_time = Time.now
    clog "Button lighting took #{end_time - start_time - skip_dur} seconds!", :debug, __LINE__
    clog "Logging took #{skip_dur} seconds!", :debug, __LINE__
    nil
  end

  # See what the user is doing, and react accordingly
  def process_input
    if inputs.mouse.down
      process_mouse_down
    elsif stable_state.holding_cards and inputs.mouse.button_left
      drag_cards
    elsif stable_state.holding_cards and inputs.mouse.up
      drop_cards
      light_buttons
    end
    if inputs.keyboard.key_down.space
      # Reset the game
      $gtk.reset(seed: (Time.now.to_f * 100000).to_i)
      init_state
    end
  end

  # @param [$gtk.args] args
  def tick
    init_state
    process_input
    render
  end
end

$game = Game.new

def foo; end

def tick(args)
  trace! $game
  $game.args = args
  $game.tick
end