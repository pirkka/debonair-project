### Fifteen Puzzle - main.rb
```ruby
  # ./samples/99_genre_board_game/01_fifteen_puzzle/app/main.rb
  class Game
    attr_gtk

    def initialize
      # rng is sent to Random so that everyone gets the same levels
      @rng = Random.new 100

      @solved_board = (1..16).to_a

      # rendering size of the cell
      @cell_size = 128

      # compute left and right margins based on cell size
      @left_margin = (Grid.w - 4 * @cell_size) / 2
      @bottom_margin = (Grid.h - 4 * @cell_size) / 2

      # how long notifications should be displayed
      @notification_duration = 110

      # frame that the player won
      @completed_at = nil

      # number of times the player won
      @win_count = 0

      # spline that represents fade in and fade out of notifications
      @notification_spline = [
        [  0, 0.25, 0.75, 1.0],
        [1.0, 1.0,  1.0,  1.0],
        [1.0, 0.75, 0.25,   0]
      ]

      # current moves the player has taken on level
      @current_move_count = 0

      # move history so that undos decreases the move count
      @move_history = []

      # create a new shuffed board
      new_suffled_board!
    end

    def tick
      calc
      render
    end

    def new_suffled_board!
      # set the board to a new board
      @board = new_board

      # while the board is in a solved state
      while solved_board?
        # difficulty increases with the number of wins
        # find the empty cell (the cell with the value 16) and swap it with a random neighbor
        # do this X times (win_count + 1 * 5) to make sure the board is scrambled
        @shuffle_count = ((@win_count + 1) * 2).clamp(7, 100).to_i

        # neighbor to exclude to better shuffle the board
        exclude_neighor = nil
        @shuffle_count.times do
          # get candidate neighbors based off of neighbors of the empty cell
          # exclude the neighbor that is the mirror of the last selected neighbor
          shuffle_candidates = empty_cell_neighbors.reject do |neighbor|
            neighbor.relative_location == exclude_neighor&.mirror_location ||
            neighbor.mirror_location == exclude_neighor&.relative_location
          end

          # select a random neighbor based off of the candidate size and RNG
          selected_neighbor = shuffle_candidates[@rng.rand(shuffle_candidates.length)]

          # if the number of candidates is greater than 2, then update the exclude neighbor
          exclude_neighor = if shuffle_candidates.length >= 2
                              selected_neighbor
                            else
                              nil
                            end

          # shuffle the board by swapping the empty cell with the selected candidate
          swap_with_empty selected_neighbor.cell, empty_cell
        end
      end

      # after shuffling, reset the current move count
      @max_move_count = (@shuffle_count * 1.1).to_i

      # capture the current board state so that the player can try again (game over)
      @try_again_board = @board.copy
      @started_at = Kernel.tick_count

      # reset the completed_at time
      @completed_at = nil

      # clear the move history
      @move_history.clear
    end

    def new_board
      # create a board with cells of the
      # following format:
      # {
      #   value: 1,
      #   loc: { row: 0, col: 0 },
      #   previous_loc: { row: 0, col: 0 },
      #   clicked_at: 0
      # }
      16.map_with_index do |i|
        { value: i + 1 }
      end.sort_by do |cell|
        cell.value
      end.map_with_index do |cell, index|
        row = 3 - index.idiv(4)
        col = index % 4
        cell.merge loc: { row: row, col: col },
                   previous_loc: { row: row, col: col },
                   clicked_at: -100
      end
    end

    def render
      # render the current level and current move count (and max move count)
      outputs.labels << { x: 640, y: 720 - 64, anchor_x: 0.5, anchor_y: 0.5, text: "Level: #{@win_count + 1}", size_px: 64 }
      outputs.labels << { x: 640, y: 64, anchor_x: 0.5, anchor_y: 0.5, text: "Moves: #{@current_move_count} (#{@max_move_count})", size_px: 64 }

      # render each cell
      outputs.sprites << @board.map do |cell|
        # render the board centered in the middle of the screen
        prefab = cell_prefab cell
        prefab.merge x: @left_margin + prefab.x, y: @bottom_margin + prefab.y
      end

      # if the game has just started, display the notification of how many moves the player has to complete the level
      if @started_at && @started_at.elapsed_time < @notification_duration
        alpha_percentage = Easing.spline @started_at,
                                         Kernel.tick_count,
                                         @notification_duration,
                                         @notification_spline

        outputs.primitives << notification_prefab( "Complete in #{@max_move_count} or less.", alpha_percentage)
      end

      # if the game is completed, display the notification based on whether the player won or lost
      if @completed_at && @completed_at.elapsed_time < @notification_duration
        alpha_percentage = Easing.spline @completed_at,
                                         Kernel.tick_count,
                                         @notification_duration,
                                         @notification_spline

        message = if @current_move_count <= @max_move_count
                    "You won!"
                  else
                    "Try again!"
                  end

        outputs.primitives << notification_prefab(message, alpha_percentage)
      end
    end

    # notification prefab that displays a message in the center of the screen
    def notification_prefab text, alpha_percentage
      [
        {
          x: 0,
          y: grid.h.half - @cell_size / 2,
          w: grid.w,
          h: @cell_size,
          path: :pixel,
          r: 0,
          g: 0,
          b: 0,
          a: 255 * alpha_percentage,
        },
        {
          x: grid.w.half,
          y: grid.h.half,
          text: text,
          a: 255 * alpha_percentage,
          anchor_x: 0.5,
          anchor_y: 0.5,
          size_px: 80,
          r: 255,
          g: 255,
          b: 255
        }
      ]
    end

    def calc
      # set the completed_at time if the board is solved
      @completed_at ||= Kernel.tick_count if solved_board?

      # if the game is completed, then reset the board to either a new shuffled board or the try again board
      if @completed_at && @completed_at.elapsed_time > @notification_duration
        @completed_at = nil

        # if the player has not exceeded the max move count, then reset the board to a new shuffled board
        if @current_move_count <= @max_move_count
          new_suffled_board!
          @win_count ||= 0
          @win_count += 1
          @current_move_count = 0
        else
          # otherwise reset the board to the try again board
          @board = @try_again_board.copy
          @current_move_count = 0
        end
      end

      # don't process any input if the game is completed
      return if @completed_at

      # select the cell based on mouse, keyboard, or controller input
      selected_cell = if inputs.mouse.click
                        @board.find do |cell|
                          mouse_rect = {
                            x: inputs.mouse.x - @left_margin,
                            y: inputs.mouse.y - @bottom_margin,
                            w: 1,
                            h: 1,
                          }
                          mouse_rect.intersect_rect? render_rect(cell.loc)
                        end
                      elsif inputs.key_down.left || inputs.controller_one.key_down.x
                        empty_cell_neighbors.find { |n| n.relative_location == :left }&.cell
                      elsif inputs.key_down.right || inputs.controller_one.key_down.b
                        empty_cell_neighbors.find { |n| n.relative_location == :right }&.cell
                      elsif inputs.key_down.up || inputs.controller_one.key_down.y
                        empty_cell_neighbors.find { |n| n.relative_location == :above }&.cell
                      elsif inputs.key_down.down || inputs.controller_one.key_down.a
                        empty_cell_neighbors.find { |n| n.relative_location == :below }&.cell
                      end

      # if no cell is selected, then return
      return if !selected_cell

      # find the clicked cell's neighbors
      clicked_cell_neighbors = neighbors selected_cell

      # return if the cell's neighbors doesn't include the empty cell
      return if !clicked_cell_neighbors.map { |c| c.cell }.include?(empty_cell)

      # set when the cell was clicked so that animation can be performed
      selected_cell.clicked_at = Kernel.tick_count

      # capture the before and after swap locations so that undo can be performed
      before_swap = empty_cell.loc.copy
      swap_with_empty selected_cell, empty_cell
      after_swap = empty_cell.loc.copy
      @move_history.push_front({ before: before_swap, after: after_swap })

      frt_history = @move_history[0]
      snd_history = @move_history[1]

      # check if the last move was a reverse of the previous move, if so then decrease the move count
      if frt_history && snd_history && frt_history.after == snd_history.before && frt_history.before == snd_history.after
        @move_history.pop_front
        @move_history.pop_front
        @current_move_count -= 1
      else
        # otherwise increase the move count
        @current_move_count += 1
      end
    end

    def solved_board?
      # sort the board by the cell's location and map the values (which will be 1 to 16)
      sorted_values = @board.sort_by { |cell| (cell.loc.col + 1) + (16 - (cell.loc.row * 4)) }
                            .map { |cell| cell.value }

      # check if the sorted values are equal to the expected values (1 to 16)
      sorted_values == @solved_board
    end

    def swap_with_empty cell, empty
      # take not of the cell's current location (within previous_loc)
      cell.previous_loc = cell.loc

      # swap the cell's location with the empty cell's location and vice versa
      cell.loc, empty.loc = empty.loc, cell.loc
    end

    def cell_prefab cell
      # determine the percentage for the lerp that should be performed
      percentage = if cell.clicked_at
                     Easing.smooth_stop start_at: cell.clicked_at, duration: 15, tick_count: Kernel.tick_count, power: 5, flip: true
                   else
                     1
                   end

      # determine the cell's current render location
      cell_rect = render_rect cell.loc

      # determine the cell's previous render location
      previous_rect = render_rect cell.previous_loc

      # compute the difference between the current and previous render locations
      x = cell_rect.x + (previous_rect.x - cell_rect.x) * percentage
      y = cell_rect.y + (previous_rect.y - cell_rect.y) * percentage

      # return the cell prefab
      { x: x,
        y: y,
        w: @cell_size,
        h: @cell_size,
        path: "sprites/pieces/#{cell.value}.png" }
    end

    # helper method to determine the render location of a cell in local space
    # which excludes the margins
    def render_rect loc
      {
        x: loc.col * @cell_size,
        y: loc.row * @cell_size,
        w: @cell_size,
        h: @cell_size,
      }
    end

    # helper methods to determine neighbors of a cell
    def neighbors cell
      [
        { mirror_location: :below, relative_location: :above, cell: above_cell(cell) },
        { mirror_location: :above, relative_location: :below, cell: below_cell(cell) },
        { mirror_location: :right, relative_location:  :left, cell: left_cell(cell)  },
        { mirror_location: :left,  relative_location: :right, cell: right_cell(cell) },
      ].reject { |neighbor| !neighbor.cell }
    end

    def empty_cell
      @board.find { |cell| cell.value == 16 }
    end

    def empty_cell_neighbors
      neighbors empty_cell
    end

    def below_cell cell
      find_cell cell, -1, 0
    end

    def above_cell cell
      find_cell cell, 1, 0
    end

    def left_cell cell
      find_cell cell, 0, -1
    end

    def right_cell cell
      find_cell cell, 0, 1
    end

    def find_cell cell, d_row, d_col
      @board.find do |other_cell|
        cell.loc.row == other_cell.loc.row + d_row &&
        cell.loc.col == other_cell.loc.col + d_col
      end
    end
  end

  def boot args
    args.state ||= {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
    args.state = {}
  end

  # GTK.reset

```

### Sudoku - main.rb
```ruby
  # ./samples/99_genre_board_game/02_sudoku/app/main.rb
  class Sudoku
    def initialize
      @square_lookup = {}
      @candidates_cache = {}
      9.each do |row|
        @square_lookup[row] ||= {}
        9.each do |col|
          @square_lookup[row][col] = { row: row, col: col, value: nil }
        end
      end
      @move_history = []
      @one_to_nine = (1..9).to_a
    end

    def undo!
      return if @move_history.empty?
      last_move = @move_history.pop_back
      set_value(row: last_move.row, col: last_move.col, value: last_move.value, record_history: false)
    end

    def empty_squares
      @square_lookup.keys
                    .flat_map { |k| @square_lookup[k].values }
                    .sort_by  { |s| [s.row, s.col] }
                    .find_all { |s| !s.value }
                    .map      { |s| { row: s.row, col: s.col } }
    end

    def get_value(row:, col:)
      @square_lookup[row][col].value
    end

    def set_value(row:, col:, value:, record_history: true)
      @move_history << { row: row, col: col, value: @square_lookup[row][col].value } if record_history
      @square_lookup[row][col].value = value
      @candidates_cache = {}
    end

    def __candidates_uncached__(row:, col:)
      used_values = relations(row: row, col: col).map { |s| s[:value] }
                                                 .compact
                                                 .uniq
      @one_to_nine - used_values
    end

    def candidates(row:, col:)
      return @candidates_cache[row][col] if @candidates_cache.dig(row, col)
      @candidates_cache[row] ||= {}
      @candidates_cache[row][col] ||= __candidates_uncached__(row: row, col: col)
      candidates(row: row, col: col)
    end

    def square_lookup
      @square_lookup.keys
                    .flat_map { |k| @square_lookup[k].values }
                    .sort_by  { |s| [s.row, s.col] }
    end

    def single_candidates
      singles = []
      squares.map { |s| Hash[row: s.row,
                             col: s.col,
                             candidates: candidates(row: s.row, col: s.col)] }
             .find_all { |s| s.candidates.length == 1 }
             .map { |s| { row: s.row, col: s.col, value: s.candidates.first } }
    end

    def relations(row:, col:)
      related = []

      9.each do |c|
        related << { **@square_lookup[row][c] } if c != col
      end

      9.each do |r|
        related << { **@square_lookup[r][col] } if r != row
      end

      box_start_row = (row.idiv 3) * 3
      box_start_col = (col.idiv 3) * 3
      3.each do |r_offset|
        3.each do |c_offset|
          r = box_start_row + r_offset
          c = box_start_col + c_offset
          related << { **@square_lookup[r][c] } if r != row && c != col
        end
      end

      related.uniq
    end
  end

  class Game
    attr_gtk

    attr :sudoku

    PARTITION_BG_COLOR = { r: 96, g: 156, b: 156 }
    PARTITION_OUTER_BG_COLOR = { r: 232, g: 232, b: 232 }
    BACKGROUND_COLOR = [30, 30, 30]
    SELECTED_RECT_COLOR = { r: 255, a: 128 }
    HOVERED_RECT_COLOR = { r: 255, g: 255, b: 255, a: 128 }
    CANDIDATE_COLOR = { r: 0, g: 0, b: 0 }
    NON_CANDIDATE_COLOR = { r: 200, g: 200, b: 200 }
    EMPTY_SQUARE_COLOR = { r: 128, g: 32, b: 32 }
    FILLED_SQUARE_COLOR = { r: 32, g: 64, b: 32 }
    SINGLE_CANDIDATE_DOT_COLOR = { r: 96, g: 255, b: 255 }
    MULTIPLE_CANDIDATE_DOT_COLOR = { r: 96, g: 128, b: 128 }
    LABEL_COLOR = { r: 255, g: 255, b: 255 }

    def initialize
      @sudoku = Sudoku.new
      @board = {}
      board_rects.each do |rect|
        @board[rect.row] ||= {}
        @board[rect.row][rect.col] = rect
      end

      @partition_bgs = 3.flat_map do |row|
        3.map do |col|
          Layout.rect(row: row * 3 + 1.5, col: col * 3 + 7.5, w: 3, h: 3)
                .merge(path: :solid, **PARTITION_BG_COLOR)
        end
      end

      @partition_outer_bgs = 3.flat_map do |row|
        3.map do |col|
          Layout.rect(row: row * 3 + 1.5, col: col * 3 + 7.5, w: 3, h: 3, include_row_gutter: true, include_col_gutter: true)
                .merge(path: :solid, **PARTITION_OUTER_BG_COLOR)
        end
      end

      @number_selection_rects = {
        rects: 10.map do |col|
          n = if col == 9
                nil
              else
                col + 1
              end
          Layout.rect(row: 0, col: 7 + col, w: 1, h: 1)
                .merge(number: n)
        end
      }
    end

    def tick
      @hovered_rect = find_square(inputs.mouse.x, inputs.mouse.y)

      input_click_square
      input_click_number

      outputs.background_color = BACKGROUND_COLOR
      outputs.primitives << board_prefab

      outputs.primitives << number_selection_prefab
      outputs.primitives << @selected_rect&.merge(path: :solid, **SELECTED_RECT_COLOR)
      outputs.primitives << @hovered_rect&.merge(path: :solid, **HOVERED_RECT_COLOR)
    end

    def input_click_square
      return if !@hovered_rect
      return if !inputs.mouse.click

      @selected_rect = @hovered_rect
      @select_number_shown_at = Kernel.tick_count
      @select_number_shown = true
    end

    def input_click_number
      return if !@select_number_shown

      if inputs.mouse.click || inputs.keyboard.key_down.char
        selected_number = if inputs.keyboard.key_down.char
                            n = inputs.keyboard.key_down.char.to_i
                            if n == 0
                              { number: nil}
                            else
                              { number: n }
                            end
                          else
                            @number_selection_rects.rects.find do |r|
                              Geometry.inside_rect?({ x: inputs.mouse.x, y: inputs.mouse.y, w: 1, h: 1 }, r)
                            end
                          end

        if selected_number
          @sudoku.set_value(row: @selected_rect.row, col: @selected_rect.col, value: selected_number.number)
          @selected_rect = nil
          @select_number_shown = false
          @select_number_shown_at = nil
        end
      end
    end

    def number_selection_prefab
      return nil if !@select_number_shown

      candidates = @sudoku.candidates(row: @selected_rect.row, col: @selected_rect.col)

      outputs.primitives << @number_selection_rects.rects.map do |r|
        color = if candidates.include?(r.number)
                  CANDIDATE_COLOR
                else
                  NON_CANDIDATE_COLOR
                end
        [
          r.merge(path: :solid),
          r.center.merge(text: r.number, anchor_x: 0.5, anchor_y: 0.5, **color)
        ]
      end
    end

    def board_rects
      9.flat_map do |row|
        9.map do |col|
          Layout.rect(row: row + 1.5, col: col + 7.5, w: 1, h: 1)
                .merge(row: row, col: col)
        end
      end
    end

    def square_mark_prefabs rect
      one_third_w = rect.w.fdiv 3
      one_third_h = rect.h.fdiv 3
      {
        1 => { x: rect.x + one_third_w * 0.5, y: rect.y + one_third_h * 2.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        2 => { x: rect.x + one_third_w * 1.5, y: rect.y + one_third_h * 2.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        3 => { x: rect.x + one_third_w * 2.5, y: rect.y + one_third_h * 2.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        4 => { x: rect.x + one_third_w * 0.5, y: rect.y + one_third_h * 1.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        5 => { x: rect.x + one_third_w * 1.5, y: rect.y + one_third_h * 1.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        6 => { x: rect.x + one_third_w * 2.5, y: rect.y + one_third_h * 1.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        7 => { x: rect.x + one_third_w * 0.5, y: rect.y + one_third_h * 0.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        8 => { x: rect.x + one_third_w * 1.5, y: rect.y + one_third_h * 0.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        9 => { x: rect.x + one_third_w * 2.5, y: rect.y + one_third_h * 0.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 }
      }
    end

    def find_square(mouse_x, mouse_y)
      mouse_rect = { x: mouse_x, y: mouse_y, w: 1, h: 1 }
      @board.each do |row, cols|
        cols.each do |col, rect|
          if Geometry.inside_rect?(mouse_rect, rect)
            return rect.merge(row: row, col: col)
          end
        end
      end

      nil
    end

    def square_prefabs
      @board.keys.flat_map do |row|
        @board[row].keys.map do |col|
          square_prefab(row: row, col: col)
        end
      end
    end

    def board_prefab
      @partition_outer_bgs + @partition_bgs + square_prefabs
    end

    def square_prefab(row:, col:)
      rect = @board[row][col]
      value = @sudoku.get_value(row: row, col: col)
      candidates = @sudoku.candidates(row: row, col: col)

      bg_color = if !value && candidates.empty?
                   EMPTY_SQUARE_COLOR
                 else
                   FILLED_SQUARE_COLOR
                 end

      label = if value
                {
                  x: rect.center.x,
                  y: rect.center.y,
                  text: value,
                  anchor_x: 0.5,
                  anchor_y: 0.5,
                  **LABEL_COLOR
                }
              else
                nil
              end

      dot_color = if candidates.length == 1
                    SINGLE_CANDIDATE_DOT_COLOR
                  else
                    MULTIPLE_CANDIDATE_DOT_COLOR
                  end

      dots = if value
               []
             else
               square_mark_prefabs(rect).find_all { |n, r| candidates.include?(n) }
                                        .map { |n, r| r.merge(path: :solid, **dot_color) }
             end

      [
        rect.merge(path: :solid, **bg_color),
        label,
        dots
      ]
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

### Sudoku - Tests - sudoku_tests.rb
```ruby
  # ./samples/99_genre_board_game/02_sudoku/tests/sudoku_tests.rb
  class SudokuTests
    def test_single_candidates(args, assert)
      s = Sudoku.new
      s.set_value(row: 0, col: 0, value: 1)
      s.set_value(row: 0, col: 1, value: 2)
      s.set_value(row: 0, col: 2, value: 3)
      s.set_value(row: 1, col: 0, value: 4)
      s.set_value(row: 1, col: 1, value: 5)
      s.set_value(row: 1, col: 2, value: 6)
      s.set_value(row: 2, col: 0, value: 7)
      s.set_value(row: 2, col: 1, value: 8)
      assert.equal! s.single_candidates.first, { row: 2, col: 2, value: 9 }
      assert.equal! s.single_candidates.length, 1
    end
  end

```
