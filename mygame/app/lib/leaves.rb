class Leaves

  # on every run of the game, these scores are generated randomly for each plant species
  # 
  # alkaloids include psychoactive compounds like caffeine, nicotine, morphine, cannabinoids and psilocybin
  # alkaloids can have strong effects on the player character's mental state and abilities
  # they may induce feelings of euphoria, relaxation, or anxiety
  # they can also affect endurance, perception, cognition, and mood
  # 
  # flavonoid scores represent the taste properties of the leaves, such as bitterness, sweetness, astringency, and umami
  # 
  # rarity indicates how common or rare the leaves are in the game world

  attr_accessor :alkaloid_scores, :flavonoid_scores, :color, :rarity

  def initialize(type)
    @type = type
  end


end