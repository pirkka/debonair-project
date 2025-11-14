class HUD

  def self.draw args
    self.draw_items args
    self.draw_health args
    self.draw_hero_info args
    self.draw_seed args
    self.draw_messages args
    self.debug_info args if $debug
  end

  def self.draw_health args
    hero = args.state.hero
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
    hero.traumas.each_with_index do |trauma, index|
      args.outputs.labels << {
        x: 960,
        y: 620 - index * 13,
        text: "#{trauma.severity} #{trauma.kind.to_s.gsub('_',' ')} on #{trauma.hit_location.to_s.gsub('_',' ')}",
        size_enum: -3,
        r: 255,
        g: 0,
        b: 0,
        a: 255,
        font: "fonts/olivetti.ttf"
      }
    end
  end
  def self.draw_items args
    hero = args.state.hero
    return unless hero && hero.carried_items.any?
    args.outputs.labels << {
      x: 960,
      y: 422,
      text: "Items Carried",
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
        text: item.kind.to_s.gsub('_',' '),
        size_enum: 0,
        r: 255,
        g: 255,
        b: 255,
        a: 255,
        font: "fonts/olivetti.ttf"
      }
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
      }  end

  def self.draw_seed args
    seed = args.state.seed || "unknown"
    args.outputs.labels << {
      x: 10,
      y: 40,
      text: "level: #{args.state.hero.level+1} time: #{args.state.kronos.world_time.to_i} seed: #{seed} ",
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
    if $debug
      args.outputs.labels << {
        x: 10,
        y: 130,
        text: "ticks: #{$args.state.tick_count} framerate: #{args.gtk.current_framerate} delta: #{millisecs} input_f #{$input_frames} standing_f: #{GUI.standing_still_frames}, moving_f: #{GUI.moving_frames}, input_cooldown: #{GUI.input_cooldown}, hero_locked: #{GUI.hero_locked}",
        size_enum: 0,

        r: 255,
        g: 255,
        b: 255,
        a: 255
      }
      args.outputs.labels << {
        x: 10,
        y: 100,
        text: "pos [#{hero.x}, #{hero.y}] level #{hero.level} tiletype: #{args.state.dungeon.levels[hero.level].tiles[hero.y][hero.x]} auto_move: #{GUI.auto_move}",
        size_enum: 0,

        r: 255,
        g: 255,
        b: 255,
        a: 255
      }
    end
  end

  def self.output_message args, message
    args.state.hud_messages ||= []
    args.state.hud_messages << { text: message, time: args.state.kronos.world_time }
    # keep only last 5 messages
    if args.state.hud_messages.size > 5
      args.state.hud_messages.shift 
    end
  end 
end