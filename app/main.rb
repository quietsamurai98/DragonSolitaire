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
MIN_LOG_LEVEL = LOG_LEVELS[:trace]

def clog(msg, level = nil)
  level ||= :info
  level = LOG_LEVELS[level]
  if MIN_LOG_LEVEL[:level] <= level[:level]
    puts "#{level[:str]}#{msg}"
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

# Reset the game
def init_state(args)
  args.state.initialized ||= false
  if args.state.initialized
    return
  end
  $gtk.set_window_title "Dragon Solitaire"
  args.state.initialized = true
  args.state.holding_cards = false
  args.state.mouse_down_pos = nil
  args.state.held_cards = nil
  args.state.cards = []
  # The next line generates an array of {s: suit, v: value} hashes that represents all cards in the deck.
  card_data = ((%i{red green blue}).flat_map { |s| ([0, 0, 0] + (0..9).to_a).map { |v| {s: s, v: v} } } << {s: :misc, v: 0}).shuffle
  card_data.each_with_index { |card_datum, idx|
    card = Card.new({
                        suit: card_datum[:s],
                        value: card_datum[:v],
                        file: (idx % 8),
                        rank: (idx / 8).to_i,
                        z: idx,
                        id: idx
                    })
    clog "#{card.suit.to_s}_#{card.value.to_s} at rank #{card.rank} and file #{card.file}"
    card.set_pos(card.calculate_snap_position)
    args.state.cards << card
    args.state.entities = args.state.cards
  }
end

# Render everything
def render(args)
  args.outputs.sprites << [0, 0, 1280, 720, "sprites/background.png"]
  args.outputs.sprites << args.state.entities.sort_by { |ent| ent.z }.map { |ent| ent.sprite.list }
end

# Determine the entity the user clicked on
def get_clicked_entity(args)
  args.state.entities
      .sort_by { |ent| -ent.z }
      .find { |ent| ent.contains_point(args.inputs.mouse.down.x, args.inputs.mouse.down.y) }
end

# Lists the cards that should be picked up along with a base card
# @param [Object] args
# @param [Card] base_card
# @return [Array<Card>]
def list_cards_to_grab(args, base_card)
  # @type [Array<Card>]
  cards = args.state.cards
  if base_card.rank == -1
    return [base_card]
  end
  cards.find_all { |card| card.file == base_card.file and card.rank > base_card.rank }.sort_by { |card| card.rank }
end

# Pick up a partial file of cards
def grab_cards(args, base_card)
  # clog "#{base_card.suit.to_s}_#{base_card.value.to_s} clicked"
  args.state.mouse_down_pos = {x: args.inputs.mouse.down.x, y: args.inputs.mouse.down.y}
  args.state.held_cards = list_cards_to_grab(args, base_card)
  args.state.held_cards.each do |held_card|
    held_card[:card].z += args.state.tick_count
    clog "GRABBED #{held_card.suit.to_s[0]}#{held_card.value}"
  end
  args.state.holding_cards = true
end

# See what the user clicked on, then respond appropriately
def process_mouse_down(args)
  clicked_ent = get_clicked_entity(args)
  if clicked_ent == nil
    clog('NIL CLICKED', :trace)
  else
    if args.state.cards.include?(clicked_ent)
      grab_cards(args, clicked_ent)
    end
  end
end

# Update the positions of the held cards so they follow the mouse
def drag_cards(args)
  dx = args.inputs.mouse.x - args.state.mouse_down_pos[:x]
  dy = args.inputs.mouse.y - args.state.mouse_down_pos[:y]
  args.state.held_cards.each do |held_card|
    held_card.set_pos({x: held_card[:init_pos][:x] + dx, y: held_card[:init_pos][:y] + dy})
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

# @param [Object] args
# @param [Integer] file
# @return [Array<Card>]
def cards_in_file(args, file)
  args.state.cards.find_all { |card| card.file == file and not (args.state.held_cards.include? card) }.sort_by { |card| card.rank }
end

# Drops the currently held cards
def drop_cards(args)
  droppable = false
  #@type [Array<Card>]
  held_cards = args.state.held_cards
  #@type [Card]
  base_card = held_cards[0]
  clog "foo", :trace
  clog base_card.class, :trace
  $gtk.trace!
  base_rf = get_rank_file(base_card.sprite.center)
  clog "bar", :trace
  file = base_rf[:file]
  if base_rf[:rank] == -1 and held_cards.length == 1 # Special top row
    if file < 3 # Free spaces
      droppable = not(cards_in_file(args, file).any { |card| card.rank == -1 })
    elsif file == 4 # Flower space
      droppable = (base_card.suit == :misc and base_card.value == 0) # Only one flower, no need to check if occupied
    elsif file > 4 # Discard space
      card = cards_in_file(args, file).find { |card| card.rank == -1 }
      droppable = card == nil ? base_card.value == 1 : ((base_card.value == (card.value + 1)) and (base_card.suit == card.suit))
    end
    if droppable
      base_rf[:rank] = -1
    end
  elsif file == base_card.file
    droppable = false # This is misleading. You CAN drop cards back in their original file. In fact, that's exactly what happens when droppable is false.
  elsif base_rf[:rank] >= 0 # Normal play area
    file_card = cards_in_file(args, file)[-1]
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
  held_cards.each_with_index do |held_card, idx|
    # @type [Card]
    card = held_card[:card]
    card.rank = base_rf[:rank] + idx
    card.file = base_rf[:file]
    card.set_pos(card.calculate_snap_position)
  end
  args.state.mouse_down_pos = nil
  args.state.held_cards = nil
  args.state.mouse_down_pos = nil
end

# See what the user is doing, and react accordingly
def process_input(args)
  if args.inputs.mouse.down
    process_mouse_down(args)
  end
  if args.inputs.mouse.button_left and args.state.holding_cards and not args.inputs.mouse.down
    drag_cards(args)
  end
  if args.inputs.mouse.up and args.state.holding_cards
    drop_cards(args)
  end
  if args.inputs.keyboard.key_down.space
    # Reset the game
    $gtk.reset(seed: Time.now.to_i)
    init_state(args)
  end
end

# @param [$gtk.args] args
def tick(args)
  init_state(args)
  process_input(args)
  render(args)
end

$gtk.reset