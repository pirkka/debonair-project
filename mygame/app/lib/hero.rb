class Hero < Entity

  attr_reader :role, :species, :trait, :age, :name

  def initialize(x, y)
    super(x, y)
    @kind = :pc
    @role = Hero.roles.sample
    @species = Hero.species.sample
    @trait = Hero.traits.sample
    @age = Hero.age.sample
    @name = 'Jaakko'
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
    if @trait == :cyborg || @trait == :robot
      seconds_per_tile -= 0.3
    end
    return seconds_per_tile
  end

  def c
    [0, 4]
  end

  def take_action args
    # hero is controlled by player, so no AI here
  end 

end