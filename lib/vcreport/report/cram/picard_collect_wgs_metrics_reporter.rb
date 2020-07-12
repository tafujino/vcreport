# frozen_string_literal: true

require 'vcreport/chr_region'
require 'vcreport/edam'
require 'vcreport/report/cram/picard_collect_wgs_metrics'
require 'csv'

module VCReport
  module Report
    class Cram
      class PicardCollectWgsMetricsReporter < Reporter
        DEFAULT_MIN_BASE_QUALITY = 20

        # @param cram_path   [Pathname]
        # @param chr_region  [ChrRegion]
        # @param ref_path    [Pathname]
        # @param metrics_dir [Pathname]
        # @param job_manager [JobManager, nil]
        def initialize(cram_path, chr_region, ref_path, metrics_dir, job_manager)
          @cram_path = cram_path
          @chr_region = chr_region
          @ref_path = ref_path
          @out_dir = metrics_dir / 'picard-collectWgsMetrics'
          @picard_collect_wgs_metrics_path =
            @out_dir / "#{@cram_path.basename}.#{chr_region.id}.wgs_metrics"
          super(job_manager, targets: @picard_collect_wgs_metrics_path, deps: @cram_path)
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
            section.java_type == 'htsjdk.samtools.metrics.StringHeader'
          end.map(&:content).join("\n")
          metrics_section, histogram_section = ['METRICS CLASS', 'HISTOGRAM'].map do |title|
            sections.find { |section| section.title == title }
          end
          metrics_section_values = parse_metrics_section(metrics_section)
          histogram = parse_histogram_section(histogram_section)
          args = [
            @picard_collect_wgs_metrics_path,
            @chr_region,
            command_log,
            metrics_section_values,
            histogram
          ].flatten
          PicardCollectWgsMetrics.new(*args)
        end

        # @return [Boolean]
        def run_metrics
          FileUtils.mkpath @out_dir
          job_definition =
            {
              in_bam: cwl_file_field(@cram_path, edam: Edam::BAM),
              reference: cwl_file_field(@reference, edam: Edam::FASTA),
              reference_interval_name: @chr_region.interval_list_path.id.to_s,
              reference_interval_list: cwl_file_field(@chr_region.interval_list_path)
            }
          script_path = "#{HUMAN_RESEQ_DIR}/Tools/samtools-idxstats.cwl"
          run_cwl(script_path, job_definition, @out_dir)
        end

        # @param lines [Array<String>] lines from picard-CollectWgsMetrics output
        # @param sym   [Symbol]
        # @return      [Array<Section>]
        def split_by_section(lines, sym = '##')
          regexp = /^#{Regexp.escape(sym)}\s*(?:(.+)\t)?(.+)\s*$/
          lines.slice_before(regexp).map do |chunk|
            chunk.reject! { |line| line =~ /^\s*$/ }
            chunk.shift =~ regexp
            Section.new($1, $2, chunk.join("\n"))
          end
        end

        # @param str [String]
        # @return    [CSV::Table]
        def parse_tsv(str)
          CSV.parse(
            str,
            col_sep: "\t",
            headers: true,
            converters: :numeric,
            header_converters: :symbol
          )
        end

        # @param section [Seciton]
        # @return        [Array] territory,
        #                        coverage stats,
        #                        percent excluded,
        #                        percent coverage, and
        #                        het snp
        def parse_metrics_section(section)
          row = parse_tsv(section.content).first
          territory = row[:genome_territory]
          coverage_stats = PicardCollectWgsMetrics::CoverageStats.new(
            *row.values_at(*%w[mean sd median mad].map { |k| :"#{k}_coverage" })
          )
          percent_excluded = parse_percent_excluded(row)
          percent_coverage = row.filter_map do |k, v|
            [$1.to_i, v] if k =~ /^pct_(\d+)x$/
          end.to_h
          het_snp = PicardCollectWgsMetrics::HetSnp.new(
            *row.values_at(*%w[sensitivity q].map { |k| :"het_snp_#{k}" })
          )
          [territory, coverage_stats, percent_excluded, percent_coverage, het_snp]
        end

        # @param row [CSV::Row]
        # @return    [PicardCollectWgsMetrics::PercentExcluded]
        def parse_percent_excluded(row)
          params =
            PicardCollectWgsMetrics::PercentExcluded::FIELDS.map.to_h do |k|
            [k, row[:"pct_exc_#{k}"]]
          end
          PicardCollectWgsMetrics::PercentExcluded.new(**params)
        end

        # @param section [Seciton]
        # @return        [Hash{ Integer => Integer }] coverage -> count
        def parse_histogram_section(section)
          parse_tsv(section.content).map.to_h do |row|
            %i[coverage high_quality_coverage_count].map { |k| row[k] }
          end
        end
      end
    end
  end
end
