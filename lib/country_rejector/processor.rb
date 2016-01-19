module CountryRejector
  class Processor
    class << self
      def call(ip)
        nil # return a string with city code like "FR" or return nil if not found
      end
    end
  end
end