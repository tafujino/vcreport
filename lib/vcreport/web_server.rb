# frozen_string_literal: true

require 'vcreport/settings'
require 'pathname'
require 'erb'
require 'rake'
require 'posix/spawn'

module VCReport
  module WebServer
    TEMPLATE_DIR = 'web_server'

    class << self
      # @param dir  [Pathname]
      # @param port [Integer]
      def start(dir, port)
        config_path = create_config_file(dir, port)
        execute("#{NGINX_PATH} -c #{config_path}", port)
      end

      private

      # @param dir  [Pathname]
      # @param port [Integer]
      def create_config_file(dir, port)
        conf_path = dir / NGINX_CONF_FILENAME
        conf_dir = conf_path.dirname
        FileUtils.mkpath(conf_dir) unless File.exist?(conf_dir)
        access_log_path = dir / ACCESS_LOG_FILENAME
        template_path = Pathname.new(TEMPLATE_DIR) /
                        "#{File.basename(NGINX_CONF_FILENAME)}.erb"
        template_path = File.expand_path(template_path, __dir__)
        report_dir = dir / REPORT_DIR
        erb = ERB.new(File.read(template_path), trim_mode: '-')
        str = erb.result(binding)
        File.write(conf_path, str)
        conf_path
      end

      # @param cmd  [String]
      # @param port [Integer]
      def execute(cmd, port)
        pid = POSIX::Spawn.spawn(cmd)
        warn "Started a web server (pid = #{pid})"
        warn "Access http://localhost:#{port}/ for a report"
        Process.waitpid(pid)
      end
    end
  end
end
