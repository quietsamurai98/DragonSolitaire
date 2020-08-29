COLORS = {
    red: {r: 217, g: 95, b: 2},
    green: {r: 27, g: 158, b: 119},
    blue: {r: 117, g: 112, b: 179},
    white: {r: 255, g: 255, b: 255}
}

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
end

class Card
  attr_accessor :suit, :value, :x, :y, :z, :id

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
    @sprite = CardMultiSprite.new
    update_sprite_pos
    update_sprite_img
  end

  def set_pos(params = {})
    @x = params[:x] || @x
    @y = params[:y] || @y
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
end

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
                        x: (160 * (idx % 8)) + 16,
                        y: 300 - (36 * (idx / 8).to_i),
                        z: idx,
                        id: idx
                    })
    args.state.cards << card
    args.state.entities = args.state.cards
  }
end

def render(args)
  args.outputs.sprites << [0, 0, 1280, 720, "sprites/background.png"]
  args.outputs.sprites << args.state.cards.sort_by { |card| card.z }.map { |card| card.sprite.list }
end

def get_clicked_entity(args)
  args.state.entities
      .sort_by { |ent| -ent.z }
      .find { |ent| ent.contains_point(args.inputs.mouse.down.x, args.inputs.mouse.down.y) }
end

def get_held_cards(args, base_card)
  [base_card] # TODO: Return a list of all cards in the picked up stack
end

def process_input(args)
  if args.inputs.mouse.down
    clicked_ent = get_clicked_entity(args)
    if clicked_ent == nil
      puts 'NIL CLICKED'
    else
      if args.state.cards.include?(clicked_ent)
        puts "#{clicked_ent.suit.to_s}_#{clicked_ent.value.to_s} clicked"
        args.state.mouse_down_pos = {x: args.inputs.mouse.down.x, y: args.inputs.mouse.down.y}
        args.state.held_cards = get_held_cards(args, clicked_ent).map { |card| {card: card, init_pos: {x: card.x, y: card.y}} }
        args.state.held_cards.each do |held_card|
          held_card[:card].z += args.state.tick_count
        end
        args.state.holding_cards = true
      end
    end
  end
  if args.inputs.mouse.button_left and args.state.holding_cards and not args.inputs.mouse.down
    dx = args.inputs.mouse.x - args.state.mouse_down_pos[:x]
    dy = args.inputs.mouse.y - args.state.mouse_down_pos[:y]
    args.state.held_cards.each do |held_card|
      held_card[:card].set_pos({x: held_card[:init_pos][:x] + dx, y: held_card[:init_pos][:y] + dy})
    end
  end
  if args.inputs.mouse.up and args.state.holding_cards
    args.state.mouse_down_pos = nil
    args.state.held_cards = nil
    args.state.mouse_down_pos = nil
  end
  if args.inputs.keyboard.key_down.space
    args.state.initialized = false
  end
end

# @param [Object] args
def tick(args)
  init_state(args)
  process_input(args)
  render(args)
end

$gtk.reset