class Foliage

  # hsl hue cheat sheet:
  # 0 = red 30 = orange 60 = yellow 120 = green 180 = cyan 240 = blue 270 = purple 300 = magenta

  FOLIAGE_TYPES = {
    small_rocks: { color: [30, 40, 50], char: [10, 15] },
    lichen: { color: [150, 100, 80], char: [9, 10] },
    puddle: { color: [220, 100, 80], char: [14, 2] },
    moss: { color: [120, 100, 70], char: [10, 10] },
    fungus: { color: [30, 70, 70], char: [9, 10] },
    small_plant: { color: [100, 100, 70], char: [13,14] }
  }

  def self.draw args, level
    tile_size = Utils.tile_size(args)
    x_offset = Utils.offset_x(args)
    y_offset = Utils.offset_y(args)
    tile_visibility = Tile.tile_visibility(level, args)
    tile_viewport = Utils.tile_viewport args
    x_start = tile_viewport[0]
    y_start = tile_viewport[1]
    x_end = tile_viewport[2]
    y_end = tile_viewport[3]
    for y in (y_start..y_end)
      for x in (x_start..x_end)
        next unless level.foliage[y][x]
        visible = tile_visibility[y] && tile_visibility[y][x]
        foliage_type = level.foliage[y][x]
        foliage_data = FOLIAGE_TYPES[foliage_type]
        next unless foliage_data
        lighting = level.lighting[y][x]
        saturation_modifier = visible ? 1.0 : 0.7
        lightness_modifier = visible ? 1.0 : 0.4
        lightness_modifier = 1.0 - (1.0 * (1.0 - lighting.clamp(0.0, 1.0)))
        hue = foliage_data[:color][0]
        color = Color.hsl_to_rgb(hue, 80 * saturation_modifier, 70 * lightness_modifier)
        args.outputs.primitives << {
          path: "sprites/sm16px.png",
          x: x * tile_size + x_offset,
          y: y * tile_size + y_offset,
          w: tile_size,
          h: tile_size,
          r: color[:r],
          g: color[:g],
          b: color[:b],
          a: 255,
          tile_x: foliage_data[:char][0] * 16,
          tile_y: foliage_data[:char][1] * 16,
          tile_w: 16,
          tile_h: 16
        }
      end
    end
  end
end