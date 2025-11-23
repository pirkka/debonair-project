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
      :spear,
      :katana,
      :club
    ]
  end

  def self.common_attributes
    [
      :rusty,
      :broken,
      :fine,
      :crude
    ]
  end

  def self.rare_attributes
    [
      :masterwork
    ]
  end

  def set_weight
    case @kind
    when :dagger
      @weight = 0.4
    when :sword
      @weight = 1.5
    when :axe
      @weight = 2.0
    when :mace
      @weight = 2.5
    when :spear
      @weight = 1.8
    when :katana
      @weight = 1.3
    when :club
      @weight = 2.2
    else
      @weight = 0.6
    end 
  end

  def self.randomize(depth, args)
    weapon = Weapon.new(Weapon.kinds.sample)
    weapon.depth = depth
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

  def use(entity, args)
    if entity.wielded_items.include?(self)
      HUD.output_message(args, "You unwield the #{self.attributes.join(' ')} #{self.kind.to_s.gsub('_',' ')}.".gsub('  ',' '))
      entity.wielded_items.delete(self)
    else
      entity.wielded_items = [self] # only one weapon at a time for now
      HUD.output_message(args, "You wield the #{self.attributes.join(' ')}#{self.kind.to_s.gsub('_',' ').gsub('  ',' ')}.")
      SoundFX.play(:blade, args) # TODO: different sound for different weapon types
    end
    args.state.kronos.spend_time(entity, entity.walking_speed * 0.5, args) 
  end

  def title
    "#{self.attributes.join(' ')} #{self.kind.to_s.gsub('_',' ')}".gsub('  ',' ').trim
  end

  def self.generate_for_npc(npc, depth, args)
    case npc.species
    when :goblin
      weapon = Weapon.new(:dagger)
      weapon.add_attribute(:crude)
    when :orc
      weapon = Weapon.new(:axe)
      weapon.add_attribute(:crude)
    when :skeleton
      weapon = Weapon.new(:sword)
      weapon.add_attribute(:rusty)
    else
      weapon = Weapon.randomize(depth, args)
    end
    return weapon
  end

  def break_check(args)
    roll = args.state.rng.d20
    break_threshold = 11
    if self.attributes.include?(:broken)
      return
    end
    if self.attributes.include?(:masterwork)
      break_threshold += 8
    end
    if self.attributes.include?(:fine)
      break_threshold += 5
    end
    if self.attributes.include?(:crude) || self.attributes.include?(:rusty)
      break_threshold -= 3
    end
    if roll >= break_threshold
      HUD.output_message(args, "Your #{self.title} breaks!")
      SoundFX.play_sound(:item_break, args)
      self.add_attribute(:broken)
    end
  end
  
end