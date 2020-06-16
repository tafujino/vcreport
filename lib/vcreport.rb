# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/settings'
require 'vcreport/report'
require 'vcreport/metrics'
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

      desc 'report [DIRECTORY]', 'Generate reports'
      def report(dir)
        Report.run(dir)
      end

      desc 'metrics [DIRECTORY]', 'Calculate metrics'
      def metrics(dir)
        Metrics.run(dir)
      end
    end
  end
end
