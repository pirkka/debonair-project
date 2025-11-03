class Architect
  # singleton class that creates the dungeon and populates it with entities
  def self.instance
    @instance ||= Architect.new
  end

  def setup(settings)
    @settings ||= {}
    @settings[:levels] ||= 10
    @settings[:level_width] ||= 24  
    @settings[:level_height] ||= 24

  end

  def architect_dungeon(args)
    Leaves.create_kinds(args)
    create_dungeon(args)
    populate_entities(args)
  end

  def create_dungeon(args)
    # Code to create the dungeon layout
    dungeon = Dungeon.new
    staircase_x = rand(@settings[:level_width])
    staircase_y = rand(@settings[:level_height])
    args.state.dungeon_entrance_x = staircase_x
    args.state.dungeon_entrance_y = staircase_y

    for i in 0..(@settings[:levels] - 1)
      dungeon.levels[i] = Level.new
      dungeon.levels[i].depth = i
      dungeon.levels[i].tiles = Array.new(@settings[:level_height]) { Array.new(@settings[:level_width], :floor) }
      # add staircase up (entrance)
      dungeon.levels[i].tiles[staircase_y][staircase_x] = :staircase_up
      # add few walls for testing
      for wall in 1..200
        x = rand(@settings[:level_width])
        y = rand(@settings[:level_height])
        unless dungeon.levels[i].tiles[y][x] == :staircase_up
          dungeon.levels[i].tiles[y][x] = :wall
        end
      end
      # add staircase down
      # sanity check to avoid overlapping staircases and staircases inside walls
      while dungeon.levels[i].tiles[staircase_y][staircase_x] != :floor do
        staircase_x = rand(@settings[:level_width])
        staircase_y = rand(@settings[:level_height])
      end
      dungeon.levels[i].tiles[staircase_y][staircase_x] = :staircase_down if i < (@settings[:levels] - 1) 
    end
    args.state[:dungeon] = dungeon
  end

  def populate_entities(args)
    # Code to add entities to the dungeon
    args.state.entities = []
    dungeon = args.state.dungeon
    hero = Hero.new(args.state.dungeon_entrance_x, args.state.dungeon_entrance_y)
    hero.level = 0
    args.state.hero = hero
    args.state.entities << hero
  end
end