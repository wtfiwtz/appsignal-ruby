module DependencyHelper
  module_function

  def rails_present?
    dependency_present? 'rails'
  end

  def active_record_present?
    dependency_present? 'active_record'
  end

  def sequel_present?
    dependency_present? 'sequel'
  end

  def resque_present?
    dependency_present? 'resque'
  end

  def active_job_present?
    dependency_present? 'active_job'
  end

  def sinatra_present?
    dependency_present? 'sinatra'
  end

  def padrino_present?
    dependency_present? 'padrino'
  end

  def grape_present?
    dependency_present? 'grape'
  end

  def webmachine_present?
    dependency_present? 'webmachine'
  end

  def running_jruby?
    defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  end

  def capistrano_present?
    dependency_present? 'capistrano'
  end

  def capistrano2_present?
    capistrano_present? &&
      Gem.loaded_specs['capistrano'].version < Gem::Version.new('3.0')
  end

  def capistrano3_present?
    capistrano_present? &&
      Gem.loaded_specs['capistrano'].version >= Gem::Version.new('3.0')
  end

  def dependency_present?(dependency_file)
    Gem.loaded_specs.key? dependency_file
  end
end
