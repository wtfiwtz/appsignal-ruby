ENV['RAILS_ENV'] ||= 'test'
ENV['PADRINO_ENV'] ||= 'test'

require 'rack'
require 'rspec'
require 'pry'
require 'timecop'
require 'webmock/rspec'

puts "Runnings specs in #{RUBY_VERSION} on #{RUBY_PLATFORM}"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support/stubs'))

begin
  require 'rails'
  Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support/rails','*.rb'))].each {|f| require f}
  puts 'Rails present, running Rails specific specs'
  RAILS_PRESENT = true
rescue LoadError
  puts 'Rails not present, skipping Rails specific specs'
  RAILS_PRESENT = false
end

def rails_present?
  RAILS_PRESENT
end

def active_job_present?
  require 'active_job'
  true
rescue LoadError
  false
end

def active_record_present?
  require 'active_record'
  true
rescue LoadError
  false
end

def running_jruby?
  defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
end

def capistrano_present?
  !! Gem.loaded_specs['capistrano']
end

def capistrano2_present?
  capistrano_present? &&
    Gem.loaded_specs['capistrano'].version < Gem::Version.new('3.0')
end

def capistrano3_present?
  capistrano_present? &&
    Gem.loaded_specs['capistrano'].version >= Gem::Version.new('3.0')
end

def sequel_present?
  require 'sequel'
  true
rescue LoadError
  false
end

def resque_present?
  require 'resque'
  true
rescue LoadError
  false
end

def sinatra_present?
  begin
    require 'sinatra'
    true
  rescue LoadError
    false
  end
end

def padrino_present?
  require 'padrino'
  true
rescue LoadError
  false
end

def grape_present?
  require 'grape'
  true
rescue LoadError
  false
end

def webmachine_present?
  require 'webmachine'
  true
rescue LoadError
  false
end

require 'appsignal'

def spec_dir
  File.dirname(__FILE__)
end

def tmp_dir
  @tmp_dir ||= File.expand_path('tmp', spec_dir)
end

def fixtures_dir
  @fixtures_dir ||= File.expand_path('support/fixtures', spec_dir)
end

def helpers_dir
  @helpers_dir ||= File.expand_path('support/helpers', spec_dir)
end

Dir[File.join(helpers_dir, '*.rb')].each { |file| require file }

RSpec.configure do |config|
  config.include ConfigHelpers
  config.include EnvHelpers
  config.include NotificationHelpers
  config.include TimeHelpers
  config.include TransactionHelpers

  config.before :all do
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
  end

  config.after do
    Thread.current[:appsignal_transaction] = nil
  end

  config.before do
    ENV['RAILS_ENV'] = 'test'
    ENV['PADRINO_ENV'] = 'test'

    # Clean environment
    ENV.keys.select { |key| key.start_with?('APPSIGNAL_') }.each do |key|
      ENV[key] = nil
    end
  end

  config.after :all do
    FileUtils.rm_f(File.join(project_fixture_path, 'log/appsignal.log'))
    Appsignal.config = nil
    Appsignal.logger = nil
  end
end

class VerySpecificError < RuntimeError
end
