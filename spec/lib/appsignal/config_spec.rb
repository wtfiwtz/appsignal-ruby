describe Appsignal::Config do
  subject { config }

  describe "with a config file" do
    let(:config) { project_fixture_config('production') }

    it "should not log an error" do
      Logger.any_instance.should_not_receive(:log_error)
      subject
    end

    its(:valid?)        { should be_true }
    its(:active?)       { should be_true }
    its(:log_file_path) { should end_with('spec/support/project_fixture/appsignal.log') }

    it "should merge with the default config and fill the config hash" do
      subject.config_hash.should eq({
        :debug                          => false,
        :ignore_errors                  => [],
        :ignore_actions                 => [],
        :filter_parameters              => [],
        :instrument_net_http            => true,
        :instrument_redis               => true,
        :instrument_sequel              => true,
        :skip_session_data              => false,
        :send_params                    => true,
        :endpoint                       => 'https://push.appsignal.com',
        :push_api_key                   => 'abc',
        :name                           => 'TestApp',
        :active                         => true,
        :enable_frontend_error_catching => false,
        :frontend_error_catching_path   => '/appsignal_error_catcher',
        :enable_allocation_tracking     => true,
        :enable_gc_instrumentation      => false,
        :running_in_container           => false,
        :enable_host_metrics            => true,
        :enable_minutely_probes         => false,
        :hostname                       => Socket.gethostname,
        :ca_file_path                   => File.join(resources_dir, 'cacert.pem')
      })
    end

    context "if a log file path is set" do
      let(:config) { project_fixture_config('production', :log_path => '/tmp') }

      its(:log_file_path) { should end_with('/tmp/appsignal.log') }

      context "if it is not writable" do
        before { FileUtils.mkdir_p('/tmp/not-writable', :mode => 0555) }

        let(:config) { project_fixture_config('production', :log_path => '/tmp/not-writable') }

        its(:log_file_path) { should eq '/tmp/appsignal.log' }
      end

      context "if it does not exist" do
        let(:config) { project_fixture_config('production', :log_path => '/non-existing') }

        its(:log_file_path) { should eq '/tmp/appsignal.log' }
      end

      context "if it is nil" do
        let(:config) { project_fixture_config('production', :log_path => nil) }

        before { config.stub(:root_path => nil) }

        its(:log_file_path) { should eq '/tmp/appsignal.log' }
      end
    end

    context "when there is a pre 0.12 style endpoint" do
      let(:config) { project_fixture_config('production', :endpoint => 'https://push.appsignal.com/1') }

      it "should strip the path" do
        subject[:endpoint].should eq 'https://push.appsignal.com'
      end
    end

    context "when there is an endpoint with a non-standard port" do
      let(:config) { project_fixture_config('production', :endpoint => 'http://localhost:4567') }

      it "should keep the port" do
        subject[:endpoint].should eq 'http://localhost:4567'
      end
    end

    describe "#[]= and #[]" do
      it "should get the value for an existing key" do
        subject[:push_api_key].should eq 'abc'
      end

      it "should change and get the value for an existing key" do
        subject[:push_api_key] = 'abcde'
        subject[:push_api_key].should eq 'abcde'
      end

      it "should return nil for a non-existing key" do
        subject[:nonsense].should be_nil
      end
    end

    describe "#write_to_environment" do
      before do
        subject.config_hash[:http_proxy]     = 'http://localhost'
        subject.config_hash[:ignore_actions] = ['action1', 'action2']
        subject.config_hash[:log_path]  = '/tmp'
        subject.config_hash[:hostname]  = 'app1.local'
        subject.config_hash[:filter_parameters] = %w(password confirm_password)
        subject.write_to_environment
      end

      it "should write the current config to env vars" do
        ENV['APPSIGNAL_ACTIVE'].should                       eq 'true'
        ENV['APPSIGNAL_APP_PATH'].should                     end_with('spec/support/project_fixture')
        ENV['APPSIGNAL_AGENT_PATH'].should                   end_with('/ext')
        ENV['APPSIGNAL_DEBUG_LOGGING'].should                eq 'false'
        ENV['APPSIGNAL_LOG_FILE_PATH'].should                end_with('/tmp/appsignal.log')
        ENV['APPSIGNAL_PUSH_API_ENDPOINT'].should            eq 'https://push.appsignal.com'
        ENV['APPSIGNAL_PUSH_API_KEY'].should                 eq 'abc'
        ENV['APPSIGNAL_APP_NAME'].should                     eq 'TestApp'
        ENV['APPSIGNAL_ENVIRONMENT'].should                  eq 'production'
        ENV['APPSIGNAL_AGENT_VERSION'].should                eq Appsignal::Extension.agent_version
        ENV['APPSIGNAL_LANGUAGE_INTEGRATION_VERSION'].should eq Appsignal::VERSION
        ENV['APPSIGNAL_HTTP_PROXY'].should                   eq 'http://localhost'
        ENV['APPSIGNAL_IGNORE_ACTIONS'].should               eq 'action1,action2'
        ENV['APPSIGNAL_FILTER_PARAMETERS'].should            eq 'password,confirm_password'
        ENV['APPSIGNAL_SEND_PARAMS'].should                  eq 'true'
        ENV['APPSIGNAL_RUNNING_IN_CONTAINER'].should         eq 'false'
        ENV['APPSIGNAL_WORKING_DIR_PATH'].should             be_nil
        ENV['APPSIGNAL_ENABLE_HOST_METRICS'].should          eq 'true'
        ENV['APPSIGNAL_ENABLE_MINUTELY_PROBES'].should       eq 'false'
        ENV['APPSIGNAL_HOSTNAME'].should                     eq 'app1.local'
        ENV['APPSIGNAL_PROCESS_NAME'].should                 include 'rspec'
      end

      describe "APPSIGNAL_CA_FILE_PATH" do
        context "when default value" do
          it "does not set the env variable" do
            ENV['APPSIGNAL_CA_FILE_PATH'].should be_nil
          end
        end

        context "when not default value" do
          before do
            subject.config_hash[:ca_file_path] = '/custom/ca_file_path.pem'
            subject.write_to_environment
          end

          it "sets the env variable" do
            ENV['APPSIGNAL_CA_FILE_PATH'].should eq '/custom/ca_file_path.pem'
          end
        end
      end

      context "if working_dir_path is set" do
        before do
          subject.config_hash[:working_dir_path] = '/tmp/appsignal2'
          subject.write_to_environment
        end

        it "should write the current config to env vars" do
          ENV['APPSIGNAL_WORKING_DIR_PATH'].should eq '/tmp/appsignal2'
        end
      end
    end

    context "if the env is passed as a symbol" do
      let(:config) { project_fixture_config(:production) }

      its(:active?) { should be_true }
    end

    context "and there's config in the environment" do
      before do
        ENV['APPSIGNAL_PUSH_API_KEY'] = 'push_api_key'
        ENV['APPSIGNAL_DEBUG'] = 'true'
      end

      it "should ignore env vars that are present in the config file" do
        subject[:push_api_key].should eq 'abc'
      end

      it "should use env vars that are not present in the config file" do
        subject[:debug].should eq true
      end

      context "running on Heroku" do
        before do
          ENV['DYNO'] = 'true'
        end
        after do
          ENV.delete('DYNO')
        end

        it "should set running in container to true" do
          subject[:running_in_container].should be_true
        end
      end
    end

    context "and there is an initial config" do
      let(:config) { project_fixture_config('production', :name => 'Initial name', :initial_key => 'value') }

      it "should merge with the config" do
        subject[:name].should eq 'TestApp'
        subject[:initial_key].should eq 'value'
      end
    end

    context "and there is an old-style config" do
      let(:config) { project_fixture_config('old_api_key') }

      it "should fill the push_api_key with the old style key" do
        subject[:push_api_key].should eq 'def'
      end

      it "should fill ignore_errors with the old style ignore exceptions" do
        subject[:ignore_errors].should eq ['StandardError']
      end
    end
  end

  context "when there is a config file without the current env" do
    let(:config) { project_fixture_config('nonsense') }

    it "should log an error" do
      Logger.any_instance.should_receive(:error).with(
        "Not loading from config file: config for 'nonsense' not found"
      ).once
      Logger.any_instance.should_receive(:error).with(
        "Push api key not set after loading config"
      ).once
      subject
    end

    its(:valid?)  { should be_false }
    its(:active?) { should be_false }
  end

  context "when there is no config file" do
    let(:initial_config) { {} }
    let(:config) { Appsignal::Config.new('/tmp', 'production', initial_config) }

    its(:valid?)        { should be_false }
    its(:active?)       { should be_false }
    its(:log_file_path) { should end_with('/tmp/appsignal.log') }

    context "with valid config in the environment" do
      before do
        ENV['APPSIGNAL_PUSH_API_KEY']   = 'aaa-bbb-ccc'
        ENV['APPSIGNAL_ACTIVE']         = 'true'
        ENV['APPSIGNAL_APP_NAME']       = 'App name'
        ENV['APPSIGNAL_DEBUG']          = 'true'
        ENV['APPSIGNAL_IGNORE_ACTIONS'] = 'action1,action2'
      end

      its(:valid?)  { should be_true }
      its(:active?) { should be_true }

      its([:push_api_key])   { should eq 'aaa-bbb-ccc' }
      its([:active])         { should eq true }
      its([:name])           { should eq 'App name' }
      its([:debug])          { should eq true }
      its([:ignore_actions]) { should eq ['action1', 'action2'] }
    end
  end

  context "when a nil root path is passed" do
    let(:initial_config) { {} }
    let(:config) { Appsignal::Config.new(nil, 'production', initial_config) }

    its(:valid?)  { should be_false }
    its(:active?) { should be_false }
  end
end
