# frozen_string_literal: true

require 'vcreport/report/vcf_collection'
require 'vcreport/report/cram'
require 'vcreport/report/render'
require 'vcreport/report/table'
require 'fileutils'
require 'pathname'

module VCReport
  module Report
    class Sample
      PREFIX = 'report'

      # @return [String] sample name
      attr_reader :name

      # @return [Time, nil] workflow end time
      attr_reader :end_time

      # @return [VcfCollection]
      attr_reader :vcf_collection

      # @return [Cram, nil]
      attr_reader :cram

      # @param name           [String]
      # @param end_time       [Time, nil]
      # @param vcf_collection [VcfCollection]
      # @param cram           [Cram]
      def initialize(name, end_time = nil, vcf_collection = nil, cram = nil)
        @name = name
        @end_time = end_time
        @vcf_collection = vcf_collection
        @cram = cram
      end

      # @param report_dir [String]
      def render(report_dir)
        report_dir = Pathname.new(report_dir)
        out_dir = report_dir / @name
        FileUtils.mkpath out_dir unless File.exist?(out_dir)
        render_params = { render_toc: true, toc_nesting_level: TOC_NESTING_LEVEL }
        Render.run(PREFIX, out_dir, binding, **render_params)
      end
    end
  end
end
