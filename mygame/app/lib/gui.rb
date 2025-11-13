class GUI

  def self.initialize_state args
    @@auto_move = nil
    @@hero_locked = false
    @@just_used_staircase = true
    @@input_cooldown = 0
    @@moving_frames = 0
    @@standing_still_frames = 0
    @@tiles_observed = false
  end

  def self.standing_still_frames
    return @@standing_still_frames
  end

  def self.moving_frames
    return @@moving_frames
  end

  def self.input_cooldown
    return @@input_cooldown
  end

  def self.hero_locked
    return @@hero_locked
  end

  def self.staircase_animation args
    duration_in_frames = 100
    cutoff = 50
    @@staircase_animation_frame ||= 0
    if @@staircase_animation_frame == 0
      SoundFX.play_sound(:staircase, args)
    end
    @@staircase_animation_frame += 1
    if @@staircase_animation_frame < cutoff
      alpha = @@staircase_animation_frame.to_f / cutoff.to_f
    else
      alpha = 1.0 - (@@staircase_animation_frame.to_f - cutoff.to_f) / (duration_in_frames.to_f - cutoff.to_f)
    end
    alpha = (alpha * 255).to_i.clamp(0, 255)
    args.outputs.primitives << { x: 0, y: 0, w: 1280, h: 720, path: :solid, r: 0, g: 0, b: 0, a: alpha, blendmode_enum: 1 }
    if @@staircase_animation_frame > cutoff && args.state.staircase
      # actually change level now
      old_level = args.state.dungeon.levels[args.state.current_level]
      old_level.entities.delete(args.state.hero)
      args.state.hero.level += (args.state.staircase == :down ? 1 : -1)
      args.state.current_level = args.state.hero.level
      args.state.staircase = nil
      @@tiles_observed = false
      new_level = args.state.dungeon.levels[args.state.current_level]
      new_level.entities << args.state.hero
    end
    if @@staircase_animation_frame >= duration_in_frames
      args.state.scene = :gameplay
      @@staircase_animation_frame = 0
    end
  end

  def self.handle_input args
    $input_frames ||= 0
    $input_frames += 1
    unless GUI.is_hero_locked? # already moving
      # add a slight cooldown to prevent rapid movement
      @@input_cooldown ||= 0
      if @@input_cooldown > 0
        @@input_cooldown -= 1
        @@moving_frames += 1
      else
      # player movement
        if args.inputs.up
          GUI.move_player(0, 1, args)
        elsif args.inputs.down
          GUI.move_player(0, -1, args)
        elsif args.inputs.left
          GUI.move_player(-1, 0, args)
        elsif args.inputs.right
          GUI.move_player(1, 0, args)
        elsif @@auto_move
          dx, dy = @@auto_move
          moved = GUI.move_player(dx, dy, args)
          unless moved
            @@auto_move = nil # stop auto moving if blocked
          end
        else
          # standing still
          @@standing_still_frames += 1
          @@moving_frames = 0
          if args.inputs.keyboard.key_down.space
            # pick up item(s) on the current tile
            # check for items
            hero = args.state.hero
            level = args.state.dungeon.levels[hero.level]
            items_on_tile = level.items.select { |item| item.x == hero.x && item.y == hero.y }
            items_on_tile.each do |item|
              hero.pick_up_item(item, level)
              SoundFX.play_sound(:pick_up, args)
            end
          end
        end
      end

    else
      # hero is locked, ignore input
      @@moving_frames += 1
      @@standing_still_frames = 0
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
    Tile.observe_tiles args unless @@tiles_observed
    @@tiles_observed = true
    Tile.draw_tiles args
  end

  def self.draw_items args
    level = args.state.dungeon.levels[args.state.current_level]
    return unless level
    tile_size = $tile_size * $zoom
    dungeon = args.state.dungeon
    level_height = level.tiles.size
    level_width = level.tiles[0].size
    x_offset = $pan_x + (1280 - (level_width * tile_size)) / 2
    y_offset = $pan_y + (720 - (level_height * tile_size)) / 2

    level.items.each do |item|
      visible = Tile.is_tile_visible?(item.x, item.y, args)
      next unless visible
      args.outputs.sprites << {
        x: x_offset + item.x * tile_size,
        y: y_offset + item.y * tile_size,
        w: tile_size,
        h: tile_size,
        path: "sprites/simple-mood-16x16.png",
        tile_x: item.c[0]*16,
        tile_y: item.c[1]*16,
        tile_w: 16,
        tile_h: 16,
        r: item.color[0],
        g: item.color[1],
        b: item.color[2],
        a: 255
      }
    end
  end

  def self.draw_entities args
    level = args.state.dungeon.levels[args.state.current_level]
    return unless level
    level.entities.each do |entity|
      unless entity == args.state.hero
        visible = Tile.is_tile_visible?(entity.x, entity.y, args) && !entity.invisible?
        if args.state.hero.telepathy_range > 0
          dist_x = (entity.x - args.state.hero.x).abs
          dist_y = (entity.y - args.state.hero.y).abs
          # pythagorean distance
          dist = Math.sqrt(dist_x**2 + dist_y**2)
          visible = true if dist <= args.state.hero.telepathy_range
        end
        if visible
          entity.has_been_seen = true
        end
        next unless visible
      end
      tile_size = $tile_size * $zoom
      dungeon = args.state.dungeon
      level = dungeon.levels[args.state.current_level]
      level_height = level.tiles.size
      level_width = level.tiles[0].size
      x_offset = $pan_x + (1280 - (level_width * tile_size)) / 2
      y_offset = $pan_y + (720 - (level_height * tile_size)) / 2
      x = entity.visual_x
      y = entity.visual_y
      alpha = 255
      if entity.invisible?
        alpha = 100
      end
      args.outputs.sprites << {
        x: x_offset + x * tile_size,
        y: y_offset + y * tile_size,
        w: tile_size,
        h: tile_size,
        path: "sprites/simple-mood-16x16.png",
        tile_x: entity.c[0]*16,
        tile_y: entity.c[1]*16,
        tile_w: 16,
        tile_h: 16,
        r: entity.color[0],
        g: entity.color[1],
        b: entity.color[2],
        a: alpha
      }
    end
  end

  def self.draw_background args
    args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, path: :solid, r: 0, g: 0, b: 0, a: 255 }
  end

  # return false if move not possible
  def self.move_player dx, dy, args
    hero = args.state.hero
    if args.inputs.keyboard.key_held.shift
      @@auto_move = [dx, dy] # move until blocked
    end
    @@standing_still_frames = 0
    @@moving_frames += 1
    # auto move end check
    if @@auto_move != [dx, dy]
      @@auto_move = nil
    end
    # boundary checks
    if hero.x + dx < 0 || hero.y + dy < 0
      @@auto_move = nil
      return false
    end
    if hero.x + dx >= args.state.dungeon.levels[hero.level].tiles[0].size ||
       hero.y + dy >= args.state.dungeon.levels[hero.level].tiles.size
      @@auto_move = nil
      return false
    end
    target_tile = args.state.dungeon.levels[hero.level].tiles[hero.y + dy][hero.x + dx]
    unless Tile.is_walkable?(target_tile, args)
      @@auto_move = nil
      return false
    end
    if Tile.occupied?(hero.x + dx, hero.y + dy, args)
      if @@auto_move
        @@auto_move = nil # stop auto moving if blocked
        return false
      end
      GUI.lock_hero
      npc = args.state.dungeon.levels[hero.level].entity_at(hero.x + dx, hero.y + dy)
      npc.enemies << hero unless npc.enemies.include?(hero)
      Combat.resolve_attack(hero, npc, args)
      args.state.kronos.spend_time(hero, hero.walking_speed, args) # todo fix speed depending on action
      return true
    end
    # we are cleared to move
    GUI.lock_hero
    hero.x += dx # logical position is updated first, visual changes later
    hero.y += dy
    args.state.kronos.spend_time(hero, hero.walking_speed, args) 
    return true
  end

  def self.update_entity_animations args
    animation_speed = 0.2 # tiles per frame
    level = args.state.dungeon.levels[args.state.current_level]
    return unless level
    level.entities.each do |entity|
      if entity.visual_x < entity.x
        entity.visual_x += animation_speed
        if entity.visual_x > entity.x
          entity.visual_x = entity.x
        end
      elsif entity.visual_x > entity.x
        entity.visual_x -= animation_speed
        if entity.visual_x < entity.x
          entity.visual_x = entity.x
        end
      end
      if entity.visual_y < entity.y
        entity.visual_y += animation_speed
        if entity.visual_y > entity.y
          entity.visual_y = entity.y
        end
      elsif entity.visual_y > entity.y
        entity.visual_y -= animation_speed
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
    # input cooldown depends on moving frames
    if @@moving_frames > 200
      @@input_cooldown = 2 # frames
    elsif @@moving_frames > 60
      @@input_cooldown = 4 # frames
    elsif @@moving_frames > 20
      @@input_cooldown = 4 # frames
    else
      @@input_cooldown = 8 # frames
    end    
    SoundFX.play_sound(:walk, $gtk.args)
  end

  def self.unlock_hero(args)
    @@hero_locked = false
    @@tiles_observed = false
    # check if we stepped on something?
    x = args.state.hero.x
    y = args.state.hero.y
    level = args.state.hero.level
    dungeon = args.state.dungeon
    tile = dungeon.levels[level].tiles[y][x]
    unless @@just_used_staircase
      if tile == :staircase_down  
        if level < dungeon.levels.size - 1
          args.state.staircase = :down
          @@just_used_staircase = true
          args.state.scene = :staircase
        end
      elsif tile == :staircase_up
        if level > 0
          args.state.staircase = :up
          @@just_used_staircase = true
          args.state.scene = :staircase
        else
          # reached the surface, game over          
          args.state.scene = :game_over
        end
      end
    end
  end

  def self.pan_to_player args
    hero = args.state.hero
    tile_size = $tile_size * $zoom
    dungeon = args.state.dungeon
    level = dungeon.levels[args.state.current_level]
    level_height = level.tiles.size
    level_width = level.tiles[0].size
    x_offset = $pan_x + ($gui_width - (level_width * tile_size)) / 2
    y_offset = $pan_y + ($gui_height - (level_height * tile_size)) / 2
    x = hero.x
    y = hero.y
    hero_center_x = x_offset + x * tile_size + tile_size / 2
    hero_center_y = y_offset + y * tile_size + tile_size / 2

    if hero_center_x < $gui_width * $auto_pan_margin || hero_center_x > $gui_width * (1 - $auto_pan_margin)
      # let's set a horizontal pan target
      # desired x offset to center hero
      desired_x_offset = $gui_width / 2 - (x * tile_size + tile_size / 2)
      $pan_x += (desired_x_offset - x_offset) * $auto_pan_speed
    end

    if hero_center_y < $gui_height * $auto_pan_margin || hero_center_y > $gui_height * (1 - $auto_pan_margin)
      # let's set a vertical pan target
      # desired y offset to center hero
      desired_y_offset = $gui_height / 2 - (y * tile_size + tile_size / 2)
      $pan_y += (desired_y_offset - y_offset) * $auto_pan_speed
    end
    
  end

  def self.auto_move
    return @@auto_move
  end
end