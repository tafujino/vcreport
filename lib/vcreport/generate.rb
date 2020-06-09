# frozen_string_literal: true

require 'vcreport/progress_report'
require 'vcreport/sample_report'
require 'pathname'

module VCReport
  module Generate
    class << self
      # @param data_dir [String]
      # @param report_dir [String]
      def run(data_dir, report_dir)
        data_dir = Pathname.new(data_dir)
        report_dir = Pathname.new(report_dir)
        sample_dirs = scan_sample_directories(data_dir)
        reports = sample_dirs.map do |sample_dir|
          SampleReport
            .run(sample_dir)
            .tap { |report| report.render(report_dir) }
        end
        ProgressReport.new(data_dir, reports).render(report_dir)
      end

      private

      # @param data_dir [Pathname]
      # @return         [Array<Pathname>]
      def scan_sample_directories(data_dir)
        Dir[data_dir / '*']
          .map { |e| Pathname.new(e) }
          .select(&:directory?)
      end
    end
  end
end
