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

  attr_accessor :alkaloid_scores, :flavonoid_scores, :color, :rarity, :kind

  def self.alkaloids
    [:berberine, :quinine, :caffeine, :nicotine, :cocaine, :codeine, :morphine, :cannabinoids, :psilocybin]
  end

  def self.flavonoids
    [:bitterness, :sweetness, :astringency, :umami]
  end

  def initialize(kind)
    @kind = kind
    @alkaloid_scores = {}
    @flavonoid_scores = {}
  end

  def self.common_kinds
    [:green, :dark_green, :light_green, :olive, :lime]
  end

  def self.rare_kinds
    [:yellow, :red, :purple, :black, :pink, :blue]
  end

  def self.create_kinds args
    args.state.leaf_kinds = []
    common_kinds = self.common_kinds
    rare_kinds = self.rare_kinds
    alkaloid_lottery = self.alkaloids.shuffle
    flavonoid_lottery = self.flavonoids.shuffle
    for kind in common_kinds do
      new_leaf = new(kind)
      alkaloid = alkaloid_lottery.pop
      flavonoid = flavonoid_lottery.pop
      new_leaf.alkaloid_scores[alkaloid] = Numeric.rand(1..3) if alkaloid
      new_leaf.flavonoid_scores[flavonoid] = Numeric.rand(1..3) if flavonoid
      new_leaf.rarity = :common
      args.state.leaf_kinds << new_leaf
    end
    alkaloid_lottery = self.alkaloids.shuffle
    flavonoid_lottery = self.flavonoids.shuffle
    for kind in rare_kinds do
      new_leaf = new(kind)
      alkaloid = alkaloid_lottery.pop
      flavonoid = flavonoid_lottery.pop
      new_leaf.alkaloid_scores[alkaloid] = Numeric.rand(1..3) if alkaloid
      new_leaf.flavonoid_scores[flavonoid] = Numeric.rand(1..3) if flavonoid
      new_leaf.rarity = :rare
      secondary_alkaloid = self.alkaloids.sample
      new_leaf.alkaloid_scores[secondary_alkaloid] = Numeric.rand(1..3)
      secondary_flavonoid = self.flavonoids.sample
      new_leaf.flavonoid_scores[secondary_flavonoid] = Numeric.rand(1..3)
      args.state.leaf_kinds << new_leaf
    end
  end

end