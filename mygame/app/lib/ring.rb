class Ring < Item

  @@mask_index_seed = nil

  def initialize(kind)
    super(kind, :ring)
  end

  def self.kinds
    return [
    :ring_of_endurance, 
    :ring_of_fire_resistance, 
    :ring_of_cold_resistance,
    :ring_of_invisibility,
    :ring_of_protection, 
    :ring_of_strength, 
    :ring_of_stealth, 
    :ring_of_regeneration, 
    :ring_of_adornment,
    :ring_of_teleportation,
    :ring_of_accuracy,
    :ring_of_night_vision,
    :ring_of_warning,
    :ring_of_telepathy]
  end

  def self.masks
    [
      :sapphire,
      :emerald,
      :ruby,
      :diamond,
      :onyx,
      :topaz,
      :amethyst,
      :garnet,
      :opal,
      :turquoise
    ]
  end
end