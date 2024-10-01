require 'rubygems'
require 'mp3info'
require 'gosu'

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)

WIDTH = 8000
HEIGHT = 5000
SCROLL_SPEED = 30

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

module Genre
  POP, CLASSIC, JAZZ, ROCK = *1..4
end

GENRE_NAMES = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']

class UI 
  attr_accessor :stop, :play, :next

  def initialize()
    @stop = Gosu::Image.new("assets/stop.png", false)
    @play = Gosu::Image.new("assets/play.png", false)
    @next = Gosu::Image.new("assets/next.png", false)
  end
end

class Track
  attr_accessor :title, :location, :song, :x, :y

  def initialize(title, location)
    @title = title
    @location = location
    @x = x
    @y = y
    @song = Gosu::Song.new(location.strip)
  end
end

class Album
  attr_accessor :title, :artist, :artwork, :genre, :tracks, :year, :x, :y

  def initialize(title, artist, artwork_file, genre, tracks, year)
    @title = title
    @artist = artist
    @artwork = Gosu::Image.new(artwork_file.strip)
    @genre = genre
    @tracks = tracks
    @year = year
  end
end

class MusicPlayerMain < Gosu::Window
  def initialize
    super WIDTH, HEIGHT
    self.caption = "Music Player"

    @title = Gosu::Font.new(40)
    @track_font = Gosu::Font.new(180)
    @playing_track_font = Gosu::Font.new(380)
    @current_playing_track = nil
		@album = nil
    @albums = load_albums()

    @ui = UI.new()

    @width_scale = 3240.to_f / 1920
    @height_scale = 1980.to_f / 1080
    @desired_width = 850 * @width_scale
    @desired_height = 850 * @height_scale

    # Sort Options UI
    @sort_font = Gosu::Font.new(300)
    @current_sort_option


    @scroll_y = 0
    @max_scroll = @albums.size * (@desired_height + 50) - HEIGHT
    @scrollbar_height = HEIGHT * (HEIGHT.to_f / (@albums.size * (@desired_height + 50)))

    @current_color_index = 0    
    @color_change_delay = 0    
       
    @start_time = 0
    @total_duration = 0 


  end

  def load_albums
    file = File.new('albums.txt', 'r')
    albums = []
    album_count = file.gets.to_i
    album_count.times do
      tracks = []
      album_artist = file.gets
      album_title = file.gets
      album_year_recorded = file.gets.to_i
      album_artwork = file.gets
      album_genre = GENRE_NAMES[file.gets.to_i]
      count = file.gets.to_i
      count.times do |i|
        name = file.gets
        location = file.gets.chomp
        track = Track.new(name, location)
        track.x = WIDTH - 1700
        track.y = 30 + i * 600
        tracks << track
      end
      album = Album.new(album_title, album_artist, album_artwork, album_genre, tracks, album_year_recorded)
      albums << album
    end
    file.close()
    return albums
  end

  def draw
    draw_background
    draw_ui
    draw_albums
    draw_scrollbar
		draw_track(@album) if @album
    draw_duration_bar if @current_playing_track
  end
  

	def area_clicked(leftX, topY, rightX, bottomY)
		return mouse_x >= leftX && mouse_x <= rightX && mouse_y >= topY && mouse_y <= bottomY
	end


  def draw_background
    draw_quad(0, 0, TOP_COLOR, width, 0, TOP_COLOR, 0, height, BOTTOM_COLOR, width, height, BOTTOM_COLOR, ZOrder::BACKGROUND)
  end

  def draw_ui
    ui_width = 500  # Change to your desired width
    ui_height = 500  # Change to your desired height
    ui_y_position = HEIGHT - ui_height - 50  # Move UI to the bottom
    # Calculate scale factors based on the desired dimensions
    stop_scale_x = ui_width.to_f / @ui.stop.width
    stop_scale_y = ui_height.to_f / @ui.stop.height

    play_scale_x = ui_width.to_f / @ui.play.width
    play_scale_y = ui_height.to_f / @ui.play.height

    next_scale_x = ui_width.to_f / @ui.next.width
    next_scale_y = ui_height.to_f / @ui.next.height

    # Draw buttons with scaling
    @ui.stop.draw(50, ui_y_position, ZOrder::UI, stop_scale_x, stop_scale_y)
    @ui.play.draw(250 + ui_width + 20, ui_y_position, ZOrder::UI, play_scale_x, play_scale_y)  # Adjust spacing between buttons
    @ui.next.draw(450 + (ui_width + 20) * 2, ui_y_position, ZOrder::UI, next_scale_x, next_scale_y)

    #Draw sort buttons
    @sort_font.draw_text("Sort By:", 50, 300, ZOrder::UI, 0.7, 0.7, Gosu::Color::WHITE)
    @sort_font.draw_text("|", 700, 230, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    @sort_font.draw_text("Title", 1000, 250, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    @sort_font.draw_text("|", 1700, 230, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    @sort_font.draw_text("Genre", 1900, 250, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    @sort_font.draw_text("|", 2700, 230, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    @sort_font.draw_text("Date", 2900, 250, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)


  end

  def draw_albums
		space_between_albums = 200
		adjust_album_width = 0
    x = -(@desired_width +space_between_albums) + 300
		y = 600
    row_spacing = 700
		@albums.each_with_index do |album, index|
			x += @desired_width + space_between_albums
			if x + @desired_width > WIDTH - 1800
				x = 300
        y += @desired_height + row_spacing
			end

			original_width = album.artwork.width
			original_height = album.artwork.height
			artwork_width_scale = @desired_width.to_f / original_width
			artwork_height_scale = @desired_height.to_f / original_height
			album.x = x
			album.y = y-@scroll_y

			if album.y.between?(-@desired_width-200, HEIGHT)
        truncated_title = truncate_text(album.title.strip,18)
        @title.draw_text(truncated_title, album.x+50, album.y + @desired_width+200, ZOrder::PLAYER, 3.0 * @width_scale, 3.0 * @height_scale, Gosu::Color::BLACK)
        album.artwork.draw(album.x, album.y, ZOrder::PLAYER, artwork_width_scale, artwork_height_scale)
      end
		end
  end

  def draw_track(album)
    colors = [
      Gosu::Color::GRAY,
      Gosu::Color::WHITE,
      Gosu::Color::AQUA,
      Gosu::Color::RED,
      Gosu::Color::GREEN,
      Gosu::Color::BLUE,
      Gosu::Color::YELLOW,
      Gosu::Color::FUCHSIA,
      Gosu::Color::CYAN,
      Gosu::Color.rgba(255, 165, 0, 255),  # Deep Orange
      Gosu::Color.rgba(128, 0, 128, 255),  # Indigo
      Gosu::Color.rgba(0, 255, 127, 255),  # Spring Green
      Gosu::Color.rgba(255, 20, 147, 255), # Deep Pink
      Gosu::Color.rgba(75, 0, 130, 255),   # Indigo
      Gosu::Color.rgba(255, 105, 180, 255) # Hot Pink
    ]
    current_color = colors[@current_color_index]
    
    for i in 0..album.tracks.length-1
      album.tracks[i].x = WIDTH - 1700
      album.tracks[i].y = 30 + i * 600
      
      if album.tracks[i].song.playing? 
        @current_playing_track = album.tracks[i].title
        @track_font.draw_text(album.tracks[i].title, album.tracks[i].x, album.tracks[i].y, ZOrder::PLAYER, 1.0, 1.0, current_color)
      else
        @track_font.draw_text(album.tracks[i].title, album.tracks[i].x, album.tracks[i].y, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
      end
    end

    if @current_playing_track
      @playing_track_font.draw_text("Playing: #{@current_playing_track}", 1000, 100, ZOrder::PLAYER, 1.0, 1.0, current_color)
    end 

    # Update the color every 20 frames
    if @color_change_delay > 20
      @current_color_index = (@current_color_index + 1) % colors.length
      @color_change_delay = 0   # Reset the delay counter
    else
      @color_change_delay += 1  # Increment the delay counter
    end
  end

  def draw_duration_bar
    return unless @current_playing_track && @total_duration > 0
    
    elapsed_time = Gosu.milliseconds - @start_time
    progress = [elapsed_time / @total_duration.to_f, 1.0].min  # Ensure the value doesn't exceed 1.0

    bar_width = WIDTH - 1900  # Width of the bar
    bar_height = 50  # Height of the bar
    bar_x = 50  # Left padding
    bar_y = HEIGHT - 200  # Above the UI buttons

    # Draw the progress bar background
    Gosu.draw_rect(bar_x, bar_y, bar_width, bar_height, Gosu::Color::GRAY, ZOrder::UI)

    # Draw the filled part based on progress
    filled_width = bar_width * progress
    Gosu.draw_rect(bar_x, bar_y, filled_width, bar_height, Gosu::Color::GREEN, ZOrder::UI)

    # # Display the elapsed time and total duration (formatted as mm:ss)
    # elapsed_time_text = format_time(elapsed_time)
    # total_duration_text = format_time(@total_duration)

    # @title.draw_text("#{elapsed_time_text} / #{total_duration_text}", bar_x + bar_width + 30, bar_y + 5, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
  end
  
  def draw_scrollbar
    scrollbar_y = (@scroll_y.to_f / @max_scroll) * (HEIGHT - @scrollbar_height)
    Gosu.draw_rect(WIDTH - 1900, scrollbar_y, 100, @scrollbar_height, Gosu::Color::GRAY, ZOrder::UI)
  end

  def truncate_text(text, max_width)
    if text.length > max_width
      while text.length+3 > max_width
        text = text.chop
      end
      text += "..."
    end
    return text
  end
  # Formats time in milliseconds to "mm:ss"
  def format_time(milliseconds)
    total_seconds = milliseconds / 1000
    minutes = total_seconds / 60
    seconds = total_seconds % 60
    format("%02d:%02d", minutes, seconds)
  end
  def play_track(track)
    track.song.play(false)
    @start_time = Gosu.milliseconds
    @total_duration = Mp3Info.open(track.location).length.to_i * 1000
  end
	
  def sort(choice)
    
    if @current_sort_option == choice
      @albums.reverse!
    else
      case choice
      when "Genre"
        @albums.sort_by! { |album| GENRE_NAMES.index(album.genre) }
      when "Names"
        @albums.sort_by! { |album| album.title }
      when "Year Recorded"
        @albums.sort_by! { |album| album.year }
      end
    end
    @current_sort_option = choice
  end

  def button_down(id)
    sort_choice = ""
    case id
    when Gosu::MsWheelDown
      @scroll_y = [@scroll_y + SCROLL_SPEED * 5, @max_scroll].min
    when Gosu::MsWheelUp
      @scroll_y = [@scroll_y - SCROLL_SPEED * 5, 0].max
    when Gosu::MsLeft

      # Check if the sort buttons are clicked
      if area_clicked(1000, 250, 1000+@sort_font.text_width("Names"), 250+@sort_font.height)  # Title sort button bounds
        sort_choice = "Names"
        sort(sort_choice)
        puts "Sorting by Title"
      elsif area_clicked(1900, 250, 1900+@sort_font.text_width("Genre"), 250+@sort_font.height)  # Genre sort button bounds
        sort_choice = "Genre"
        sort("Genre")
        puts "Sorting by Genre"
      elsif area_clicked(2900, 250, 2900+@sort_font.text_width("Year"), 250+@sort_font.height)  # Date sort button bounds
        sort_choice = "Year"
        sort("Year")
        puts "Sorting by Year"
      end

      # Check if an album was clicked
      @albums.each do |album|
        if area_clicked(album.x, album.y, album.x + @desired_width, album.y + @desired_height)
          puts "Album clicked: #{album.title.strip}"
          @album = album
        end
      end
  
      if @album 
        @album.tracks.each_with_index do |track, index|
          if area_clicked(track.x, track.y, track.x+@track_font.text_width(track.title), track.y+@track_font.height)
            puts "Track clicked: #{track.title.strip}"
            play_track(track)
            # Further action can be implemented here, such as playing the track
          end
        end
      end
    end
  end
end

MusicPlayerMain.new.show if __FILE__ == $0
