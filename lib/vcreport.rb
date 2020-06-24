# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/settings'
require 'vcreport/report'
require 'thor'

module VCReport
  module CLI
    class Main < Thor
      def self.exit_on_failure?
        true
      end

      desc 'start [DIRECTORY]', 'Start a daemon'
      def start(dir)
        say 'Start a report daemon'
        say "Directory: #{dir}"
      end

      desc 'stop [DIRECTORY]', 'Stop a daemon'
      def stop(dir)
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
