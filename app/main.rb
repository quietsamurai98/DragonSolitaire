COLORS = {
    red: {r: 217, g: 95, b: 2},
    green: {r: 27, g: 158, b: 119},
    blue: {r: 117, g: 112, b: 179},
}

class CardSprite
  attr_accessor :background
  #noinspection RubyResolve
  attr_sprite

  def initialize(x, y)
    @x = x
    @y = y
    @w = 128
    @h = 180
    @background = [x,y,128,180,"sprites/card_bg.png"]
  end

  def set_appearance(suit, value)
    if value == 0 or suit == :misc #Card has a special sprite
      @r = 255
      @g = 255
      @b = 255
      if suit == :misc and value == 0
        @path = "sprites/card_flower.png"
      else
        if suit != :misc
          @r = COLORS[suit][:r]
          @g = COLORS[suit][:g]
          @b = COLORS[suit][:b]
          @path = "sprites/card_dragon_#{suit.to_s}.png"
        end
      end
    else
      @path = "sprites/card_#{value.to_s}.png"
      @r = COLORS[suit][:r]
      @g = COLORS[suit][:g]
      @b = COLORS[suit][:b]
    end
  end
end

class Card
  attr_accessor :suit, :value, :sprite, :x, :y
  # constructor
  def initialize(params = {})
    @suit = params[:suit] || :red
    @value = params[:value] || 0
    @x = params[:x] || 0
    @y = params[:y] || 0
    @sprite = CardSprite.new(@x, @y)
    update_sprite
  end

  def update_sprite
    @sprite.x = @x
    @sprite.y = @y
    @sprite.set_appearance(@suit, @value)
  end
end

def init_state(args)
  args.state.initialized ||= false
  if args.state.initialized
    return
  end
  $gtk.set_window_title "Dragon Solitaire"
  args.state.initialized = true
  args.state.cards = []
  # The next line generates an array of {s: suit, v: value} hashes that represents all cards in the deck.
  card_data = ((%i{red green blue}).flat_map { |s| ([0, 0, 0] + (0..9).to_a).map { |v| {s: s, v: v} } } << {s: :misc, v: 0}).shuffle
  card_data.each_with_index { |card_datum, idx|
    card = Card.new({
                        suit: card_datum[:s],
                        value: card_datum[:v],
                        x: (160 * (idx % 8))+16,
                        y: 300-(36 * (idx / 8).to_i)
                    })
    args.state.cards << card
  }
end

# @param [Object] args
def tick(args)
  if args.inputs.mouse.click
    args.state.initialized = false
  end
  init_state(args)
  #                          X    Y  WIDTH  HEIGHT  RED  GREEN  BLUE
  args.outputs.solids << [   0,   0,  1280,    720, 1,   55,  30]
  args.outputs.sprites << args.state.cards.map { |card| [card.sprite.background, card.sprite] }
end

$gtk.reset