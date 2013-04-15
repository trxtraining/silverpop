require 'logger' 

module Silverpop

  class Base

    class << self
      attr_accessor :logger
    end
    
    self.logger = defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER : Logger.new(STDERR)

    def initialize(api_post_url)
      @api_post_url = api_post_url
    end
    
    def query(xml, session_encoding='')
      url = URI.parse @api_post_url
      http, resp    = Net::HTTP.new(url.host, url.port), ''
      http.use_ssl  = true
      http.start do |http|
        path = url.path + session_encoding
        resp = http.post path, xml, {'Content-type' => 'text/xml'}
      end
      resp = resp.body
    end

    def strip_cdata string
      string.sub('<![CDATA[', '').sub(']]>', '')
    end

  end

end