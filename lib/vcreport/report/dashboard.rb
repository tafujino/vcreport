# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
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
        data = ts_tv_ratio
        chr_regions = data.entries.filter_map { |e| e[:chr_region] }.uniq
        chr_regions.map do |chr_region|
          data = data.select(chr_region: chr_region)
          sample_col = C3js::Column.new(:sample_name, 'sample name')
          tstv_col = C3js::Column.new(:ts_tv_ratio, 'ts/tv')
          puts data.bar_chart_json(sample_col, tstv_col, bindto: 'chart')
        end
#        c3js = ts_tv_ratio
#        pp c3js
#        chr_region = c3js.entries.first[:chr_region]
#        pp c3js.select(chr_region: chr_region)
#        puts c3js.select(chr_region: chr_region).rows_text(
#             sample_name: 'sample name', ts_tv_ratio: 'ts/tv')
      end

      # @param report_dir [String]
      # @return           [Pathname] HTML path
      def render(report_dir)
        report_dir = Pathname.new(report_dir)
        FileUtils.mkpath report_dir unless File.exist?(report_dir)
        Render.run(PREFIX, report_dir, binding, use_markdown: false)
      end

      module C3js
        class Column
          # @return [Symbol]
          attr_reader :id

          # @return [String]
          attr_reader :label

          # @return [Boolean]
          attr_reader :is_categorical

          # @param id             [Symbol]
          # @param label          [String]
          # @param is_categorical [Boolean]
          def initialize(id, label, is_categorical = false)
            @id = id
            @label = label
            @is_categorical = is_categorical
          end
        end

        class Data
          # @return [Array<Hash>]
          attr_reader :entries

          # @param entries [Array<Hash>]
          def initialize(entries)
            @entries = entries
          end

#          # @param key_and_value [Hash{ Symbol => Object }]
#          # @return              [Data]
#          def select_and_shadow(**key_and_value)
#            entries = @entries.filter_map do |e|
#              next nil unless key_and_value.all? { |k, v| e[k] == v }
#
#              e1 = e.clone
#              key_and_value.keys.each { |k| e1.delete(k) }
#              e1
#            end
#            Data.new(entries)
#          end

          # @param key_and_value [Hash{ Symbol => Object }]
          # @return              [Data]
          def select(**key_and_value)
            entries = @entries.filter_map do |e|
              next nil unless key_and_value.all? { |k, v| e[k] == v }

              e
            end
            Data.new(entries)
          end

          # @param cols [Array<Column>]
          # @return     [Array<Array>>]
          def rows(*cols)
            @entries.inject([cols.map(&:label)]) do |a, e|
              a << e.values_at(*cols.map(&:id))
            end
          end

          # @param cols [Array<Column>]
          # @return     [String]
          def bar_chart_json(*cols, bindto:)
            row_data = rows(*cols)
            chart = {
              bindto: "##{bindto}", data: { rows: row_data }, type: 'bar'
            }
            chart.deep_stringify_keys!
            JSON.generate(chart)
          end

#          # @param key_and_name [Hash{ Symbol => String }]
#          # @return             [String]
#          def rows_text(**key_and_name)
#            a = [key_and_name.values]
#            @entries.each do |e|
#              a << e.values_at(*key_and_name.keys)
#            end
#            JSON.generate(a)
#          end
#

#          # @param key
#          def sort!(key)
#            @entries.sort_by do |a, b|
#              if block_given?
#                yield a[key], a
#              end
#          end
#
#          # @param keys [Array<String>]
#          def columns(*keys)
#            keys.map do |key|
#              @entries.map { |e| e[key] }.preprend(name)
#            end
#          end

#          # @param key_and_name [Hash{ Symbol => String }]
#          #                     column key -> human-readable name
#          def columns(**key_and_name)
#            key_and_name.map do |key, name|
#              @entries.map { |e| e[key] }.preprend(name)
#            end
#          end
        end
      end

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
            h.merge(sample_name: sample.name, chr_region: e.chr_region)
          end
        end.then { |a| C3js::Data.new(a) }
      end
    end
  end
end
