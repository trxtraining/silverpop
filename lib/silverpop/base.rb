module Silverpop

  def self.configure
    yield(Silverpop::Base)
  end

  class Base

    extend Forwardable

    def_delegators :'self.class', :url, :ftp_url, :ftp_port, :log
    def_delegators :'self.class', :username, :password, :ftp_username, :ftp_password

    class << self

      def setup_urls(pod)
        Engage.url = "https://api#{pod}.silverpop.com/XMLAPI"
        Engage.ftp_url = "transfer#{pod}.silverpop.com"
        Engage.ftp_port = nil # need for testing

        Transact.url = "https://transact#{pod}.silverpop.com/XTMail"
        Transact.ftp_url = "transfer#{pod}.silverpop.com"
      end

      def engage_username=(username)
        Engage.username = username
      end

      def engage_password=(password)
        Engage.password = password
      end

      def engage_ftp_username=(username)
        Engage.ftp_username = username
      end

      def engage_ftp_password=(password)
        Engage.ftp_password = password
      end

      def transact_username=(username)
        Transact.username = username
      end

      def transact_password=(password)
        Transact.password = password
      end

      attr_accessor :logger

      def log(*args)
        level = args.first.is_a?(Symbol) ? args.first : :error
        logger.send(level, *args[1..-1]) if logger
      end
    end

    def query(xml, session_encoding='')
      u = URI.parse url
      http, resp    = Net::HTTP.new(u.host, u.port), ''
      http.use_ssl  = true
      http.start do |http|
        path = u.path + session_encoding
        resp = http.post path, xml, {'Content-type' => 'text/xml'}
      end
      resp.body
    end

    def strip_cdata string
      string.sub('<![CDATA[', '').sub(']]>', '')
    end

    private

    def on_job_ready(job_id)
      while ['WAITING', 'RUNNING'].include? (status = get_job_status(job_id))
        puts "#{Time.now} Job #{job_id}: #{status}"
        sleep 5
      end
      puts "#{Time.now} Job #{job_id}: #{status}"

      if status == 'COMPLETE'
        yield
      else
        raise ArgumentError, "#{status} status, Silverpop service didn't finish #{job_id} job"
      end
    end
  end
end