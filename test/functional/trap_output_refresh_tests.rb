require File.dirname(__FILE__) + '/../test_helper'

# > ruby test/functional/trap_output_refresh_tests.rb

class TrapOutputRefreshTests < ActionController::TestCase

  # If you click run-tests and then so a browser refresh
  # the output is not restored correctly
  
  Root_test_folder = RAILS_ROOT + '/test/test_dojos'

  def root_test_folder_reset
    system("rm -rf #{Root_test_folder}")
    Dir.mkdir Root_test_folder
  end

  def make_params(language)
    { :dojo_name => language, 
      :dojo_root => Root_test_folder,
      :filesets_root => RAILS_ROOT + '/filesets',
      'language' => language,
      'kata' => 'Prime Factors'
    }
  end

  Code_files = { 
    'C' => 'untitled.c',
  }
  
  def test_output_is_correct_after_refresh
    language = 'C'
    root_test_folder_reset
    params = make_params(language)
    assert Dojo::create(params)
    assert Dojo::configure(params)
    dojo = Dojo.new(params)
    avatar = Avatar.new(dojo, 'lion')
    output = avatar.run_tests(avatar.visible_files)
    # now refresh
    dojo = Dojo.new(params)
    avatar = Avatar.new(dojo, 'lion')
    assert_equal output, avatar.visible_files['output']
  end    
      
end
