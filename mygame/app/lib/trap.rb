# traps are placed on the level and trigger when an entity steps on them
class Trap
  attr_reader :x, :y, :kind, :level
  attr_accessor :found
  def initialize(x, y, kind, level)
    @x = x
    @y = y
    @kind = kind
    @level = level
    @found = false
    @target_x = nil
    @target_y = nil
  end

  def self.kinds
    return [:spike, :fire, :poison_dart, :teleportation, :trapdoor]
    # return [:spike, :fire, :poison_dart, :rock, :sleep_gas, :bear_trap, :teleportation, :pit, :trapdoor]
  end

  def title args
    return "%s trap" % [@kind.to_s.gsub('_',' ')]
  end

  def self.trigger_trap_at(entity, x, y, args)
    level = Utils.level_by_depth(entity.depth, args)
    level.traps.each do |trap|
      if trap.x == x && trap.y == y
        trap.trigger(entity, args)
      end
    end
  end

  def trigger entity, args
    if entity == args.state.hero
      GUI.add_input_cooldown(30)
    end
    printf "%s triggered a %s trap at (%d,%d)!\n" % [entity.name, @kind.to_s.gsub('_',' '), @x, @y]
    @found = true
    case @kind
    when :spike
      amount_of_spikes = 1 + (args.state.rng.rand(3))
      amount_of_spikes.times do
        body_part = entity.random_body_part(args)
        hit_severity = Trauma.severities[1 + args.state.rng.rand(3)] # skip the healed one
        hit_kind = :pierce
        Trauma.inflict(entity, body_part, hit_kind, hit_severity, args)
        SoundFX.play_sound(:hero_hurt, args)
      end
      HUD.output_message args, "#{entity.name} is impaled by #{amount_of_spikes} spikes!"
    when :poison_dart
      Status.new(entity, :poisoned, 10, args)
      HUD.output_message args, "#{entity.name} is poisoned by a poison dart!"

    # when :fire
    # when :rock
    # when :sleep_gas
    # when :bear_trap, :pit etc

    when :teleportation
      HUD.output_message args, "#{entity.name} steps on a teleportation trap!"
      entity.teleport(args)
    when :trapdoor
      HUD.output_message args, "#{entity.name} falls through a trapdoor to the level below!"
      Utils.move_entity_to_level(entity, entity.depth + 1, args)
      @target_x = entity.x
      @target_y = entity.y
    end
  end

  def self.populate_for_level(level, args)
    # place traps randomly in the level
    number_of_traps = args.state.rng.rand(6) + (level.depth/2).floor - 2 + 30
    if number_of_traps < 0
      number_of_traps = 0
    end
    traps_installed = 0
    safety = 0
    while traps_installed < number_of_traps
      safety += 1
      if safety > 1000
        printf "Could not place all traps on level %d - placed %d out of %d\n" % [level.depth, traps_installed, number_of_traps]
        break
      end
      x = args.state.rng.rand(level.width)
      y = args.state.rng.rand(level.height)
      # check if the tile is already taken by another trap
      exiting_trap_in_the_same_spot = false
      level.traps.each do |existing_trap|
        if existing_trap.x == x && existing_trap.y == y
          exiting_trap_in_the_same_spot = true
          break
        end
      end
      next if exiting_trap_in_the_same_spot
      tile = level.tiles[y][x]
      # only floor tiles can have traps - no staircases, water etc
      next unless tile == :floor
      # we can place a trap, yes!
      kind = Trap.kinds.sample
      trap = Trap.new(x, y, kind, level)
      level.traps << trap
      traps_installed += 1
    end
    printf "Placed %d traps on level %d\n" % [traps_installed, level.depth]
  end

  def self.draw_traps args
    level = Utils.level(args)
    level.traps.each do |trap|
      if trap.found
        x = trap.x
        y = trap.y
        tile_size = Utils.tile_size(args)
        sprite_tile_size = 16
        if Utils.within_viewport?(x, y, args)
          #draw it
          screen_x = Utils.offset_x(args) + x * tile_size
          screen_y = Utils.offset_y(args) + y * tile_size
          args.outputs.sprites << {
            x: screen_x, y: screen_y, w: tile_size, h: tile_size  , 
            path: "sprites/sm16px.png",
            source_x: sprite_tile_size * 8, source_y: sprite_tile_size * 5, source_w: sprite_tile_size, source_h: sprite_tile_size
          }
        end
      end
    end
  end
end