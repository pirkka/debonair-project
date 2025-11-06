class GameOverScreen
  def self.tick args
    args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, path: :solid, r: 0, g: 0, b: 0, a: 255 }
    args.outputs.labels << { x: 640, y: 360, text: "Thanks for Playing", size_enum: 5, alignment_enum: 1, r: 0, g: 0, b: 255 }
    args.outputs.labels << { x: 640, y: 300, text: "press space to continue", size_enum: 3, alignment_enum: 1, r: 0, g: 0, b: 255 }  
    if args.inputs.keyboard.key_down.space
      $gtk.reset
      args.state.scene = :title_screen
    end
  end
end