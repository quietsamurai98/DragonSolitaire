class Card
  attr_accessor :suit, :value
  #noinspection RubyResolve
  attr_sprite
  # constructor
  def initialize(params = {})
    @suit = params[:suit] || :red
    @value = params[:value] || 0
    self.x = params[:x] || 0
    self.y = params[:y] || 0
    self.w = 75
    self.h = 105
    update_sprite_path
  end

  def update_sprite_path
    self.path = "sprites/card_#{self.suit.to_s[0]}_#{self.value.to_s}.png"
  end
end

def init_state(args)
  args.state.initialized ||= false
  if args.state.initialized
    return
  end
  args.state.initialized = true
  args.state.cards = []
  # The next line generates an array of {s: suit, v: value} hashes that represents all cards in the deck.
  card_data = (%i{red green blue}).flat_map { |s| ([0, 0, 0] + (0..9).to_a).map { |v| {s: s, v: v} } } << {s: :misc, v: 0}
  card_data.each_with_index { |card_datum, idx|
    card = Card.new({
                        suit: card_datum[:s],
                        value: card_datum[:v],
                        x: (80 * (idx % 10)) + 5,
                        y: (110 * (idx / 10).to_i) + 5
                    })
    args.state.cards << card
  }
end

# @param [Object] args
def tick(args)
  init_state(args)
  args.outputs.sprites << args.state.cards
end

$gtk.reset