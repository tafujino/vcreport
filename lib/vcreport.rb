# frozen_string_literal: true

require 'vcreport/version'
require 'thor'

module VCReport
  module CLI
    class Main < Thor
      def self.exit_on_failure?
        true
      end

      desc 'start [DATA_DIR] [REPORT_DIR]', 'Start reporting'
      def start(data_dir, report_dir)
      end

      desc 'stop [DATA_DIR]', 'Stop reporting'
      def stop(data_dir)
      end
    end
  end
end
