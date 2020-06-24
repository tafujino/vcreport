# frozen_string_literal: true

require 'vcreport/settings'
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
        num_samples_per_page = DEFAULT_NUM_SAMPLES_PER_PAGE
        slices = @sample_reports.each_slice(num_samples_per_page).to_a
        num_slices = slices.length
        slices.each.with_index(1) do |slice_reports, page_num|
          paging = Paging.new(page_num, num_slices)
          # @slice_reports are passed to ERB
          @slice_reports = slice_reports
          render_markdown(PREFIX, report_dir, paging: paging)
          render_html(PREFIX, report_dir, paging: paging)
        end
      end
    end
  end
end
