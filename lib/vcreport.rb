# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/settings'
require 'vcreport/report'
require 'vcreport/daemon'
require 'vcreport/process_info'
require 'vcreport/job_manager'
require 'thor'

require 'active_support'
require 'active_support/core_ext/numeric/conversions'

module VCReport
  module CLI
    class Main < Thor
      def self.exit_on_failure?
        true
      end

      desc 'start [DIRECTORY]', 'Start a daemon'
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
        config = Config.load(dir)
        job_manager = JobManager.new(options['threads'])
        Daemon.start(dir, config, job_manager, options['interval'])
      end

      desc 'stop [DIRECTORY]', 'Stop a daemon'
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

      desc 'status [DIRECTORY]', 'Show daemon status'
      def status(dir)
        psinfo = Daemon.status(dir)
        if psinfo
          pid_message = "pid = #{psinfo.pid}, pgid = #{psinfo.pgid}"
          say_status 'running', "#{dir} (#{pid_message})", :green
        else
          say_status 'not running', dir, :green
        end
      end

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
        config = Config.load(dir)
        job_manager = JobManager.new(options['threads'])
        Report.run(dir, config, job_manager, render: false)
        job_manager.wait
      end
    end
  end
end
