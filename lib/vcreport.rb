# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/settings'
require 'vcreport/report'
require 'vcreport/daemon'
require 'thor'

module VCReport
  module CLI
    class Main < Thor
      def self.exit_on_failure?
        true
      end

      desc 'start [DIRECTORY]', 'Start a daemon'
      option 'threads',  aliases: 't', type: :numeric, desc: 'number of threads for metrics calculation'
      option 'interval', aliases: 'i', type: :numeric, desc: 'monitoring interval (seconds)'
      def start(dir)
        say_status 'start', dir, :green
        num_threads = options['num-threads'] || DEFAULT_METRICS_NUM_THREADS
        metrics_interval = options['interval'] || Daemon::DEFAULT_METRICS_INTERVAL
        metrics_manager = MetricsManager.new(num_threads)
        Daemon.start(dir, metrics_manager, metrics_interval)
      end

      desc 'stop [DIRECTORY]', 'Stop a daemon'
      def stop(dir)
        case Daemon.stop(dir)
        when :success
          say_status 'stop', dir, :green
        when :not_running
          say_status 'not running', dir, :yellow
        when :fail
          say_status 'fail', dir, :red
        else
          warn 'Unexpected error.'
          exit 1
        end
      end

      desc 'status [DIRECTORY]', 'Show daemon status'
      def status(dir)
        ps = Daemon.status(dir)
        if ps
          pid_message = "(pid = #{ps[:pid]}, pgid = #{ps[:pgid]})"
          say_status 'running', "#{dir} (#{pid_message})", :green
        else
          say_status 'not running', dir, :green
        end
      end

      desc 'render [DIRECTORY]', 'Generate reports'
      def render(dir)
        Report.run(dir)
      end

      desc 'metrics [DIRECTORY]', 'Calculate metrics'
      option 'threads', aliases: 't', type: :numeric, desc: 'number of threads for metrics calculation'
      def metrics(dir)
        num_threads = options['num-threads'] || DEFAULT_METRICS_NUM_THREADS
        metrics_manager = MetricsManager.new(num_threads)
        Report.run(dir, metrics_manager, render: false)
        metrics_manager.wait
      end
    end
  end
end
