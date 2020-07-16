# frozen_string_literal: true

require 'vcreport/settings'
require 'pathname'
require 'erb'
require 'rake'
require 'webrick'

module VCReport
  module WebServer
    TEMPLATE_DIR = 'web_server'

    class << self
      # @param dir  [Pathname]
      # @param port [Integer]
      def start(dir, port)
        server = WEBrick::HTTPServer.new(
          DocumentRoot: dir / REPORT_DIR,
          Port: port
        )
        trap(:INT) { server.shutdown }
        server.start
      end
    end
  end
end
