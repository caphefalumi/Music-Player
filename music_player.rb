require 'rubygems'
require 'gosu'

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)

WIDTH = 7300
HEIGHT = 4000

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

module Genre
  POP, CLASSIC, JAZZ, ROCK = *1..4
end

GENRE_NAMES = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']



class Track
	attr_accessor :title, :location
	def initialize (title, location)
		@title = title
		@location = location
	end
end

class Album
  attr_accessor :title, :artist, :artwork, :genre, :tracks, :x, :y, :page

  def initialize(title, artist, artwork_file, genre, tracks)
    @title = title
    @artist = artist
    @artwork = Gosu::Image.new(artwork_file.strip) # Load the artwork image
    @genre = genre
    @tracks = tracks
  end
end


# Put your record definitions here

class MusicPlayerMain < Gosu::Window

	def initialize
	    super WIDTH, HEIGHT
	    self.caption = "Music Player"
			@title = Gosu::Font.new(40) # Initialize the font
			@albums = load_albums()

			@width_scale = 3240.to_f / 1920
      @height_scale = 1980.to_f / 1080
      @desired_width = 650 * @width_scale  # Set the desired width for all album artworks
      @desired_height = 650 * @height_scale # Set the desired height for all album artworks

			
			@albums_cached_image = nil  # Cache for the pre-drawn album images
			@current_track_title = nil
			@draw_ui = nil
			draw_albums_once           # Call method to draw albums only once
	end


  # Put in your code here to load albums and tracks
	def load_albums()
		file = File.new('albums.txt','r')
		albums = Array.new()
		album_count = file.gets.to_i
		for _ in 0..album_count-1
			tracks = Array.new()
			album_artist = file.gets
			album_title = file.gets
			album_artwork = file.gets
			album_genre = GENRE_NAMES[file.gets.to_i]
			count = file.gets.to_i
			for __ in 0..count-1
				name = file.gets
				location = file.gets
				track = Track.new(name, location)	
				tracks << track
			end
			album = Album.new(album_title, album_artist, album_artwork, album_genre, tracks)
			albums << album
		end
		file.close()
		return albums
	end

	def print_albums()
		puts "------------ALL ALBUMS------------"
		i = 0
		while i < @albums.length
			puts "#{i+1}. Title: #{albums[i].title} Artist: #{albums[i].artist} Genre: #{albums[i].genre} \n Artwork: #{albums[i].artwork}"
			i+=1
		end
	end
	def draw_albums_once
    # Create an off-screen image of the entire window size
    @albums_cached_image = Gosu.render(WIDTH, HEIGHT) do
			space_between_albums = 200
			y = 600
      @albums.each_with_index do |album, index|
        x = 100 + (index * (@desired_width + space_between_albums))  # Space out the albums horizontally
        escape_line = false
        if x + @desired_width > WIDTH-1900
          x = 100
          escape_line = true
				end
        if escape_line
          y = 2300 + (index % 2) * (@desired_height + 50)  # Space out the albums vertically
          escape_line = false
        end

        # Get the current width and height of the artwork
        original_width = album.artwork.width
        original_height = album.artwork.height

        # Calculate scaling factors
        artwork_width_scale = @desired_width.to_f / original_width
        artwork_height_scale = @desired_height.to_f / original_height

        # Store the album coordinates
        album.x = x
        album.y = y
				album.page = 1
				puts "Title #{album.title} X: #{album.x} Y: #{album.y} #{@desired_width}"
        # Draw album title and artwork
        @title.draw_text(album.title, x + 200, y + 650 * @height_scale, ZOrder::PLAYER, 3.0 * @width_scale, 3.0 * @height_scale, Gosu::Color::BLACK)
        album.artwork.draw(album.x+200, album.y, ZOrder::PLAYER, artwork_width_scale, artwork_height_scale)
      end
  	end
	end
	def draw_ui
		@title.draw_text("Music Player", 500, 100, ZOrder::UI, 10.0, 10.0, Gosu::Color::BLACK)
		@title.draw_text("Albums", 3000, 100, ZOrder::UI, 10.0, 10.0, Gosu::Color::BLACK)
	end


  # Draws the artwork on the screen for all the albums
	def draw_albums
    @albums_cached_image.draw(0, 0, ZOrder::PLAYER) if @albums_cached_image
		@draw_ui.draw(0,0,ZOrder:UI) if @draw_ui
	end
	

  # Detects if a 'mouse sensitive' area has been clicked on
  # i.e either an album or a track. returns true or false

  def area_clicked(leftX, topY, rightX, bottomY)
		return mouse_x >= leftX && mouse_x <= rightX && mouse_y >= topY && mouse_y <= bottomY
  end


  # Takes a String title and an Integer ypos
  # You may want to use the following:
  def display_track(title)
		@current_track_title = title  # Store the title for later rendering in draw
  end


  # Takes a track index and an Album and plays the Track from the Album

  def playTrack(track, album)
  	 # complete the missing code
  			@song = Gosu::Song.new(album.tracks[track].location)
  			@song.play(false)
    # Uncomment the following and indent correctly:
  	#	end
  	# end
  end

# Draw a coloured background using TOP_COLOR and BOTTOM_COLOR

	def draw_background
		draw_quad(0, 0, TOP_COLOR,   # Top-left corner
		width, 0,TOP_COLOR,  # Top-right corner
		0, height, BOTTOM_COLOR,  # Bottom-left corner
		width, height, BOTTOM_COLOR,  # Bottom-right corner
		ZOrder::BACKGROUND)
	end

 # Draws the album images and the track list for the selected album

	def draw()
		# Complete the missing code
		draw_background()
		draw_albums()
		draw_ui()
		if @current_track_title
			@title.draw_text(@current_track_title, 7000, 1000, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		end
		
	end
	def button_down(id)
		case id
		when Gosu::MsLeft
			@albums.each do |album|
				if area_clicked(album.x, album.y, album.x + @desired_width, album.y + @desired_height)

					puts "Album clicked: #{album.title.strip}"
					# Further action can be implemented here, such as:
					display_tracklist(album)
					# play_track(album)
				end
			end
		end
	end

	def display_tracklist(album)
		album.tracks.each do |track|
			display_track(track.title)
		end
	end

	def needs_cursor?; true; end



end

# Show is a method that loops through update and draw

MusicPlayerMain.new.show if __FILE__ == $0