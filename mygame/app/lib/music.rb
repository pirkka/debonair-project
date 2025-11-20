class Music

  attr_reader :bpm, :pattern_count, :beat_count, :bar_count
  attr_reader :start_time
  attr_reader :pattern_length
  attr_reader :scale

  def self.setup(args)
    args.state.music = Music.new
    args.state.music.start
  end

  def initialize
    printf "Initializing music system...\n"
    @samples = {}
    scan_samples
    @bpm = 80
    @pattern_length = 8 # bars
  end

  def start
    printf "Starting music system...\n"
    now = Time.now
    @start_time = now
    @beat_count = nil 
    @bar_count = nil
    @pattern_count = nil
    @music_volume = 0.0
    @scale = Music.scales.keys.sample
    alter_pattern!
  end

  def alter_pattern!
    @pattern ||= {}
    @pattern[:notes] ||= {}
    printf "Altering music pattern...\n"
    # fx track
    if Numeric.rand(0.0..1.0) < 0.2
      @pattern[:fx] = nil
      (0...@pattern_length * 4).each do |beat|
        if beat % 4 == 0
          @pattern[:fx] ||= []
          @pattern[:fx] << @samples[:fx].sample if @samples[:fx] && !@samples[:fx].empty?
        else
          @pattern[:fx] ||= []
          @pattern[:fx] << nil
        end
      end
    end
    # strings track
    if Numeric.rand(0.0..1.0) < 0.1
      kind = :strings
      @pattern[kind] = nil
      string_sample = @samples[kind].sample
      counter = 1
      (0...@pattern_length * 4).each do |beat|
        counter += 1
        if beat % 8 == 0
          @pattern[kind] ||= []
          @pattern[kind] << string_sample if string_sample
          @pattern[:notes][kind] ||= []
          @pattern[:notes][kind] << [0,3,7].sample
        elsif beat % 8 == 4
          @pattern[kind] ||= []
          @pattern[kind] << string_sample if string_sample
          @pattern[:notes][kind] << [0,3,7].sample
        else
          @pattern[kind] ||= []
          @pattern[kind] << nil
          @pattern[:notes][kind] << nil
        end
      end
    end
    # drumtrax
    if Numeric.rand(0.0..1.0) < 0.2
      @pattern[:kick] = nil
      @pattern[:snare] = nil
      @pattern[:hihat] = nil
      (0...@pattern_length * 4).each do |beat|
        kick_sample = @samples[:kick].sample
        snare_sample = @samples[:snare].sample
        hihat_sample = @samples[:hihat].sample
        @pattern[:hihat] ||= []
        @pattern[:hihat] << hihat_sample if hihat_sample
        if beat % 4 == 2
          @pattern[:snare] ||= []
          @pattern[:snare] << snare_sample if snare_sample
        else
          @pattern[:snare] ||= []
          @pattern[:snare] << nil
        end
        if beat % 4 == 0
          @pattern[:kick] ||= []
          @pattern[:kick] << kick_sample if kick_sample
        else
          @pattern[:kick] ||= []
          @pattern[:kick] << nil
        end
      end
    end
    # pad
    if Numeric.rand(0.0..1.0) < 0.5
      @pattern[:pad] = nil
      # pad on every 8th beat
      the_sample = @samples[:pad].sample
      (0...@pattern_length * 4).each do |beat|
        if beat % 8 == 0
          @pattern[:pad] ||= []
          @pattern[:pad] << the_sample if @samples[:pad] && !@samples[:pad].empty?
          @pattern[:notes][:pad] ||= []
          relative_note = [0,3,7].sample
          note = Music.scales[@scale].take(relative_note + 1).sum
          @pattern[:notes][:pad] << note
        elsif beat % 8 == 4
          @pattern[:pad] ||= []
          @pattern[:pad] << the_sample if @samples[:pad] && !@samples[:pad].empty?
          @pattern[:notes][:pad] ||= []
          relative_note = [0,3,7].sample
          note = Music.scales[@scale].take(relative_note + 1).sum
          @pattern[:notes][:pad] << note
        else
          @pattern[:pad] ||= []
          @pattern[:pad] << nil
          @pattern[:notes][:pad] ||= []
          @pattern[:notes][:pad] << nil
        end
      end
    end
    if Numeric.rand(0.0..1.0) < 0.3
      # perc can be pretty random lol
      @pattern[:perc] = nil
      primary_sample = @samples[:perc].sample
      secondary_sample = @samples[:perc].sample
      interval = [1,2,3,4,6].sample
      (0...@pattern_length * 4).each do |beat|
        the_sample = Numeric.rand(0.0..1.0) < 0.7 ? primary_sample : secondary_sample
        if beat % interval == 0
          @pattern[:perc] ||= []
          @pattern[:perc] << the_sample if @samples[:perc] && !@samples[:perc].empty?
        else
          @pattern[:perc] ||= []
          @pattern[:perc] << nil
        end
      end
    end
    printf "New pattern is ready.\n"
    @pattern.each do |kind, beats|
      if kind == :notes
        next
      end
      printf kind.to_s.ljust(16) + ": "
      beats.each_with_index do |beat, index|
        if beat
          printf "x"
        else
          printf "-"
        end
      end
      if kind != :notes && beats.length != @pattern_length * 4
        raise "Pattern length mismatch for kind #{kind}! expted #{@pattern_length * 4} but got #{beats.length}"
      end
      printf "\n"
    end
  end

  def calc_beat
    (elapsed_time * 60 / @bpm).floor % (@pattern_length * 4)
  end

  def calc_bars
    (calc_beat / 4).floor % @pattern_length
  end

  def calc_pattern
    (elapsed_time * 60 / @bpm / 4 / @pattern_length).floor
  end

  def elapsed_time
    Time.now - @start_time
  end

  def self.tick(args)
    args.state.music.tick(args) if args.state.music
  end

  def elapsed_time
    Time.now - @start_time
  end

  def self.scales
    {
      melodic_minor: [0,2,1,2,2,2,2,1],
      harmonic_minor: [0,2,1,2,2,1,3,1],
      natural_minor: [0,2,1,2,2,1,2,2],
      major: [0,2,2,1,2,2,2,1]

    }
  end

  def tick(args)
    old_bar_count = @bar_count
    new_bar_count = self.calc_bars
    if old_bar_count != new_bar_count
      @bar_count = new_bar_count
    end
    #printf "Music tick... elapsed time = #{self.elapsed_time} # pattern time: #{elapsed_pattern_time} old beat #{old_beat} / new beat #{new_beat}\n"
    old_pattern_count = @pattern_count
    new_pattern_count = self.calc_pattern
    if old_pattern_count != new_pattern_count  
      @pattern_count = new_pattern_count
      alter_pattern!
    end
    old_beat_count = @beat_count
    new_beat_count = self.calc_beat
    if old_beat_count != new_beat_count
      @beat_count = new_beat_count
      printf "Pattern: #{@pattern_count} Bar: #{@bar_count} Beat: #{@beat_count}\n"
      play_beat(args)
    end
  end

  def play_beat(args)
      # play pattern sounds for this beat from all banks
      if @pattern
        @pattern.each do |kind, beats|
          if beats && beats[@beat_count]
            # do we have a note(pitch) info also?
            if @pattern[:notes] && @pattern[:notes][kind] && @pattern[:notes][kind][@beat_count]
              pitch = @pattern[:notes][kind][@beat_count]
              numeric_pitch = (pitch - 1.0)/12.0 + 1.0
              printf "Playing sample: %s with semitone pitch %s - numeric pitch: %s\n" % [kind.to_s, pitch.to_s, numeric_pitch.to_s]
            end
            sample_file = beats[@beat_count]
            #printf "Playing sample: %s\n" % sample_file
            sample_path = "sounds/music/#{kind}/" + sample_file
            args.outputs.audio[kind] = {
              input: sample_path,
              gain: @music_volume || 0.5,
              pitch: numeric_pitch || 1.0
            }
          end
        end
      end
  end

  def scan_samples
    printf "Scanning music samples...\n"
    # iterate through directory structure and find music samples
    # Dir.glob not working
    @samples = {}
    path = "sounds/music/"
    $gtk.list_files(path).each do |subdirectory|
      next if subdirectory == ".DS_Store"
      kind = subdirectory.split("/").last.to_sym
      @samples[kind.to_sym] = []
      # Check if it's a directory by trying to list its contents
      subdir_path = path + subdirectory + "/"
      sub_files = $gtk.list_files(subdir_path) rescue nil
      next unless sub_files
      if sub_files
        # It's a directory, recurse into it
        $gtk.list_files(subdir_path).each do |file|
          next if file == ".DS_Store"
          if file.end_with?(".mp3")
            @samples[kind.to_sym] << file
          end
        end
      end
    end
    @samples.each do |kind, files|
      printf "Samples for kind %s: %s\n" % [kind, files.size.to_s]
    end
  end
end

