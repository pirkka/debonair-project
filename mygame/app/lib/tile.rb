class Tile

  attr_accessor :type, :hue, :mossiness

  @@tile_memory_per_level = []
  @@tile_visibility_per_level = []
  @@los_cache_per_level = {}

  def self.reset_memory_and_visibility
    @@tile_memory_per_level = []
    @@tile_visibility_per_level = []
  end

  def self.tile_visibility(level, args)
    depth = level.depth
    return @@tile_visibility_per_level[depth] || []
  end 

  def self.tile_types
    [:floor, :rock, :wall, :water, :staircase_up, :staircase_down, :chasm]
  end

  def self.blocks_line_of_sight?(tile_type)
    return [:wall, :rock, :closed_door].include?(tile_type)
  end

  def self.is_walkable?(tile_type, args)
    return [:floor, :staircase_up, :staircase_down, :water].include?(tile_type)
  end

  def self.occupied?(x, y, args)
    level = Utils.level(args)
    level.entities.each do |entity|
      if entity.x == x && entity.y == y
        return true
      end
    end 
    return false
  end

  def self.entity_at(x, y, args)
    level = Utils.level(args)
    level.entities.each do |entity|
      if entity.x == x && entity.y == y
        return entity
      end
    end 
    return nil
  end

  def self.is_tile_visible?(x, y, args)
    tile_visibility = @@tile_visibility_per_level[args.state.current_depth] || []
    return tile_visibility[y] && tile_visibility[y][x]
  end

  def self.is_tile_memorized?(x, y, args)
    tile_memory = @@tile_memory_per_level[args.state.current_depth] || []
    return tile_memory[y] && tile_memory[y][x]
  end

  def self.enter(entity, x, y, args)
    level = Utils.level_by_depth(entity.depth, args)
    tile = level.tile_at(x, y)
    entity.x = x
    entity.y = y
    base_walking_speed = entity.walking_speed || 1.0
    random_element = 0.8 + (args.state.rng.nxt_float * 0.4) # 0.8 to 1.2
    time_spent = base_walking_speed * self.terrain_modifier_for_entity(tile, entity, args) * random_element
    args.state.kronos.spend_time(entity, time_spent, args)
    Lighting.mark_lighting_stale
    GUI.mark_tiles_stale
    entity.walking_sound(tile, args)
  end

  def self.terrain_modifier_for_entity(tile, entity, args)
    case tile
    when :floor
      return 1.0
    when :water
      if entity.slowed_in_water?
        return 2.0
      else
        return 1.0
      end
    else
      return 1.0
    end
  end

  def self.auto_map_whole_level args
    depth = args.state.current_depth
    level = Utils.level(args)
    level_height = Utils.level_height(args)
    level_width = Utils.level_width(args)
    tile_memory = []
    for y in 0...level_height
      tile_memory[y] ||= []
      for x in 0...level_width
        tile_memory[y][x] = level.tiles[y][x]
      end
    end
    @@tile_memory_per_level[depth] = tile_memory
  end

  def self.observe_tiles args
    dungeon = args.state.dungeon
    level = dungeon.levels[args.state.current_depth]
    vision_range = args.state.hero.vision_range

    # determine visible tiles (line of sight)
    tile_visibility = @@tile_visibility_per_level[args.state.current_depth] ||= []
    tile_viewport = Utils.tile_viewport args
    x_start = tile_viewport[0]
    y_start = tile_viewport[1]
    x_end = tile_viewport[2]
    y_end = tile_viewport[3]

    for y in (y_start..y_end)
      tile_visibility[y] ||= []
      for x in (x_start..x_end)
        if Utils::distance(args.state.hero.x, args.state.hero.y, x, y) > vision_range
          tile_visibility[y][x] = false
          next
        end
        # cache the los value
        los_cache_key = "#{args.state.hero.x},#{args.state.hero.y}->#{x},#{y}"
        level.los_cache[los_cache_key] ||= Utils.line_of_sight?(args.state.hero.x, args.state.hero.y, x, y, level)
        if level.los_cache[los_cache_key]
          tile_visibility[y][x] = true
        else
          tile_visibility[y][x] = false
        end
      end
    end
    @@tile_visibility_per_level[args.state.current_depth] = tile_visibility

    # update memory with currently visible tiles
    @@tile_memory_per_level[args.state.current_depth] ||= [] 
    for y in (y_start..y_end)
      @@tile_memory_per_level[args.state.current_depth][y] ||= []
      for x in (x_start..x_end)
        if tile_visibility[y][x]
          @@tile_memory_per_level[args.state.current_depth][y][x] = level.tiles[y][x]
        end
      end
    end
  end

  def self.draw_tiles args
    level = Utils.level(args)
    tile_size = Utils.tile_size(args)
    x_offset = Utils.offset_x(args)
    y_offset = Utils.offset_y(args)
    hue = level.floor_hsl[0]
    tile_visibility = @@tile_visibility_per_level[args.state.current_depth] || []
    tile_memory = @@tile_memory_per_level[args.state.current_depth] || []

    # get the camera boundaries to limit drawing to visible area
    # 
    tile_viewport = Utils.tile_viewport args
    x_start = tile_viewport[0]
    y_start = tile_viewport[1]
    x_end = tile_viewport[2]
    y_end = tile_viewport[3]

    for x in (x_start..x_end)
      for y in (y_start..y_end)
        tile_memory[y] ||= []
        tile_visibility[y] ||= []
        if tile_visibility[y][x]
          tile = level.tiles[y][x]
        else
          tile = tile_memory[y][x] || :unknown
        end
        lighting = level.lighting[y][x] 
        Tile.draw(tile, y, x, tile_size, x_offset, y_offset, hue, tile_visibility[y][x], lighting, args)
      end
    end
  end

  def self.draw(tile, y, x, tile_size, x_offset, y_offset, hue, visible, lighting, args)
    # base color
    saturation_modifier = visible ? 1.0 : 0.7
    #lightness_modifier = visible ? 1.0 : 0.4
    if visible
      lightness_modifier = 1.0 - (1.0 * (1.0 - lighting.clamp(0.0, 1.0)))
    else
      lightness_modifier = 0.3
    end
    color = case tile
      when :rock
        Color.hsl_to_rgb(hue, 80 * saturation_modifier, 70 * lightness_modifier)
      when :floor
        Color.hsl_to_rgb(hue, 80 * saturation_modifier, 0 * lightness_modifier)
      when :wall
        Color.hsl_to_rgb(hue, 50 * saturation_modifier, 10 * lightness_modifier)
      when :open_door
        { r: 150, g: 75, b: 0 }
      when :closed_door
        { r: 100, g: 50, b: 0 }
      when :water
        # blue 360 hue
        hue = 220
        Color.hsl_to_rgb(hue, 100 * saturation_modifier, 0 * lightness_modifier)
      when :chasm
        { r: 0, g: 0, b: 120 }
      else
        { r: 0, g: 0, b: 0 }
      end
    args.outputs.solids << { 
      x: x_offset + x * tile_size,
      y: y_offset + y * tile_size,
      w: tile_size,
      h: tile_size,
      path: :solid,
      r: color[:r],
      g: color[:g],
      b: color[:b]
    }
    # floor decoration is printed on top of the solid below
    if tile == :floor
      # highlight square
      c = Color.hsl_to_rgb(hue, 80 * saturation_modifier, 80 * lightness_modifier)
      rotation = (x+y) % 4 # 0, 90, 180, 270 degrees
      angle = rotation * 90
      args.outputs.sprites << {
        x: x_offset + x * tile_size,
        y: y_offset + y * tile_size,
        w: tile_size,
        h: tile_size,
        angle: angle,
        path: "sprites/tile/gravel.png",
        r: c[:r],
        g: c[:g],
        b: c[:b]
      }
    end
    if tile == :wall
      # highlight 
      c = Color.hsl_to_rgb(hue, 50 * saturation_modifier, 40 * lightness_modifier)
      args.outputs.sprites << {
        x: x_offset + x * tile_size,
        y: y_offset + y * tile_size,
        w: tile_size,
        h: tile_size,
        path: "sprites/tile/wall.png",
        r: c[:r],
        g: c[:g],
        b: c[:b]
      }
    end
    # rock decoration
    if tile == :rock
      # highlight 
      c = Color.hsl_to_rgb(hue, 50 * saturation_modifier, 0 * lightness_modifier)
      margin = 0  
      rotation = (x+y) % 4 # 0, 90, 180, 270 degrees
      angle = rotation * 90
      args.outputs.sprites << {
        x: x_offset + x * tile_size,
        y: y_offset + y * tile_size,
        w: tile_size,
        h: tile_size,
        angle: angle,
        path: "sprites/tile/rock.png",
        r: c[:r],
        g: c[:g],
        b: c[:b]
      }
    end
    unless Tile.occupied?(x, y, args)
      # special tiles
      c = Color.hsl_to_rgb(hue, 80 * saturation_modifier, 80 * lightness_modifier)
      if tile == :staircase_up
        args.outputs.sprites << {
          x: x_offset + x * tile_size,
          y: y_offset + y * tile_size,
          w: tile_size,
          h: tile_size,
          path: "sprites/sm16px.png",
          tile_x: 12*16,
          tile_y: 3*16,
          tile_w: 16,
          tile_h: 16,
          r: c[:r],
          g: c[:g],
          b: c[:b]
        }
      end
      if tile == :staircase_down
        args.outputs.sprites << {
          x: x_offset + x * tile_size,
          y: y_offset + y * tile_size,
          w: tile_size,
          h: tile_size,
          path: "sprites/sm16px.png",
          tile_x: 14*16,
          tile_y: 3*16,
          tile_w: 16,
          tile_h: 16,
          r: c[:r],
          g: c[:g],
          b: c[:b]
        }
      end
      if tile == :water
        c = Color.hsl_to_rgb(hue, 100 * saturation_modifier, 60 * lightness_modifier)
        args.outputs.sprites << {
          x: x_offset + x * tile_size,
          y: y_offset + y * tile_size,
          w: tile_size,
          h: tile_size,
          path: "sprites/sm16px.png",
          tile_x: 7*16,
          tile_y: 15*16,
          tile_w: 16,
          tile_h: 16,
          r: c[:r],
          g: c[:g],
          b: c[:b]
        }
      end
    end
  end
end


