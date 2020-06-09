# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/daemon'
require 'vcreport/generate'
require 'thor'
require 'rake'

module VCReport
  module CLI
    class Main < Thor
      extend Rake::DSL

      def self.exit_on_failure?
        true
      end

      desc 'start [DATA_DIR] [REPORT_DIR]', 'Start reporting'
      def start(data_dir, report_dir)
        vcrepd_path = File.expand_path('vcrepd', __dir__)
        sh "#{vcrepd_path} #{data_dir} #{report_dir}"
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
