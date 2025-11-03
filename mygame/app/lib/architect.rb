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
    create_dungeon(args)
    #populate_entities(args)
  end

  def create_dungeon(args)
    # Code to create the dungeon layout
    dungeon = Dungeon.new
    staircase_x = rand(@settings[:level_width])
    staircase_y = rand(@settings[:level_height])
    for i in 0..(@settings[:levels] - 1)
      dungeon.levels[i] = Level.new
      dungeon.levels[i].depth = i
      dungeon.levels[i].tiles = Array.new(@settings[:level_height]) { Array.new(@settings[:level_width], :floor) }
      # add few walls for testing
      for wall in 1..50
        x = rand(@settings[:level_width])
        y = rand(@settings[:level_height])
        dungeon.levels[i].tiles[y][x] = :wall
      end
      # add staircase up and down
      dungeon.levels[i].tiles[staircase_y][staircase_x] = :staircase_up
      staircase_x = rand(@settings[:level_width])
      staircase_y = rand(@settings[:level_height])
      dungeon.levels[i].tiles[staircase_y][staircase_x] = :staircase_down if i < (@settings[:levels] - 1) 
    end
    args.state[:dungeon] = dungeon
  end

  def populate_entities(args)
    # Code to add entities to the dungeon
  end
end