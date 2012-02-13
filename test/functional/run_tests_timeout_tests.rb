require File.dirname(__FILE__) + '/../test_helper'

# > ruby test/functional/run_tests_timeout_tests.rb

class RunTestsTimeOutTests < ActionController::TestCase

  Root_test_folder = RAILS_ROOT + '/test/test_dojos'

  def root_test_folder_reset
    system("rm -rf #{Root_test_folder}")
    Dir.mkdir Root_test_folder
  end

  # Relies on gcc and make being installed

  def make_params
    { :dojo_name => 'Jon Jagger', 
      :dojo_root => Root_test_folder,
      :filesets_root => RAILS_ROOT + '/filesets',
      'language' => 'C',
      'kata' => 'Unsplice',
      :browser => 'None (test)'
    }
  end
  
  def ps_count
    `ps aux | grep -E "(cyberdojo|make|run\.tests)"`.lines.count
  end
  
  def test_that_code_with_infinite_loop_times_out_and_doesnt_leak_processes
    root_test_folder_reset
    params = make_params
    assert Dojo::create(params)
    Dojo.configure(params)
    dojo = Dojo.new(params)
    filename = 'untitled.c'
    avatar_name = Avatar::names.shuffle[0]
    avatar = Avatar.new(dojo, avatar_name)
    manifest = avatar.manifest
    code = manifest[:visible_files][filename][:content]
    manifest[:visible_files][filename][:content] = code.sub('return 42;', 'for(;;);')
    
    ps_count_before = ps_count
    avatar.run_tests(manifest)
    ps_count_after = ps_count
    assert_equal ps_count_before, ps_count_after, 'proper cleanup of shell processes'
    
    assert_not_nil manifest[:output] =~ /Terminated by the CyberDojo server after 10 seconds/, manifest[:output]
  end
  
end
