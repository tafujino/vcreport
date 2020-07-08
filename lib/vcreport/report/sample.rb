# frozen_string_literal: true

require 'vcreport/chr_regions'
require 'vcreport/report/vcf'
require 'vcreport/report/cram'
require 'vcreport/report/render'
require 'vcreport/metrics_manager'
require 'fileutils'
require 'pathname'

module VCReport
  module Report
    class Sample
      PREFIX = 'report'

      include Render

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

      # @param report_dir       [String]
      # @param should_overwrite [Boolean]
      def render(report_dir, should_overwrite = true)
        report_dir = Pathname.new(report_dir)
        out_dir = report_dir / @name
        FileUtils.mkpath out_dir unless File.exist?(out_dir)
        render_markdown(PREFIX, out_dir, should_overwrite: should_overwrite)
        render_html(PREFIX, out_dir, should_overwrite: should_overwrite)
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
            Vcf.run(vcf_path, chr_region, metrics_dir, metrics_manager)
          end.compact
          cram_path = sample_dir / "#{name}.dedup.cram"
          cram = Cram.run(cram_path, metrics_dir, metrics_manager)
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
