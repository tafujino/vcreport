# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/settings'
require 'vcreport/report'
require 'vcreport/monitor'
require 'vcreport/web_server'
require 'vcreport/process_info'
require 'vcreport/job_manager'
require 'thor'
require 'mono_logger'

module VCReport
  class << self
    # @param dir [String, Pathname]
    # @return    [Pathname]
    def initialize_dir(dir)
      dir = Pathname.new(dir).expand_path
      system_dir = dir / SYSTEM_DIR
      FileUtils.mkpath system_dir unless File.exist?(system_dir)
      dir
    end
  end

  module CLI
    class MonitorCommand < Thor
      desc 'start [DIRECTORY]', 'Start a monitoring daemon'
      option 'threads',
             aliases: 't',
             type: :numeric,
             desc: 'Number of threads for metrics calculation',
             default: JOB_DEAULT_NUM_THREADS
      option 'interval',
             aliases: 'i',
             type: :numeric,
             desc: 'Monitoring interval (seconds)',
             default: VCReport::Monitor::DEFAULT_INTERVAL
      def start(dir)
        dir = VCReport.initialize_dir(dir)
        config = Config.load(dir)
        num_threads = options['threads']
        logger = MonoLogger.new(dir / METRICS_LOG_FILENAME)
        job_manager = JobManager.new(num_threads, logger)
        Monitor.start(dir, config, job_manager, options['interval'])
      end

      desc 'stop [DIRECTORY]', 'Stop a monitoring daemon'
      def stop(dir)
        dir = VCReport.initialize_dir(dir)
        case Monitor.stop(dir)
        when :success
          say_status 'stop', dir, :green
        when :not_running
          say_status 'not running', dir, :yellow
          exit 1
        when :fail
          say_status 'fail', dir, :red
          exit 1
        else
          warn 'Unexpected error.'
          exit 1
        end
      end

      desc 'status [DIRECTORY]', 'Show the status of monitoring daemon'
      def status(dir)
        dir = VCReport.initialize_dir(dir)
        psinfo = Monitor.status(dir)
        if psinfo
          pid_message = "pid = #{psinfo.pid}, pgid = #{psinfo.pgid}"
          say_status 'running', "#{dir} (#{pid_message})", :green
        else
          say_status 'not running', dir, :green
        end
      end
    end

    class Main < Thor
      def self.exit_on_failure?
        true
      end

      desc 'monitor [COMMAND]', 'Manage a monitoring daemon'
      subcommand :monitor, MonitorCommand

      desc 'http [COMMAND]', 'Start a web server'
      option 'port',
             aliases: 'p',
             type: :numeric,
             desc: 'Port number',
             default: WebServer::DEFAULT_PORT
      def http(dir)
        dir = VCReport.initialize_dir(dir)
        port = options['port'].to_i
        WebServer.start(dir, port)
      end

      desc 'render [DIRECTORY]', 'Generate reports'
      def render(dir)
        dir = VCReport.initialize_dir(dir)
        config = Config.load(dir)
        Report.run(dir, config)
      end

      desc 'metrics [DIRECTORY]', 'Calculate metrics'
      option 'threads',
             aliases: 't',
             type: :numeric,
             desc: 'Number of threads for metrics calculation',
             default: JOB_DEAULT_NUM_THREADS
      def metrics(dir)
        dir = VCReport.initialize_dir(dir)
        config = Config.load(dir)
        num_threads = options['threads']
        logger = MonoLogger.new(dir / METRICS_LOG_FILENAME)
        job_manager = JobManager.new(num_threads, logger)
        Report.run(dir, config, job_manager, render: false)
        job_manager.terminate
      end
    end
  end
end
