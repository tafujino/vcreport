# frozen_string_literal: true

require 'vcreport/chr_region'
require 'vcreport/report/render'
require 'vcreport/report/sample'
require 'fileutils'
require 'pathname'
require 'json'
require 'csv'

module VCReport
  module Report
    class Dashboard
      PREFIX = 'dashboard'
      COVERAGE_STATS_TYPES = %i[mean sd median mad].freeze

      # @param samples [Array<Sample>]
      def initialize(samples)
        @samples = samples.sort_by(&:end_time).reverse
      end

      # @param report_dir [String]
      # @return           [Pathname] HTML path
      def render(report_dir)
        report_dir = Pathname.new(report_dir)
        FileUtils.mkpath report_dir unless File.exist?(report_dir)
        Render.run(PREFIX, report_dir, binding, use_markdown: false)
      end

      class PlotEntry
        # @return [String]
        attr_reader :sample_name

        # @return [Object]
        attr_reader :value

        # @param sample_name [String]
        # @param value       [Object]
        def initialize(sample_name, value)
          @sample_name = sample_name
          @value = value
        end
      end

      class PlotData
        # @return [Array<PlotEntry>]
        attr_reader :entries

        # @param [Array<PlotEntry>]
        def initialize(entries)
          @entries = entries
        end

        # @param [String]
        def json_text
          JSON.generate(
            @entries.map do |e|
              { sample_name: e.sample_name, value: e.value }
            end
          )
        end

        # @param [String]
        def csv_text
          CSV.generate do |csv|
            csv << %w[sample_name value]
            @entries.each do |e|
              csv << [e.sample_name, e.value]
            end
          end
        end
      end

      # @param data [String]
      # @param type [String]
      # @param id   [String]
      # @return     [String]
      def data_embedding_html(data, type, id)
        <<~HTML.chomp
          <script type="#{type}" id="#{id}">#{data.chomp}</script>
        HTML
      end

      # @return [Hash{ ChrRegion => PlotData }]
      def ts_tv_ratio
        @samples.map do |sample|
          sample.vcf_collection.vcfs.map do |vcf|
            {
              sample_name: sample.name,
              chr_region: vcf.chr_region,
              ts_tv_ratio: vcf.bcftools_stats&.ts_tv_ratio
            }
          end
        end.flatten(1)
          .group_by { |h| h[:chr_region] }
          .transform_values do |a|
          PlotData.new(
            a.map { |h| PlotEntry.new(h[:sample_name], h[:ts_tv_ratio]) }
          )
        end
      end

      # @return [Hash{ ChrRegion => Hash{ Symbol => PlotData } }]
      def coverage_stats
        @samples.map do |sample|
          sample
            .cram
            .picard_collect_wgs_metrics_collection
            .picard_collect_wgs_metrics.map do |e|
            h = COVERAGE_STATS_TYPES.map.to_h do |type|
              [type, e.coverage_stats.send(type)]
            end
            h.merge(sample_name: sample.name, chr_region: e.chr_region)
          end
        end.flatten(1)
          .group_by { |h| h[:chr_region] }
          .transform_values do |a|
          COVERAGE_STATS_TYPES.map.to_h do |type|
            plot_entries = a.map do |h|
              PlotEntry.new(h[:sample_name], h[type])
            end
            [type, PlotData.new(plot_entries)]
          end
        end
      end
    end
  end
end
