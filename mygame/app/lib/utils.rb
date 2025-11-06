module Utils

  def self.distance(x0, y0, x1, y1)
    return Math.sqrt((x1 - x0)**2 + (y1 - y0)**2)
  end

  def self.line_of_sight?(x0, y0, x1, y1, level)
    line_points = get_line(x0, x1, y0, y1)
    line_points.shift
    line_points.pop
    line_points.each do |point|
      tile = level.tiles[point[:y]][point[:x]]
      if Tile.blocks_line_of_sight?(tile)
        return false
      end
    end
    return true
  end

  # Bresenham's line algorithm
  # https://www.roguebasin.com/index.php/Bresenham%27s_Line_Algorithm#Ruby
  def self.get_line(x0,x1,y0,y1)
    points = []
    steep = ((y1-y0).abs) > ((x1-x0).abs)
    if steep
      x0,y0 = y0,x0
      x1,y1 = y1,x1
    end
    if x0 > x1
      x0,x1 = x1,x0
      y0,y1 = y1,y0
    end
    deltax = x1-x0
    deltay = (y1-y0).abs
    error = (deltax / 2).to_i
    y = y0
    ystep = nil
    if y0 < y1
      ystep = 1
    else
      ystep = -1
    end
    for x in x0..x1
      if steep
        points << {:x => y, :y => x}
      else
        points << {:x => x, :y => y}
      end
      error -= deltay
      if error < 0
        y += ystep
        error += deltax
      end
    end
    return points
  end
end