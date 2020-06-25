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
        max_pages = (MAX_SAMPLES.to_f / DEFAULT_NUM_SAMPLES_PER_PAGE).ceil
        @num_digits = max_pages.digits.length
      end

      # @param report_dir           [Pathname]
      # @param num_samples_per_page [Integer]
      def render(report_dir, num_samples_per_page = DEFAULT_NUM_SAMPLES_PER_PAGE)
        FileUtils.mkpath report_dir unless File.exist?(report_dir)
        slices = @sample_reports.each_slice(num_samples_per_page).to_a
        slices.each.with_index(1) do |slice_reports, page_num|
          paging = Paging.new(page_num, slices.length, @num_digits)
          @slice_reports = slice_reports # passed to ERB
          render_markdown(PREFIX, report_dir, paging: paging)
          render_html(PREFIX, report_dir, paging: paging)
        end
      end
    end
  end
end
