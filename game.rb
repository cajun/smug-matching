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
    @tiny = image photo.tiny_url
    
    self.width = 104
    self.height = 104
    
    @cover = image 'smuggy_bigger.jpg',
      :top => self.top, :left => self.left,
      :width => 100, :height => 100
    
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
          next if t.found 
          t.cover.show
          t.hidden = true
        end
      end
    end
  end
end

Shoes.app :title => 'Smug Games', :width => 800, :height => 800 do
  @tiles =[]
  won = false
  total_time = 0
  background black
  stack do
    flow :align => 'center' do
      para 'Nick Name ( e.g. kleinpeter) ', :stroke => white
      @nick = edit_line :text => 'kleinpeter'
  
      button 'Load Tiles' do
        total_time = 0
        won = false
        @tiles.clear
        load_tiles
      end
      
      para( link( 'About' ) ) do
        dialog do
          stack do
            title 'Smug Games'
            subtitle "Release Name"
            subtitle bold "#{Shoes::RELEASE_NAME}"
            subtitle "Version"
            subtitle bold "#{Shoes::RELEASE_ID} :: #{Shoes::REVISION}"
          end
        end
      end
      
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
          @tiles << tile( photo, :margin => 2 )
        end
      end
      
      flow do
        para "#{photos.size / 2} matches to find"
      end
    end
  end
end