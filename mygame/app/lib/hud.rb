class HUD

  @@minimap_tiles = nil
  @@minimap_stale = true

  def self.draw args
    self.draw_hero_info args
    self.draw_health args
    self.draw_inventory args
    self.draw_seed args
    self.draw_messages args
    self.debug_info args if $debug
  end

  def self.mark_minimap_stale
    @@minimap_stale = true
  end

  def self.draw_health args
    hero = args.state.hero
    traumas = Trauma.active_traumas(hero)
    if !traumas.empty?
      args.outputs.labels << {
      x: 960,
      y: 641,
      text: "Health",
      size_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      font: "fonts/olivetti.ttf"
      }
    traumas.each_with_index do |trauma, index|
      args.outputs.labels << {
        x: 960,
        y: 620 - index * 16,
        text: "#{trauma.severity} #{trauma.kind.to_s.gsub('_',' ')} trauma on #{trauma.body_part.to_s.gsub('_',' ')}",
        size_enum: 0,
        r: 255,
        g: 0,
        b: 0,
        a: 255,
        font: "fonts/olivetti.ttf"
      }
    end
    end
  end
  def self.draw_inventory args
    hero = args.state.hero
    return unless hero && hero.carried_items.any?
    return unless args.inputs.controller_one.key_held.r2 || args.inputs.keyboard.key_held.shift
    title = "Items Carried (#{Item.carried_weight(hero).round(2)} kg)"
    args.outputs.labels << {
      x: 960,
      y: 422,
      text: title,
      size_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      font: "fonts/olivetti.ttf"
    }
    carried_items = hero.carried_items
    x = 960
    y = 400
    item_size = 20
    carried_items.each_with_index do |item, index|
      args.outputs.labels << {
        x: x,
        y: y,
        text: item.title(args) + " " + hero.wield_info(item),
        size_enum: 0,
        r: 255,
        g: 255,
        b: 255,
        a: 255,
        font: "fonts/olivetti.ttf"
      }
      if hero.worn_items.include?(item)
        args.outputs.sprites << {
          x: x - 20,
          y: y - item_size - 3,
          r: 255,
          g: 255,
          b: 255,
          a: 255,
          w: 21,
          h: 21,  
          path: "sprites/sm16px.png",
          tile_x: 10*16,
          tile_y: 15*16,
          tile_w: 16,
          tile_h: 16
        }
      end
      y -= item_size
    end
    if args.state.selected_item_index
      selected_item_index = args.state.selected_item_index
      # draw a yellow rectangle behind the selected item
      args.outputs.solids << {
        x: x - 5,
        y: 400 - (selected_item_index + 1) * item_size - 5,
        w: 300,
        h: item_size + 5,
        r: 255,
        g: 255,
        b: 0,
        a: 100
      }
    end
    args.state.hero.carried_items.each_with_index do |item, index|
      if args.state.hero.wielded_items.include?(item)
        # draw a hand icon next to wielded items
        args.outputs.sprites << {
          x: x - 20,
          y: 400 - item_size - index * item_size - 3,
          r: 255,
          g: 255,
          b: 255,
          a: 255,
          w: 21,
          h: 21,
          path: "sprites/sm16px.png",
          tile_x: 9*16,
          tile_y: 15*16,
          tile_w: 16,
          tile_h: 16
        }
      end
    end
  end

  def self.draw_hero_info args
    hero = args.state.hero
    args.outputs.labels << {
      x: 960,
      y: 700,
      text: "#{hero.name}",
      size_enum: 2,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      font: "fonts/olivetti.ttf"
    }
    args.outputs.labels << {
      x: 960,
      y: 670,
      text: "#{hero.age.to_s.gsub('adult','')} #{hero.trait.to_s.gsub('none','')} #{hero.species} #{hero.role}".gsub('  ',' ').gsub('_','').trim,
      size_enum: -2,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      font: "fonts/olivetti.ttf"
    }   
    # exhaustion bar
    exhaust_bar_width = 270
    exhaust_bar_height = 3
    args.outputs.solids << {
      x: 960,
      y: 643,
      w: exhaust_bar_width,
      h: exhaust_bar_height,
      r: 0,
      g: 0,
      b: 0,
      a: 255
    }
    exhaustion_width = (hero.exhaustion * exhaust_bar_width).to_i
    args.outputs.solids << {
      x: 960,
      y: 643,
      w: exhaustion_width,
      h: exhaust_bar_height,
      r: 255,       
      g: 220,
      b: 100,
      a: 255
    }
    # hunger bar
    hunger_bar_width = 270
    hunger_bar_height = 3
    args.outputs.solids << {
      x: 960,
      y: 638,
      w: hunger_bar_width,
      h: hunger_bar_height,
      r: 0,
      g: 0,
      b: 0,
      a: 255
    }
    hunger_width = (hero.hunger * hunger_bar_width).to_i
    args.outputs.solids << {
      x: 960,
      y: 638,
      w: hunger_width,
      h: hunger_bar_height,
      r: 100,       
      g: 70,     
      b: 0,
      a: 255
    }
  end

  def self.draw_seed args
    seed = args.state.seed || "unknown"
    args.outputs.labels << {
      x: 10,
      y: 40,
      text: "level: #{args.state.hero.depth+1} time: #{args.state.kronos.world_time.to_i} seed: #{seed} ",
      size_enum: 0,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      font: "fonts/olivetti.ttf"
    }
  end

  def self.draw_messages args
    hud_messages = args.state.hud_messages || []
    x = 10
    y = 700
    line = 0
    message_size = 20
    hud_messages.each do |message|
      args.outputs.labels << {
        x: x,
        y: y - line * message_size,
        text: message[:text],
        size_enum: 0,
        r: 255,
        g: 255,
        b: 255,
        a: 255,
        font: "fonts/olivetti.ttf"
      }
      line += 1
    end
  end

  def self.debug_info args  
    hero = args.state.hero
    time_now = Time.now.to_f
    last_tick_time = args.state.last_tick_time
    delta_time = last_tick_time ? time_now - last_tick_time : 0
    args.state.last_tick_time = time_now
    millisecs = (delta_time * 1000).to_i
    level = args.state.dungeon.levels[hero.depth]
    if $debug
      args.outputs.labels << {
        x: 10,
        y: 130,
        text: "framerate: #{args.gtk.current_framerate}, input_cooldown: #{GUI.input_cooldown}, hero_locked: #{GUI.hero_locked}",
        size_enum: 0,

        r: 255,
        g: 255,
        b: 255,
        a: 255
      }
      if level
        args.outputs.labels << {
          x: 10,
          y: 100,
          text: "pos [#{hero.x}, #{hero.y}] level #{hero.depth} vibe: #{level.vibe if level} tiletype: #{level.tiles[hero.y][hero.x] if level} foliage: #{level.foliage[hero.y][hero.x] if level.foliage} lighting: #{level.lighting[hero.y][hero.x] if level.lighting} auto_move: #{GUI.auto_move}",
          size_enum: 0,
          r: 255,
          g: 255,
          b: 255,
          a: 255
        }
      end
      if args.state.profile_data
        y = 550
        args.state.profile_data.each do |subsystem, time_taken|
          args.outputs.labels << {
            x: 10,
            y: y,
            text: "#{subsystem.to_s.gsub('_',' ')}: #{(time_taken * 1000).to_i} ms (max: #{(args.state.profile_record_data[subsystem] * 1000).to_i} ms)",
            size_enum: 0,
            r: 255,
            g: 255,
            b: 255,
            a: 255
          }
          y -= 30
        end
      end
    end
  end
  def self.output_message args, message
    args.state.hud_messages ||= []
    m = message.to_s.gsub('_',' ').gsub('  ',' ').trim
    args.state.hud_messages << { text: m, time: args.state.kronos.world_time }
    # keep only last N messages
    if args.state.hud_messages.size > 7
      args.state.hud_messages.shift 
    end
  end 

  def self.update_minimap args
    level = Utils.level(args)
    return unless level
    # first get the tile memory for the hero
    tile_memory = Tile.tile_memory(level.depth, args)
    #print tile_memory.inspect
    return unless tile_memory
    # copy the tile memory without side effects
    @@minimap_tiles = []
    # iterate through tile_memory and copy
    tile_memory.each_with_index do |row, row_index|
      @@minimap_tiles[row_index] ||= []
      if row == nil
        next
      end
      row.each_with_index do |tile, col_index|
        @@minimap_tiles[row_index][col_index] = tile
      end
    end
    hero = args.state.hero
    level.entities.each do |entity|
      if Tile.is_tile_visible?(entity.x, entity.y, args)
        @@minimap_tiles[entity.y][entity.x] = :npc
      end
    end
    @@minimap_tiles[hero.y][hero.x] = :hero if hero && @@minimap_tiles[hero.y]
    # compact the minimap by removing empty rows and columns
    compacted_tile_memory = @@minimap_tiles
    compacted_offset_x = 0
    compacted_offset_y = 0
    # remove empty rows and columns from compacted_tile_memory
    # remove empty rows from top
    while compacted_tile_memory.size > 0 && (compacted_tile_memory.first == nil || compacted_tile_memory.first.all? { |t| t == nil } || compacted_tile_memory.first == [])
      compacted_tile_memory.shift
      compacted_offset_y += 1
    end
    # remove empty rows from bottom
    while compacted_tile_memory.size > 0 && (compacted_tile_memory.last == nil || compacted_tile_memory.last.all? { |t| t == nil } || compacted_tile_memory.last == [])
      compacted_tile_memory.pop
    end  
    # remove empty columns from left
    while compacted_tile_memory.first && compacted_tile_memory.all? { |row| row.first == nil }
      compacted_tile_memory.each { |row| row.shift }
      compacted_offset_x += 1
    end  
    # remove empty columns from right
    while compacted_tile_memory.first && compacted_tile_memory.all? { |row| row.last == nil }
      compacted_tile_memory.each { |row| row.pop }
    end
    @@minimap_tiles = compacted_tile_memory
    @@minimap_stale = false
  end

  def self.draw_minimap args
    if @@minimap_stale
      self.update_minimap args
    end
    tile_size = 3
    map_height = @@minimap_tiles.first ? @@minimap_tiles.first.size * tile_size : 0
    map_width = @@minimap_tiles.size * tile_size
    buffer = 20
    x_offset = 1200 - map_width - buffer 
    y_offset = buffer
    return if map_width <= 0 || map_height <= 0
    @@minimap_tiles.each_with_index do |row, row_index| # Y rows
      row.each_with_index do |tile, col_index| # X columns
        #printf "Drawing minimap tile at row #{row_index} col #{col_index} tile #{tile}\n"
        color = { r: 10, g: 10, b: 10 }
        color = case tile
          when :floor then { r: 30, g: 30, b: 30 }
          when :wall then { r: 120, g: 120, b: 120 }
          when :rock then { r: 80, g: 80, b: 80 }
          when :staircase_down then { r: 0, g: 255, b: 0 }
          when :staircase_up then { r: 0, g: 255, b: 0 }
          when :water then { r: 10, g: 10, b: 110 }
          when :lava then { r: 255, g: 0, b: 0 }
          when :hero then { r: 255, g: 255, b: 255 }
          when :npc then { r: 220, g: 120, b: 0 }
        else
          { r: 0, g: 0, b: 0 }
        end
        if tile == nil
          next
        end
        args.outputs.primitives << {
          x: x_offset + col_index * tile_size,
          y: y_offset + row_index * tile_size,
          w: tile_size,
          h: tile_size,
          r: color[:r],
          g: color[:g],
          b: color[:b],
          a: 255,
          path: :solid
        }
      end
    end
  end
end