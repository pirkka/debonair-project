class GUI
  def self.draw_hud args
    args.outputs.labels << [20, 720 - 20, "Debonair", 10, 1, 255, 255, 255]
  end

  def self.draw_background args
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'background.png' }
  end

  def self.draw_tiles args
    args.outputs.solids << [470, 520, 50, 50]
  end
end