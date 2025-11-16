class Hero < Entity

  include Needy

  attr_reader :role, :species, :trait, :age, :name, :exhaustion, :sleep_deprivation, :insanity, :carried_items
  attr_accessor :hunger

  def initialize(x, y)
    super(x, y)
    initialize_needs
    @kind = :pc
    @role = Hero.roles.sample
    @species = Hero.species.sample
    @trait = Hero.traits.sample
    @age = Hero.age.sample
    @name = 'Jaakko'
    @exhaustion = 0.2 # 0.0 = totally rested, 1.0 = totally exhausted
    @hunger = 0.2 # 0.0 = satiated, 1.0 = starving
    @hunger_level = :okay
    @sleep_deprivation = 0.2 # 0.0 = well-rested, 1.0 = totally sleep-deprived
    @insanity = 0.0 # 0.0 = sane, 1.0 = totally insane
    @stress = 0.0 # 0.0 = calm, 1.0 = totally stressed
    @carried_items = []
  end

  def self.roles
    [
      :archeologist, # maps and artifacts
      :cleric, # holiness
      :detective, # investigation and clues
      :druid, # spells and nature
      :mage, # classic spellcaster
      :monk, # martial arts and spirituality
      :ninja, # stealth and combat
      :rogue, # agility and trickery
      :samurai, # combat and honor
      :thief, # stealth and deception
      :tourist, # camera and confidence
      :warrior, # strength and bravery
    ]
  end

  def self.species
    [
      :human,
      :elf,
      :dwarf,
      :orc,
      :gnome,
      :halfling,
      :dark_elf,
      :goblin,
      :troll,
      :duck # glorantha style
    ]
  end

  def self.age
    [
      :teen,
      :adult,
      :elder
    ]
  end

  def self.traits
    [
      :none,
      :undead,
      :mutant,
      :cyborg,      
      :alien,
      :robot,
      :vampire,
      :werewolf,
      :zombie,
      :demon,
      :angel
    ]
  end

  def vision_range
    range = 7
    if @age == :elder
      range -= 2
    end
    if @species == :dwarf || @species == :gnome
      range -= 1
    end
    if @species == :elf || @species == :dark_elf
      range += 1
    end
    return range
  end

  def walking_speed
    seconds_per_tile = 1.0
    if @age == :elder
      seconds_per_tile += 0.5
    end
    if @trait == :robot
      seconds_per_tile += 0.1
    end
    if @trait == :cyborg 
      seconds_per_tile -= 0.1
    end
    if @species == :duck
      seconds_per_tile += 0.2
    end
    if @species == :elf || @species == :dark_elf
      seconds_per_tile -= 0.2
    end
    if @role == :ninja || @role == :thief
      seconds_per_tile -= 0.2
    end
    return seconds_per_tile / Trauma.walking_speed_modifier(self) 
  end

  def mental_speed
    seconds_per_thought = 1.0
    if @age == :elder
      seconds_per_thought += 0.5
    end
    if @trait == :robot
      seconds_per_thought -= 0.2
    end
    if @trait == :cyborg 
      seconds_per_thought -= 0.1
    end
    if @role == :mage || @role == :detective
      seconds_per_thought -= 0.3
    end
    return seconds_per_thought
  end


  def pickup_speed
    seconds_per_pickup = 1.0 # seconds to pick up items
    if @species == :halfling || @species == :gnome
      seconds_per_pickup -= 0.3
    end
    return seconds_per_pickup
  end

  def rest(args)
    args.state.kronos.spend_time(self, 1.0, args)
    apply_exhaustion(-0.05, args)
  end

  def stealth_range
    range = 10 # smaller is stealthier
    if @role == :ninja || @role == :thief
      range -= 3
    end
    if @species == :halfling || @species == :gnome
      range -= 3
    end
    return range
  end

  def c
    [0, 4]
  end

  def take_action args
    # hero is controlled by player, so no AI here
  end 

  def pick_up_item(item, level)
    @carried_items << item
    level.items.delete(item)
    item.x = nil
    item.y = nil
    item.level = nil
    printf "Picked up item: %s\n" % item.kind.to_s
  end

  def has_item?(item_kind)
    @carried_items.each do |item|
      return true if item.kind == item_kind
    end
    return false
  end

  def apply_exhaustion (amount, args)
    @exhaustion += amount
    @exhaustion = 0.0 if @exhaustion < 0.0
    @exhaustion = 1.0 if @exhaustion > 1.0
    if @exhaustion > 0.6
      HUD.output_message(args, "You feel somewhat exhausted.")
    end
    if @exhaustion > 0.8
      HUD.output_message(args, "You feel proper exhausted.")
    end
    if @exhaustion > 0.9
      HUD.output_message(args, "You feel super exhausted, you really need to rest soon.")
    end
  end
  
  def apply_hunger args
    hero = self
    hunger_increase = 0.001 # per game world time unit
    @hunger += hunger_increase
    hunger_level_before = @hunger_level
    if @hunger >= 1.0
      @hunger_level = :dying
    elsif @hunger >= 0.8
      @hunger_level = :starving
    elsif @hunger >= 0.5
      @hunger_level = :hungry
    elsif @hunger >= 0.2
      @hunger_level = :okay
    else
      @hunger_level = :satiated
    end
    if @hunger > 0.9
      HUD.output_message(args, "Eat soon or you will die from hunger.")
    end
    if hunger_level_before != @hunger_level
      case @hunger_level
      when :satiated
        if hero.traits.include?(:robot) || hero.traits.include?(:undead)
          HUD.output_message(args, "You feel full of energy.")
        else
          HUD.output_message(args, "You feel satiated.")
        end
      when :okay
        if !hunger_level_before == :satiated
          if hero.traits.include?(:robot) || hero.traits.include?(:undead)
            HUD.output_message(args, "You no longer lack energy.")
          else
            HUD.output_message(args, "You are no longer hungry.")
          end
        end
      when :hungry
        if hero.traits.include?(:robot) || hero.traits.include?(:undead)
          HUD.output_message(args, "You are somewhat low on energy.")
        else
          HUD.output_message(args, "You feel hungry.")
        end 
      when :starving
        if hero.traits.include?(:robot) || hero.traits.include?(:undead)
          HUD.output_message(args, "You are low on energy!")
        else
          HUD.output_message(args, "You feel starving!")
        end
      when :dying
        if hero.traits.include?(:undead) || hero.traits.include?(:robot)
          HUD.output_message(args, "You have no energy left. Eat something.")
        else
          HUD.output_message(args, "You starve to death!")
          args.state.hero.perished = true
          args.state.hero.reason_of_death = "of starvation"
        end
      end
    end      
  end

  def apply_walking_exhaustion args
    base_exhaustion_increase = 0.002 # per tile walked
    exhaustion_increase = base_exhaustion_increase * Item.encumbrance_factor(self, args) 
    if self.traits.include?(:robot)
      exhaustion_increase *= 0.5
    end
    apply_exhaustion(exhaustion_increase, args)
  end
end