class NPC < Entity

  include Needy

  attr_accessor :char, :species, :has_been_seen, :level, :status, :behaviours, :carried_items

  def initialize(species, x = 0, y = 0, level_depth = 0)
    @kind = :npc
    @species = species
    @has_been_seen = false
    @home = [x, y]
    @home_level = level_depth
    @level = level_depth
    @status = []
    super(x, y)
    initialize_needs
    @behaviours = []
    Behaviour.setup_for_npc(self)
  end

  def name
    @species.to_s.capitalize.gsub('_',' ')
  end

  def color
    case @species
    when :goblin
      return [20, 125, 20]
    when :grid_bug
      return [255, 0, 255]
    when :rat
      return [80, 70, 48]
    else
      return [255, 255, 255]
    end
  end
  
  def c 
    # character representation from the sprite sheet
    case @species
    when :goblin
      return [8,4]
    when :grid_bug
      return [8,7]
    when :rat 
      return [2,7]
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
        npc = NPC.new(:goblin, room.center_x, room.center_y, level.depth)
        level.entities << npc
      when 2
        npc = NPC.new(:grid_bug, room.center_x, room.center_y, level.depth)
        level.entities << npc
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

  def walking_speed
    case @species
    when :goblin
      return 1.4 # seconds per tile
    when :grid_bug
      return 0.7
    when :rat
      return 0.8
    when :gelatinous_cube # these guys keep the dungeon clean??
      return 5.0
    else
      return 1.0
    end
  end

  def take_action args
    #printf "NPC #{@species} at (#{@x}, #{@y}) taking action at time #{args.state.kronos.world_time}\n"
    Behaviour.select_for_npc(self).execute(args)
  end

end