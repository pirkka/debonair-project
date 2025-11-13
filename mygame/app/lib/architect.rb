class Architect
  # singleton class that creates the dungeon and populates it with entities
  def self.instance
    @instance ||= Architect.new
  end

  def setup(settings)
    @settings ||= {}
    @settings[:levels] ||= 3
    @settings[:level_width] ||= 80   
    @settings[:level_height] ||= 40
  end

  def self.create_seed(args)
    dictionary_adjectives = ['Brave', 'Cunning', 'Wise', 'Fierce', 'Nimble', 'Sturdy', 'Gentle', 'Bold']
    dictionary_subjectives = ['Battle', 'Shadow', 'Light', 'Storm', 'Flame', 'Frost', 'Stone', 'Wind']
    dictionary_prepositions = ['of the', 'from the', 'under the', 'above the', 'beyond the', 'within the', 'across the', 'through the']
    dictionary_location_adjectives = ['Dark', 'Silent', 'Ancient', 'Mystic', 'Hidden', 'Forgotten', 'Enchanted', 'Sacred']
    dictionary_locations = ['Forest', 'Mountain', 'River', 'Desert', 'Cave', 'Swamp', 'Plains', 'Valley']
    seed = ''
    seed += dictionary_adjectives.sample + ' '
    seed += dictionary_subjectives.sample + ' '
    seed += dictionary_prepositions.sample + ' '
    seed += dictionary_location_adjectives.sample + ' '
    seed += dictionary_locations.sample
    args.state.seed = seed.downcase.gsub(' ','_')
    printf "Generated seed: %s\n" % args.state.seed
    return args.state.seed
  end

  def self.set_seed(args, seed)
    printf "Setting seed to: %s\n" % seed
    args.state.seed = seed
  end

  def self.use_seed(args)
    printf "Using seed: %s\n" % args.state.seed
    hash = args.state.seed.hash
    printf "Seed hash: %d\n" % hash
    args.state.rng = SeededRandom.new(hash)
    Math.srand(hash)
  end

  def architect_dungeon(args)
    Leaves.create_kinds(args)
    create_dungeon(args)
    populate_entities(args)
    populate_items(args)
  end

  def create_level(args, depth, vibe)
    level = Level.new
    level.depth = depth
    level.vibe = vibe
    level.tiles = Array.new(@settings[:level_height]) { Array.new(@settings[:level_width], :floor) }
    return level
  end

  def create_dungeon(args)
    # Code to create the dungeon layout
    dungeon = Dungeon.new
    staircase_x = rand(@settings[:level_width]-2) + 1
    staircase_y = rand(@settings[:level_height]-2) + 1
    args.state.dungeon_entrance_x = staircase_x
    args.state.dungeon_entrance_y = staircase_y
    args.state.dungeon = dungeon

    for depth in 0..(@settings[:levels] - 1)
      level = create_level(args, depth, :hack)

      dungeon.levels[depth] = level

      # add staircase up (entrance)
      previous_tile = level.tiles[staircase_y][staircase_x]
      level.tiles[staircase_y][staircase_x] = :staircase_up
      
      should_be_same = args.state.dungeon.levels[depth].tiles[staircase_y][staircase_x]
      # add rooms and corridors
      level.create_rooms(args)


      level.create_corridors(args)
      
      # dig corridor from staircase up to entry room
      entry_room = level.rooms.sample
      level.dig_corridor(args, staircase_x, staircase_y, entry_room.center_x, entry_room.center_y)

      # finally place staircase down in a room
      if depth < (@settings[:levels] - 1)
        exit_room = level.rooms.sample
        staircase_x = Numeric.rand(exit_room.x...(exit_room.x + exit_room.w)).to_i
        staircase_y = Numeric.rand(exit_room.y...(exit_room.y + exit_room.h)).to_i        
        safety = 0
        while level.tiles[staircase_y][staircase_x] != :floor do
          safety += 1
          if safety > 10
            printf "Could not place staircase down after 10 tries, placing in center of exit room\n"
            staircase_x = exit_room.x + (exit_room.w / 2).to_i
            staircase_y = exit_room.y + (exit_room.h / 2).to_i
            break
          end
          staircase_x = Numeric.rand(exit_room.x...(exit_room.x + exit_room.w)).to_i
          staircase_y = Numeric.rand(exit_room.y...(exit_room.y + exit_room.h)).to_i
        end
        level.tiles[staircase_y][staircase_x] = :staircase_down
      else
        # last level has no staircase down
        # it has the amulet!!!
        amulet_room = level.rooms.sample
        amulet_x = Numeric.rand(amulet_room.x...(amulet_room.x + amulet_room.w)).to_i
        amulet_y = Numeric.rand(amulet_room.y...(amulet_room.y + amulet_room.h)).to_i
        level.tiles[amulet_y][amulet_x] = :floor
        amulet_item = Item.new(:amulet_of_yendor, :amulet)
        amulet_item.level = depth
        amulet_item.x = amulet_x
        amulet_item.y = amulet_y
        level.items << amulet_item
      end

    end
    args.state[:dungeon] = dungeon
  end

  def populate_entities(args)
    hero = Hero.new(args.state.dungeon_entrance_x, args.state.dungeon_entrance_y)
    hero.level = 0
    args.state.hero = hero
    args.state.dungeon.levels[0].entities << hero
    NPC.populate_dungeon(args.state.dungeon, args)
  end

  def populate_items(args)
    Item.populate_dungeon(args.state.dungeon, args)
  end
end