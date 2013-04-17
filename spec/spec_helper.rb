# imitate the configuration setup from billfloat project
SILVERPOP_POD = 5
RAILS_ROOT = File.expand_path("..", __FILE__) 

require File.expand_path('../../lib/silverpop', __FILE__)

RSpec.configure do |config|
  # to run all tests: INCLUDE_REMOTE=true rspec
  config.filter_run_excluding :remote => true unless ENV['INCLUDE_REMOTE']
  
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = "default"
end

RSpec::Matchers.define(:be_same_file_as) do |file_path|
  match do |actual_file_path|
    md5_hash(actual_file_path).should == md5_hash(file_path)
  end
  
  def md5_hash(file_path)
    Digest::MD5.file(file_path).hexdigest
  end
end
