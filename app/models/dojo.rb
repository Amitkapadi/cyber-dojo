
require 'digest/sha1'
require 'make_time_helper.rb'
require 'traffic_light_helper.rb'
require 'Locking'
require 'Files'

class Dojo
  
  include Locking
  extend Locking  
  include MakeTimeHelper
  extend MakeTimeHelper
  include TrafficLightHelper
  extend TrafficLightHelper
  include Files
  extend Files
  
  Index_filename = 'index.rb' 

  def self.exists?(params)
    name = params[:dojo_name]
    root_folder = params[:dojo_root]    
    inner = root_folder + '/' + Dojo::inner_folder(name)
    outer = inner + '/' + Dojo::outer_folder(name)
    File.directory? inner and File.directory? outer
  end

  def self.create(params)
    name = params[:dojo_name]
    root_folder = params[:dojo_root]    
    inner = root_folder + '/' + Dojo::inner_folder(name)
    outer = inner + '/' + Dojo::outer_folder(name)
    
    if !File.directory? root_folder
      make_dir(root_folder)
    end

    io_lock(root_folder) do
      if File.directory? inner and File.directory? outer
        false
      else
        make_dir(inner)
        make_dir(outer)
        true
      end
    end
  end
  
  def self.configure(params)
    name = params[:dojo_name]
    root_folder = params[:dojo_root]
    io_lock(root_folder) do
      dojo = Dojo.new(params)
      
      info = { 
        :name => name, 
        :created => make_time(Time.now),
        :kata => params['kata'],
        :language => params['language'],
        :browser => params[:browser]
      }
      
      file_write(dojo.manifest_filename, info)
      
      index_filename = root_folder + '/' + Dojo::Index_filename
      index = File.exists?(index_filename) ? eval(IO.read(index_filename)) : [ ]       
      file_write(index_filename, index << info)      

      file_write(dojo.messages_filename, [ ])
      
      sandbox = dojo.folder + '/sandbox' 
      make_dir(sandbox)
      fileset = LanguageFileSet.new(params[:filesets_root] + '/language/' + params['language'])
      fileset.copy_hidden_files_to(sandbox)
    end    
  end

  def self.inner_folder(name)
    Dojo::sha1(name)[0..1] # ala git    
  end

  def self.outer_folder(name)
    Dojo::sha1(name)[2..-1] # ala git
  end

  def self.sha1(name)
    Digest::SHA1.hexdigest(name)
  end
  
  #---------------------------------

  def initialize(params)
    @name = params[:dojo_name]
    @dojo_root = params[:dojo_root]
    @filesets_root = params[:filesets_root]
  end

  def name
    @name
  end
  
  def create_new_avatar_folder(avatar_name)
    @created = false
    io_lock(folder) do
      avatar_folder = folder + '/' + avatar_name
      if !File.exists? avatar_folder
        Avatar.new(self, avatar_name)
        @created = true
        post_message(avatar_name, "#{avatar_name} has joined the dojo")
      end
    end
    @created
  end
  
  def avatar_names
    Avatar.names.select { |name| exists? name }
  end
  
  def avatars
    avatar_names.map { |name| Avatar.new(self, name) }
  end

  def all_increments
    avatars.inject({}) do |result,avatar|
      result.merge( { avatar.name => avatar.increments } )
    end
  end
  
  def seconds_per_heartbeat
    10
  end

  def messages
    io_lock(messages_filename) { eval IO.read(messages_filename) }
  end

  def post_message(sender_name, text, type = :notification)
    messages = [ ]
    io_lock(messages_filename) do
      messages = eval IO.read(messages_filename)
      text = text.strip
      if text != ''
        messages <<  { 
          :sender => sender_name, 
          :text => text,
          :created => make_time(Time.now),
          :type => type
        }
        file_write(messages_filename, messages)
      end
    end
    messages
  end
  
  def tab
    fileset = LanguageFileSet.new(filesets_root + '/language/' + language)
    " " * fileset.tab_size
  end
  
  def unit_test_framework
    fileset = LanguageFileSet.new(filesets_root + '/language/' + language)
    fileset.unit_test_framework
  end
  
  def language
    manifest[:language]
  end
  
  def exercise
    manifest[:kata]    
  end
      
  # TODO: aiming to drop...
  def kata
    filesets =
    {
      :kata => exercise,
      :language => language
    }
    Kata.new(filesets_root, filesets)
  end
  
  def folder
    @dojo_root + '/' + Dojo::inner_folder(name) + '/' + Dojo::outer_folder(name)
  end

  def manifest_filename
    folder + '/' + 'manifest.rb'
  end

  def messages_filename
    folder + '/' + 'messages.rb'
  end
  
  def created
    Time.mktime(*manifest[:created])
  end
  
  def age_in_seconds
    duration_in_seconds(created, Time.now)
  end
  
  def manifest
    eval IO.read(manifest_filename)
  end

  def filesets_root
    @filesets_root
  end
  
private

  def exists?(name)
    File.exists? folder + '/' + name
  end
  
  def self.make_dir(name)
    if !File.directory? name
      Dir.mkdir name
    end
  end
  
end


