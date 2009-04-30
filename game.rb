Shoes.setup do
  gem 'activesupport'
  gem 'rest-client'
  gem 'smile'
end

require 'smile'

class Tile < Shoes::Widget
  attr_accessor :photo, :tiny, :cover, :hidden, :found
  @@tiles =[]
  def initialize( photo, args=nil )
    @@tiles << self
    @photo = photo
    
    @tiny = image photo.send( "#{args[:image_size]}_url" ), :align => 'center'
    
    @base_width = 100
    @base_height = 100
    
    case args[:image_size]
    when 'tiny'
      @base_width = 100
      @base_height = 100
    when 'small'
      @base_width = 400
      @base_height = 300
    when 'medium'
      @base_width = 600
      @base_height = 450
    end
    
    self.width  = @base_width + 3
    self.height = @base_height + 3
    
    @cover = image 'smuggy_bigger.jpg',
      :top => self.top, :left => self.left,
      :width => @base_width, :height => @base_height
    
    @hidden = true
    @found = false
    @cover.click do
      next if uncovered.size > 1
      @cover.hide
      tile_shown = uncovered.first
      @hidden = !@hidden
      match( tile_shown )
    end
  end
  
  def uncovered
    @@tiles.select{ |t| !t.hidden && !t.found }
  end
  
  def match( tile )
    return if( tile.nil? )
    if( tile.photo == @photo )
      tile.found = true
      @found = true
    else
      timer( 1 ) do
        @@tiles.each do |t|
          info t.found
          next if t.found 
          t.cover.show
          t.hidden = true
        end
      end
    end
  end
end

Shoes.app :title => "Smug Games", 
  :width => 800, :height => 800 do
  @tiles =[]
  won = false
  total_time = 0
  background black
  @size = 'tiny'
  @number_of_tiles = 'all'
  
  stack do
    flow :align => 'center' do
      para 'Nick Name ( e.g. kleinpeter) ', :stroke => white
      @nick = edit_line :text => 'kleinpeter'
    end
    
    flow :align => 'center' do
      para 'Tile Size'
      list_box :items => %w{ tiny small medium } do |item|
        @size = item.text
      end
      
      para 'Max Number of Tiles'
      list_box :items => %w{ 2 10 20 30 all}, :choose => 'all' do |item|
        @number_of_tiles = item.text
      end
      
      button 'Load Tiles' do
        total_time = 0
        won = false
        @tiles.clear
        load_tiles
      end
      
      para link( 'About' , :click => Proc.new {
        dialog do
          stack do
            title 'Smug Games', :align => 'center'
            subtitle "Shoes #{Shoes::RELEASE_NAME}", :align => 'center'
            subtitle "Version #{Shoes::RELEASE_ID}.#{Shoes::REVISION}", :align => 'center'
          end
        end
      })
      
    end
    
    @links = para link( 'Visit SmugMug', :click => 'http://www.smugmug.com/' ),
            :align => 'center'
    @status = para "Enter name and click load tiles to start", :align => 'center', 
      :stroke => white
  end
  
  @grid = stack

  every( 1 ) do
    if( @tiles.size > 1 && !won )
      total_time += 1
      total = @tiles.size / 2
      found = @tiles.select{ |x| x.found }.size / 2
      
      @status.replace(
        "#{found} found out of #{total} in #{total_time} seconds"
      )
      if( found == total )
        won = true
        alert( "Yon Won in #{total_time} sec!!!!")
        
      end
    end
  end
  
  def load_tiles
    smug = Smile::Smug.new
    smug.auth_anonymously
    albums = smug.albums( :NickName => @nick.text, :Heavy => 1 ).select{ |x| x.image_count.to_i > 1 }
    
    if albums.size == 0
      alert( "No albums to load for #{@nick.text}!!! Pick another nick name" )
      return
    end
    
    album = albums.sort_by{ rand }.first
    photos = album.photos
    
    unless( @number_of_tiles == 'all' )
      photos = photos[0, @number_of_tiles.to_i / 2 ]
    end  
    
    @links.replace(
          link( 'Visit SmugMug', :click => 'http://www.smugmug.com/' ), " ",
          link( "#{album.title} at SmugMug", :click => photos.first.album_url )
    )
    
    @grid.clear if @grid 
    @grid.append do
      a = flow do
        # make two images show in the list
        photos += photos
        photos.sort_by{ rand }.each do |photo|
          @tiles << tile( photo, :margin => 5, :image_size => @size )
        end
      end
      
      flow do
        para "#{photos.size / 2} matches to find"
      end
    end
  end
end