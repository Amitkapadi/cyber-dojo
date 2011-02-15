require 'folders_in.rb'

class FileSet

  def initialize(filesets_root, name)
    @filesets_root = filesets_root
    @name = name
  end

  def choices
    folders_in(path)
  end  
  
  def random_choice
    choices.shuffle[0]
  end
  
  def read_into(manifest, choice)
    fullpath = path + '/' + choice
    file_set = eval IO.read(fullpath + '/' + 'manifest.rb')
    file_set.each do |key,value|
	    if key == :visible_filenames
        manifest[:visible_files].merge! FileSet::read_visible(fullpath, value)
      elsif key == :hidden_filenames
        manifest[:hidden_filenames] += value
        manifest[:hidden_pathnames] += FileSet::read_hidden_pathnames(fullpath, value)
      else
        manifest[key] = value
      end
    end    

  end
  
private

  def path
    @filesets_root + '/' + @name
  end

  def self.read_visible(file_set_folder, filenames)
    visible_files = {}
    filenames.each do |filename|
      visible_files[filename] = 
        { :content => IO.read(file_set_folder + '/' + filename),
          :caret_pos => 0 
        }
    end
    visible_files
  end

  def self.read_hidden_pathnames(file_set_folder, filenames)
    pathed = []
    filenames.each do |filename|
      pathed << file_set_folder + '/' + filename
    end
    pathed
  end

end


