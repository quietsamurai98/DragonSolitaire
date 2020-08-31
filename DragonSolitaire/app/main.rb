# Constants used for debugging
FLOWER_POWER = false # Every card can be dropped into the flower card slot. If you're looking for a cheat code, here it is.
SHUFFLE = true # Shuffle the deck. You can't win if you don't shuffle. Used to debug dragon buttons.
ONLY_DRAGONS = false # Skip numbered cards
TRACE_ENABLED = false # Enable tracing. SUPER SLOW!
PRODUCTION = false # Enable production mode
MIN_LOG_LEVEL = :warn # Minimum log level for clog. Trace *kills* framerate if running on HDD.

COLORS = {
    red: {r: 217, g: 95, b: 2},
    green: {r: 27, g: 158, b: 119},
    blue: {r: 117, g: 112, b: 179},
    white: {r: 255, g: 255, b: 255}
}

LOG_LEVELS = {
    trace: {str: "[TRACE] ", level: 0},
    prof: {str: "[PROF]  ", level: 1},
    debug: {str: "[DEBUG] ", level: 2},
    info: {str: "[INFO]  ", level: 3},
    warn: {str: "[WARN]  ", level: 4},
    err: {str: "[ERROR] ", level: 5},
    fatal: {str: "[FATAL] ", level: 6},
}

# @param [String, #to_s] msg The message to log
# @param [Symbol, nil] level The level at which to log msg
# @param [#to_s] line Just pass in `__LINE__`.
def clog(msg, level = nil, line = '???')
    level ||= :info
    level = LOG_LEVELS[level]
    if LOG_LEVELS[MIN_LOG_LEVEL][:level] <= level[:level]
      puts "#{level[:str]}[L\##{line}]  #{msg}"
    end
end

def profile(method_name="anonymous", &code)
  start_time = Time.now
  out = code.call
  t = Time.now - start_time
  if t.to_f.round(3) > 0.001
    clog("`#{method_name}` took #{t.to_f.round(3).to_s} seconds", :prof, __LINE__)
  end
  out
end

# Name is misleading. Only allows a foreground colored mask sprite and a background sprite.
#noinspection RubyResolve
class AbstractMultiSprite
  attr_accessor :background
  attr_sprite

  def set_color(color)
    @r = color[:r]
    @g = color[:g]
    @b = color[:b]
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

class ButtonMultiSprite < AbstractMultiSprite
  def initialize(params = {})
    @x = params[:x] || 0
    @y = params[:y] || 0
    @w = 48
    @h = 48
    @a = 255
    @path = nil
    @background = {x: x, y: y, w: @w, h: @h, path: "sprites/button_bg_dim.png"}
  end

  def set_img(suit, state)
    @path = "sprites/button_icon_#{suit.to_s}.png"
    @background[:path] = "sprites/button_bg_#{state.to_s}.png"
    set_color(COLORS[suit])
    if state == :off
      @r *= 0.5
      @g *= 0.5
      @b *= 0.5
      @a = 128
    end
  end

  def set_color(color)
    super
  end

  def set_pos(params = nil)
    super
  end

  def list
    super
  end

  def center
    super
  end

end

#noinspection RubyResolve
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

#noinspection RubyResolve
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
    if value == 0 || suit == :misc
      #Card has a special sprite
      if suit == :misc && value == 0
        set_color(COLORS[:white])
        @path = "sprites/card_flower.png"
      elsif suit == :misc && value == 1
        set_color(COLORS[:white])
        @path = "sprites/card_back.png"
      elsif suit != :misc
        set_color(COLORS[suit])
        @path = "sprites/card_dragon_#{suit.to_s}.png"
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

#noinspection RubyResolve
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
    x1 < x && x < x2 && y1 < y && y < y2
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

#noinspection RubyResolve
class StableState
  attr_accessor :holding_cards, :mouse_down_pos, :entities, :buttons, :cards, :held_cards, :gtk_state,
                :last_mouse_bits, :auto_move_cooldown, :sprites, :paused, :screen_dirty

  # @param [OpenEntity] gtk_state The actual state of the game engine
  def initialize(gtk_state)
    if TRACE_ENABLED
      trace!
    end
    @last_mouse_bits = 0
    @auto_move_cooldown = 20
    @get_state = gtk_state
    $gtk.set_window_title "Dragon Solitaire"
    #@type Boolean
    @holding_cards = false
    #@type Hash
    @mouse_down_pos = {x: 0, y: 0}
    #@type Array<Card>
    @held_cards = []
    #@type Array<Entity>
    @entities = []
    #@type Array<Button>
    @buttons = [
        Button.new({suit: :red, state: :dim, x: 536, y: 647}),
        Button.new({suit: :green, state: :dim, x: 536, y: 590}),
        Button.new({suit: :blue, state: :dim, x: 536, y: 533})
    ]
    @entities += @buttons
    @cards = []
    # The next line generates an array of {s: suit, v: value} hashes that represents all cards in the deck.
    card_data = ((%i{red green blue}).flat_map { |s| ((1..(ONLY_DRAGONS ? 0 : 9)).to_a + [0, 0, 0, 0]).map { |v| {s: s, v: v} } } << {s: :misc, v: 0})
    if SHUFFLE
      card_data = card_data.shuffle
    end
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
      clog("#{card.suit.to_s}_#{card.value.to_s} at rank #{card.rank} and file #{card.file}", :trace, __LINE__)
      card.set_pos(card.calculate_snap_position)
      @screen_dirty = true
      @cards << card
    }
    @entities += @cards
  end

  def serialize
    {holding_cards: holding_cards, mouse_down_pos: mouse_down_pos, held_cards: held_cards, cards: cards, buttons: buttons}
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end


end

#noinspection RubyResolve
class Game
  attr_gtk

  # @return [StableState]
  def stable_state
    state.stable_state
  end

  def stable_state= (val)
    state.stable_state = val
  end

  def initialize(args)
    @args = args
    if TRACE_ENABLED
      trace!
    end
    new_game
  end

  def new_game
    self.stable_state = StableState.new(@args)
    light_buttons
  end

  def tick_count
    state.tick_count
  end

  # Render everything
  def render
    outputs.background_color = [1, 55, 30]
    stable_state.sprites = []
    stable_state.paused = false
    outputs.static_sprites.clear
    stable_state.sprites << [0, 0, 1280, 720, "sprites/background.png"]
    stable_state.sprites << stable_state.entities.sort_by { |ent| ent.z }.map { |ent| ent.sprite.list }
    outputs.sprites << stable_state.sprites
  end
  # Just re-render the last frame. Reduces idle CPU usage.
  def render_paused
    outputs.background_color = [1, 55, 30]
    unless stable_state.paused
      outputs.static_sprites << stable_state.sprites
      stable_state.paused = true
    end
  end

  # @param [Card] card
  # @param [nil, Integer] rank
  # @param [nil, Integer] file
  # @param [nil, Integer] value
  # @param [nil, Symbol] suit
  def alter_card(card, rank = nil, file = nil, value = nil, suit = nil)
    card.rank = rank if rank
    card.file = file if file
    card.suit = suit if suit
    card.value= value if value
    card.set_pos(card.calculate_snap_position)
  end

  # Determine the entity the user clicked on
  def get_clicked_entity
    stable_state.entities
        .sort_by { |ent| -ent.z }
        .find { |ent| ent.contains_point(inputs.mouse.x, inputs.mouse.y) }
  end

  # Lists the cards that should be picked up along with a base card
  # @param [Card] base_card
  # @return [Array<Card>]
  def list_cards_to_grab(base_card)
    # @type [Array<Card>]
    cards = stable_state.cards
    if base_card.rank == -1
      if base_card.file > 2 || (base_card.suit == :misc && base_card.value != 0)
        return []
      else
        return [base_card]
      end
    end
    grabbed_cards = [base_card] + cards.find_all { |card| card.file == base_card.file && card.rank > base_card.rank }.sort_by { |card| card.rank }
    valid = true
    (0..grabbed_cards.length - 2).each { |idx|
      valid &= ((grabbed_cards[idx].value == (grabbed_cards[idx + 1].value + 1)) && (grabbed_cards[idx].suit != grabbed_cards[idx + 1].suit))
    }
    unless valid
      return []
    end
    grabbed_cards
  end

  # Pick up a partial file of cards
  def grab_cards(base_card)
    grab_list = list_cards_to_grab(base_card)
    if grab_list.length != 0
      stable_state.mouse_down_pos = {x: inputs.mouse.x, y: inputs.mouse.y}
      stable_state.held_cards = grab_list
      stable_state.held_cards.each { |held_card| held_card.z += tick_count }
      stable_state.holding_cards = true
    end
  end

  # @param [Button] btn
  def dragon_button_pressed(btn)
    if btn.state == :on
      file = get_bank_file_for_dragon(btn.suit)
      cards_in_play(true).find_all { |card| card.suit == btn.suit && card.value == 0 }.each do |card|
        alter_card(card, -1, file, 1, :misc)
      end
      btn.state = :off
      btn.update_sprite_img
      dim_buttons
      light_buttons
    end
  end

  # See what the user clicked on, then respond appropriately
  def process_mouse_down
    clicked_ent = get_clicked_entity
    if clicked_ent == nil
      clog('NIL CLICKED', :trace, __LINE__)
    else
      if stable_state.cards.include?(clicked_ent)
        clog("CLICKED CARD #{clicked_ent.suit.to_s}_#{clicked_ent.value.to_s}", :trace, __LINE__)
        dim_buttons
        profile('grab_cards') {grab_cards(clicked_ent)}
      elsif stable_state.buttons.include?(clicked_ent)
        clog("CLICKED #{clicked_ent.suit.to_s} BUTTON", :trace, __LINE__)
        dragon_button_pressed(clicked_ent)
      end
    end
  end

  # @param [Card] card card
  def auto_move_card(card)
    return nil unless (cards_on_top + stable_state.cards.find_all {|c| c.rank == -1 && c.file < 3}).include? card
    discarded_cards = stable_state.cards.find_all {|c| c.rank == -1 && c.file > 4}
    discard_pile_top_card = discarded_cards.find {|c| c.suit == card.suit && c.value+1 == card.value}
    new_rank = nil
    new_file = nil
    if FLOWER_POWER || (card.suit == :misc && card.value == 0)
      new_rank = -1
      new_file = 4
    elsif discard_pile_top_card
      if ((cards_in_play(true )-[card]-discarded_cards).count {|c| c.suit != card.suit && c.suit!=:misc && (c.value+1) == card.value}) == 0
        new_rank = -1
        new_file = discard_pile_top_card.file
      end
    elsif card.suit != :misc && card.value == 1
      new_rank = -1
      new_file = (5..7).find {|f| discarded_cards.none?{|c| c.file == f}}
    end
    if new_rank || new_file
      alter_card(card, new_rank, new_file)
      stable_state.auto_move_cooldown = 5
    end
    !!(new_rank || new_file)
  end

  def auto_move_cards
    stable_state.auto_move_cooldown -= 1 if stable_state.auto_move_cooldown > 0
    return false if stable_state.holding_cards || (stable_state.auto_move_cooldown != 0)
    q = cards_on_top + stable_state.cards.find_all {|c| c.rank == -1 && c.file < 3}
    c = q.shift
    while c
      return true if auto_move_card(c)
      c = q.shift
    end
    dim_buttons
    light_buttons
    false
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
    stable_state.cards.find_all { |card| card.file == file && not((stable_state.held_cards || []).include? card) }.sort_by { |card| card.rank }
  end

  # @param [Boolean] include_bank
  # @return [Array<Card>]
  def cards_in_play(include_bank = false)
    stable_state.cards.find_all { |card| card.rank != -1 || (include_bank && card.file < 3) }.sort_by { |card| card.rank }
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
      (card.rank == -1) &&
          (card.file < 3) &&
          (not ((stable_state.held_cards || []).include? card))
    }.sort_by { |card| card.file }
  end

  # Drops the currently held cards
  # Abandon hope, all ye who debug here
  def drop_cards
    
    droppable = false
    #@type Array<Card>
    held_cards = stable_state.held_cards
    #@type Card
    base_card = held_cards[0]
    if base_card != nil
      base_rf = get_rank_file(base_card.sprite.center)
      file = base_rf[:file]
      if base_rf[:rank] == -1 && held_cards.length == 1 # Special top row
        if file < 3 # Bank spaces
          droppable = not(cards_in_file(file).any? { |card| card.rank == -1 })
        elsif file == 4 # Flower space
          droppable = FLOWER_POWER || (base_card.suit == :misc && base_card.value == 0) # Only one flower, no need to check if occupied
        elsif file > 4 # Discard space
          card = cards_in_file(file).find_all { |card| card.rank == -1 }.sort_by { |card| card.value }[-1]
          droppable = card == nil ? base_card.value == 1 : ((base_card.value == (card.value + 1)) && (base_card.suit == card.suit))
        end
        if droppable
          base_rf[:rank] = -1
        end
      elsif (file == base_card.file) && ((base_rf[:rank] == -1) == (base_card.rank == -1))
        droppable = false # This is misleading. You CAN drop cards back in their original file. In fact, that's exactly what happens when droppable is false.
      elsif base_rf[:rank] >= 0 # Normal play area
        file_card = cards_in_file(file).find_all { |card| card.rank >= 0 }[-1]
        if file_card == nil
          droppable = true
          base_rf[:rank] = 0
        else
          droppable = ((file_card.suit != base_card.suit) && (file_card.value - 1 == base_card.value) && (base_card.value > 0))
          base_rf[:rank] = file_card.rank + 1
        end
      end
      unless droppable
        base_rf = {rank: base_card.rank, file: base_card.file}
      end
      idx = 0
      held_cards.each do |held_card|
        new_rank = base_rf[:rank] + idx
        idx += 1
        new_file = base_rf[:file]
        alter_card(held_card, new_rank, new_file)
      end
    else
      clog("UNEXPECTED STATE: Somehow, the player has grabbed zero cards.", :err, __LINE__)
    end
    stable_state.held_cards = []
    stable_state.holding_cards = false
  end

  def dim_buttons
    stable_state.buttons.each { |btn|
      if btn.state == :on
        btn.state = :dim
      end
    }
  end

  # @return [Integer, nil]
  def get_bank_file_for_dragon(suit)
    bank = cards_in_bank
    (0..2).to_a.find { |file| (nil == bank.find { |card| card.file == file }) || (nil == bank.find { |card| card.file == file && not(card.value == 0 && card.suit == suit) }) }
  end

  def light_buttons
    
    stable_state.buttons.find_all do |button|
      clog("Testing #{button.suit} button...", :trace, __LINE__)
      #@type Button
      btn = button
      dim_test = btn.state != :off
      clog("dim_test: #{dim_test}", :trace, __LINE__)
      bank_test = (dim_test && (get_bank_file_for_dragon(btn.suit) != nil))
      clog("bank_test: #{bank_test}", :trace, __LINE__)
      access_test = (bank_test && (4 == (cards_in_bank + cards_on_top).count { |card| ((card.suit == btn.suit) && (card.value == 0)) }))
      clog("access_test: #{access_test}", :trace, __LINE__)
      access_test
    end.each do |button|
      button.state = :on
      clog("Lighting #{button.suit} button", :trace, __LINE__)
    end
    nil
  end

  def mouse_mask_to_list(mask)
    out = []
    out << :lmb if inputs.mouse.click || (mask & 1) != 0
    out << :mmb if (mask & 2) != 0
    out << :rmb if (mask & 4) != 0
    out << :mouse5 if (mask & 8) != 0
    out << :mouse4 if (mask & 16) != 0
    out
  end
  def mouse_down_list
    mouse_mask_to_list ~stable_state.last_mouse_bits & inputs.mouse.button_bits
  end
  def mouse_up_list
    mouse_mask_to_list stable_state.last_mouse_bits & ~inputs.mouse.button_bits
  end
  def mouse_held_list
    mouse_mask_to_list stable_state.last_mouse_bits & inputs.mouse.button_bits
  end
  def mouse_unheld_list
    mouse_mask_to_list ~(stable_state.last_mouse_bits & inputs.mouse.button_bits)
  end

  # See what the user is doing, and react accordingly
  def process_input
    input_detected = true
    if mouse_down_list.include? :lmb
      profile('process_mouse_down') {process_mouse_down}
    elsif stable_state.holding_cards && mouse_held_list.include?(:lmb)
      profile('drop_cards') {drag_cards}
    elsif stable_state.holding_cards && mouse_up_list.include?(:lmb)
      profile('drop_cards') {drop_cards}
      profile('dim_buttons') {dim_buttons}
      profile('light_buttons') {light_buttons}
    elsif inputs.keyboard.key_down.space
      # Reset the game
      stable_state.screen_dirty = true
      new_game
    else
      input_detected = false
    end
    stable_state.auto_move_cooldown = 10 if input_detected
    input_detected
  end

  # @param [$gtk.args] args
  def tick(args)
    @args = args
    old_dirty = stable_state.screen_dirty || stable_state.auto_move_cooldown != 0
    stable_state.screen_dirty = false
    if inputs.keyboard.has_focus
      stable_state.screen_dirty |= auto_move_cards if old_dirty
      profile('process_input') { stable_state.screen_dirty |= process_input }
    end
    if stable_state.screen_dirty || (Kernel::global_tick_count == 0)
      render
    else
      render_paused
    end
    stable_state.last_mouse_bits=inputs.mouse.button_bits
  end
end

if Kernel::global_tick_count == 0
  $game = nil
end
if PRODUCTION
  $gtk.define_singleton_method(:production) { true } #shhhhhhh
end
#noinspection RubyResolve,RubyNilAnalysis
def tick(args)
  GTK::Trace.flush_trace(true) if Kernel.global_tick_count % 600 == 0
  if Kernel::global_tick_count == 0
    $game = Game.new args
    if PRODUCTION
      args.gtk.log_level = :on
      $gtk.define_singleton_method(:production) { true } #shhhhhhh
    end
  end
  $game.tick args
end