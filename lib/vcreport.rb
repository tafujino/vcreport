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

      desc 'start [DATA_DIR] [REPORT_DIR]', 'Start reporting'
      def start(data_dir, report_dir)
        vcrepd_path = File.expand_path('vcrepd', File.dirname($PROGRAM_NAME))
        pp vcrepd_path
        say 'Start a report daemon'
        say "Data directory: #{data_dir}"
        say "Report directory: #{report_dir}"
        ret = system "#{vcrepd_path} #{data_dir} #{report_dir}"
        unless ret
          warn 'Report dameon failed'
          exit 1
        end
      end

      desc 'stop [DATA_DIR]', 'Stop reporting'
      def stop(data_dir)
      end

      desc 'generate [DATA_DIR] [REPORT_DIR]', 'Generate reports'
      def generate(data_dir, report_dir)
        Generate.run(data_dir, report_dir)
      end
    end
  end
end
