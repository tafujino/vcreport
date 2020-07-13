# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/settings'
require 'vcreport/report'
require 'vcreport/daemon'
require 'vcreport/process_info'
require 'vcreport/job_manager'
require 'thor'

module VCReport
  class << self
    def prepare_system_dir(dir)
      dir = Pathname.new(dir)
      system_dir = dir / SYSTEM_DIR
      FileUtils.mkpath system_dir unless File.exist?(system_dir)
    end
  end

  module CLI
    class Monitor < Thor
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
             default: Daemon::DEFAULT_INTERVAL
      def start(dir)
        VCReport.prepare_system_dir(dir)
        config = Config.load(dir)
        num_threads = options['threads']
        logger = Logger.new(METRICS_LOG_FILENAME)
        job_manager = JobManager.new(num_threads, logger)
        Daemon.start(dir, config, job_manager, options['interval'])
      end

      desc 'stop [DIRECTORY]', 'Stop a monitoring daemon'
      def stop(dir)
        case Daemon.stop(dir)
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
        prepare_system_dir(dir)
        psinfo = Daemon.status(dir)
        if psinfo
          pid_message = "pid = #{psinfo.pid}, pgid = #{psinfo.pgid}"
          say_status 'running', "#{dir} (#{pid_message})", :green
        else
          say_status 'not running', dir, :green
        end
      end
    end

    class Http < Thor
    end

    class Main < Thor
      def self.exit_on_failure?
        true
      end

      desc 'monitor [COMMAND]', 'Manage a monitoring daemon'
      subcommand :monitor, Monitor

      desc 'http [COMMAND]', 'Manage a web server'
      subcommand :http, Http

      desc 'render [DIRECTORY]', 'Generate reports'
      def render(dir)
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
        dir = Pathname.new(dir)
        VCReport.prepare_system_dir(dir)
        config = Config.load(dir)
        num_threads = options['threads']
        logger = Logger.new(dir / METRICS_LOG_FILENAME)
        job_manager = JobManager.new(num_threads, logger)
        Report.run(dir, config, job_manager, render: false)
        job_manager.terminate
      end
    end
  end
end
