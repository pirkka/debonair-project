class GameOverScreen
  @@played_game_over_sound = false
  def self.reset args
    @@played_game_over_sound = false
  end
  def self.play_game_over_sound sound, args
    if @@played_game_over_sound
      return
    end
    SoundFX.play_sound(sound, args)
    @@played_game_over_sound = true
  end
  def self.tick args
    printf " Game Over Screen Tick\n"
    args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, path: :solid, r: 0, g: 0, b: 0, a: 255 }
    if args.state.hero.has_item?(:amulet_of_skandor) && !args.state.hero.perished
      args.outputs.labels << { x: 640, y: 500, text: "Congratulations!", size_enum: 5, alignment_enum: 1, r: 250, g: 250, b: 250 }
      args.outputs.labels << { x: 640, y: 460, text: "You have retrieved the Amulet of Skandor", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
      args.outputs.labels << { x: 640, y: 420, text: "and escaped the dungeon alive!", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
        GameOverScreen.play_game_over_sound(:fanfare, args)
    else
      args.outputs.labels << { x: 640, y: 500, text: "Game Over", size_enum: 5, alignment_enum: 1, r: 250, g: 250, b: 250 }
      if args.state.hero.perished
        reason_of_death = args.state.hero.reason_of_death || "unknown causes"
        args.outputs.labels << { x: 640, y: 460, text: "You have died #{reason_of_death} on level #{args.state.current_level + 1}.".gsub('  ', ' '), size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
        GameOverScreen.play_game_over_sound(:player_died, args)
      else
        args.outputs.labels << { x: 640, y: 460, text: "You escaped the dungeon without the Amulet of Skandor.", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
        GameOverScreen.play_game_over_sound(:crickets, args)
      end
    end
    args.outputs.labels << { x: 640, y: 320, text: "Thanks for Playing", size_enum: 5, alignment_enum: 1, r: 250, g: 250, b: 250 }
    args.outputs.labels << { x: 640, y: 280, text: "press space to continue", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
    if args.inputs.keyboard.key_down.space || args.inputs.controller_one.key_down.a
      args.gtk.reset
      args.state.scene = :title_screen
    end
  end
end