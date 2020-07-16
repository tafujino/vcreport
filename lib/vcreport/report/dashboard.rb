# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'vcreport/settings'
require 'vcreport/chr_region'
require 'vcreport/report/render'
require 'vcreport/report/sample'
require 'vcreport/report/c3js'
require 'pathname'
require 'fileutils'

module VCReport
  module Report
    class Dashboard
      PREFIX = 'dashboard'
      COVERAGE_STATS_TYPES = {
        mean: 'mean', sd: 'SD', median: 'median', mad: 'MAD'
      }.freeze
      X_AXIS_LABEL_HEIGHT = 100

      # @param samples [Array<Sample>]
      # @param config  [Config]
      def initialize(samples, config)
        @samples = samples.sort_by(&:end_time).reverse
        @config = config
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
        [
          D3_JS_PATH,
          C3_JS_PATH,
          C3_CSS_PATH,
          GITHUB_MARKDOWN_CSS_PATH
        ].each do |src_path|
          Render.copy_file(src_path, report_dir)
        end
        Render.run(
          PREFIX,
          report_dir,
          binding,
          toc_nesting_level: DASHBOARD_TOC_NESTING_LEVEL
        )
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
        tstv_col = C3js::Column.new(:ts_tv_ratio, 'ts/tv')
        ts_tv_ratio.then do |data|
          @config.vcf.chr_regions.map.to_h do |chr_region|
            json = data.select(chr_region: chr_region)
                     .bar_chart_json(
                       @sample_col,
                       tstv_col,
                       bindto: "tstv_#{chr_region.id}",
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
            h = COVERAGE_STATS_TYPES.keys.map.to_h do |type|
              [type, e.coverage_stats.send(type)]
            end
            h.merge(sample_name: sample.name,
                    chr_region: e.chr_region)
          end
        end.then { |a| C3js::Data.new(a) }
      end

      # @return [Hash{ ChrRegion => Hash{ Symbol => String } }]
      def coverage_stats_json
        coverage_stats_cols = COVERAGE_STATS_TYPES.map do |id, label|
          C3js::Column.new(id, label)
        end
        intervals = @config.metrics.picard_collect_wgs_metrics.intervals
        coverage_stats.then do |data|
          intervals.map.to_h do |chr_region|
            coverage_stats_cols.map.to_h do |col|
              bindto = "coverage_stats_#{chr_region.id}_#{col.id}"
              json = data.select(chr_region: chr_region)
                       .bar_chart_json(
                         @sample_col,
                         col,
                         bindto: bindto,
                         **@default_chart_params
                       )
              [col, json]
            end.then do |jsons_of_chr_region|
              [chr_region, jsons_of_chr_region]
            end
          end
        end
      end
    end
  end
end
