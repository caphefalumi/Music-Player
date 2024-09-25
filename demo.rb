require 'gosu'

class MusicPlayerWindow < Gosu::Window
  def initialize
    super 640, 480
    self.caption = "Gosu Music Player"
    
    # Load the song (change the path to your song file)
    @song = Gosu::Song.new("sounds/01-Cracklin-rose.mp3")
  end

  def update
    # Play the song when the window opens
    @song.play(true) unless @song.playing?
  end

  def draw
    # You can customize the visuals here (e.g., display text or images)
    Gosu::Font.new(32).draw_text("Playing Song...", 180, 220, 1, 1.0, 1.0, Gosu::Color::WHITE)
  end
end

window = MusicPlayerWindow.new
window.show
