# frozen_string_literal: true

require 'vcreport/chr_regions'
require 'vcreport/report/vcf'
require 'vcreport/report/vcf_reporter'
require 'vcreport/report/cram'
require 'vcreport/report/cram_reporter'
require 'vcreport/report/render'
require 'vcreport/report/table'
require 'vcreport/metrics_manager'
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

      # @return [Array<Vcf>]
      attr_reader :vcfs

      # @return [Cram, nil]
      attr_reader :cram

      # @param name     [String]
      # @param end_time [Time, nil]
      # @param vcfs     [Array<Vcf>]
      # @param cram     [Cram]
      def initialize(name, end_time = nil, vcfs = [], cram = nil)
        @name = name
        @end_time = end_time
        @vcfs = vcfs
        @cram = cram
      end

      # @param report_dir [String]
      def render(report_dir)
        report_dir = Pathname.new(report_dir)
        out_dir = report_dir / @name
        FileUtils.mkpath out_dir unless File.exist?(out_dir)
        Render.run(PREFIX, out_dir, binding)
      end

      private

      # @return [Table]
      def bcftools_stats_table
        return nil if @vcfs.empty?

        header = ['chr. region', '# of snps', '# of indels', 'ts/tv']
        type = %i[string integer integer float]
        rows = @vcfs.map do |vcf|
          [vcf.chr_region, vcf.num_snps, vcf.num_indels, vcf.ts_tv_ratio]
        end
        Table.new(header, rows, type)
      end

      class << self
        # @param sample_dir      [Pathname]
        # @param metrics_manager [MetricsManager, nil]
        # @return                [Sample]
        def run(sample_dir, metrics_manager)
          name = sample_dir.basename.to_s
          finish_path = (sample_dir / 'finish')
          return Sample.new(name) unless finish_path.exist?

          end_time = File::Stat.new(finish_path).mtime
          metrics_dir = sample_dir / 'metrics'
          vcfs = CHR_REGIONS.map do |chr_region|
            # VCF is supposed to be gzipped
            vcf_path = sample_dir / "#{name}.#{chr_region}.g.vcf.gz"
            VcfReporter.new(
              vcf_path, chr_region, metrics_dir, metrics_manager
            ).run
          end.compact
          cram_path = sample_dir / "#{name}.dedup.cram"
          cram = CramReporter.new(cram_path, metrics_dir, metrics_manager).run
          Sample.new(
            name,
            end_time,
            vcfs,
            cram
          )
        end
      end
    end
  end
end
