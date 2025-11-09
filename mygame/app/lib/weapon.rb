class Weapon < Item
  
  def initialize(kind)
    super(kind, :weapon)
  end

  def self.kinds
    return [
    :dagger, 
    :sword, 
    :axe, 
    :mace, 
    :bow, 
    :spear,
    :katana,
    :club]
  end

  def self.common_attributes
    [
      :rusty,
      :broken,
      :fine
    ]
  end

  def self.rare_attributes
    [
      :masterwork
    ]
  end

  def self.randomize(level, args)
    weapon = Weapon.new(Weapon.kinds.sample)
    weapon.level = level
    common_roll = args.state.rng.d6
    secondary_common_roll = args.state.rng.d8
    rare_roll = args.state.rng.d20
    if rare_roll == 20
      weapon.add_attribute(Weapon.rare_attributes.sample)
    end
    if common_roll <= 2
      weapon.add_attribute(Weapon.common_attributes.sample)
    end
    if secondary_common_roll == 1
      weapon.add_attribute(Weapon.common_attributes.sample)
    end
    return weapon
  end
end