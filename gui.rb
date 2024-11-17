#####################
  # Global Setting #
#####################
require "gosu"
#cosole colouring
require "colorize"
#XML file reading
require "nokogiri"
#Wave file reading
require "waveinfo"



WIDTH = 1920 / 2
HEIGHT = 1080 / 2

BACK,MIDDLE,TOP,PLAYBAR,BUTTONS = *0..4
ELEMENT,FONT,IMAGE = *0..2

#Colour 
PRIMARY = Gosu::Color.argb(255, 26, 26, 26)
SECONDARY = Gosu::Color.argb(255, 33, 33, 33)
TIERTARY = Gosu::Color.argb(255, 85, 85, 85)
HIGHLIGHT = Gosu::Color.argb(255, 106, 121, 255)
TEXT = Gosu::Color.argb(255, 132, 132, 132)
WHITE_TEXT = Gosu::Color.argb(255, 255, 255, 255)
IMAGE_COLOR = Gosu::Color.argb(255, 255, 255, 255)
OVERLAY = Gosu::Color.argb(50, 255, 255, 255)
SONGS = Gosu::Color.argb(100, 26, 26, 26)
PROGRESS_BAR = Gosu::Color.argb(255, 106 - 25, 121 - 25, 255 - 25)

###############
  # Classes #
###############
class Element
  attr_accessor :x, :y, :width, :height, :colour, :z, :name
  def initialize(x, y, width, height, colour, z, name)
      @name = name
      @x = x
      @y = y
      @width = width
      @height = height
      @colour = colour
      @z = z
  end
end

class Image
  attr_accessor :x, :y, :width, :height, :colour, :z, :name, :path
  def initialize(x, y, width, height, colour, z, name, path)
      @name = name
      @x = x
      @y = y
      @width = width
      @height = height
      @colour = colour
      @z = z
      @path = path
  end
end

class Font
  attr_accessor :x, :y, :z, :size, :colour, :name, :text
  def initialize(x, y, z, size, colour, name, text)
      @size = size
      @name = name
      @x = x
      @y = y
      @z = z
      @colour = colour
      @text = text
  end
end

class Particle
  attr_accessor :x, :y, :size, :direction_x, :direction_y, :r, :g, :b, :t
  def initialize(x,y,size,direction_x,direction_y,r,g,b,t)
      @x = x
      @y = y
      @size = size
      @direction_x = direction_x
      @direction_y = direction_y
      @r = r
      @g = g
      @b = b
      @t = t
  end
end

class Song
	attr_accessor :name, :location
	def initialize (name, location)
		@name = name
		@location = location
	end
end

class Album
	attr_accessor :title, :artist, :genre, :songs, :cover
	def initialize (title, artist, genre, songs, cover)
		@title = title
		@artist = artist
		@genre = genre
        @songs = songs
        @cover = cover
	end
end


##############
  # Events #
##############
#Replaces element colour while mouse over
def hover_event(element)
 element.colour = OVERLAY
end

def click_event(element)
#Check if element name starts with the included string
  if element.name["album_button"]
    #Split up element name and grabs the ending integer
    album_ID = element.name.split("_")[2].to_i
    #Sets current clicked on album to button integer
    @selected_album = album_ID.to_i
  end

  if element.name["song_button"]
    song_ID = element.name.split("_")[2].to_i
    play_song(song_ID)
  end

  if element.name["scroll_button"]
    scroll_ID = element.name.split("_")[2].to_i
    case scroll_ID
    when 0 #up
        @page -= 1
    when 1 #down
        @page += 1
    end
  end

  if element.name["play_button"]
    play_ID = element.name.split("_")[2].to_i
    case play_ID
    when 0 # Repeat
        @repeat_song ? @repeat_song = false : @repeat_song = true
        puts "Repeat = " + @repeat_song.to_s.blue
    when 1 # Forward
        play_song(@currently_playing + 1)
    when 2 # Pause
        particle_burst(20,2,3)
        if @pause_play == "pause"
            @pause_play = "play"
            @song_settings.pause
        else
            @pause_play = "pause"
            @song_settings.resume
        end
    when 3 # Backward
        play_song(@currently_playing - 1)
    when 4 # Stop
        stop_song()
    end
  end
end

#################
  # functions #
#################
#truncate function takes a string and max character and cuts it to set size then adds ... to end of string
def truncate(string, max)
  return string.size > max ? "#{string[0...max]}..." : string
end

#load in an image safely so that the program doesn't crash
def load_image(path)
  begin
      return Gosu::Image.new(path)
    rescue
      return Gosu::Image.new("images/error.png") rescue nil
  end
end

#takes in an images set size and converts it into a 1.0 scale value
def img_size(image_size, new_size)
  decrease = new_size.fdiv(image_size)
  return decrease
end

#clears console
def clear_console()
  puts "\e[H\e[2J"
end

#sorts all inputed or added elements into array
def add_element(type,*args)
  #sorts elements by type
  case type
  when ELEMENT
    #(type, x, y, width, height, colour, z, name)
    @elements << Element.new(*args)
  when IMAGE
    #(type, x, y, width, height, colour, z, name, file_path)
    @elements << Image.new(*args)
  when FONT
    #(type, x, y, z, size, colour, name, text)
    @elements << Font.new(*args)
  end
end

#Sort element into classtype and draws out elements
def draw_elements()
  for element in @elements do
      case element.class.name
      when "Element"
        draw_rect(element.x,element.y,element.width,element.height,element.colour,element.z)
      when "Image"
      #safely load image from path
        img = load_image(element.path)
      #Uses img_size to conver size to 1.0 size scaling
        img.draw_rot(element.x,element.y,10,0,0,0,img_size(img.width,element.width),img_size(img.height,element.height),element.colour)
      when "Font"
        @info_font.draw_text_rel(element.text,element.x,element.y,element.z,0,0,element.size,element.size,element.colour)
      end
  end
end

#outputs the element that the mouse's x and y are currently over
def iterate_element()
  for element in @elements do
    #Check if button type
      if element.class.name != "Font" && element.name.include?("button") # Checks if it's a button type
        if mouse_x.between?(element.x,element.x + element.width) and mouse_y.between?(element.y,element.y + element.height)
            return element
        end
      end
  end
  #fall back
  return nil
end

#Reads in file and adds dato into classes and the outputs and array with all included class data
def read_album(data)
  #Assigns XML file path arrays to appropriate variables and if fails then assign emty array
	album_names = data.xpath("//album/name") rescue album_names = []
	album_artist = data.xpath("//album/artist") rescue album_artist = []
  album_genre = data.xpath("//album/genre") rescue album_genre = []
  album_cover = data.xpath("//album/cover") rescue album_cover = []

  #Temp function array for returning
	album_array = Array.new
  i = 0
  while i < album_names.size	
    #Iterates through albums in xml file
		album_songs = data.xpath("//album[#{i+1}]/songs/song/name")
		album_songs_dir = data.xpath("//album[#{i+1}]/songs/song/location")
		song = 0
    song_array = Array.new
    #Iterates through all albums songs and stroes an array of song classes within the album classes songs attribute
		while song < album_songs.size
			song_array << Song.new(album_songs[song].text,album_songs_dir[song].text)
			song += 1
		end
		album_array << Album.new(album_names[i].text,album_artist[i].text,album_genre[i].text,song_array,album_cover[i])
		i += 1
	end
	return album_array
end

#Playing songs bases off of an inputed index
def play_song(id)
  #Resets pause button
  @pause_play = "pause"
  #Makes sure no other song is playing
  @song_settings.stop rescue nil
  begin
    path = @data_array[@selected_album].songs[id.to_i].location
    #Grab info from wav
    wave = WaveInfo.new(path)
    #Broadcasts song duration
    @song_length = wave.duration
    #reset tick so that @count_up starts at 0
    @tick = Gosu.milliseconds
    #Broadcasts currently playing song
    @currently_playing = id
    @playing_album_name = @data_array[@selected_album].title.upcase
    @playing_song_name = @data_array[@selected_album].songs[id].name.upcase
    @playing_thumbnail = @data_array[@selected_album].cover
    #Sample plays wav file from path
    song = Gosu::Sample.new(path) # Sample plays wav file from path
    @song_settings = song.play(100,1,false)
    @show_playbar = true
  rescue
    @show_player = false
    stop_song()
    puts "SONG WAS NOT FOUND".red
  end
end

#events surrounding the stopping of the currently playing song
def stop_song()
  @song_settings.stop rescue nil
  @show_playbar = false
end

#Use nokogiri xml builder to crease structured xml based of all the songs within each album
def create_all_songs()
  File.open("all_songs.xml", "w+") 
  builder = Nokogiri::XML::Builder.new do |xml| xml.root {
    for album in @data_array do
      for song in album.songs do
            xml.song {
              xml.name song.name
              xml.location song.location
              xml.genre album.genre
              xml.artist album.artist
            }
        end
      end
  }
  end
  File.write("all_songs.xml", builder.to_xml)
end

#Drawing out individual particle stored within the @particles instance array and adding motion to the particle
def draw_particles()
  for particle in @particles do
    colour_fade = Gosu::Color.argb(particle.t -= 5, particle.r, particle.g, particle.b)
    draw_rect(particle.x += particle.direction_x,particle.y += particle.direction_y,particle.size,particle.size,colour_fade,10)

  #Removes particle from array, prevent being redrawn after transparency below 0, improving performance and indefinite particle array growth
    if particle.t <= 0
      @particles.delete(particle)
    end
  end
end

#Contains initialization data for each particle and controls the amout, size and speed
def particle_burst(amount, size, speed)
  r = 255
  g = 255
  b = 255

  #Removes 0 from set of possible speeds to prevent particles from having no motion
  rand_x = [*-speed..speed] - [0]
  rand_y = [*-speed..speed] - [0]
  DEBUG ? (puts "#{rand_x} : #{rand_y}") : nil
  amount.times do
    @particles << Particle.new(mouse_x,mouse_y,size,rand_x.sample,rand_y.sample,r,g,b,255)
  end
end

############
  # Gosu #
############
class Window < Gosu::Window

  def initialize
    super WIDTH, HEIGHT

    #Class Arrays
    @elements = Array.new
    @album_array = Array.new
    @particles = Array.new

    #Loads in files and enables reading and writing?
    File.file?("player_data.xml") ? file = File.open("player_data.xml", "r+") : file = File.open("player_data.xml", "w+") 
    @data = Nokogiri::XML(file)

    #Initialization variables
    @progress = 0
    @pause_play = "pause"
    @info_font = Gosu::Font.new(20)
    #Read in data
    @data_array = read_album(@data)
    @selected_album = 0
    @repeat_song = false
    @show_playbar = false
    @song_length = nil
    @currently_playing = nil
    @playing_album_name = nil
    @playing_song_name = nil
    @playing_thumbnail = nil
    @morph = 0
    @viewable_albums = 7
    @page = 0
    @tick = Gosu.milliseconds
    
    #Creates file with songs from all albums
    create_all_songs()
  end

  #Cursor can be shown when hovering over the program window
  def needs_cursor?
    true
  end

  #Finds the current element the mouse is over and passes into click_event for button functionallity
  def button_up(id)
    case id
    when Gosu::MsLeft
        if iterate_element() != nil
            element = iterate_element()
            click_event(element)
        end
    end
  end

  def update
    #Load all rects, font and image data and store into an array. All maths and loops are iterated all within this function.
    initialize_elements()
    #Find current element that the ouse is over and passes through hover_event
    if iterate_element() != nil
      element = iterate_element()
      hover_event(element)
    end


    #Sets window title
    self.caption = "Music Player"
  end

  def draw
    #Draws out every element from it's class attribute asscessor data
    draw_elements()
    #Draw any particle classes that are currently present
    draw_particles()
  end
end

def initialize_elements
  #Cleans array each frames to prevent duplication
  @elements = Array.new
  #Amount of possible viewable albums to prevent ui overlap
  @viewable_albums = 7
  if @show_playbar
    #Scales result for when bar is visible
    @viewable_albums = 6 # Scales result for when bar is visible
    start_playbar()
    draw_play_bar()
  end
  draw_album_bar()
  draw_song_panel()
end

#Song progress bar functionality and track track's running time
def start_playbar
  if @pause_play == "pause"
      @count_up = (Gosu.milliseconds - @tick)
      seconds = @count_up / 1000
    #Fit progress to window width
      @progress = seconds * WIDTH / @song_length
      if seconds >= @song_length.to_i && @repeat_song
        play_song(@currently_playing)
      elsif seconds >= @song_length.to_i
        play_song(@currently_playing + 1)
      end
  else
    #Pause counter at current time
    @tick = Gosu.milliseconds - @count_up
  end
end

#Visual maths and song button creation
def draw_song_panel
  margin = 10
  titles = ["NAME", "ARTIST", "GENRE", "RELEASE"] 
  add_element(ELEMENT,0,0,WIDTH,HEIGHT,SECONDARY,BACK,"rect_song_background")
  add_element(FONT,200 + margin,margin,PLAYBAR,1,HIGHLIGHT,"txt_songs","SONGS")

  shift = 0
  for title in titles
    add_element(FONT,200 + margin + shift,@info_font.height + margin,PLAYBAR,0.7,TEXT,"txt_title",title)
    #Spacting between each title
    shift += 200 
  end
  draw_songs()
end

#Creates all possible song titles
def draw_songs
  i = 0
  spacing = 0
  #grabs song data from array and currently selected album index
  while i < @data_array[@selected_album].songs.length
    draw_song(spacing,i)
    i += 1
    spacing += (40 + 5)
  end
end

#Drawing singular song to the song panel with y input controls the distance offset between each panel while i is the passed array index
def draw_song(y,i)
  margin = 20
  album = @data_array[@selected_album]
  song_info = [album.songs[i].name, album.artist, album.genre, "Unknown"]
  add_element(ELEMENT,200,margin + 40 + y,WIDTH,(margin * 2),SONGS,MIDDLE, "song_button_#{i}")
  shift = 0
  for info in song_info
      add_element(FONT,200 + margin + shift,margin + 50 + y,PLAYBAR,0.7,WHITE_TEXT,"txt_songs",info)
      shift += 200
  end
end

#Adds and calculates album bar basic positions
def draw_album_bar
  bar_width = 200
  margin = 15
  box_height = 50
  add_element(ELEMENT,0,0,bar_width,HEIGHT,PRIMARY,MIDDLE, "rect_album_background")
  #determine the current page number using a instance variable to shift viewable element out and in of the defined amount of viewable albums
  if !(@page <= 0)
    add_element(ELEMENT,0,0,bar_width,25,HIGHLIGHT,MIDDLE,"scroll_button_0")
  end
  if !(@page + @viewable_albums >= @data_array.size)
    #Scale button positioning to work around the playbar and prevent UI overlapping
    @show_playbar ? offset = 100 : offset = 25 
    add_element(ELEMENT,0,HEIGHT - offset,bar_width,25,HIGHLIGHT,MIDDLE,"scroll_button_1")
  end
  display_albums(margin, box_height, bar_width)
end

#Displaying multiple albums using a interation while loop to keeping regards to the viewable albums and current page
def display_albums(margin, box_height, bar_width)
  spacing = 0
  spacing_add = box_height + margin
  i = @page
  while i < @viewable_albums + @page
      display_album(@data_array[i].title, spacing, box_height, margin, bar_width, PRIMARY, "album_button_#{i}",i) rescue nil
      spacing += spacing_add
      i += 1
  end
end

#displaying a single album complimenting
def display_album(name, spacing, box_height, margin, bar_width, color, button_name,i)
  box_width = bar_width - (margin * 2)
  font_size = 15
  top_seperator = 25
  name = truncate(name, 20)
  
  add_element(ELEMENT,margin,top_seperator + margin + spacing,box_width,box_height,color,TOP,button_name)
  add_element(FONT,margin + box_height + 10,top_seperator + (margin + (box_height / 2) - (font_size / 2)) + spacing,TOP,0.7,TEXT,"txt_album_name",name)
  add_element(IMAGE,margin,top_seperator + margin + spacing,box_height,box_height,IMAGE_COLOR,TOP,"img_album_thumbnail",@data_array[i].cover)
end

def draw_play_bar()
  #Basic Playbar
  playbar_height = 75
  progress = @progress
  scale = 0.5
  button_margin = 50
  text_margin = 10
  bottom_height = HEIGHT - playbar_height

  #Playbar elements uses settings math to allow for easier positioning and style tinkering
  #Play Panel
  add_element(ELEMENT,0,bottom_height,WIDTH,playbar_height,PRIMARY,PLAYBAR, "rect_playbar_background")  
  #Duration Empty Bar
  add_element(ELEMENT,0,bottom_height - 5,WIDTH,5,TIERTARY,PLAYBAR,"rect_empty_bar") 
  # Duration Bar
  add_element(ELEMENT,0,bottom_height - 5,progress,5,PROGRESS_BAR,PLAYBAR,"rect_duration_bar")  
  add_element(IMAGE,0, HEIGHT - playbar_height, playbar_height,playbar_height, IMAGE_COLOR, PLAYBAR, "img_play_thumbnail", @playing_thumbnail)
  add_element(FONT,playbar_height + text_margin,bottom_height + text_margin,PLAYBAR,1.0,HIGHLIGHT,"txt_album",@playing_album_name)
  add_element(FONT,playbar_height + text_margin,bottom_height + text_margin + @info_font.height,PLAYBAR,0.7,TEXT, "txt_album_song",@playing_song_name)
  
  #arrand and each loop to evenly and dynamicaly space out all of the playbar buttons
  #contain images name
  playbar_images = ["repeat","fast_forward",@pause_play,"fast_backward", "stop"] #Contains image names
  image_spacing = 50
  playbar_images.each_with_index do |image, index|
      add_spacing = (index * image_spacing)
      total_spacing = image_spacing * playbar_images.length / 2
      #size of images
      size = 25
      #Image element file path tag combined with the array
      add_element(IMAGE,(WIDTH / 2 + total_spacing) - (add_spacing) - (size / 2),HEIGHT - (playbar_height / 2) - (size / 2),size,size,IMAGE_COLOR,BUTTONS,"play_button_#{index}","images/" + image + ".png")
  end
end

window = Window.new
window.show