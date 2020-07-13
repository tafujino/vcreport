# frozen_string_literal: true

require 'vcreport/settings'
require 'pathname'

module VCReport
  module Report
    class Index
      PREFIX = 'index'

      # @param results_dir              [Pathname]
      # @param progress_front_html_path [Pathname]
      def initialize(results_dir, progress_front_html_path)
        @results_dir = results_dir
        @progress_front_html_path = progress_front_html_path
      end

      # @param report_dir [Pathname]
      # @return           [Array<Pathname>] HTML paths
      def render(report_dir)
        FileUtils.mkpath report_dir unless File.exist?(report_dir)
        Render.run(PREFIX, report_dir, binding)
      end
    end
  end
end