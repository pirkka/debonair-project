### Hd Labels - main.rb
```ruby
  # ./samples/07_advanced_rendering_hd/01_hd_labels/app/main.rb
  def tick args
    args.state.output_cycle ||= :top_level

    args.outputs.background_color = [0, 0, 0]
    args.outputs.solids << [0, 0, 1280, 720, 255, 255, 255]
    if args.state.output_cycle == :top_level
      render_main args
    else
      render_scene args
    end

    # cycle between labels in top level args.outputs
    # and labels inside of render target
    if Kernel.tick_count.zmod? 300
      if args.state.output_cycle == :top_level
        args.state.output_cycle = :render_target
      else
        args.state.output_cycle = :top_level
      end
    end

    args.state.window_scale ||= 1
    if args.inputs.keyboard.key_down.space
      if args.state.window_scale == 1
        args.state.window_scale = 2
        GTK.set_window_scale 2
      else
        args.state.window_scale = 1
        GTK.set_window_scale 1
      end
    end
  end

  def render_main args
    # center line
    args.outputs.lines   << { x:   0, y: 360, x2: 1280, y2: 360 }
    args.outputs.lines   << { x: 640, y:   0, x2:  640, y2: 720 }

    # horizontal ruler
    args.outputs.lines   << { x:   0, y: 370, x2: 1280, y2: 370 }
    args.outputs.lines   << { x:   0, y: 351, x2: 1280, y2: 351 }

    # vertical ruler
    args.outputs.lines   << { x:  575, y: 0, x2: 575, y2: 720 }
    args.outputs.lines   << { x:  701, y: 0, x2: 701, y2: 720 }

    args.outputs.sprites << { x: 640 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square/blue.png", a: 128 }
    args.outputs.labels  << { x:  640, y:   0, text: "(bottom)",  alignment_enum: 1, vertical_alignment_enum: 0 }
    args.outputs.labels  << { x:  640, y: 425, text: "top_level", alignment_enum: 1, vertical_alignment_enum: 1 }
    args.outputs.labels  << { x:  640, y: 720, text: "(top)",     alignment_enum: 1, vertical_alignment_enum: 2 }
    args.outputs.labels  << { x:    0, y: 360, text: "(left)",    alignment_enum: 0, vertical_alignment_enum: 1 }
    args.outputs.labels  << { x: 1280, y: 360, text: "(right)",   alignment_enum: 2, vertical_alignment_enum: 1 }
  end

  def render_scene args
    args.outputs[:scene].background_color = [255, 255, 255, 0]

    # center line
    args.outputs[:scene].lines   << { x:   0, y: 360, x2: 1280, y2: 360 }
    args.outputs[:scene].lines   << { x: 640, y:   0, x2:  640, y2: 720 }

    # horizontal ruler
    args.outputs[:scene].lines   << { x:   0, y: 370, x2: 1280, y2: 370 }
    args.outputs[:scene].lines   << { x:   0, y: 351, x2: 1280, y2: 351 }

    # vertical ruler
    args.outputs[:scene].lines   << { x:  575, y: 0, x2: 575, y2: 720 }
    args.outputs[:scene].lines   << { x:  701, y: 0, x2: 701, y2: 720 }

    args.outputs[:scene].sprites << { x: 640 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square/blue.png", a: 128, blendmode_enum: 0 }
    args.outputs[:scene].labels  << { x:  640, y:   0, text: "(bottom)",      alignment_enum: 1, vertical_alignment_enum: 0, blendmode_enum: 0 }
    args.outputs[:scene].labels  << { x:  640, y: 425, text: "render target", alignment_enum: 1, vertical_alignment_enum: 1, blendmode_enum: 0 }
    args.outputs[:scene].labels  << { x:  640, y: 720, text: "(top)",         alignment_enum: 1, vertical_alignment_enum: 2, blendmode_enum: 0 }
    args.outputs[:scene].labels  << { x:    0, y: 360, text: "(left)",        alignment_enum: 0, vertical_alignment_enum: 1, blendmode_enum: 0 }
    args.outputs[:scene].labels  << { x: 1280, y: 360, text: "(right)",       alignment_enum: 2, vertical_alignment_enum: 1, blendmode_enum: 0 }

    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :scene }
  end

```

### Texture Atlases - main.rb
```ruby
  # ./samples/07_advanced_rendering_hd/02_texture_atlases/app/main.rb
  # With HD mode enabled. DragonRuby will automatically use HD sprites given the following
  # naming convention (assume we are using a sprite called =player.png=):
  #
  # | Name  | Resolution | File Naming Convention        |
  # |-------+------------+-------------------------------|
  # | 720p  |   1280x720 | =player.png=                  |
  # | HD+   |   1600x900 | =player@125.png=              |
  # | 1080p |  1920x1080 | =player@125.png=              |
  # | 1440p |  2560x1440 | =player@200.png=              |
  # | 1800p |  3200x1800 | =player@250.png=              |
  # | 4k    |  3200x2160 | =player@300.png=              |
  # | 5k    |  6400x2880 | =player@400.png=              |

  # Note: Review the sample app's game_metadata.txt file for what configurations are enabled.

  def tick args
    args.outputs.background_color = [0, 0, 0]
    args.outputs.borders << { x: 0, y: 0, w: 1280, h: 720, r: 255, g: 255, b: 255 }

    args.outputs.labels << { x: 30, y: 30.from_top, text: "render scale: #{args.grid.native_scale}", r: 255, g: 255, b: 255 }
    args.outputs.labels << { x: 30, y: 60.from_top, text: "render scale: #{args.grid.texture_scale_enum}", r: 255, g: 255, b: 255 }

    args.outputs.sprites << { x: -640 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x: -320 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }

    args.outputs.sprites << { x:    0 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x:  320 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x:  640 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x:  960 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x: 1280 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }

    args.outputs.sprites << { x: 1600 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x: 1920 - 50, y: 360 - 50, w: 100, h: 100, path: "sprites/square.png" }

    args.outputs.sprites << { x:  640 - 50, y:          720, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x:  640 - 50, y: 100.from_top, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x:  640 - 50, y:     360 - 50, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x:  640 - 50, y:            0, w: 100, h: 100, path: "sprites/square.png" }
    args.outputs.sprites << { x:  640 - 50, y:         -100, w: 100, h: 100, path: "sprites/square.png" }

    if args.inputs.keyboard.key_down.right_arrow
      GTK.set_window_scale 1, 9, 16
    elsif args.inputs.keyboard.key_down.left_arrow
      GTK.set_window_scale 1, 32, 9
    elsif args.inputs.keyboard.key_down.up_arrow
      GTK.toggle_window_fullscreen
    end
  end

```

### Allscreen Properties - main.rb
```ruby
  # ./samples/07_advanced_rendering_hd/03_allscreen_properties/app/main.rb
  def tick args
    label_style = { r: 255, g: 255, b: 255, size_enum: 4 }
    args.outputs.background_color = [0, 0, 0]
    args.outputs.borders << { x: 0, y: 0, w: 1280, h: 720, r: 255, g: 255, b: 255 }

    args.outputs.labels << { x: 10, y:  10.from_top, text: "texture_scale:       #{args.grid.texture_scale}", **label_style }
    args.outputs.labels << { x: 10, y:  40.from_top, text: "texture_scale_enum:  #{args.grid.texture_scale_enum}",  **label_style }
    args.outputs.labels << { x: 10, y:  70.from_top, text: "allscreen_offset_x:  #{args.grid.allscreen_offset_x}", **label_style }
    args.outputs.labels << { x: 10, y: 100.from_top, text: "allscreen_offset_y:  #{args.grid.allscreen_offset_y}", **label_style }

    if (Kernel.tick_count % 500) < 250
      args.outputs.labels << { x: 10, y: 130.from_top, text: "cropped to:          grid", **label_style }

      args.outputs.sprites << { x:        args.grid.left,
                                y:        args.grid.bottom,
                                w:        args.grid.w,
                                h:        args.grid.h,
                                # world.png has a 720p baseline size of 2000x2000 pixels
                                # we want to crop the center of the sprite
                                # wrt the bounds of the safe area.
                                source_x: 2000 - args.grid.w / 2,
                                source_y: 2000 - args.grid.h / 2,
                                source_w: 1280,
                                source_h: 720,
                                path: "sprites/world.png" } # world.png has a 720p baseline size of 2000x2000 pixels
    else
      args.outputs.labels << { x: 10, y: 130.from_top, text: "cropped to:          allscreen", **label_style }

      args.outputs.sprites << { x:        args.grid.allscreen_left,
                                y:        args.grid.allscreen_bottom,
                                w:        args.grid.allscreen_w,
                                h:        args.grid.allscreen_h,
                                # world.png has a 720p baseline size of 2000x2000 pixels
                                # we want to crop the center of the sprite to the bounds
                                # wrt to the bounds of the entire renderable area.
                                source_x: 2000 - args.grid.allscreen_w / 2,
                                source_y: 2000 - args.grid.allscreen_h / 2,
                                source_w: args.grid.allscreen_w,
                                source_h: args.grid.allscreen_h,
                                path:     "sprites/world.png" }
    end

    args.outputs.sprites << { x: 0, y: 0.from_top - 165, w: 410, h: 165, r: 0, g: 0, b: 0, a: 200, path: :pixel }

    if args.inputs.keyboard.key_down.right_arrow
      GTK.set_window_scale 1, 9, 16
    elsif args.inputs.keyboard.key_down.left_arrow
      GTK.set_window_scale 1, 32, 9
    elsif args.inputs.keyboard.key_down.up_arrow
      GTK.toggle_window_fullscreen
    end
  end

```

### Layouts And Portrait Mode - main.rb
```ruby
  # ./samples/07_advanced_rendering_hd/04_layouts_and_portrait_mode/app/main.rb
  def tick args
    args.outputs.solids << Layout.rect(row: 0, col: 0, w: 12, h: 24, include_row_gutter: true, include_col_gutter: true).merge(b: 255, a: 80)

    # rows (light blue)
    light_blue = { r: 128, g: 255, b: 255 }
    args.outputs.labels << Layout.rect(row: 1, col: 3).merge(text: "row examples", vertical_alignment_enum: 1, alignment_enum: 1)
    4.map_with_index do |row|
      args.outputs.solids << Layout.rect(row: row, col: 0, w: 1, h: 1).merge(**light_blue)
    end

    2.map_with_index do |row|
      args.outputs.solids << Layout.rect(row: row * 2, col: 1, w: 1, h: 2).merge(**light_blue)
    end

    4.map_with_index do |row|
      args.outputs.solids << Layout.rect(row: row, col: 2, w: 2, h: 1).merge(**light_blue)
    end

    2.map_with_index do |row|
      args.outputs.solids << Layout.rect(row: row * 2, col: 4, w: 2, h: 2).merge(**light_blue)
    end

    # columns (yellow)
    yellow = { r: 255, g: 255, b: 128 }
    args.outputs.labels << Layout.rect(row: 1, col: 9).merge(text: "column examples", vertical_alignment_enum: 1, alignment_enum: 1)
    6.times do |col|
      args.outputs.solids << Layout.rect(row: 0, col: 6 + col, w: 1, h: 1).merge(**yellow)
    end

    3.times do |col|
      args.outputs.solids << Layout.rect(row: 1, col: 6 + col * 2, w: 2, h: 1).merge(**yellow)
    end

    6.times do |col|
      args.outputs.solids << Layout.rect(row: 2, col: 6 + col, w: 1, h: 2).merge(**yellow)
    end

    # max width/height baseline (transparent green)
    green = { r: 0, g: 128, b: 80 }
    args.outputs.labels << Layout.rect(row: 4, col: 6).merge(text: "max width/height examples", vertical_alignment_enum: 1, alignment_enum: 1)
    args.outputs.solids << Layout.rect(row: 4, col: 0, w: 12, h: 2).merge(a: 64, **green)

    # max height
    args.outputs.solids << Layout.rect(row: 4, col: 0, w: 12, h: 2, max_height: 1).merge(a: 64, **green)

    # max width
    args.outputs.solids << Layout.rect(row: 4, col: 0, w: 12, h: 2, max_width: 6).merge(a: 64, **green)

    # labels relative to rects
    label_color = { r: 0, g: 0, b: 0 }
    white = { r: 232, g: 232, b: 232 }

    # labels realtive to point, achored at 0.0, 0.0
    args.outputs.labels << Layout.rect(row: 5.5, col: 6).merge(text: "labels using Layout.point anchored to 0.0, 0.0", vertical_alignment_enum: 1, alignment_enum: 1)
    grey = { r: 128, g: 128, b: 128 }
    args.outputs.solids << Layout.rect(row: 7, col: 4).merge(**grey)
    args.outputs.labels << Layout.point(row: 7, col: 4, row_anchor: 1.0, col_anchor: 0.0).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    args.outputs.solids << Layout.rect(row: 7, col: 5).merge(**grey)
    args.outputs.labels << Layout.point(row: 7, col: 5, row_anchor: 1.0, col_anchor: 0.5).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    args.outputs.solids << Layout.rect(row: 7, col: 6).merge(**grey)
    args.outputs.labels << Layout.point(row: 7, col: 6, row_anchor: 1.0, col_anchor: 1.0).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    args.outputs.solids << Layout.rect(row: 8, col: 4).merge(**grey)
    args.outputs.labels << Layout.point(row: 8, col: 4, row_anchor: 0.5, col_anchor: 0.0).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    args.outputs.solids << Layout.rect(row: 8, col: 5).merge(**grey)
    args.outputs.labels << Layout.point(row: 8, col: 5, row_anchor: 0.5, col_anchor: 0.5).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    args.outputs.solids << Layout.rect(row: 8, col: 6).merge(**grey)
    args.outputs.labels << Layout.point(row: 8, col: 6, row_anchor: 0.5, col_anchor: 1.0).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    args.outputs.solids << Layout.rect(row: 9, col: 4).merge(**grey)
    args.outputs.labels << Layout.point(row: 9, col: 4, row_anchor: 0.0, col_anchor: 0.0).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    args.outputs.solids << Layout.rect(row: 9, col: 5).merge(**grey)
    args.outputs.labels << Layout.point(row: 9, col: 5, row_anchor: 0.0, col_anchor: 0.5).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    args.outputs.solids << Layout.rect(row: 9, col: 6).merge(**grey)
    args.outputs.labels << Layout.point(row: 9, col: 6, row_anchor: 0.0, col_anchor: 1.0).merge(text: "[x]", alignment_enum: 1, vertical_alignment_enum: 1, **label_color)

    # centering rects
    args.outputs.labels << Layout.rect(row: 10.5, col: 6).merge(text: "layout.rect centered inside another layout.rect", vertical_alignment_enum: 1, alignment_enum: 1)
    outer_rect = Layout.rect(row: 12, col: 4, w: 3, h: 3)

    # render outer rect
    args.outputs.solids << outer_rect.merge(**light_blue)

    # center a yellow rect with w and h of two
    args.outputs.solids << Layout.rect_center(
      Layout.rect(w: 1, h: 5), # inner rect
      outer_rect, # outer rect
    ).merge(**yellow)

    # center a black rect with w three h of one
    args.outputs.solids << Layout.rect_center(
      Layout.rect(w: 5, h: 1), # inner rect
      outer_rect, # outer rect
    )

    args.outputs.labels << Layout.rect(row: 16.5, col: 6).merge(text: "layout.rect_group usage", vertical_alignment_enum: 1, alignment_enum: 1)

    horizontal_markers = [
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 }
    ]

    args.outputs.solids << Layout.rect_group(row: 18,
                                                  dcol: 1,
                                                  w: 1,
                                                  h: 1,
                                                  group: horizontal_markers)

    vertical_markers = [
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 },
      { r: 0, g: 0, b: 0 }
    ]

    args.outputs.solids << Layout.rect_group(row: 18,
                                                  drow: 1,
                                                  w: 1,
                                                  h: 1,
                                                  group: vertical_markers)

    colors = [
      { r:   0, g:   0, b:   0 },
      { r:  50, g:  50, b:  50 },
      { r: 100, g: 100, b: 100 },
      { r: 150, g: 150, b: 150 },
      { r: 200, g: 200, b: 200 },
    ]

    args.outputs.solids << Layout.rect_group(row: 19,
                                                  col: 1,
                                                  dcol: 2,
                                                  w: 2,
                                                  h: 1,
                                                  group: colors)

    args.outputs.solids << Layout.rect_group(row: 19,
                                                  col: 1,
                                                  drow: 1,
                                                  w: 2,
                                                  h: 1,
                                                  group: colors)
  end

  GTK.reset

```

### Camera Ultrawide Allscreen - main.rb
```ruby
  # ./samples/07_advanced_rendering_hd/05_camera_ultrawide_allscreen/app/main.rb
  class Game
    attr_gtk

    def tick
      if Kernel.tick_count == 0
        # set window to an ultra wide aspect ratio for the demonstration
        GTK.set_window_scale(1.0, 32, 9)
      end

      state.player ||= {
        x: -64,
        y: -64,
        w: 128,
        h: 128,
        path: :solid,
        r: 80,
        g: 128,
        b: 128
      }

      state.boxes ||= 1000.map do |i|
        {
          x: Numeric.rand(-3000..3000),
          y: Numeric.rand(-3000..3000),
          w: 64,
          h: 64,
          r: Numeric.rand(128..255),
          g: Numeric.rand(128..255),
          b: Numeric.rand(128..255),
          a: 128,
          path: :solid
        }
      end

      calc_camera

      render
    end

    def calc_camera
      if !state.camera
        state.camera = {
          x: 0,
          y: 0,
          target_x: 0,
          target_y: 0,
          target_scale: 1,
          scale: 1
        }
      end

      state.view_zoom ||= 1

      state.player.x += 10 * inputs.left_right
      state.player.y += 10 * inputs.up_down

      if inputs.keyboard.key_down.plus
        state.view_zoom *= 1.1
      elsif inputs.keyboard.key_down.minus
        state.view_zoom /= 1.1
      end

      state.camera.target_x = state.player.x + state.player.w / 2
      state.camera.target_y = state.player.y + state.player.h / 2
      state.camera.target_scale = state.view_zoom

      ease = 0.1
      state.camera.scale += (state.camera.target_scale - state.camera.scale) * ease
      state.camera.x += (state.camera.target_x - state.camera.x) * ease
      state.camera.y += (state.camera.target_y - state.camera.y) * ease
    end

    def render
      outputs.background_color = [0, 0, 0]

      outputs[:scene].w = Camera.viewport_w
      outputs[:scene].h = Camera.viewport_h
      outputs[:scene].background_color = [0, 0, 0]

      outputs[:scene].primitives << Camera.find_all_intersect_viewport(state.camera, state.boxes)
                                          .map do |b|
                                            Camera.to_screen_space(state.camera, b)
                                          end

      outputs[:scene].primitives << Camera.to_screen_space(state.camera, state.player)

      outputs.primitives << { **Camera.viewport, path: :scene }

      outputs.lines << { x: 640, y: 0, h: 720, r: 255, g: 255, b: 255 }
      outputs.lines << { x: 0, y: 360, w: 1280, r: 255, g: 255, b: 255 }

      outputs.labels << { x: 640,
                          y: 720 - 32,
                          text: "Note: All Screen rendering requires a Pro license (Standard license will be letter boxed)",
                          anchor_x: 0.5,
                          anchor_y: 0.5,
                          size_px: 32,
                          r: 255,
                          g: 255,
                          b: 255 }

      outputs.labels << { x: 640,
                          y: 32,
                          text: "Arrow keys to move camera, +/- to zoom in/out",
                          anchor_x: 0.5,
                          anchor_y: 0.5,
                          size_px: 32,
                          r: 255,
                          g: 255,
                          b: 255 }

      outputs.watch "Mouse Screen Space: #{inputs.mouse.rect}"
      outputs.watch "Mouse World Space: #{Camera.to_world_space state.camera, inputs.mouse.rect}"
    end
  end

  class Camera
    class << self
      def viewport_w
        Grid.allscreen_w
      end

      def viewport_h
        Grid.allscreen_h
      end

      def viewport_w_half
        if Grid.origin_center?
          0
        else
          Grid.allscreen_w.fdiv(2).ceil
        end
      end

      def viewport_h_half
        if Grid.origin_center?
          0
        else
          Grid.allscreen_h.fdiv(2).ceil
        end
      end

      def viewport_offset_x
        if Grid.origin_center?
          0
        else
          Grid.allscreen_x
        end
      end

      def viewport_offset_y
        if Grid.origin_center?
          0
        else
          Grid.allscreen_y
        end
      end

      def __to_world_space__ camera, rect
        return nil if !rect

        x = (rect.x - viewport_w_half + camera.x * camera.scale - viewport_offset_x) / camera.scale
        y = (rect.y - viewport_h_half + camera.y * camera.scale - viewport_offset_y) / camera.scale

        if rect.w
          w = rect.w / camera.scale
          h = rect.h / camera.scale
          { **rect, x: x, y: y, w: w, h: h }
        else
          { **rect, x: x, y: y }
        end
      end

      def to_world_space camera, rect
        if rect.is_a? Array
          rect.map { |r| to_world_space camera, rect }
        else
          __to_world_space__ camera, rect
        end
      end

      def __to_screen_space__ camera, rect
        return nil if !rect

        x = rect.x * camera.scale - camera.x * camera.scale + viewport_w_half
        y = rect.y * camera.scale - camera.y * camera.scale + viewport_h_half

        if rect.w
          w = rect.w * camera.scale
          h = rect.h * camera.scale
          { **rect, x: x, y: y, w: w, h: h }
        else
          { **rect, x: x, y: y }
        end
      end

      def to_screen_space camera, rect
        if rect.is_a? Array
          rect.map { |r| to_screen_space camera, r }
        else
          __to_screen_space__ camera, rect
        end
      end

      def viewport
        if Grid.origin_center?
          {
            x: viewport_offset_x,
            y: viewport_offset_y,
            w: viewport_w,
            h: viewport_h,
            anchor_x: 0.5,
            anchor_y: 0.5
          }
        else
          {
            x: viewport_offset_x,
            y: viewport_offset_y,
            w: viewport_w,
            h: viewport_h,
          }
        end
      end

      def viewport_world camera
        to_world_space camera, viewport
      end

      def find_all_intersect_viewport camera, os
        Geometry.find_all_intersect_rect viewport_world(camera), os
      end
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  GTK.reset

```
