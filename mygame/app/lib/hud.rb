class HUD
    def self.draw args
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
      if $debug
        args.outputs.labels << {
          x: 10,
          y: 130,
          text: "ticks: #{$args.state.tick_count} input_f #{$input_frames} standing_f: #{GUI.standing_still_frames}, moving_f: #{GUI.moving_frames}, input_cooldown: #{GUI.input_cooldown}, hero_locked: #{GUI.hero_locked}",
          size_enum: 0,

          r: 255,
          g: 255,
          b: 255,
          a: 255
        }
        args.outputs.labels << {
          x: 10,
          y: 100,
          text: "pos [#{hero.x}, #{hero.y}] level #{hero.level} tiletype: #{args.state.dungeon.levels[hero.level].tiles[hero.y][hero.x]}",
          size_enum: 0,

          r: 255,
          g: 255,
          b: 255,
          a: 255
        }
      end
    end
end