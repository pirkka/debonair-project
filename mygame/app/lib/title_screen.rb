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
      args.state.run = Run.new args
      args.state.run.setup args
      GUI.initialize_state args
      printf "Game start complete.\n"
      printf "Dungeon has %d levels.\n" % args.state.dungeon.levels.size
      args.state.dungeon.levels.each_with_index do |level, index|
        printf " Level %d has %d rooms and %d entities and %d items.\n" % [index, level.rooms.size, level.entities.size, level.items.size]
      end
      args.state.scene = :gameplay
  end
end