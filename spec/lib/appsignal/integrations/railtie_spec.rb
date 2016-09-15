if DependencyHelper.rails_present?
  describe Appsignal::Integrations::Railtie do
    context "after initializing the app" do
      it "should call initialize_appsignal" do
        expect( Appsignal::Integrations::Railtie ).to receive(:initialize_appsignal)

        MyApp::Application.config.root = project_fixture_path
        MyApp::Application.initialize!
      end
    end

    describe "#initialize_appsignal" do
      let(:app) { MyApp::Application }
      before { app.middleware.stub(:insert_before => true) }

      context "logger" do
        before  { Appsignal::Integrations::Railtie.initialize_appsignal(app) }
        subject { Appsignal.logger }

        it { should be_a Logger }
      end

      context "config" do
        subject { Appsignal.config }
        context "basics" do
          before  { Appsignal::Integrations::Railtie.initialize_appsignal(app) }

          it { should be_a(Appsignal::Config) }

          its(:root_path)  { should eq Pathname.new(project_fixture_path) }
          its(:env)        { should eq 'test' }
          its([:name])     { should eq 'TestApp' }
          its([:log_path]) { should eq Pathname.new(File.join(project_fixture_path, 'log')) }
        end

        context "initial config" do
          before  { Appsignal::Integrations::Railtie.initialize_appsignal(app) }
          subject { Appsignal.config.initial_config }

          its([:name]) { should eq 'MyApp' }
        end

        context "with APPSIGNAL_APP_ENV ENV var set" do
          before do
            ENV.should_receive(:fetch).with('APPSIGNAL_APP_ENV', 'test').and_return('env_test')
            Appsignal::Integrations::Railtie.initialize_appsignal(app)
          end

          its(:env) { should eq 'env_test' }
        end
      end

      context "listener middleware" do
        it "should have added the listener middleware" do
          expect( app.middleware ).to receive(:insert_before).with(
            ActionDispatch::RemoteIp,
            Appsignal::Rack::RailsInstrumentation
          )
        end

        context "when frontend_error_catching is enabled" do
          let(:config) do
            Appsignal::Config.new(
              project_fixture_path,
              'test',
              :name => 'MyApp',
              :enable_frontend_error_catching => true
            )
          end

          before do
            Appsignal.stub(:config => config)
          end

          it "should have added the listener and JSExceptionCatcher middleware" do
            expect( app.middleware ).to receive(:insert_before).with(
              ActionDispatch::RemoteIp,
              Appsignal::Rack::RailsInstrumentation
            )

            expect( app.middleware ).to receive(:insert_before).with(
              Appsignal::Rack::RailsInstrumentation,
              Appsignal::Rack::JSExceptionCatcher
            )
          end
        end

        after { Appsignal::Integrations::Railtie.initialize_appsignal(app) }
      end
    end
  end
end
