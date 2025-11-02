require 'app/lib/architect'
require 'app/lib/GUI'

def setup
  Architect.instance.setup(args.state)
  Architect.instance.architect_dungeon(args.state)
end

def tick args
  args.state.logo_rect ||= { x: 576,
                             y: 200,
                             w: 128,
                             h: 101 }

  args.outputs.sprites << { x: args.state.logo_rect.x,
                            y: args.state.logo_rect.y,
                            w: args.state.logo_rect.w,
                            h: args.state.logo_rect.h,
                            path: 'dragonruby.png',
                            angle: Kernel.tick_count }    

  GUI.draw_background args
  GUI.draw_tiles args
  GUI.draw_hud args
end
