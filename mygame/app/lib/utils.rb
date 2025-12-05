module Utils

  def self.level(args)
    return args.state.dungeon.levels[args.state.current_depth]
  end

  def self.level_by_depth(depth, args)
    return args.state.dungeon.levels[depth]
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

  def self.distance_between_entities(entity1, entity2)
    return self.distance(entity1.x, entity1.y, entity2.x, entity2.y)
  end

  def self.in_hero_fov?(target_x, target_y, args)
    hero = args.state.hero
    return self.within_fov(hero.x, hero.y, target_x, target_y, hero.facing, 210)
  end

  def self.within_fov_of(eye_entity, target_entity, fov_angle)
    return self.within_fov(eye_entity.x, eye_entity.y, target_entity.x, target_entity.y, eye_entity.facing, fov_angle)
  end

  def self.within_fov(eye_x, eye_y, target_x, target_y, facing, fov_angle)
    if eye_x == target_x && eye_y == target_y
      return true
    end
    if (eye_x - target_x).abs < 2 && (eye_y - target_y).abs < 2
      return true
    end
    dx = target_x - eye_x
    dy = target_y - eye_y
    angle_to_target = Math.atan2(dy, dx) * (180.0 / Math::PI)
    facing_angle = case facing
                   when :east
                     0
                   when :north
                     90
                   when :west
                     180
                   when :south
                     -90
                   else
                     0
                   end
    angle_diff = (angle_to_target - facing_angle + 360) % 360
    angle_diff = 360 - angle_diff if angle_diff > 180
    return angle_diff <= (fov_angle / 2)
  end

  def self.move_entity_to_level(entity, target_depth, args)
    # remove from current level
    current_level = self.level_by_depth(entity.depth, args)
    current_level.entities.delete(entity)
    # add to target level
    target_level = self.level_by_depth(target_depth, args)
    entity.set_depth(target_depth, args)
    if entity == args.state.hero
      entity.max_depth = entity.depth if entity.depth > entity.max_depth
    end
    target_level.entities << entity
    # check the target tile - is it a wall or rock?
    target_tile = target_level.tiles[entity.y][entity.x]
    if Tile.is_solid?(target_tile, args)
      # find nearest walkable tile
      found = false
      radius = 1
      while !found
        low_x = [entity.x - radius, 0].max
        high_x = [entity.x + radius, target_level.width - 1].min
        low_y = [entity.y - radius, 0].max
        high_y = [entity.y + radius, target_level.height - 1].min
        (low_x..high_x).each do |x|
          (low_y..high_y).each do |y|
            if !Tile.is_solid?(target_level.tiles[y][x], args) && !Tile.occupied?(x, y, args)
              entity.x = x
              entity.y = y
              found = true
              break
            end
          end
          break if found
        end
        radius += 1
      end
    end


    if entity == args.state.hero
      args.state.current_depth = target_depth
      GUI.mark_tiles_stale
      Lighting.mark_lighting_stale
    end
  end

  def self.within_viewport?(x, y, args)
    tile_viewport = self.tile_viewport args
    x_start = tile_viewport[0]
    y_start = tile_viewport[1]
    x_end = tile_viewport[2]
    y_end = tile_viewport[3]
    return x >= x_start && x <= x_end && y >= y_start && y <= y_end
  end

  def self.tile_viewport args
    # return an array [x_start, y_start, x_end, y_end] of tiles that are visible in the current viewport
    # use zoom level and pan offsets to calculate
    tile_size = self.tile_size args
    x_start = ((-self.offset_x(args)) / tile_size).floor.clamp(0, self.level_width(args) - 1)
    y_start = ((-self.offset_y(args)) / tile_size).floor.clamp(0, self.level_height(args) - 1)
    x_end = ((-self.offset_x(args) + 1280) / tile_size).ceil.clamp(0, self.level_width(args) - 1)
    y_end = ((-self.offset_y(args) + 720) / tile_size).ceil.clamp(0, self.level_height(args) - 1) 
    return [x_start, y_start, x_end, y_end]
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

  def self.list_files_recursive(path, extension = nil)
    results = []
    $gtk.list_files(path).each do |file|
      full_path = "#{path}/#{file}"
      # Check if it's a directory by trying to list its contents
      sub_files = $gtk.list_files(full_path) rescue nil
      if sub_files
        # It's a directory, recurse into it
        results += list_files_recursive(full_path, extension)
      elsif extension.nil? || file.end_with?(extension)
        results << full_path
      end
    end
    results
  end
end