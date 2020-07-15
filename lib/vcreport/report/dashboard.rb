# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'vcreport/settings'
require 'vcreport/chr_region'
require 'vcreport/report/render'
require 'vcreport/report/sample'
require 'vcreport/report/c3js'
require 'fileutils'
require 'pathname'

module VCReport
  module Report
    class Dashboard
      PREFIX = 'dashboard'
      COVERAGE_STATS_TYPES = %i[mean sd median mad].freeze
      X_AXIS_LABEL_HEIGHT = 100

      # @param samples     [Array<Sample>]
      # @param chr_regions [Array<ChrRegion>]
      def initialize(samples, chr_regions)
        @samples = samples.sort_by(&:end_time).reverse
        @chr_regions = chr_regions
        @sample_col = C3js::Column.new(:sample_name, 'sample name')
        @default_chart_params = {
          x: @sample_col,
          x_axis_label_height: X_AXIS_LABEL_HEIGHT
        }
      end

      # @param report_dir [String]
      # @return           [Pathname] HTML path
      def render(report_dir)
        report_dir = Pathname.new(report_dir)
        FileUtils.mkpath report_dir unless File.exist?(report_dir)
        Render.run(PREFIX, report_dir, binding, toc_nesting_level: TOC_NESTING_LEVEL)
      end

      private

      # @return [C3js::Data]
      def ts_tv_ratio
        @samples.flat_map do |sample|
          sample.vcf_collection.vcfs.map do |vcf|
            {
              sample_name: sample.name,
              chr_region: vcf.chr_region,
              ts_tv_ratio: vcf.bcftools_stats&.ts_tv_ratio
            }
          end
        end.then { |a| C3js::Data.new(a) }
      end

      # @return [Hash{ ChrRegion => String }]
      def ts_tv_ratio_json
        ts_tv_ratio.then do |data|
          tstv_col = C3js::Column.new(:ts_tv_ratio, 'ts/tv')
          @chr_regions.map.to_h do |chr_region|
            json = data.select(chr_region: chr_region)
                     .bar_chart_json(
                       @sample_col,
                       tstv_col,
                       bindto: chr_region.id,
                       **@default_chart_params
                     )
            [chr_region, json]
          end
        end
      end

      # @return [C3js::Data]
      def coverage_stats
        @samples.flat_map do |sample|
          sample
            .cram
            .picard_collect_wgs_metrics_collection
            .picard_collect_wgs_metrics.map do |e|
            h = COVERAGE_STATS_TYPES.map.to_h do |type|
              [type, e.coverage_stats.send(type)]
            end
            h.merge(sample_name: sample.name,
                    chr_region: e.chr_region)
          end
        end.then { |a| C3js::Data.new(a) }
      end
    end
  end
end
