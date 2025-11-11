class Level
  attr_accessor :depth, :levels, :tiles, :items
  attr_accessor :floor_hue # this determines the color scheme of the level
  attr_accessor :vibe # this is a placeholder for different styles of level
  attr_accessor :rooms
  attr_accessor :entities

  def initialize
    @tiles = []
    @floor_hue = Numeric.rand(360)
    @vibe = :hack
    @rooms = []
    @entities = []
    @items = []
  end

  def entity_at(x, y)
    @entities.each do |entity|
      if entity.x == x && entity.y == y
        return entity
      end
    end
    return nil
  end

  def create_rooms(args)
    # first put some walls in there
    for y in 0...@tiles.size
      for x in 0...@tiles[y].size
        @tiles[y][x] = :rock unless @tiles[y][x] == :staircase_up
      end
    end
    # Code to create rooms in the level
    room_target = Numeric.rand(7..12)
    safety = 0  
    while @rooms.size < room_target do
      safety += 1
      if safety > 500
        printf "Could not create enough rooms after 500 tries, created %d out of %d\n" % [@rooms.size, room_target]
        break
      end
      width = Numeric.rand(3..7)
      height = Numeric.rand(3..7)
      buffer = 1
      x = rand(@tiles[0].size - width - buffer*2) + buffer
      y = rand(@tiles.size - height - buffer*2) + buffer
      new_room = Room.new(x, y, width, height)
      if rooms.none? { |room| room.intersects?(new_room) }
        rooms << new_room
      end
    end
    @rooms.each do |room|
      for i in room.y...(room.y + room.h)
        for j in room.x...(room.x + room.w)
          @tiles[i][j] = :floor if @tiles[i][j] == :rock
        end
      end
    end
  end
  
  def has_staircase_up?
    @tiles.each do |row|
      row.each do |tile|
        return true if tile == :staircase_up
      end
    end
    return false
  end

  def dig_corridor(args, x1, y1, x2, y2)
    current_x = x1
    current_y = y1
    while current_x != x2 || current_y != y2 do
      @tiles[current_y][current_x] = :floor if @tiles[current_y][current_x] == :rock
      if current_x < x2
        current_x += 1
      elsif current_x > x2
        current_x -= 1
      elsif current_y < y2
        current_y += 1
      elsif current_y > y2
        current_y -= 1
      end
    end
    @tiles[current_y][current_x] = :floor if @tiles[current_y][current_x] == :rock
    # put door if it's a wall!
    @tiles[current_y][current_x] = :closed_door if @tiles[current_y][current_x] == :wall
  end

  def create_corridors(args)
    # Code to create corridors between rooms
    # 
    # first let's dig a corridor to exit

    #
    # every room has 1 to 2 corridors to other rooms
    # every corridor leads to a random point in another room
    @rooms.each do |room|
      #printf "Creating corridors for room at (%d,%d) size (%d,%d)\n" % [room.x, room.y, room.w, room.h]
      corridor_target = 1 || Numeric.rand(1..2)
      corridors = 0
      while corridors < corridor_target do
        break if corridors > 5 # safety to avoid infinite loops
        target_room = @rooms.sample
        next if target_room == room
        # point in the middle of the target room
        target_x = Numeric.rand(target_room.x...(target_room.x + target_room.w)).to_i
        target_y = Numeric.rand(target_room.y...(target_room.y + target_room.h)).to_i
        # create a corridor from center of room to target_x, target_y
        current_x = room.x + (room.w / 2).to_i
        current_y = room.y + (room.h / 2).to_i
        #printf "  Corridor from (%d,%d) to (%d,%d)\n" % [current_x, current_y, target_x, target_y]
        safety = 0
        horizontal_mode = [true, false].sample
        previous_x = current_x
        previous_y = current_y
        while current_x != target_x || current_y != target_y do
          #printf "    At (%d,%d)\n" % [current_x, current_y]
          safety += 1
          if safety > 100 then
            printf "    Corridor creation aborted due to safety limit.\n"
            break
          end
          if Numeric.rand < 0.2
            horizontal_mode = !horizontal_mode
          end
          if horizontal_mode
            if current_x < target_x
              previous_x = current_x
              current_x += 1
            elsif current_x > target_x
              previous_x = current_x
              current_x -= 1
            end
          else
            if current_y < target_y
              previous_y = current_y
              current_y += 1
            elsif current_y > target_y
              previous_y = current_y
              current_y -= 1
            end
          end
          @tiles[current_y][current_x] = :floor if @tiles[current_y][current_x] == :rock
        end
        corridors += 1
      end
    end
  end

end


class Room
  attr_accessor :x, :y, :w, :h, :center_x, :center_y
  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
    @center_x = (x + (w / 2)).to_i  
    @center_y = (y + (h / 2)).to_i
  end
  
  def intersects?(other)
    return !(@x + @w < other.x || other.x + other.w < @x ||
             @y + @h < other.y || other.y + other.h < @y)
  end
end
