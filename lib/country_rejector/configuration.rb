module CountryRejector
  class Configuration
    attr_accessor :banned_list, :country_detector, :env_ip_tag, :timeout_ms

    def initialize
      @banned_list = []
      @country_detector = ::CountryRejector::Processor
      @env_ip_tag = "HTTP_X_REAL_IP"
      @timeout_ms = 500
    end
  end
end