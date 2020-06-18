# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/scan'
require 'vcreport/report/progress'
require 'vcreport/report/sample'
require 'pathname'

module VCReport
  module Report
    class << self
      # @param dir [String]
      def run(dir)
        dir = Pathname.new(dir)
        report_dir = dir / REPORT_DIR
        reports = sample_dirs(dir).map do |sample_dir|
          Report::Sample
            .run(sample_dir)
            .tap { |report| report.render(report_dir) }
        end
        Report::Progress.new(dir, reports).render(report_dir)
      end

      private

      # @param dir [Pathname]
      # @return    [Array<Pathname>]
      def sample_dirs(dir)
        results_dir = dir / RESULTS_DIR
        Dir[results_dir / '*']
          .map { |e| Pathname.new(e) }
          .select(&:directory?)
      end
    end
  end
end
