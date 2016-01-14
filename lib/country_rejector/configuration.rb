module CountryRejector
  class Configuration
    attr_accessor :banned_list, :country_detector, :env_ip_tag

    def initialize
      @banned_list = []
      @country_detector = lambda {|ip| ::TZInfo::detect_country(ip) }
      @env_ip_tag = "HTTP_X_REAL_IP"
    end
  end
end