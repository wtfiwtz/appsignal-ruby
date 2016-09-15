if sinatra_present?
  require 'appsignal/integrations/sinatra'
  describe Appsignal::Rack::SinatraInstrumentation do
    let(:settings) { double(:raise_errors => false) }
    let(:app) { double(:call => true, :settings => settings) }
    let(:env) { {'sinatra.route' => 'GET /', :path => '/', :method => 'GET'} }
    let(:middleware) { Appsignal::Rack::SinatraInstrumentation.new(app) }

    describe "#call" do
      before do
        start_agent
        middleware.stub(:raw_payload => {})
        Appsignal.stub(:active? => true)
      end

      it "should call without monitoring" do
        expect(Appsignal::Transaction).to_not receive(:create)
      end

      after { middleware.call(env) }
    end

    describe ".settings" do
      subject { middleware.settings }

      it "should return the app's settings" do
        expect(subject).to eq(app.settings)
      end
    end
  end

  describe Appsignal::Rack::SinatraBaseInstrumentation do
    before :all do
      start_agent
    end

    let(:settings) { double(:raise_errors => false) }
    let(:app) { double(:call => true, :settings => settings) }
    let(:env) { {'sinatra.route' => 'GET /', :path => '/', :method => 'GET'} }
    let(:options) { {} }
    let(:middleware) { Appsignal::Rack::SinatraBaseInstrumentation.new(app, options) }

    describe "#call" do
      before do
        middleware.stub(:raw_payload => {})
      end

      context "when appsignal is active" do
        before { Appsignal.stub(:active? => true) }

        it "should call with monitoring" do
          expect( middleware ).to receive(:call_with_appsignal_monitoring).with(env)
        end
      end

      context "when appsignal is not active" do
        before { Appsignal.stub(:active? => false) }

        it "should not call with monitoring" do
          expect( middleware ).to_not receive(:call_with_appsignal_monitoring)
        end

        it "should call the stack" do
          expect( app ).to receive(:call).with(env)
        end
      end

      after { middleware.call(env) }
    end

    describe "#call_with_appsignal_monitoring" do
      it "should create a transaction" do
        Appsignal::Transaction.should_receive(:create).with(
          kind_of(String),
          Appsignal::Transaction::HTTP_REQUEST,
          kind_of(Sinatra::Request),
          kind_of(Hash)
        ).and_return(double(:set_action => nil, :set_http_or_background_queue_start => nil, :set_metadata => nil))
      end

      it "should call the app" do
        app.should_receive(:call).with(env)
      end

      context "with an error" do
        let(:error) { VerySpecificError.new }
        let(:app) do
          double.tap do |d|
            d.stub(:call).and_raise(error)
            d.stub(:settings => settings)
          end
        end

        it "should set the error" do
          Appsignal::Transaction.any_instance.should_receive(:set_error).with(error)
        end
      end

      context "with an error in sinatra.error" do
        let(:error) { VerySpecificError.new }
        let(:env) { {'sinatra.error' => error} }

        it "should set the error" do
          Appsignal::Transaction.any_instance.should_receive(:set_error).with(error)
        end

        context "if raise_errors is on" do
          let(:settings) { double(:raise_errors => true) }

          it "should not set the error" do
            Appsignal::Transaction.any_instance.should_not_receive(:set_error)
          end
        end

        context "if sinatra.skip_appsignal_error is set" do
          let(:env) { {'sinatra.error' => error, 'sinatra.skip_appsignal_error' => true} }

          it "should not set the error" do
            Appsignal::Transaction.any_instance.should_not_receive(:set_error)
          end
        end
      end

      describe "action name" do
        it "should set the action" do
          Appsignal::Transaction.any_instance.should_receive(:set_action).with('GET /')
        end

        context "without 'sinatra.route' env" do
          let(:env) { {:path => '/', :method => 'GET'} }

          it "returns nil" do
            Appsignal::Transaction.any_instance.should_receive(:set_action).with(nil)
          end
        end

        context "with option to set path a mounted_at prefix" do
          let(:options) {{ :mounted_at  => "/api/v2" }}

          it "should call set_action with a prefix path" do
            Appsignal::Transaction.any_instance.should_receive(:set_action).with("GET /api/v2/")
          end

          context "without 'sinatra.route' env" do
            let(:env) { {:path => '/', :method => 'GET'} }

            it "returns nil" do
              Appsignal::Transaction.any_instance.should_receive(:set_action).with(nil)
            end
          end
        end

        context "with mounted modular application" do
          before { env['SCRIPT_NAME'] = '/api' }

          it "should call set_action with an application prefix path" do
            Appsignal::Transaction.any_instance.should_receive(:set_action).with("GET /api/")
          end

          context "without 'sinatra.route' env" do
            let(:env) { {:path => '/', :method => 'GET'} }

            it "returns nil" do
              Appsignal::Transaction.any_instance.should_receive(:set_action).with(nil)
            end
          end
        end
      end

      it "should set metadata" do
        Appsignal::Transaction.any_instance.should_receive(:set_metadata).twice
      end

      it "should set the queue start" do
        Appsignal::Transaction.any_instance.should_receive(:set_http_or_background_queue_start)
      end

      context "with overridden request class and params method" do
        let(:options) { {:request_class => ::Rack::Request, :params_method => :filtered_params} }

        it "should use the overridden request class and params method" do
          request = ::Rack::Request.new(env)
          ::Rack::Request.should_receive(:new).
                          with(env.merge(:params_method => :filtered_params)).
                          at_least(:once).
                          and_return(request)
        end
      end

      after { middleware.call(env) rescue VerySpecificError }
    end
  end
end
