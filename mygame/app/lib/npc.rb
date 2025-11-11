class NPC < Entity
  attr_accessor :char, :species, :has_been_seen, :level, :status

  def initialize(species, x = 0, y = 0, level_depth = 0)
    @kind = :npc
    @species = species
    @has_been_seen = false
    @home = [x, y]
    @home_level = level_depth
    @level = level_depth
    @status = []
    super(x, y)
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
    # simple random walk AI
    # check status for :fleeing_hero, :attacking_hero, etc.
    target_coordinates = nil
    case args.state.rng.d6
    when 1
      # move up
      target_coordinates = [@x, @y + 1]
    when 2
      # move down
      target_coordinates = [@x, @y - 1]
    when 3
      # move left
      target_coordinates = [@x - 1, @y]
    when 4
      # move right
      target_coordinates = [@x + 1, @y]
    else
      # do nothing
    end
    if target_coordinates
      level = args.state.dungeon.levels[self.level]
      target_tile = level.tiles[target_coordinates[1]][target_coordinates[0]]
      if Tile.is_walkable?(target_tile, args) && !Tile.occupied?(target_coordinates[0], target_coordinates[1], args)
        @x = target_coordinates[0]
        @y = target_coordinates[1]
      end
      if target_coordinates[0] == args.state.hero.x && target_coordinates[1] == args.state.hero.y && self.level == args.state.hero.level
        # attack hero
        Combat.resolve_attack(self, args.state.hero, args)
      end
    end
    args.state.kronos.spend_time(self, self.walking_speed, args) # todo fix speed depending on action
  end

end