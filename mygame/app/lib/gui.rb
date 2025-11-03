
$zoom = 0.7
$pan_x = 0.0
$pan_y = 0.0
$zoom_speed = 0.0
$max_zoom = 3.0
$min_zoom = 0.2

class GUI

  @@hero_locked = false
  @@just_used_staircase = false

  def self.handle_input args

    unless GUI.is_hero_locked? # already moving
      # player movement
      if args.inputs.keyboard.key_down.up
        GUI.move_player(0, 1, args)
      elsif args.inputs.keyboard.key_down.down
        GUI.move_player(0, -1, args)
      elsif args.inputs.keyboard.key_down.left
        GUI.move_player(-1, 0, args)
      elsif args.inputs.keyboard.key_down.right
        GUI.move_player(1, 0, args)
      end
    end

    # zooming with mouse wheel
    zoom_acceleration = 0.2
    if args.inputs.mouse.wheel
      zoom_input = args.inputs.mouse.wheel.y
      if zoom_input > 0
        $zoom_speed += zoom_acceleration
      elsif zoom_input < 0
        $zoom_speed -= zoom_acceleration
      end
    end
    $zoom_speed *= 0.8 # deceleration
    if $zoom_speed.abs < 0.1
      $zoom_speed = 0
    end
    zoom_delta = $zoom_speed
    requested_zoom = $zoom + zoom_delta
    $zoom = requested_zoom.clamp($min_zoom, $max_zoom)

    # panning with touch/mouse drag
    if args.inputs.mouse.buffered_held && args.inputs.mouse.moved
        delta_x = args.inputs.mouse.previous_x - args.inputs.mouse.x
        delta_y = args.inputs.mouse.previous_y - args.inputs.mouse.y
        $pan_x -= delta_x
        $pan_y -= delta_y
    end
  end

  def self.draw_tiles args
    Tile.draw_tiles args
  end

  def self.draw_entities args
    if args.state.entities.nil?
      return
    end
    args.state.entities.each do |entity|
      if entity.level == args.state.current_level
        tile_size = 40 * $zoom
        dungeon = args.state.dungeon
        level = dungeon.levels[args.state.current_level]
        level_height = dungeon.levels[args.state.current_level].tiles.size
        level_width = dungeon.levels[args.state.current_level].tiles[0].size
        x_offset = $pan_x + (1280 - (level_width * tile_size)) / 2
        y_offset = $pan_y + (720 - (level_height * tile_size)) / 2
        x = entity.visual_x
        y = entity.visual_y
        args.outputs.sprites << {
          x: x_offset + x * tile_size,
          y: y_offset + y * tile_size,
          w: tile_size,
          h: tile_size,
          path: "mygame/sprites/simple-mood-16x16.png",
          tile_x: 0*16,
          tile_y: 4*16,
          tile_w: 16,
          tile_h: 16
        }
      end
    end
  end

  def self.draw_hud args

  end

  def self.draw_background args
    args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, path: :solid, r: 0, g: 0, b: 0, a: 255 }
  end

  def self.move_player dx, dy, args
    hero = args.state.hero
    if hero.x + dx < 0 || hero.y + dy < 0
      return
    end
    if hero.x + dx >= args.state.dungeon.levels[hero.level].tiles[0].size ||
       hero.y + dy >= args.state.dungeon.levels[hero.level].tiles.size
      return
    end
    target_tile = args.state.dungeon.levels[hero.level].tiles[hero.y + dy][hero.x + dx]
    if target_tile == :wall || target_tile == :water || target_tile == :chasm
      return
    end
    # we are cleared to move
    GUI.lock_hero
    hero.x += dx # logical position is updated first, visual changes later
    hero.y += dy
  end

  def self.update_entity_animations args
    args.state.entities.each do |entity|
      if entity.visual_x < entity.x
        entity.visual_x += 0.2
        if entity.visual_x > entity.x
          entity.visual_x = entity.x
        end
      elsif entity.visual_x > entity.x
        entity.visual_x -= 0.2
        if entity.visual_x < entity.x
          entity.visual_x = entity.x
        end
      end
      if entity.visual_y < entity.y
        entity.visual_y += 0.2
        if entity.visual_y > entity.y
          entity.visual_y = entity.y
        end
      elsif entity.visual_y > entity.y
        entity.visual_y -= 0.2
        if entity.visual_y < entity.y
          entity.visual_y = entity.y
        end
      end
    end
    # check if hero has reached target
    hero = args.state.hero
    if hero.visual_x == hero.x && hero.visual_y == hero.y
      GUI.unlock_hero(args)
    end
  end  

  def self.is_hero_locked?
    return @@hero_locked
  end

  def self.lock_hero
    @@hero_locked = true
    @@just_used_staircase = false
  end

  def self.unlock_hero(args)
    @@hero_locked = false
    # check if we stepped on something?
    x = args.state.hero.x
    y = args.state.hero.y
    level = args.state.hero.level
    dungeon = args.state.dungeon
    tile = dungeon.levels[level].tiles[y][x]
    unless @@just_used_staircase
      if tile == :staircase_down
        if level < dungeon.levels.size - 1
          args.state.current_level += 1
          args.state.hero.level += 1
          @@just_used_staircase = true
        end
      elsif tile == :staircase_up
        if level > 0
          args.state.current_level -= 1
          args.state.hero.level -= 1
          @@just_used_staircase = true
        end
      end
    end
  end
end