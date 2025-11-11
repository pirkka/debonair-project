class HUD

  def self.draw_items args
    hero = args.state.hero
    return unless hero && hero.carried_items.any?
    carried_items = hero.carried_items
    x = 900
    y = 700
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
  end

  def self.draw_hero_info args
      hero = args.state.hero
      args.outputs.labels << {
        x: 10,
        y: 40,
        text: "#{hero.name}, #{hero.age.to_s.gsub('adult','')} #{hero.trait.to_s.gsub('none','')} #{hero.species} #{hero.role}".gsub('  ',' ').gsub('_',''),
        size_enum: 0,
        r: 255,
        g: 255,
        b: 255,
        a: 255,
        font: "fonts/olivetti.ttf"
      }
  end

  def self.draw_seed args
    seed = args.state.seed || "unknown"
    args.outputs.labels << {
      x: 700,
      y: 40,
      text: "Seed: #{seed} World Time: #{args.state.kronos.world_time.to_i}",
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

    def self.draw args
      self.draw_items args
      self.draw_hero_info args
      self.draw_seed args
      self.draw_messages args
      self.debug_info args if $debug
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