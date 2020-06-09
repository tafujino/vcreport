# frozen_string_literal: true

require 'vcreport/sample_report'
require 'vcreport/render'
require 'pathname'
require 'fileutils'

module VCReport
  class ProgressReport
    PREFIX = 'progress'

    include Render

    # @return [Pathname]
    attr_reader :data_dir

    # @return [Array<SampleReport>]
    attr_reader :sample_reports

    # @param data_dir       [Pathname]
    # @param sample_reports [Array<SampleReport>]
    def initialize(data_dir, sample_reports)
      @data_dir = data_dir.expand_path
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
