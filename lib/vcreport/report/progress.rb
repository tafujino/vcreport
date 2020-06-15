# frozen_string_literal: true

require 'vcreport/report/sample'
require 'vcreport/report/render'
require 'pathname'
require 'fileutils'

module VCReport
  module Report
    class Progress
      PREFIX = 'progress'

      include Render

      # @return [Pathname]
      attr_reader :results_dir

      # @return [Array<Report::Sample>]
      attr_reader :sample_reports

      # @param results_dir    [Pathname]
      # @param sample_reports [Array<Report::Sample>]
      def initialize(results_dir, sample_reports)
        @results_dir = results_dir
        @sample_reports = sample_reports.sort_by(&:end_time).reverse
      end

      # @param report_dir [Pathname]
      def render(report_dir)
        report_dir = Pathname.new(report_dir)
        FileUtils.mkpath report_dir unless File.exist?(report_dir)
        render_markdown(PREFIX, report_dir)
        render_html(PREFIX, report_dir)
      end
    end
  end
end
