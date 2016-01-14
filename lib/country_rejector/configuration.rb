module CountryRejector
  class Configuration
    attr_accessor :banned_list, :country_detector, :env_ip_tag, :timeout_ms

    def initialize
      @banned_list = []
      @country_detector = lambda {|ip| ::TZInfo::detect_country(ip) }
      @env_ip_tag = "HTTP_X_REAL_IP"
      @timeout_ms = 1
    end
  end
end