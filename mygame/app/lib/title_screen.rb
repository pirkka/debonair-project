class TitleScreen
  def self.tick args
    args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, path: :solid, r: 0, g: 0, b: 0, a: 255 }
    args.outputs.labels << {
      x: 640, y: 450, text: "Debonair Project", size_enum: 30, alignment_enum: 1, r: 255, g: 255, b: 255, font: "fonts/greek-freak.ttf"
    }
    args.outputs.labels << {
      x: 640, y: 300, text: "Press Space To Start", size_enum: 3, alignment_enum: 1, r: 255, g: 255, b: 255, font: "fonts/greek-freak.ttf"
    }
    if args.inputs.keyboard.key_down.space
      self.start_new_game args
    end
  end

  def self.start_new_game args
      Architect.create_seed(args)
      Architect.set_seed(args, 'jolly developers II') # for testing purposes
      Architect.use_seed(args)
      Architect.instance.setup({})
      Architect.instance.architect_dungeon(args)
      args.state.current_level = 0
      GUI.initialize_state args
      printf "Game start complete.\n"
      printf "Dungeon has %d levels.\n" % args.state.dungeon.levels.size
      printf "Dungeon has %d entities.\n" % args.state.entities.size
      args.state.scene = :gameplay
  end
end