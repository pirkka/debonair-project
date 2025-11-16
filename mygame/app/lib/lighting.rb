class Lighting
  def self.calculate_light_level_at(level, x, y)
    timer = Time.now
    # initilalize light levels at zero
    # iterate through all light sources on the level
    light_level = 0.0
    if level.lights
      level.lights.each do |light|
        distance = Utils::distance(light.x, light.y, x, y)
        if distance < 0.1
          distance = 0.1
        end
        contribution = light.intensity / (distance * distance)
        light_level += contribution
      end
    end
    puts "Light calculation took #{Time.now - timer} seconds"
    return light_level
  end

  def self.populate_lights(args)
    dungeon = args.state.dungeon
    for level in dungeon.levels
      level.lights = []
      # place a torch in each room
      level.rooms.each do |room|
        torch = Light.new(room.center_x, room.center_y, :torch)
        level.lights << torch
      end
      # calculate lighting for the level
      self.calculate_lighting(level, args)
    end
  end

  def self.calculate_lighting(level, args)
    level.lighting = Array.new(level.height) { Array.new(level.width, 0.0) }
    for y in 0...level.height
      for x in 0...level.width
        level.lighting[y][x] = self.calculate_light_level_at(level, x, y)
      end
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
      return 13.0
    when :torch
      return 5.0
    when :lamp
      return 7.5
    when :candle
      return 0.4
    end
    return 0
  end
end