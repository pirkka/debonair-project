#$gtk.trace_nil_punning!

#$fixed_seed = 'dsfjkldasjdfdsaf' # THIS ONE IS A NICE SAMURAI SEED
#$fixed_seed = 'testing12345678'
$debug = false
$enable_music = false
$dynamic_light_system = true
$zoom = 0.7
$pan_x = 0.0
$pan_y = 0.0
$zoom_speed = 0.0
$max_zoom = 3.0
$min_zoom = 0.2
$tile_size = 40
$gui_width = 1280
$gui_height = 720
$auto_pan_margin = 0.444 # percentage of screen size
$auto_pan_speed = 0.026

# vendor libraries
require 'app/vendor/perlin_noise'

# project code
require 'app/lib/music'
require 'app/lib/need'
require 'app/lib/architect'
require 'app/lib/dungeon'
require 'app/lib/level'
require 'app/lib/gui'
require 'app/lib/tile'
require 'app/lib/entity'
require 'app/lib/hero'
require 'app/lib/color'
require 'app/lib/leaves'
require 'app/lib/sound_fx'
require 'app/lib/utils'
require 'app/lib/hud'
require 'app/lib/seeded_random'
require 'app/lib/title_screen'
require 'app/lib/game_over_screen'
require 'app/lib/npc'
require 'app/lib/kronos'
require 'app/lib/item'
require 'app/lib/ring'
require 'app/lib/weapon'
require 'app/lib/combat'
require 'app/lib/species'
require 'app/lib/trauma'
require 'app/lib/run'
require 'app/lib/behaviour'
require 'app/lib/potion'
require 'app/lib/food'
require 'app/lib/scroll'
require 'app/lib/debug'
require 'app/lib/lighting'
require 'app/lib/score'
require 'app/lib/foliage'

def boot args
  args.state = {}
  #GTK.ffi_misc.add_controller_config "03000000c82d00001b30000001000000,8BitDo Ultimate 2C,a:b0,b:b1,back:b10,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b12,leftshoulder:b6,leftstick:b13,lefttrigger:a5,leftx:a0,lefty:a1,paddle1:b5,paddle2:b2,rightshoulder:b7,rightstick:b14,righttrigger:a4,rightx:a2,righty:a3,start:b11,x:b3,y:b4,platform:Mac OS X,"
  if $enable_music
    Music.setup(args)
  end
end

def reset args
  printf "Resetting game state...\n"
  args.state.dungeon = nil
  args.state.hero = nil
  args.state.current_depth = nil
  args.state.kronos = nil
  args.state.scene = :title_screen
  Tile.reset_memory_and_visibility
  if $enable_music
    Music.setup(args)
  end
end

def tick args
  # if (!args.inputs.keyboard.has_focus &&
  #     Kernel.tick_count != 0)
  #   args.outputs.background_color = [0, 0, 0]
  #   args.outputs.labels << { x: 640,
  #                            y: 360,
  #                            text: "Game paused while window is not in focus.",
  #                            alignment_enum: 1,
  #                            r: 255, g: 255, b: 255 }
  #   return
  # end
  # 
  Music.tick args 
  args.state.scene ||= :title_screen
  case args.state.scene
  when :gameplay
    gameplay_tick args
  when :staircase
    staircase_tick args
  when :title_screen
    title_screen_tick args
  when :game_over
    game_over_tick args
  when :high_score_list
    high_score_list args
  end
end

def title_screen_tick args
  TitleScreen.tick args
end

def game_over_tick args
  GameOverScreen.tick args
end

def high_score_list args
  Score.tick args
end

def start_profile subsystem, args
  # measure performance here for each subsystem
  # e.g.
  # start_time = Time.now
  # ... subsystem code ...
  # end_time = Time.now
  # elapsed_time = end_time - start_time
  # args.state.profile_data[:subsystem_name] = elapsed_time
  # At end of frame, display profile data on screen
  args.state.profile_data ||= {}
  args.state.profile_data[subsystem] = Time.now
end

def end_profile subsystem, args
  # finalize performance measurement for subsystem
  start_time = args.state.profile_data[subsystem]
  end_time = Time.now
  elapsed_time = end_time - start_time
  args.state.profile_data[subsystem] = elapsed_time
  args.state.profile_record_data ||= {}
  record = args.state.profile_record_data["#{subsystem}".to_sym]
  if record.nil? || elapsed_time > record
    args.state.profile_record_data["#{subsystem}".to_sym] = elapsed_time
  end
end

def gameplay_tick args
  GUI.handle_input args
  args.state.kronos.advance_time args
  GUI.update_entity_animations args
  start_profile(:lighting_calculation, args)
  Lighting.calculate_lighting(args.state.dungeon.levels[args.state.current_depth], args) if $dynamic_light_system
  end_profile(:lighting_calculation, args)
  GUI.draw_background args
  GUI.draw_tiles args
  start_profile(:foliage_drawing, args)
  GUI.draw_foliage args
  end_profile(:foliage_drawing, args)
  start_profile(:light_drawing, args)
  Light.draw_lights args
  end_profile(:light_drawing, args)
  GUI.draw_items args
  GUI.draw_entities args
  GUI.pan_to_player args
  GUI.update_screen_flash args
  HUD.draw args
end

def staircase_tick args
  Lighting.calculate_lighting(args.state.dungeon.levels[args.state.current_depth], args) if $dynamic_light_system
  GUI.draw_background args
  GUI.draw_tiles args
  GUI.draw_items args
  GUI.draw_entities args
  GUI.staircase_animation args
  GUI.pan_to_player args
  HUD.draw args
end