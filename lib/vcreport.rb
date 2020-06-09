# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/daemon'
require 'vcreport/generate'
require 'thor'

module VCReport
  module CLI
    class Main < Thor
      def self.exit_on_failure?
        true
      end

      desc 'start [DATA_DIR] [REPORT_DIR]', 'Start a report daemon'
      def start(data_dir, report_dir)
        vcrepd_path = File.expand_path('vcrepd', File.dirname($PROGRAM_NAME))
        say 'Start a report daemon'
        say "Data directory: #{data_dir}"
        say "Report directory: #{report_dir}"
        pid = spawn "#{vcrepd_path} #{data_dir} #{report_dir} 2>1 > /dev/null"
        Process.detach(pid)
      end

      desc 'list', 'list running daemons'
      def list
        warn %w[PID DATA_DIR REPORT_DIR].join("\t")
        processes.each do |pid, data_dir, report_dir|
          warn [pid, data_dir, report_dir].join("\t")
        end
      end

      desc 'stop [DATA_DIR]', 'Stop a report daemon'
      def stop(data_dir)
      end

      desc 'generate [DATA_DIR] [REPORT_DIR]', 'Generate reports'
      def generate(data_dir, report_dir)
        Generate.run(data_dir, report_dir)
      end
    end
  end
end
