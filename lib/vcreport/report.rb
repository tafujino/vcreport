# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/report/progress'
require 'vcreport/report/sample'
require 'vcreport/metrics_manager'

require 'pathname'

module VCReport
  module Report
    class << self
      # @param dir             [String]
      # @param metrics_manager [MetricsManager, nil]
      def run(dir, metrics_manager = nil)
        dir = Pathname.new(dir)
        report_dir = dir / REPORT_DIR
        reports = sample_dirs(dir).map do |sample_dir|
          Report::Sample
            .run(sample_dir, metrics_manager)
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
