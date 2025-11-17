class NPC < Entity

  include Needy

  attr_accessor :char, :species, :has_been_seen, :depth, :status, :behaviours, :carried_items

  def initialize(species, x = 0, y = 0, depth = 0)
    @kind = :npc
    @species = species
    @has_been_seen = false
    @home = [x, y]
    @home_depth = depth
    @depth = depth
    @status = []
    @traits = []
    super(x, y)
    initialize_needs
    @behaviours = []
    Behaviour.setup_for_npc(self)
    self.setup_traits
  end

  def name
    @species.to_s.capitalize.gsub('_',' ')
  end

  def hue # deprecate!!!
    case @species
    when :goblin, :orc
      return 120  
    when :grid_bug
      return 300
    when :rat
      return 40
    else
      return 0
    end
  end

  # these are HSl values (hue, saturation, level)
  def color
    case @species
    when :goblin, :orc
      return [20, 255, 100]
    when :grid_bug
      return [130, 170, 100]
    when :rat
      return [80, 80, 20]
    when :wraith
      return [200, 200, 255]
    when :skeleton
      return [0, 0, 100]
    when :minotaur
      return [150, 75, 0]
    else
      return [255, 255, 255]
    end
  end

  def setup_traits
    case @species
    when :goblin, :orc
      @traits << [:skinny, :fat, :short, :tall, :muscular].sample
    when :grid_bug
      @traits << [:shiny, :metallic, :buzzing].sample
    when :rat
      @traits << [:skinny, :fat, :big, :small, :muscular].sample
    when :wraith
    when :skeleton
    when :minotaur
    end
  end


  def c 
    # x, y character representation from the sprite sheet
    case @species
    when :goblin
      return [7,6]
    when :grid_bug
      return [8,7]
    when :rat 
      return [2,7]
    when :orc
      return [15,4]
    when :wraith
      return [7,5]  
    when :skeleton
      return [3,5]
    when :minotaur
      return [13,4]
    else
      return [16,14]
    end
  end

  def emote
    case @species
    when :goblin
      return "grins mischievously"
    when :grid_bug
      return "makes weird noise"
    when :rat
      return "growls hungrily"
    else
      return "looks around"
    end
  end

  def self.populate_dungeon(dungeon, args)
    for level in dungeon.levels
      self.populate_level(level, args)
    end
  end

  def self.populate_level(level, args)
    level.rooms.each do |room|
      case args.state.rng.d6
      when 1
        if level.depth < 6
          mobtype = :goblin
        else
          mobtype = :orc
        end
        npc = NPC.new(mobtype, room.center_x, room.center_y, level.depth)
        npc.carried_items << Weapon.generate_for_npc(npc, level.depth, args)
        level.entities << npc
        level_mod = (level.depth / 10).floor
        level_mod.times do |i|
          new_npc = NPC.new(mobtype, room.center_x + Numeric.rand(-2..2), room.center_y + Numeric.rand(-2..2), level.depth)
          new_npc.carried_items << Weapon.generate_for_npc(npc, level.depth, args)
          level.entities << new_npc
        end

      when 2
        if level.depth < 4
          npc = NPC.new(:grid_bug, room.center_x, room.center_y, level.depth)
          level.entities << npc
        elsif level.depth < 8
          npc = NPC.new(:skeleton, room.center_x, room.center_y, level.depth)
          level.entities << npc
        else
          npc = NPC.new(:wraith, room.center_x, room.center_y, level.depth)
          level.entities << npc
        end
      when 3
        npc = NPC.new(:rat, room.center_x, room.center_y, level.depth)
        level.entities << npc
        if args.state.rng.d6 > 3
          npc2 = NPC.new(:rat, room.center_x + 1, room.center_y, level.depth)
          level.entities << npc2
        end
        if args.state.rng.d6 == 6
          npc3 = NPC.new(:rat, room.center_x - 1, room.center_y, level.depth)
          level.entities << npc3
        end
      end
    end
  end

  def walking_speed # separate to attack speed later
    species_speed = 1.0
    case @species
    when :goblin
      species_speed = 1.4 # seconds per tile
    when :grid_bug
      species_speed = 0.2
    when :rat
      species_speed = 0.8
    when :gelatinous_cube # these guys keep the dungeon clean??
      species_speed = 5.0
    end
    return species_speed / Trauma.walking_speed_modifier(self)
  end

  def take_action args
    #printf "NPC #{@species} at (#{@x}, #{@y}) taking action at time #{args.state.kronos.world_time}\n"
    Behaviour.select_for_npc(self).execute(args)
  end

  def title
    self.species
  end
end