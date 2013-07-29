require 'net/ftp'
require 'ftpd'

class FtpServer

  class Driver
    def initialize(dir)
      @dir = dir
    end

    def authenticate(user, password)
      true
    end

    def file_system(user)
      Ftpd::DiskFileSystem.new(@dir)
    end
  end

  PORT = 35372

  def self.start
    puts "starting ftp server"

    if defined?(@@server) and not @@server.nil?
      raise ArgumentError, 'The FTP server is already running'
    end

    ftp_folder = File.expand_path('./folder', File.dirname(__FILE__))
    driver = Driver.new(ftp_folder)

    @@server = Ftpd::FtpServer.new(driver)
    @@server.server_name = "FtpServer"
    @@server.log = nil
    @@server.port = PORT
    @@server.start

  rescue Exception => e
    @@server.stop if @@server
    @@server = nil
    raise e
  end

  def self.stop
    puts "stopping ftp server"
    raise ArgumentError, 'The FTP server is already stopped' if @@server.nil?
    @@server.stop
    @@server = nil
  end
end

