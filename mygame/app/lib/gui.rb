
$zoom = 1.0
$pan_x = 0.0
$pan_y = 0.0
$zoom_speed = 0.0
$max_zoom = 3.0
$min_zoom = 0.2

class GUI

  def self.handle_input args

    # zooming with mouse wheel
    zoom_acceleration = 0.2
    if args.inputs.mouse.wheel
      zoom_input = args.inputs.mouse.wheel.y
      if zoom_input > 0
        $zoom_speed += zoom_acceleration
      elsif zoom_input < 0
        $zoom_speed -= zoom_acceleration
      end
    end
    $zoom_speed *= 0.8 # deceleration
    if $zoom_speed.abs < 0.1
      $zoom_speed = 0
    end
    zoom_delta = $zoom_speed
    requested_zoom = $zoom + zoom_delta
    $zoom = requested_zoom.clamp($min_zoom, $max_zoom)

    # panning with touch/mouse drag
    if args.inputs.mouse.buffered_held && args.inputs.mouse.moved
        delta_x = args.inputs.mouse.previous_x - args.inputs.mouse.x
        delta_y = args.inputs.mouse.previous_y - args.inputs.mouse.y
        $pan_x -= delta_x
        $pan_y -= delta_y
    end
  end

  def self.draw_tiles args
    Tile.draw_tiles args
  end



  def self.draw_hud args

  end

  def self.draw_background args
    args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, path: :solid, r: 0, g: 0, b: 0, a: 255 }
  end

  
end