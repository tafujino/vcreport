# frozen_string_literal: true

require 'vcreport/chr_region'
require 'vcreport/report/render'
require 'vcreport/report/sample'
require 'fileutils'
require 'pathname'

module VCReport
  module Report
    class Dashboard
      PREFIX = 'dashboard'

      # @param samples [Array<Sample>]
      def initialize(samples)
        @samples = samples
        pp coverage_stats
      end

      # @param report_dir [String]
      # @return           [Pathname] HTML path
      def render(report_dir)
        report_dir = Pathname.new(report_dir)
        FileUtils.mkpath report_dir unless File.exist?(report_dir)
        Render.run(PREFIX, report_dir, binding)
      end

      class CoverageStats
        # @return [String]
        attr_reader :sample_name

        # @return [Float]
        attr_reader :stats

        # @param sample_name [String]
        # @param stats       [Float]
        def initialize(sample_name, stats)
          @sample_name = sample_name
          @stats = stats
        end
      end

      # @return [Hash{ ChrRegion => Hash{ Symbol => Array<CoverageStats> } }]
      def coverage_stats
        @samples.map do |sample|
          sample
            .cram
            .picard_collect_wgs_metrics_collection
            .picard_collect_wgs_metrics.map do |e|
            {
              sample_name: sample.name,
              chr_region: e.chr_region,
              mean: e.coverage_stats.mean,
              sd: e.coverage_stats.sd,
              median: e.coverage_stats.median,
              mad: e.coverage_stats.mad
            }
          end
        end.flatten(1)
          .group_by { |h| h[:chr_region] }
          .transform_values do |a|
          %i[mean sd median mad].map.to_h do |type|
            coverage_stats_array = a.map do |h|
              CoverageStats.new(h[:sample_name], h[type])
            end
            [type, coverage_stats_array]
          end
        end
      end
    end
  end
end
