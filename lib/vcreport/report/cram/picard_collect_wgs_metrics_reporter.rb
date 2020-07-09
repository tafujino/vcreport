# frozen_string_literal: true

require 'vcreport/chr_region'
require 'vcreport/report/cram/picard_collect_wgs_metrics'
require 'csv'

module VCReport
  module Report
    class Cram
      class PicardCollectWgsMetricsReporter < Reporter
        DEFAULT_MIN_BASE_QUALITY = 20

        # @param cram_path       [Pathname]
        # @param chr_region      [ChrRegion]
        # @param metrics_dir     [Pathname]
        # @param metrics_manager [MetricsManager, nil]
        def initialize(cram_path, metrics_dir, metrics_manager)
          @cram_path = cram_path
          @chr_region = chr_region
          @out_dir = metrics_dir / 'picard-collectWgsMetrics'
          @picard_collect_wgs_metrics_path =
            @out_dir / "#{@cram_path.basename}.#{chr_region.id}.wgs_metrics"
          super(metrics_manager, @picard_collect_wgs_metrics_path)
        end

        private

        class Section
          # @return [String, nil]
          attr_reader :title

          # @return [String]
          attr_reader :java_type

          # @return [String]
          attr_reader :content

          def initialize(title, java_type, content)
            @title = title
            @java_type = java_type
            @content = content
          end
        end

        # @return [PicardCollectWgsMetrics]
        def parse
          lines = File.readlines(@picard_collect_wgs_metrics_path, chomp: true)
          sections = split_by_section(lines)
          command_log = sections.select do |section|
            section.type = 'htsjdk.samtools.metrics.StringHeader'
          end.map(&:content).join("\n")
          metrics_section, histogram_section = ['METRICS CLASS', 'HISTOGRAM'].map do |title|
            sections.find { |section| section.title = title }
          end
          histogram = parse_histogram_section(histogram_section)
          PicardCollectWgsMetrics.new(
            *[command_log, parse_metrics_section(metrics_section), histogram].flatten
          )
        end

        # @return [Boolean]
        def metrics
        end

        # @param lines [Array<String>] lines from picard-CollectWgsMetrics output
        # @param sym   [Symbol]
        # @return      [Array<Section>]
        def split_by_section(lines, sym = '##')
          regexp = /^#{Regex.escape(sym)}\s*(?:(.+)\t)(.+)\s*$/
          lines.slice_before(regexp).map do |chunk|
            chunk.reject!(/^\s*$/)
            chunk.shift =~ regexp
            Section.new($1, $2, chunk.join("\n"))
          end
        end

        # @param section [Seciton]
        # @return        [Array] territory,
        #                        coverage stats,
        #                        percent excluded,
        #                        percent coverage, and
        #                        het snp
        def parse_metrics_section(section)
          metrics = CSV.table(section.content, col_sep: "\t")
          row = metrics.first
          territory = row[:genome_territory]
          coverage_stats = PicardCollectWgsMetrics::CoverageStats.new(
            *row.values_at(%w[mean sd median mad].map { |k| :"#{k}_coverage" })
          )
          percent_excluded = parse_percent_excluded(row)
          percent_coverage = row.filter_map.to_h do |k, v|
            [$1.to_i, v] if k =~ /^pct_(\d+)x$/
          end
          het_snp = PicardCollectWgsMetrics::HetSnp.new(
            *row.values_at(%w[sensitivity q].map { |k| :"het_snp_#{k}" })
          )
          [territory, coverage_stats, percent_excluded, percent_coverage, het_snp]
        end

        # @param row [CSV::Row]
        # @return    [PicardCollectWgsMetrics::PercentExcluded]
        def parse_percent_excluded
          params =
            PicardCollectWgsMetrics::PercentExcluded::FIELDS.map.to_h do |k|
            [k, row[:"pct_exc_#{k}"]]
          end
          PicardCollectWgsMetrics::PercentExcluded.new(params)
        end

        # @param section [Seciton]
        # @return        [Hash{Integer => Integer] coverage -> count
        def parse_histogram_section(section)
          CSV.table(section.content, col_sep: "\t").map.to_h do |row|
            %i[coverage high_quality_coverage_count].map { |k| row[k] }
          end
        end
      end
    end
  end
end
