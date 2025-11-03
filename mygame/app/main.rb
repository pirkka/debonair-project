require 'app/lib/architect'
require 'app/lib/dungeon'
require 'app/lib/level'
require 'app/lib/GUI'
require 'app/lib/tile'

def boot args
  self.reset args  
end

def reset args
  Architect.instance.setup({})
  Architect.instance.architect_dungeon(args)
  args.state[:current_level] = 0
  printf "Setup complete. Current level is %d" % args.state[:current_level]
  printf "Dungeon has %d levels" % args.state[:dungeon].levels.size
end

def tick args
  GUI.handle_input args
  GUI.draw_background args
  GUI.draw_tiles args
  GUI.draw_hud args
end

GTK.reset