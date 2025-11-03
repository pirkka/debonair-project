class Tile

  attr_accessor :type, :hue, :mossiness

  def self.tile_types
    [:floor, :wall, :water, :staircase_up, :staircase_down]
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

    for y in level.tiles.each_index
      for x in level.tiles[y].each_index
        Tile.draw(level.tiles[y][x], y, x, tile_size, x_offset, y_offset, args)
      end
    end
  end

  def self.draw(tile, y, x, tile_size, x_offset, y_offset, args)
        color = case tile
          when :floor
            { r: 40, g: 40, b: 40 }
          when :wall
            { r: 250, g: 250, b: 250 }
          when :water
            { r: 0, g: 0, b: 255 }
          when :staircase_up
            { r: 0, g: 255, b: 0 }
          when :staircase_down
            { r: 255, g: 0, b: 0 }
          else
            { r: 0, g: 0, b: 0 }
          end
        args.outputs.solids << { x: x_offset + x * tile_size,
          y: y_offset + y * tile_size,
          w: tile_size,
          h: tile_size,
          path: :solid,
          r: color[:r],
          g: color[:g],
          b: color[:b],
          a: 120 }
  end
end