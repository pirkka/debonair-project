class GameOverScreen
  def self.tick args
    args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, path: :solid, r: 0, g: 0, b: 0, a: 255 }
    if args.state.hero.has_item?(:amulet_of_yendor)
      args.outputs.labels << { x: 640, y: 500, text: "Congratulations!", size_enum: 5, alignment_enum: 1, r: 250, g: 250, b: 250 }
      args.outputs.labels << { x: 640, y: 460, text: "You have retrieved the Amulet of Yendor", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
      args.outputs.labels << { x: 640, y: 420, text: "and escaped the dungeon alive!", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
    else
      args.outputs.labels << { x: 640, y: 500, text: "Game Over", size_enum: 5, alignment_enum: 1, r: 250, g: 250, b: 250 }
      if args.state.hero.perished
        reason_of_death = args.state.hero.reason_of_death || "unknown causes"
        args.outputs.labels << { x: 640, y: 460, text: "You have died from #{reason_of_death}.", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
      else
        args.outputs.labels << { x: 640, y: 460, text: "You escaped the dungeon without the Amulet of Yendor.", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
      end
    end
    args.outputs.labels << { x: 640, y: 320, text: "Thanks for Playing", size_enum: 5, alignment_enum: 1, r: 250, g: 250, b: 250 }
    args.outputs.labels << { x: 640, y: 280, text: "press space to continue", size_enum: 3, alignment_enum: 1, r: 250, g: 250, b: 250 }
    if args.inputs.keyboard.key_down.space
      args.gtk.reset
      reset args
      args.state.scene = :title_screen
    end
  end
end