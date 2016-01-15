require 'spec_helper'

describe CountryRejector do
  before :each do
    reset_configuration
  end

  it 'has a version number' do
    expect(CountryRejector::VERSION).not_to be nil
  end

  context "Configuration" do
    it "should fallback to the default configuration" do
      conf = CountryRejector::Middleware.configuration
      expect(conf.banned_list).to eq []
      expect(conf.env_ip_tag).to eq "HTTP_X_REAL_IP"
    end

    it "should update all configurations" do
      CountryRejector::Middleware.configure do |config|
        config.banned_list = ["CU", "BAD_COUNTRY"]
        config.country_detector = lambda {|ip| "FR" }
        config.env_ip_tag = "CUSTOM"
      end

      conf = CountryRejector::Middleware.configuration
      expect(conf.banned_list).to eq ["CU", "BAD_COUNTRY"]
      expect(conf.env_ip_tag).to eq "CUSTOM"
      expect(conf.country_detector.call("fake_ip")).to eq "FR"
    end
  end

  describe "Middleware" do
    # App is the second middleware that return allways 200 OK
    let(:last_middleware) { lambda {|env| [200, env, ['OK']]} }

    # subject is the tested middleware, with the next middleware on first param
    subject { CountryRejector::Middleware.new(last_middleware) }

    # request is our fake request with our custom rack stack
    let(:request) { Rack::MockRequest.new(subject) }

    context "not banned country" do
      before(:each) do
        CountryRejector::Middleware.configure do |config|
          config.banned_list = ["CU", "BAD_COUNTRY"]
          config.country_detector = lambda {|ip| "FR" }
        end
      end

      it "is expected to set ip_rejected to false"do
        response = request.get("/", {"rack.session" => {}, "HTTP_X_REAL_IP" => "80.11.77.16"})
        expect(response.headers["rack.session"].keys).to include("ip_rejected")
        expect(response.headers["rack.session"]["ip_rejected"]).to eq(false)
      end

      it "should accept requests if HTTP_X_REAL_IP variable is not set" do
        response = request.get("/", {"rack.session" => {}})
        expect(response.headers["rack.session"].keys).to_not include("ip_rejected")
      end

      it "should not call country_detector if ip_rejected is set" do
        CountryRejector::Middleware.configure do |config|
          config.country_detector = lambda {|ip| raise "The Lambda was call" }
        end
        expect {
          request.get("/", {"rack.session" => {"ip_rejected" => false}, "HTTP_X_REAL_IP" => "175.45.177.50"})
        }.to_not raise_error
      end

      # I don't like this Workaround :(
      it "should call country_detector if ip_rejected is NOT set" do
        CountryRejector::Middleware.configure do |config|
          config.country_detector = lambda {|ip| $CountryRejectorError = "The Lambda was call" }
        end
        request.get("/", {"rack.session" => {}, "HTTP_X_REAL_IP" => "175.45.177.50"})
        expect($CountryRejectorError).to eq "The Lambda was call"
        $CountryRejectorError = nil
      end
    end

    context "banned country" do
      before(:each) do
        CountryRejector::Middleware.configure do |config|
          config.banned_list = ["CU", "BAD_COUNTRY"]
          config.country_detector = lambda {|ip| "CU" }
        end
      end

      it "should return a 403" do
        response = request.get("/", {"rack.session" => {}, "HTTP_X_REAL_IP" => "175.45.177.50"})
        expect(response.status).to eq 403
      end

      it "should not call country_detector if ip_rejected is set" do
        expect(CountryRejector::Configuration).to_not receive(:call)
        response = request.get("/", {"rack.session" => {"ip_rejected" => true}})
        expect(response.status).to eq 403
      end
    end

    context "bad lambda execution" do
      it "should not hung the request if the processor take more than 0.001 ms" do
        CountryRejector::Middleware.configure do |config|
          config.country_detector = lambda {|ip| sleep(1000000) }
        end
        Timeout::timeout(1) do
          response = request.get("/", {"rack.session" => {}})
        end
      end

      it "should not hung the request if the processor raise" do
        CountryRejector::Middleware.configure do |config|
          config.country_detector = lambda {|ip| raise "A big error occured" }
        end
        expect {
          request.get("/", {"rack.session" => {}})
        }.to_not raise_error
      end
    end

    context "bad env ip tag" do
      it "should skip if no IP given in env" do
        CountryRejector::Middleware.configure do |config|
          config.env_ip_tag = "UNKNOWN_BY_ENV"
        end
        response = request.get("/", {"rack.session" => {}})
        expect(response.status).to eq 200
        expect(response.headers["rack.session"].keys).to_not include("ip_rejected")
      end
    end

    context "Exception fired" do
      before :each do
        allow_any_instance_of(CountryRejector::Middleware).to receive(:get_ip_info).and_raise("WhateEverError")
      end

      it "should return 200 OK" do
        response = request.get("/", {"rack.session" => {}, "HTTP_X_REAL_IP" => "175.45.177.50"})
        expect(response.status).to eq 200
      end

      it "should catch the error" do
        expect {
          request.get("/", {"rack.session" => {}, "HTTP_X_REAL_IP" => "175.45.177.50"})
        }.to_not raise_error
      end

      it "should not assign ip_rejected session var" do
        response = request.get("/", {"rack.session" => {}, "HTTP_X_REAL_IP" => "175.45.177.50"})
        expect(response.headers["rack.session"].keys).to_not include("ip_rejected")
      end
    end

  end

end
