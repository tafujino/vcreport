# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/settings'
require 'vcreport/report'
require 'vcreport/daemon'
require 'vcreport/process_info'
require 'thor'

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
             default: DEFAULT_METRICS_NUM_THREADS
      option 'interval',
             aliases: 'i',
             type: :numeric,
             desc: 'Monitoring interval (seconds)',
             default: Daemon::DEFAULT_METRICS_INTERVAL
      option 'samples-per-page',
             aliases: 's',
             type: :numeric,
             desc: 'Number of samples per page',
             default: Report::DEFAULT_NUM_SAMPLES_PER_PAGE
      def start(dir)
        metrics_manager = MetricsManager.new(options['threads'])
        Daemon.start(dir, metrics_manager, options['interval'])
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
        ps = Daemon.status(dir)
        if ps
          pid_message = "(pid = #{ps.pid}, pgid = #{ps.pgid})"
          say_status 'running', "#{dir} (#{pid_message})", :green
        else
          say_status 'not running', dir, :green
        end
      end

      desc 'render [DIRECTORY]', 'Generate reports'
      option 'samples-per-page',
             aliases: 's',
             type: :numeric,
             desc: 'Number of samples per page',
             default: Report::DEFAULT_NUM_SAMPLES_PER_PAGE
      def render(dir)
        Report.run(dir)
      end

      desc 'metrics [DIRECTORY]', 'Calculate metrics'
      option 'threads',
             aliases: 't',
             type: :numeric,
             desc: 'Number of threads for metrics calculation',
             default: DEFAULT_METRICS_NUM_THREADS
      def metrics(dir)
        metrics_manager = MetricsManager.new(options['threads'])
        Report.run(dir, metrics_manager, render: false)
        metrics_manager.wait
      end
    end
  end
end
