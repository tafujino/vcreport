# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/report/progress'
require 'vcreport/report/sample'
require 'pathname'

module VCReport
  module Report
    class << self
      # @param dir [String]
      def run(dir)
        dir = Pathname.new(dir)
        sample_dirs = scan_sample_directories(dir / RESULTS_DIR)
        report_dir = dir / REPORT_DIR
        reports = sample_dirs.map do |sample_dir|
          Report::Sample
            .run(sample_dir)
            .tap { |report| report.render(report_dir) }
        end
        Report::Progress.new(dir, reports).render(report_dir)
      end

      private

      # @param results_dir [Pathname]
      # @return            [Array<Pathname>]
      def scan_sample_directories(results_dir)
        Dir[results_dir / '*']
          .map { |e| Pathname.new(e) }
          .select(&:directory?)
      end
    end
  end
end
