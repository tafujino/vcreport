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
      def start(dir)
        say_status 'start', dir, :green
        metrics_manager = MetricsManager.new(METRICS_NUM_THREADS)
        Signal.trap(:TERM) do
          metrics_manager.stop
          exit 143
        end
        Daemon.run(dir, metrics_manager)
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
          warn 'Unexpected error'
          exit 1
        end
      end

      desc 'status [DIRECTORY]', 'Show daemon status'
      def status(dir)
        pid = Daemon.status(dir)
        if pid
          say_status 'running', "#{dir} (pid = #{pid})", :green
        else
          say_status 'not running', dir, :green
        end
      end

      desc 'render [DIRECTORY]', 'Generate reports'
      def render(dir)
        Report.run(dir)
      end

      desc 'metrics [DIRECTORY]', 'Calculate metrics'
      def metrics(dir)
        metrics_manager = MetricsManager.new(METRICS_NUM_THREADS)
        Report.run(dir, metrics_manager, render: false)
        metrics_manager.wait
      end
    end
  end
end
