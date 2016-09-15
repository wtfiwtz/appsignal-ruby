if DependencyHelper.sinatra_present? && !DependencyHelper.padrino_present?
  ENV['APPSIGNAL_PUSH_API_KEY'] = 'key'
  require 'appsignal/integrations/sinatra'

  describe "Sinatra integration" do
    context "logger" do
      subject { Appsignal.logger }

      it { should be_a Logger }
    end

    it "should have added the instrumentation middleware" do
      Sinatra::Base.middleware.to_a.should include(
        [Appsignal::Rack::SinatraBaseInstrumentation, [], nil]
      )
    end
  end
end
