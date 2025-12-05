class GUI

  @@inspector_active = false
  @@inspector_affordances = nil
  @@inspector_selected_affordance_index = nil

  def self.activate_inspector args
    if @@inspector_active
      return
    end
    printf("Activating inspector\n")
    # this opens a context menu showing details about the tile under the cursor
    @@inspector_active = true
    # navigating affordances within inspector
    level = Utils.level args
    hero = args.state.hero
    @@inspector_affordances = Affordance.populate_for_tile(hero, @@look_mode_x, @@look_mode_y, level, args)
    @@inspector_selected_affordance_index = 0
  end

  def self.deactivate_inspector args
    if !@@inspector_active
      return
    end
    printf("Deactivating inspector\n")
    @@inspector_active = false
  end

  def self.activate_look_mode args
    unless args.state.look_mode_active
      printf("Activating look mode\n")
      args.state.look_mode_active = true
    end
  end

  def self.deactivate_look_mode args
    if !args.state.look_mode_active
      return
    end
    printf("Deactivating look mode\n")
    args.state.look_mode_active = false
    @@look_mode_x = nil
    @@look_mode_y = nil
    @@look_mode_index = nil
  end

  def self.get_all_points_of_interest(args)
    hero = args.state.hero
    level = args.state.dungeon.levels[hero.depth]
    points_of_interest = []
    # find visible items
    level.items.each do |item|
      if Tile.is_tile_visible?(item.x, item.y, args)
        points_of_interest << item
      end
    end
    # find visible traps
    level.traps.each do |trap|
      if trap.found 
        points_of_interest << trap
      end
    end
    # find visible entities
    level.entities.each do |entity|
      next if entity == hero
      if Tile.is_tile_visible?(entity.x, entity.y, args)
        points_of_interest << entity
      end
    end
    return points_of_interest
  end

  def self.describe_location(x, y, level, args)
    description = []
    # describe effects
    level.effects.each do |effect|
      if effect.x == x && effect.y == y
        description << effect.kind.to_s.gsub('_',' ')
      end
    end
    # describe entities
    level.entities.each do |entity|
      if entity.x == x && entity.y == y
        description << entity.title(args)
      end
    end
    # describe items
    level.items.each do |item|
      if item.x == x && item.y == y
        description << item.title(args)
      end
    end
    # describe traps
    level.traps.each do |trap|
      if trap.x == x && trap.y == y && trap.found
        description << trap.title(args)
      end
    end
    # describe lights
    level.lights.each do |light|
      if light.x == x && light.y == y
        description << light.kind.to_s.gsub('_',' ')
      end
    end
    # describe floor tile
    tile_type = level.tiles[y][x]
    description << tile_type.to_s.gsub('_',' ')
    return description.join(", ")
  end

  def self.handle_look_mode(args)
    if @@look_mode_cooldown && @@look_mode_cooldown > 0
      @@look_mode_cooldown -= 1
    end
    if @@look_mode_frames
      @@look_mode_frames += 1
    else
      @@look_mode_frames = 1
    end
    hero = args.state.hero
    level = args.state.dungeon.levels[hero.depth]
    @@look_mode_x ||= hero.x
    @@look_mode_y ||= hero.y

    # move cursor if directional inputs are used
    level_height = level.tiles.size
    level_width = level.tiles[0].size
    if (args.inputs.up || args.inputs.down || args.inputs.left || args.inputs.right) && @@look_mode_cooldown == 0 && @@inspector_active == false
      dx = 0
      dy = 0
      if args.inputs.up
        dy = 1
      elsif args.inputs.down
        dy = -1
      elsif args.inputs.left
        dx = -1
      elsif args.inputs.right
        dx = 1
      end
      # clamp to visible area
      wanted_x = @@look_mode_x + dx
      wanted_y = @@look_mode_y + dy
      if Tile.is_tile_visible?(wanted_x, wanted_y, args)
        @@look_mode_x = wanted_x
        @@look_mode_y = wanted_y
      end
      # clamp to level bounds
      @@look_mode_x = @@look_mode_x.clamp(0, level_width - 1)
      @@look_mode_y = @@look_mode_y.clamp(0, level_height - 1)
      @@look_mode_cooldown = 10

    end
    # check for inspector activation
    if args.inputs.controller_one.key_held.r2 || args.inputs.keyboard.key_held.tab
      if args.inputs.controller_one.key_down.a || args.inputs.keyboard.key_down.space
        GUI.activate_inspector args
      end
    end
  end

  def self.draw_look_mode args
    hero = args.state.hero
    level = args.state.dungeon.levels[hero.depth]
    GUI.draw_cursor args, level
    GUI.draw_inspector args, level
  end

  def self.follow_entity_with_cursor(entity, x, y, args)
    if @@look_mode_x == entity.x && @@look_mode_y == entity.y
      @@look_mode_x = x
      @@look_mode_y = y
    end
  end

      # gather all visible things
      # visible_things = GUI::Cursor.get_all_points_of_interest(args)
      # thing = nil

      # we are jumping to visible things
      # if visible_things.size > 0 && args.inputs.controller_one.key_down.r1 || args.inputs.controller_one.key_down.r3 || args.inputs.keyboard.key_down.q || args.inputs.keyboard.key_down.e 
      #   if @@look_mode_index == nil
      #     @@look_mode_index = 0
      #     thing = visible_things[@@look_mode_index]
      #     @look_mode_x = thing.x
      #     @look_mode_y = thing.y
      #     HUD.output_message args, "This is a #{thing.title(args)}."
      #   else
      #     if args.inputs.controller_one.key_down.r1 || args.inputs.keyboard.key_down.q && @@look_mode_cooldown == 0
      #       @@look_mode_index -= 1
      #       if @@look_mode_index < 0
      #         @@look_mode_index = visible_things.size - 1
      #       end
      #       thing = visible_things[@@look_mode_index]
      #       @look_mode_x = thing.x
      #       @look_mode_y = thing.y
      #       HUD.output_message args, "This is a #{thing.title(args)}."
      #       @@look_mode_cooldown = 10
      #     elsif args.inputs.controller_one.key_down.r3 || args.inputs.keyboard.key_down.e && @@look_mode_cooldown == 0
      #       @@look_mode_index += 1
      #       if @@look_mode_index >= visible_things.size
      #         @@look_mode_index = 0
      #       end
      #       thing = visible_things[@@look_mode_index]
      #       @look_mode_x = thing.x
      #       @look_mode_y = thing.y
      #       HUD.output_message args, "This is a #{thing.title(args)}."
      #       @@look_mode_cooldown = 10
      #     else
      #       thing = visible_things[@@look_mode_index]
      #       @look_mode_x = thing.x
      #       @look_mode_y = thing.y
      #     end
      #   end

  def self.handle_inspector_input args
    # exit inspector
    if args.inputs.controller_one.key_down.b || args.inputs.keyboard.key_down.escape || args.inputs.keyboard.key_down.tab
      GUI.deactivate_inspector args
    end
    # navigate affordances
    if @@inspector_affordances && @@inspector_affordances.size > 0
      if args.inputs.controller_one.key_down.up || args.inputs.keyboard.key_down.w || args.inputs.keyboard.key_down.up_arrow  
        if @@inspector_selected_affordance_index == nil
          @@inspector_selected_affordance_index = 0
        else
          @@inspector_selected_affordance_index -= 1
          if @@inspector_selected_affordance_index < 0
            @@inspector_selected_affordance_index = @@inspector_affordances.size - 1
          end
        end
      elsif args.inputs.controller_one.key_down.down || args.inputs.keyboard.key_down.s || args.inputs.keyboard.key_down.down_arrow
        if @@inspector_selected_affordance_index == nil
          @@inspector_selected_affordance_index = 0
        else
          @@inspector_selected_affordance_index += 1
          if @@inspector_selected_affordance_index >= @@inspector_affordances.size
            @@inspector_selected_affordance_index = 0
          end
        end
      end
    end
    # select affordance
    if (args.inputs.controller_one.key_down.a || args.inputs.keyboard.key_down.space) && @@inspector_selected_affordance_index != nil && @@inspector_affordances && @@inspector_affordances.size > 0
      selected_affordance = @@inspector_affordances[@@inspector_selected_affordance_index]
      printf "Player selected affordance: #{selected_affordance.title(args)}\n"
      hero = args.state.hero
      selected_affordance.execute(hero, args)
      GUI.deactivate_inspector args
    end
  end

  def self.draw_inspector args, level
    if @@inspector_active
      description = GUI.describe_location(@@look_mode_x, @@look_mode_y, level, args)
      inspector_width = 500
      inspector_height = 400
      border = 1
      margin = 8
      x = 50
      y = 100
      # draw border
      args.outputs.primitives << {
        x: x - border,
        y: y - border,
        w: inspector_width + border * 2,
        h: inspector_height + border * 2,
        r: 255,
        g: 255,
        b: 255,
        a: 255,
        path: :solid
      }
      # draw background
      args.outputs.primitives << {
        x: x,
        y: y,
        w: inspector_width,
        h: inspector_height,
        r: 0  ,
        g: 0,
        b: 0,
        a: 255,
        path: :solid
      }    
      # draw title
      args.outputs.labels << {
        x: x + margin,
        y: y + inspector_height - margin,
        text: description,
        size_enum: 4,
        alignment_enum: 0,
        r: 255,
        g: 255,
        b: 255,
        a: 255,
        font: "fonts/olivetti.ttf"
      }
      # draw box below selected affordance
      if @@inspector_selected_affordance_index != nil && @@inspector_affordances && @@inspector_affordances.size > 0
        args.outputs.primitives << {
          x: x + margin - 4,
          y: y + inspector_height - margin - 54 - (@@inspector_selected_affordance_index * 24) - 4,
          w: inspector_width - margin * 2 + 8,
          h: 30,
          r: 100,
          g: 100,
          b: 255,
          a: 100,
          path: :solid
        }
      end
      # draw affordances
      @@inspector_affordances.each do |affordance|
        args.outputs.labels << {
          x: x + margin,
          y: y + inspector_height - margin - 30 - (@@inspector_affordances.index(affordance) * 24),
          text: affordance.title(args),
          size_enum: 1,
          alignment_enum: 0,
          r: 200,
          g: 200,
          b: 200,
          a: 255,
          font: "fonts/olivetti.ttf"
        }
      end
    end
  end

  def self.draw_cursor args, level
    return unless args.state.look_mode_active
    return if @@look_mode_x.nil? || @@look_mode_y.nil?
    # show a marker on the looked location
    tile_size = $tile_size * $zoom
    level_height = level.tiles.size
    level_width = level.tiles[0].size
    x_offset = $pan_x + (1280 - (level_width * tile_size)) / 2
    y_offset = $pan_y + (720 - (level_height * tile_size)) / 2
    # draw cursor
    args.outputs.primitives << {
      x: x_offset + @@look_mode_x * tile_size,
      y: y_offset + @@look_mode_y * tile_size,
      r: 255,
      g: 255, 
      b: 255,
      w: tile_size,
      h: tile_size,
      path: "sprites/sm16px.png",
      tile_x: 0*16,
      tile_y: 0*16,
      tile_w: 16,
      tile_h: 16,
    }
    args.outputs.primitives << {
      x: x_offset + @@look_mode_x * tile_size,
      y: y_offset + (@@look_mode_y+1) * tile_size,
      r: 255,
      g: 255, 
      b: 255,
      w: tile_size,
      h: tile_size,
      path: "sprites/sm16px.png",
      tile_x: 15*16,
      tile_y: 1*16,
      tile_w: 16,
      tile_h: 16,
    }
    # also label it
    # calculate screen position
    screen_x = x_offset + (@@look_mode_x + 0.5) * tile_size
    screen_y = y_offset + (@@look_mode_y + 3.0) * tile_size
    description = GUI.describe_location(@@look_mode_x, @@look_mode_y, level, args)
    args.outputs.primitives << {
      x: screen_x,
      y: screen_y,
      text: description,
      size_enum: 3,
      alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      font: "fonts/olivetti.ttf"
    }
  end
end
