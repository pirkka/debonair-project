class Tile

  attr_accessor :type, :hue, :mossiness

  def self.tile_types
    [:floor, :wall, :water, :staircase_up, :staircase_down, :chasm]
  end

  def self.occupied?(x, y, args)
    args.state.entities.each do |entity|
      if entity.x == x && entity.y == y
        return true
      end
    end
    return false
  end

  def self.draw_tiles args
    if args.state[:dungeon].nil?
      return
    end
    dungeon = args.state[:dungeon]
    level = dungeon.levels[args.state[:current_level]]
    level_height = dungeon.levels[args.state[:current_level]].tiles.size
    level_width = dungeon.levels[args.state[:current_level]].tiles[0].size
    tile_size = 40 * $zoom
    x_offset = $pan_x + (1280 - (level_width * tile_size)) / 2
    y_offset = $pan_y + (720 - (level_height * tile_size)) / 2
    hue = level.floor_hue

    for y in level.tiles.each_index
      for x in level.tiles[y].each_index
        Tile.draw(level.tiles[y][x], y, x, tile_size, x_offset, y_offset, hue, args)
      end
    end
  end

  def self.draw(tile, y, x, tile_size, x_offset, y_offset, hue, args)
    # base color
    color = case tile
      when :wall
        Color.hsl_to_rgb(hue, 10, 10)
      when :water
        { r: 0, g: 0, b: 255 }
      else
        Color.hsl_to_rgb(hue, 80, 30)  
      end
    args.outputs.solids << { x: x_offset + x * tile_size,
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
      c = Color.hsl_to_rgb(hue, 80, 40)  
      margin = tile_size * 0.075
      args.outputs.solids << { x: x_offset + margin + x * tile_size,
        y: y_offset + margin + y * tile_size,
        w: tile_size - margin * 2,
        h: tile_size - margin * 2,
        path: :solid,
        r: c[:r],
        g: c[:g],
        b: c[:b] 
      }
    end
    unless Tile.occupied?(x, y, args)
      # special tiles
      c = Color.hsl_to_rgb(hue, 80, 80)  
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


