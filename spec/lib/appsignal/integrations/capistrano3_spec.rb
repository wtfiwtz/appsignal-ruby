require 'spec_helper'

if capistrano3_present?
  require 'capistrano/all'
  require 'appsignal/capistrano'

  describe "Capistrano 3 integration" do
    pending "Capistrano 3 specs"
  end
end
