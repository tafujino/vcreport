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
        vcrepd_path = File.expand_path('vcrepd', File.dirname($PROGRAM_NAME))
        say 'Start a report daemon'
        say "Data directory: #{data_dir}"
        say "Report directory: #{report_dir}"
        pid = spawn "#{vcrepd_path} #{data_dir} #{report_dir} 2>&1 > /dev/null"
        Process.detach(pid)
      end

      desc 'stop [DIRECTORY]', 'Stop a daemon'
      def stop(dir)
      end

      desc 'report [DIRECTORY]', 'Generate reports'
      def report(dir)
        Report.run(dir)
      end

      desc 'metrics [DIRECTORY]', 'Calculate metrics'
      def stats(dir)
        Metrics.run(dir)
      end
    end
  end
end
