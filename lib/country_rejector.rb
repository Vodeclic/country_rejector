####################################
#  Country      : Code  : Example IP
#
#  Cuba         : CU    : 152.206.0.1
#  Iran         : IR    : 2.144.0.1
#  North Korea  : KP    : 175.45.177.50
#  Sudan        : SD    : 41.223.163.93
#  Syria        : SY    : 77.44.210.15
#
#  We rely on nginx!!
#   -> env["HTTP_X_REAL_IP"] should be set
#
####################################

require "country_rejector/version"
require "country_rejector/configuration"

module CountryRejector
  class Middleware
    ############## class methods
    class << self
      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Configuration.new
      end
    end

    ############## instance methods
    def initialize(app)
      @app = app
    end

    def call(env)
      return reject_request if banned?(env)
      @app.call(env)
    end

    def configuration
      self.class.configuration
    end

  private

    def banned?(env)
      return env["rack.session"]["ip_rejected"] if env["rack.session"].has_key?("ip_rejected")
      current_country = configuration.country_detector.call(env[configuration.env_ip_tag])
      env["rack.session"]["ip_rejected"] = configuration.banned_list.include?(current_country)
    end

    def reject_request
      [403, {"Content-Type" => "text/plain"}, ["Forbidden Access"]]
    end
  end
end
