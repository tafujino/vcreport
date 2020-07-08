# frozen_string_literal: true

require 'vcreport/config'
require 'vcreport/report/reporter'
require 'vcreport/report/sample'
require 'vcreport/report/vcf'
require 'vcreport/report/vcf_reporter'
require 'vcreport/report/cram'
require 'vcreport/report/cram_reporter'
require 'vcreport/metrics_manager'
require 'pathname'

module VCReport
  module Report
    class SampleReporter < Reporter
      # @param sample_dir      [Pathname]
      # @param config          [Config]
      # @param metrics_manager [MetricsManager, nil]
      # @return                [Sample]
      def initialize(sample_dir, config, metrics_manager)
        @sample_dir = sample_dir
        @config = config
        super(metrics_manager)
      end

      # @return [Sample]
      def parse
        name = @sample_dir.basename.to_s
        finish_path = (@sample_dir / 'finish')
        return Sample.new(name) unless finish_path.exist?

        end_time = File::Stat.new(finish_path).mtime
        metrics_dir = @sample_dir / 'metrics'
        vcfs = @config.chr_regions.map do |chr_region|
          # VCF is supposed to be gzipped
          vcf_path = @sample_dir / "#{name}.#{chr_region.id}.g.vcf.gz"
          VcfReporter.new(
            vcf_path, chr_region, metrics_dir, @metrics_manager
          ).run
        end.compact
        cram_path = @sample_dir / "#{name}.dedup.cram"
        cram = CramReporter.new(cram_path, metrics_dir, @metrics_manager).run
        Sample.new(name, end_time, vcfs, cram)
      end
    end
  end
end
