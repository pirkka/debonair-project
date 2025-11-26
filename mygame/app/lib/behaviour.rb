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
    @target = nil
  end

  def self.setup_for_npc(npc)
    species = npc.species
    case species
    when :goblin, :orc, :skeleton, :wraith, :minotaur
      npc.behaviours << Behaviour.new(:fight, npc)
      # npc.behaviours << Behaviour.new(:attack, npc)
      npc.behaviours << Behaviour.new(:flee, npc)
    when :grid_bug
      npc.behaviours << Behaviour.new(:wander, npc)
      # npc.behaviours << Behaviour.new(:escape, npc)
      # npc.behaviours << Behaviour.new(:forage, npc)
    when :rat, :newt
      npc.behaviours << Behaviour.new(:wander, npc)
      # npc.behaviours << Behaviour.new(:forage, npc)
      # npc.behaviours << Behaviour.new(:pack, npc)
    end
  end

  def self.select_for_npc(npc, args)
    # priority one - flee
    npc.behaviours.each do |behaviour|
      if behaviour.kind == :flee && npc.traumas.size > args.state.rng.rand(6)
        return behaviour
      end
    end
    # prriority two - fight
    npc.behaviours.each do |behaviour|
      if behaviour.kind == :fight
        return behaviour
      end
    end
    # fallback - wander
    return npc.behaviours.sample
  end

  def execute args
    if args.state.hero.sees?(@npc, args)
      #printf "Executing behaviour #{@kind} for NPC #{@npc.species} at (#{@npc.x}, #{@npc.y}) - level #{@npc.depth} - time #{args.state.kronos.world_time.round(2)}\n"  
    end
    method_name = @kind.to_s
    if self.respond_to?(method_name)
      self.send(method_name, args)
    end
  end

  def flee args
    # flee from hero (and other enemies)
    npc = @npc
    enemies = npc.enemies
    if enemies.empty?
      # no enemies, wander instead
      wander args
      return
    end
    # find the closest enemy
    closest_enemy = nil
    min_distance = nil
    enemies.each do |enemy|
      if enemy.depth != npc.depth
        next
      end
      dx = enemy.x - npc.x
      dy = enemy.y - npc.y
      distance = Math.sqrt(dx * dx + dy * dy)
      if min_distance.nil? || distance < min_distance
        min_distance = distance
        closest_enemy = enemy
      end
    end
    if closest_enemy.nil?
      # no enemies on this level, wander instead
      wander args
      return
    end
    # move away from closest enemy
    dx = npc.x - closest_enemy.x
    dy = npc.y - closest_enemy.y
    if dy.abs < dx.abs || closest_enemy.y == npc.y # north-south movement   
      step_x = dx > 0 ? 1 : -1
      step_y = 0
    else
      step_y = dy > 0 ? 1 : -1
      step_x = 0  
    end
    target_x = npc.x + step_x
    target_y = npc.y + step_y
    level = args.state.dungeon.levels[npc.depth]
    target_tile = level.tiles[target_y][target_x]
    if Tile.is_walkable?(target_tile, args) && !Tile.occupied?(target_x, target_y, args)
      Tile.enter(npc, target_x, target_y, args)
      return
    else
      # cannot move away, wander instead
      wander args
      return
    end
  end

  def fight args
    # find target (e.g., hero) and move towards it
    npc = @npc
    if npc.has_status?(:shocked)
      args.state.kronos.spend_time(npc, npc.walking_speed * 4, args)
      return
    end
    hero = args.state.hero
    depth = npc.depth
    if hero && hero.depth == npc.depth
      dx = hero.x - npc.x
      dy = hero.y - npc.y
      distance = Math.sqrt(dx * dx + dy * dy)
      if distance < 20 # aggro range
        if npc.sees?(hero, args)          
          # make angry emote towards hero if here is not yet enemy!
          if !args.state.hero.is_hostile_to?(npc)
            HUD.output_message args, "#{npc.name} stares angrily at you!"
            args.state.hero.become_hostile_to(npc)
            args.state.kronos.spend_time(npc, npc.walking_speed*0.5, args)
          end
          # move towards hero, but check if the target is walkable first
          if dy.abs < dx.abs || hero.y == npc.y # north-south movement            
            step_x = dx > 0 ? 1 : -1
            step_y = 0
          else
            step_y = dy > 0 ? 1 : -1
            step_x = 0
          end
          target_x = npc.x + step_x
          target_y = npc.y + step_y
          #printf "Target x,y: #{target_x}, #{target_y}, hero x,y #{hero.x}, #{hero.y}, npc x,y #{npc.x}, #{npc.y}\n"
          level = args.state.dungeon.levels[depth]
          target_tile = level.tiles[target_y][target_x]
          if !Tile.is_walkable?(target_tile, args) && Tile.occupied?(target_x, target_y, args)
            # cannot move towards the hero, try the other direction
            if step_x != 0
              target_x = npc.x
              target_y = npc.y + (dy > 0 ? 1 : -1)
            else
              target_x = npc.x + (dx > 0 ? 1 : -1)
              target_y = npc.y 
            end
          end
          if Tile.is_walkable?(target_tile, args) 
            if Tile.occupied?(target_x, target_y, args)
              if hero.x == target_x && hero.y == target_y
                # occupied, attack!
                hero.become_hostile_to(npc)
                Combat.resolve_attack(npc, hero, args)
                args.state.kronos.spend_time(npc, npc.walking_speed, args)
                return
              else
                # occupied by something else, idle
                args.state.kronos.spend_time(npc, npc.walking_speed, args)
                return
              end
            else
              Tile.enter(npc, target_x, target_y, args)
              return
            end
          else
            # cannot move towards hero, idle
            args.state.kronos.spend_time(npc, npc.walking_speed, args)
            return
          end
        end
      end
    end
    # sensible default - wander
    wander args
  end

  def wander args
    if @npc.has_status?(:shocked)
      args.state.kronos.spend_time(@npc, @npc.walking_speed * 4, args)
      return
    end
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
      level = args.state.dungeon.levels[npc.depth]
      if level.trapped_at?(target_coordinates[0], target_coordinates[1], args)
        # do not walk into traps
        args.state.kronos.spend_time(npc, npc.walking_speed, args)
        return
      end
      target_tile = level.tiles[target_coordinates[1]][target_coordinates[0]]
      if Tile.is_walkable?(target_tile, args) && !Tile.occupied?(target_coordinates[0], target_coordinates[1], args)
        Tile.enter(npc, target_coordinates[0], target_coordinates[1], args)
        return # important to not spend time twice!
      end
    end
    args.state.kronos.spend_time(npc, npc.walking_speed, args) # todo fix speed depending on action
  end

 
end