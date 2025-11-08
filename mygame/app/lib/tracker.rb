class Instrument
  attr_accessor :name, :type

  def initialize(name, type)
    @name = name  # e.g., "piano", "synth", "drumkit", "wasteflute", "pirkka-bass", etc.
    @type = type  # e.g., :sampler, :drum_machine 
  end

  def play_note(note, duration)
    # logic to play a note with this instrument
  end

  def stop_note()
    # logic to stop playing a note, even if it has been set to sustain
  end
end

class Pattern
  
  attr_accessor :notes

  def initialize
    @notes = []          # sequence of notes for this track, every element is a bar of 16th notes
    1..8.each do |bar|
      @notes[bar] = []  # initialize each bar as an empty array
      1..16.each do |sixteenth_note|
        @notes[bar][sixteenth_note] = nil  # initialize each 16th note as nil (no note played)
      end
    end
  end

  def add_note(bar, sixteenth_note, note, duration)
    @notes[bar][sixteenth_note] = { note: note, duration: duration } # eg. { note: :C4, duration: 0.25 } 
  end

  def remove_note(bar, sixteenth_note)
    @notes[bar][sixteenth_note] = nil
  end
end

class Track
  attr_accessor :type, :instrument, :pattern

  def initialize(type, instrument)
    @type = type          # e.g., :drums, :bass, :melody
    @instrument = instrument  # e.g., "piano", "synth", "drumkit", "wasteflute", "pirkka-bass", etc.
    @pattern = Pattern.new
  end
end


class Tracker
  # multi-track music player, playing multiple instruments simultaneously
  attr_accessor :bpm  
  @bpm = 90

  # has these types of tracks always, some might be silent
  # :drums, :bass, :melody, :adlib, :harmony, :effects, :percussion
  # 
  # drums - basic rhythm track
  # bass - low frequency bass line
  # melody - main tune
  # adlib - improvisational elements, doubling melody or counter-melody
  # harmony - supporting chords and harmonies
  # effects - sound effects integrated into the music
  # percussion - additional rhythmic elements like shakers, tambourines
  #
  # each track can have it's own note sequences
  # note sequences are procedural
  # level and player actions influence the note sequences and instruments used
  # length of every sequence is 8 bars
  # key changes happen based on game events
  # time signature is 4/4
  # instruments can be changed dynamically based on game state

  def initialize
    @tracks = []
  end

  def add_track(track)
    @tracks << track
  end

  def remove_track(track)
    @tracks.delete(track)
  end

  def play
    # logic to play all tracks
  end

  def pause
    # logic to pause all tracks
  end

  def stop
    # logic to stop all tracks
  end
end

end