require 'rubygems'
require 'gosu'

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)

WIDTH = 7300
HEIGHT = 4000
SCROLL_SPEED = 30

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

module Genre
  POP, CLASSIC, JAZZ, ROCK = *1..4
end

GENRE_NAMES = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']

class UI 
  attr_accessor :stop, :play, :pause, :previous, :next
  def initialize(window)
    @stop = Gosu::Image.new(window, "assets/stop.png", false)
    @play = Gosu::Image.new(window, "assets/play.png", false)
    @pause = Gosu::Image.new(window, "assets/pause.png", false)
    @previous = Gosu::Image.new(window, "assets/previous.png", false)
    @next = Gosu::Image.new(window, "assets/next.png", false)
  end
end

class Track
  attr_accessor :title, :location, :x, :y, :width, :height
  def initialize(title, location)
    @title = title
    @location = location
  end
end

class Album
  attr_accessor :title, :artist, :artwork, :genre, :tracks, :x, :y, :page

  def initialize(title, artist, artwork_file, genre, tracks)
    @title = title
    @artist = artist
    @artwork = Gosu::Image.new(artwork_file.strip)
    @genre = genre
    @tracks = tracks
  end
end

class MusicPlayerMain < Gosu::Window
  def initialize
    super WIDTH, HEIGHT
    self.caption = "Music Player"

    @title = Gosu::Font.new(40)
		@album = nil
    @albums = load_albums()

    @width_scale = 3240.to_f / 1920
    @height_scale = 1980.to_f / 1080
    @desired_width = 650 * @width_scale
    @desired_height = 650 * @height_scale

    @scroll_y = 0
    @max_scroll = @albums.size * (@desired_height + 50) - HEIGHT
    @scrollbar_height = HEIGHT * (HEIGHT.to_f / (@albums.size * (@desired_height + 50)))

    @albums_cached_image = nil
    @current_track_title = nil
  end

  def load_albums
    file = File.new('albums.txt', 'r')
    albums = []
    album_count = file.gets.to_i
    album_count.times do
      tracks = []
      album_artist = file.gets
      album_title = file.gets
      album_artwork = file.gets
      album_genre = GENRE_NAMES[file.gets.to_i]
      count = file.gets.to_i
      count.times do
        name = file.gets
        location = file.gets
        track = Track.new(name, location)
        tracks << track
      end
      album = Album.new(album_title, album_artist, album_artwork, album_genre, tracks)
      albums << album
    end
    file.close
    albums
  end

  def draw
    draw_background
    draw_albums
    draw_scrollbar
		draw_track(@album) if @album
  end

	def area_clicked(leftX, topY, rightX, bottomY)
		return mouse_x >= leftX && mouse_x <= rightX && mouse_y >= topY && mouse_y <= bottomY
	end


  def draw_background
    draw_quad(0, 0, TOP_COLOR, width, 0, TOP_COLOR, 0, height, BOTTOM_COLOR, width, height, BOTTOM_COLOR, ZOrder::BACKGROUND)
  end

  def draw_albums
		space_between_albums = 200
		adjust_album_width = 0
		y = 600
		@albums.each_with_index do |album, index|
			adjust_album_width = @albums[index-1].title.length if @albums[index-1].title
			x = 300+ (index * (@desired_width + space_between_albums)) + adjust_album_width
			escape_line = false
			if x + @desired_width > WIDTH - 1900
				x = 300
				escape_line = true
			end
			if escape_line
				y = 2300 + (index % 2) * (@desired_height + 50)
				escape_line = false
			end

			original_width = album.artwork.width
			original_height = album.artwork.height
			artwork_width_scale = @desired_width.to_f / original_width
			artwork_height_scale = @desired_height.to_f / original_height

			album.x = x + adjust_album_width
			album.y = y-@scroll_y
			album.page = 1

			if album.y.between?(-@desired_width-200, HEIGHT)
        @title.draw_text(album.title, album.x, album.y + 650 * @height_scale, ZOrder::PLAYER, 3.0 * @width_scale, 3.0 * @height_scale, Gosu::Color::BLACK)
        album.artwork.draw(album.x, album.y, ZOrder::PLAYER, artwork_width_scale, artwork_height_scale)
      end
		end
  end

	def draw_track(album)
		for i in 0..album.tracks.length-1
      album.tracks[i].x = WIDTH -1600
      album.tracks[i].y = 30+i*600
			@title.draw_text(album.tracks[i].title, album.tracks[i].x, album.tracks[i].y, ZOrder::PLAYER, 3.0 * @width_scale, 3.0 * @height_scale, Gosu::Color::BLACK)
		end
	end
	
  def draw_scrollbar
    scrollbar_y = (@scroll_y.to_f / @max_scroll) * (HEIGHT - @scrollbar_height)
    Gosu.draw_rect(WIDTH - 1900, scrollbar_y, 100, @scrollbar_height, Gosu::Color::GRAY, ZOrder::UI)
  end

  def button_down(id)
    case id
    when Gosu::MsWheelDown
      @scroll_y = [@scroll_y + SCROLL_SPEED * 5, @max_scroll].min
    when Gosu::MsWheelUp
      @scroll_y = [@scroll_y - SCROLL_SPEED * 5, 0].max
		when Gosu::MsLeft
      puts "X: #{mouse_x}, Y: #{mouse_y}"
			@albums.each do |album|
				if area_clicked(album.x, album.y, album.x + @desired_width, album.y + @desired_height)
					puts "Album clicked: #{album.title.strip}"
					# Further action can be implemented here, such as:
					@album = album
					# play_track(album)
				end
			end
      if @album && @title
        @album.tracks.each_with_index do |track, index|
          if area_clicked(track.x,track.y, track.x+@title.text_width(track.title)+300, 3000)
            puts "Track clicked: #{track.title}"
            # Further action can be implemented here, such as:
          end
        end
      end
    end
  end
end

MusicPlayerMain.new.show if __FILE__ == $0
