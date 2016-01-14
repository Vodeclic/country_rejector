require 'spec_helper'

describe CountryRejector do
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
    before do
      CountryRejector::Middleware.configure do |config|
        config.banned_list = ["CU", "BAD_COUNTRY"]
        config.country_detector = lambda {|ip| "FR" }
      end
    end

    # App is the second middleware that return allways 200 OK
    let(:last_middleware) { lambda {|env| [200, env, ['OK']]} }

    # subject is the tested middleware, with the next middleware on first param
    subject { CountryRejector::Middleware.new(last_middleware) }

    # request is our fake request with our custom rack stack
    let(:request) { Rack::MockRequest.new(subject) }

    context "not banned countries" do
      it "is expected to set ip_rejected to false"do
        response = request.get("/", {"rack.session" => {}, "HTTP_X_REAL_IP" => "80.11.77.16"})
        expect(response.headers["rack.session"].keys).to include("ip_rejected")
        expect(response.headers["rack.session"]["ip_rejected"]).to eq(false)
      end

      it "should accept requests if HTTP_X_REAL_IP variable is not set" do
        response = request.get("/", {"rack.session" => {}})
        expect(response.headers["rack.session"].keys).to include("ip_rejected")
        expect(response.headers["rack.session"]["ip_rejected"]).to eq(false)
      end

      it "should not call country_detector if ip_rejected is set" do
        CountryRejector::Middleware.configure do |config|
          config.country_detector = lambda {|ip| raise "The Lambda was call" }
        end
        expect {
          request.get("/", {"rack.session" => {"ip_rejected" => false}, "HTTP_X_REAL_IP" => "175.45.177.50"})
        }.to_not raise_error
      end

      it "should call country_detector if ip_rejected is NOT set" do
        CountryRejector::Middleware.configure do |config|
          config.country_detector = lambda {|ip| raise "The Lambda was call" }
        end
        expect {
          request.get("/", {"rack.session" => {}, "HTTP_X_REAL_IP" => "175.45.177.50"})
        }.to raise_error("The Lambda was call")
      end
    end

    context "banned country" do
      before(:each) do
        CountryRejector::Middleware.configure do |config|
          config.country_detector = lambda {|ip| "CU" }
        end
      end

      it "should return a 403" do
        response = request.get("/", {"rack.session" => {}})
        expect(response.status).to eq 403
      end

      it "should not call country_detector if ip_rejected is set" do
        expect(CountryRejector::Configuration).to_not receive(:call)
        response = request.get("/", {"rack.session" => {"ip_rejected" => true}})
        expect(response.status).to eq 403
      end
    end
  end

end
