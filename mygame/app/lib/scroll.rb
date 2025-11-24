class Scroll < Item
  def initialize(kind)
    super(kind, :scroll)
  end

  def self.kinds
    [
      :scroll_of_mapping,
      :scroll_of_digging,
      :scroll_of_fireball
    ]
  end

  def self.randomize(level_depth, args)
    kind = args.state.rng.choice(self.kinds)
    return Scroll.new(kind)
  end

  def use(user, args)
    if user != args.state.hero
      return
    end
    # skill test
    roll = args.state.rng.d20
    # role_modifier
    role_modifier = 0
    case args.state.hero.role
    when :wizard
      role_modifier += 5
    when :archaeologist, :monk
      role_modifier += 3
    when :cleric, :druid, :detective
      role_modifier += 2
    end
    effective_roll = roll + role_modifier
    if effective_roll < 4
      HUD.output_message args, "You fail to decipher the scroll's magical script. It crumbles to dust."
      args.state.hero.carried_items.delete(self)
      args.state.kronos.spend_time(args.state.hero, args.state.hero.mental_speed, args)
      return
    end
    # successful reading
    case @kind
    when :scroll_of_mapping
      HUD.output_message args, "You gain knowledge of the level layout! The scroll crumbles to dust."
      Tile.auto_map_whole_level args
    when :scroll_of_digging
      Scroll.dig_around_entity user, effective_roll/2, args
      HUD.output_message args, "You dig a through the walls around you. The scroll crumbles to dust."
    when :scroll_of_fireball
      HUD.output_message args, "You unleash a fiery explosion around you! The scroll crumbles to dust."
      Scroll.fireball(user, args)
    else
      printf "Unknown scroll kind: %s\n" % [@kind.to_s]
    end
    args.state.hero.carried_items.delete(self)
    args.state.kronos.spend_time(args.state.hero, args.state.hero.mental_speed, args)
  end

  def self.dig_around_entity(entity, radius, args)
    level = Utils.level(args)
    low_x = [entity.x - radius, 0].max
    high_x = [entity.x + radius, level.width - 1].min
    low_y = [entity.y - radius, 0].max
    high_y = [entity.y + radius, level.height - 1].min
    printf "Digging around entity at (%d, %d) with radius %d - x: %d..%d and y: %d..%d\n" % [entity.x, entity.y, radius, low_x, high_x, low_y, high_y]
    (low_x.to_i..high_x.to_i).each do |x|
      (low_y.to_i..high_y.to_i).each do |y|
        if Math.sqrt((x - entity.x)**2 + (y - entity.y)**2) <= radius
          if level.tiles[y][x] == :wall || level.tiles[y][x] == :rock
            level.tiles[y][x] = :floor
          end
        end
      end
    end
  end

  def self.fireball(user, args)
    raise "There must be an entity to call this method on." if user.nil?
    printf user.kind.to_s + " casts fireball!\n"
    SoundFX.play("fireball", args)
    level = Utils.level(args)
    height = level.height
    width = level.width
    affected_tiles = []
    radius = 5
    (user.x - radius).upto(user.x + radius) do |x|
      (user.y - radius).upto(user.y + radius) do |y|
        printf "Checking tile at #{x}, #{y}\n"
        if x < 0 || x >= width || y < 0 || y >= height
          next
        end
        # damage entities straight up for now (later to it in fire mechanism)
        if Math.sqrt((x - user.x)**2 + (y - user.y)**2) <= radius
          # add fire to the tile
          level.add_effect(:fire, x, y, args)
          target = Tile.entity_at(x, y, args)
          if target && target != args.state.hero            
            amount_of_burns = Numeric.rand(1..3)
            amount_of_burns.times do
              body_part = target.random_body_part(args) 
              severity = Trauma.severities[Numeric.rand(1..4)] # skip the healed one
              HUD.output_message args, "The #{body_part} of #{target.species} suffers #{severity} burns!"
              Trauma.inflict(target, body_part, :burn, severity, args)            
            end
          end
        end
      end
    end
  end
end