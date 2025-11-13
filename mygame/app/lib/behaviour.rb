# class the NPC behaviours
# 
# interaction behaviours like attack, escape
# movement behaviours like patrol, wander, follow, flee
# 
# flee or fight decision making
# love / hate relationships
# ally / enemy relationships
# hunting behaviour
# eating behaviour
# foraging behaviour
# pack behaviour
# herding behaviour
# social hierarchy behaviour
# territorial behaviour
# sleeping behaviour
# mating behaviour
# nurturing behaviour
# curiosity behaviour
# exploration behaviour
# hiding behaviour

class Behaviour

  attr_accessor :destination, :kind, :npc

  def initialize(kind, npc)
    @kind = kind
    @npc = npc
    @destination = nil
  end

  def self.setup_for_npc(npc)
    species = npc.species
    case species
    when :goblin
      npc.behaviours << Behaviour.new(:wander, npc)
      # npc.behaviours << Behaviour.new(:attack, npc)
      # npc.behaviours << Behaviour.new(:escape, npc)
    when :grid_bug
      npc.behaviours << Behaviour.new(:wander, npc)
      # npc.behaviours << Behaviour.new(:escape, npc)
      # npc.behaviours << Behaviour.new(:forage, npc)
    when :rat
      npc.behaviours << Behaviour.new(:wander, npc)
      # npc.behaviours << Behaviour.new(:forage, npc)
      # npc.behaviours << Behaviour.new(:pack, npc)
    end
  end

  def self.select_for_npc(npc)
    # logic to select appropriate behaviour for npc based on its state
    # and environment
    # for now, just return a random behaviour
    return npc.behaviours.sample
  end

  def execute args
    #printf "Executing behaviour #{@kind} for NPC #{@npc.species} at (#{@npc.x}, #{@npc.y})\n"
    method_name = @kind.to_s
    if self.respond_to?(method_name)
      self.send(method_name, args)
    end
  end

  def wander args
    #printf "NPC #{@npc.species} is wandering.\n"
    npc = @npc
    # choose a random location on the map to walk to, stored in @destination
    if npc.x == @destination&.first && npc.y == @destination&.last
      @destination = nil
    end
    if !@destination || args.state.rng.d20 == 1
      target_x = npc.x + args.state.rng.rand(10) - 5
      target_y = npc.y + args.state.rng.rand(10) - 5
      @destination = [target_x, target_y]
    end
    target_coordinates = nil
    case Numeric.rand(3).to_i
    when 1
      # move northsouth
      #print "NPC #{@npc.species} at (#{npc.x}, #{npc.y}) moving towards #{@destination}\n"
      delta = @destination.last > npc.y ? 1 : -1
      target_coordinates = [npc.x, npc.y + delta]
    when 2
      # move eastwest
      #print "NPC #{@npc.species} at (#{npc.x}, #{npc.y}) moving towards #{@destination}\n"
      delta = @destination.first > npc.x ? 1 : -1
      target_coordinates = [npc.x + delta, npc.y]
    else
      #printf "NPC #{@npc.species} at (#{npc.x}, #{npc.y}) idling.\n"
      # do nothing
    end
    if target_coordinates
      level = args.state.dungeon.levels[npc.level]
      target_tile = level.tiles[target_coordinates[1]][target_coordinates[0]]
      if Tile.is_walkable?(target_tile, args) && !Tile.occupied?(target_coordinates[0], target_coordinates[1], args)
        @npc.x = target_coordinates[0]
        @npc.y = target_coordinates[1]
      end
    end
    args.state.kronos.spend_time(npc, npc.walking_speed, args) # todo fix speed depending on action
  end

 
end