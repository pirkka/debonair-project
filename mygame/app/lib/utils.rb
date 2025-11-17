module Utils

  def self.level(args)
    return args.state.dungeon.levels[args.state.current_depth]
  end

  def self.tile_size(args)
    return 40 * $zoom
  end

  def self.level_width(args)
    return self.level(args).width
  end

  def self.level_height(args)
    return self.level(args).height
  end

  def self.offset_x(args)
    $pan_x + (1280 - (self.level_width(args) * self.tile_size(args))) / 2
  end

  def self.offset_y(args)
    $pan_y + (720 - (self.level_height(args) * self.tile_size(args))) / 2
  end

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

  def self.dijkstra(start_x, start_y, end_x, end_y, level)
    # simple Dijkstra implementation for pathfinding
    visited = {}
    distances = {}
    previous = {}
    queue = []    
    for y in 0...level.height
      for x in 0...level.width
        distances["#{x},#{y}"] = Float::INFINITY
        previous["#{x},#{y}"] = nil
        queue << {:x => x, :y => y}
      end
    end
    distances["#{start_x},#{start_y}"] = 0
    while queue.size > 0 do
      # get node in queue with smallest distance
      current = nil
      current_distance = Float::INFINITY
      queue.each do |node|
        dist = distances["#{node[:x]},#{node[:y]}"]
        if dist < current_distance
          current_distance = dist
          current = node
        end
      end
      if current[:x] == end_x && current[:y] == end_y
        break
      end
      queue.delete(current)
      neighbors = [
        {:x => current[:x] + 1, :y => current[:y]},
        {:x => current[:x] - 1, :y => current[:y]},
        {:x => current[:x], :y => current[:y] + 1},
        {:x => current[:x], :y => current[:y] - 1}
      ]
      neighbors.each do |neighbor|
        next unless level.is_walkable?(neighbor[:x], neighbor[:y])
        alt = distances["#{current[:x]},#{current[:y]}"] + 1
        if alt < distances["#{neighbor[:x]},#{neighbor[:y]}"]
          distances["#{neighbor[:x]},#{neighbor[:y]}"] = alt
          previous["#{neighbor[:x]},#{neighbor[:y]}"] = current
        end
      end
    end
    # reconstruct path
    path = []
    u = {:x => end_x, :y => end_y}
    while previous["#{u[:x]},#{u[:y]}"]
      path.unshift(u)
      u = previous["#{u[:x]},#{u[:y]}"]
    end
    return path
  end
end