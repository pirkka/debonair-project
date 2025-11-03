class Tile

  attr_accessor :type, :hue, :mossiness

  def self.tile_types
    [:floor, :wall, :water, :staircase_up, :staircase_down]
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