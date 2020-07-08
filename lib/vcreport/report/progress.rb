# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/report/sample'
require 'vcreport/report/render'
require 'vcreport/report/paging'
require 'vcreport/report/table'
require 'pathname'
require 'fileutils'

module VCReport
  module Report
    class Progress
      PREFIX = 'progress'

      # @return [Pathname]
      attr_reader :results_dir

      # @return [Array<Sample>]
      attr_reader :samples

      # @param results_dir [Pathname]
      # @param samples     [Array<Sample>]
      def initialize(results_dir, samples)
        @results_dir = results_dir
        @samples = samples.sort_by(&:end_time).reverse
        max_pages = (MAX_SAMPLES.to_f / DEFAULT_NUM_SAMPLES_PER_PAGE).ceil
        @num_digits = max_pages.digits.length
      end

      # @param report_dir           [Pathname]
      # @param num_samples_per_page [Integer]
      def render(report_dir, num_samples_per_page = DEFAULT_NUM_SAMPLES_PER_PAGE)
        FileUtils.mkpath report_dir unless File.exist?(report_dir)
        slices = @samples.each_slice(num_samples_per_page).to_a
        slices.each.with_index(1) do |slice, page_num|
          paging = Paging.new(page_num, slices.length, @num_digits)
          table = sample_slice_to_table(slice)
          Render.run(PREFIX, report_dir, binding, paging: paging)
        end
      end

      private

      # @param slice [Array<Sample>]
      # @return      [Table]
      def sample_slice_to_table(slice)
        header = ['name', 'end time']
        type = %i[string string]
        rows = slice.map do |sample|
          name = markdown_link_text(sample.name, "#{sample.name}/report.html")
          [name, sample.end_time]
        end
        Table.new(header, rows, type)
      end

      # @param prefix [String]
      # @param paging [Paging]
      # @return       [String]
      def navigation_markdown_text(prefix, paging)
        prev_text, next_text = %w[prev next].map do |nav|
          digits = paging.send(nav)&.digits
          if digits
            markdown_link_text(nav, "#{prefix}#{digits}.html")
          else
            nav
          end
        end
        "\< #{prev_text} \| #{next_text} \>"
      end

      # @param text [String]
      # @param path [String, Pathname]
      def markdown_link_text(text, path)
        "[#{text}](#{path})"
      end
    end
  end
end
