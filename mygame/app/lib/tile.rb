class Tile

  attr_accessor :type, :hue, :mossiness
  @@tile_memory_per_level = []
  @@tile_visibility_per_level = []

  def self.tile_types
    [:floor, :rock, :wall, :water, :staircase_up, :staircase_down, :chasm]
  end

  def self.blocks_line_of_sight?(tile_type)
    return [:wall, :rock, :closed_door].include?(tile_type)
  end

  def self.is_walkable?(tile_type, args)
    return [:floor, :staircase_up, :staircase_down].include?(tile_type)
  end

  def self.occupied?(x, y, args)
    level = args.state.dungeon.levels[args.state.current_level]
    level.entities.each do |entity|
      if entity.x == x && entity.y == y
        return true
      end
    end 
    return false
  end

  def self.is_tile_visible?(x, y, args)
    tile_visibility = @@tile_visibility_per_level[args.state.current_level] || []
    return tile_visibility[y] && tile_visibility[y][x]
  end

  def self.observe_tiles args
    dungeon = args.state.dungeon
    level = dungeon.levels[args.state.current_level]
    vision_range = args.state.hero.vision_range

    # determine visible tiles (line of sight)
    tile_visibility = @@tile_visibility_per_level[args.state.current_level] ||= []
    for y in level.tiles.each_index
      tile_visibility[y] ||= []
      for x in level.tiles[y].each_index
        if Utils::distance(args.state.hero.x, args.state.hero.y, x, y) > vision_range
          tile_visibility[y][x] = false
          next
        end
        if Utils::line_of_sight?(args.state.hero.x, args.state.hero.y, x, y, level)
          tile_visibility[y][x] = true
        else
          tile_visibility[y][x] = false
        end
      end
    end
    @@tile_visibility_per_level[args.state.current_level] = tile_visibility

    # update memory with currently visible tiles
    @@tile_memory_per_level[args.state.current_level] ||= []
    tile_memory = @@tile_memory_per_level[args.state.current_level] 

    for y in level.tiles.each_index
      tile_memory[y] ||= []
      for x in level.tiles[y].each_index
        if tile_visibility[y][x]
          tile_memory[y][x] = level.tiles[y][x]
        end
      end
    end

    @@tile_memory_per_level[args.state.current_level] = tile_memory
  end

  def self.draw_tiles args
    dungeon = args.state.dungeon
    level = dungeon.levels[args.state.current_level]
    level_height = dungeon.levels[args.state.current_level].tiles.size
    level_width = dungeon.levels[args.state.current_level].tiles[0].size
    tile_size = 40 * $zoom
    x_offset = $pan_x + (1280 - (level_width * tile_size)) / 2
    y_offset = $pan_y + (720 - (level_height * tile_size)) / 2
    hue = level.floor_hue

    tile_visibility = @@tile_visibility_per_level[args.state.current_level] || []
    tile_memory = @@tile_memory_per_level[args.state.current_level] || []

    for y in level.tiles.each_index
      for x in level.tiles[y].each_index
        tile_memory[y] ||= []
        if tile_visibility[y][x]
          tile = level.tiles[y][x]
        else
          tile = tile_memory[y][x] || :unknown
        end
        Tile.draw(tile, y, x, tile_size, x_offset, y_offset, hue, tile_visibility[y][x], args)
      end
    end
  end

  def self.draw(tile, y, x, tile_size, x_offset, y_offset, hue, visible, args)
    # base color
    saturation_modifier = visible ? 1.0 : 0.7
    lightness_modifier = visible ? 1.0 : 0.4
    color = case tile
      when :rock
        Color.hsl_to_rgb(hue, 80 * saturation_modifier, 70 * lightness_modifier)
      when :floor
        Color.hsl_to_rgb(hue, 80 * saturation_modifier, 0 * lightness_modifier)
      when :wall
        Color.hsl_to_rgb(hue, 50 * saturation_modifier, 80 * lightness_modifier)
      when :water
        { r: 0, g: 0, b: 255 }
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
    # floor decoration
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
        path: "mygame/sprites/tile/gravel.png",
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
        path: "mygame/sprites/tile/rock.png",
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
          path: "mygame/sprites/simple-mood-16x16.png",
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
          path: "mygame/sprites/simple-mood-16x16.png",
          tile_x: 14*16,
          tile_y: 3*16,
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


