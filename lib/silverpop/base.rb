require 'logger' 

module Silverpop

  class Base

    class << self
      attr_accessor :logger
    end

    attr_reader :engage, :username, :password, :ftp_username, :ftp_password

    def initialize(pod, username, password, ftp_username, ftp_password)
      @ftp = "transfer#{pod}.silverpop.com"

      @username, @password = username, password
      @ftp_username, @ftp_password = ftp_username, ftp_password
    end
    
    def query(xml, session_encoding='')
      url = URI.parse @url
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