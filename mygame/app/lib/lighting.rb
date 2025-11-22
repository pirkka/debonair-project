class Lighting

  @@lighting_stale = true

  def self.mark_lighting_stale
    @@lighting_stale = true
  end

  def self.calculate_light_level_at(level, x, y)
    # iterate through all light sources on the level
    light_level = 0.0
    level.entities.each do |entity|
      entity.worn_items.each do |item|
        if item.kind == :ring_of_illumination
          distance = Utils::distance(entity.x, entity.y, x, y)
          if distance < 0.1
            distance = 0.1
          end
          contribution = 30.0 / (distance * distance)
          light_level += contribution
        end
      end
      # grid bugs
      if entity.species == :grid_bug
        distance = Utils::distance(entity.x, entity.y, x, y)
        if distance < 0.1
          distance = 0.1
        end
        contribution = 4.0 / (distance * distance)
        light_level += contribution
      end
    end
    level.lights.each do |light|
      distance = Utils::distance(light.x, light.y, x, y)
      if distance < 0.1
        distance = 0.1
      end
      contribution = light.intensity / (distance * distance)
      light_level += contribution
    end
    return light_level
  end

  def self.populate_lights(args)
    printf("populating lights...\n")
    dungeon = args.state.dungeon
    for level in dungeon.levels
      level.lights ||= []
      for y in 0...level.height
        for x in 0...level.width
          tile = level.tiles[y][x]
          if tile == :wall
            if args.state.rng.d12 == 1
              light = Light.new(x, y, :torch)
              level.lights << light
            end
          end
        end
      end
      # rocky levels need different lighting
      if level.vibe == :rocky
        for i in 0...(level.width * level.height / 100)
          x = args.state.rng.rand(level.width)
          y = args.state.rng.rand(level.height)
          tile = level.tiles[y][x]
          if tile == :floor
            light = Light.new(x, y, :bonfire)
            level.lights << light
          end
        end
      end 
      # calculate lighting for the level
      self.calculate_lighting(level, args)
    end
  end

  def self.calculate_lighting(level, args)
    if @@lighting_stale
      unless level.lighting
        level.lighting = Array.new(level.height) { Array.new(level.width, 0.0) }
      end
      for y in 0...level.height
        for x in 0...level.width
          # only if within line of sight
          if level.los_cache["#{args.state.hero.x},#{args.state.hero.y}->#{x},#{y}"]
            level.lighting[y][x] = self.calculate_light_level_at(level, x, y)
          end
          unless level.lighting[y][x]
            level.lighting[y][x] = 0.0
          end
        end
      end
      @@lighting_stale = false
    end
  end
end

class Light
  attr_accessor :x, :y, :intensity, :kind

  def initialize(x, y, kind)
    @x = x
    @y = y
    @kind = kind
  end

  def intensity
    case @kind
    when :bonfire
      return 6.0
    when :torch
      return 4.0
    when :lamp
      return 7.5
    when :candle
      return 0.4
    end
    return 0
  end

  def self.draw_lights args
    level = Utils.level(args)
    level.lights.each do |light|
      unless Tile.is_tile_memorized?(light.x, light.y, args)
        next
      end
      case light.kind
      when :torch, :bonfire
        x = Utils.offset_x(args) + (light.x+0.25) * Utils.tile_size(args)
        y = Utils.offset_y(args) + (light.y+0.25) * Utils.tile_size(args)
        tile_size = 16
        tile_selection = case light.kind
        when :torch
          [7,2]
        when :bonfire
          [14,5]
        end
        args.outputs.primitives << {
          x: x,
          y: y,
          w: tile_size,
          h: tile_size,
          path: "sprites/sm16px.png",
          tile_x: tile_selection[0] * tile_size,
          tile_y: tile_selection[1] * tile_size,
          tile_w: tile_size,
          tile_h: tile_size,
          angle: 0,
          r: 255,
          g: 140,
          b: 0,
          a: 200,
          blendmode: :additive
        }
      end
    end
  end
end

class PortableLight < Item
  def initialize(kind)
    super(kind, :portable_light)
  end
end