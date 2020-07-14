# frozen_string_literal: true

require 'vcreport/config'
require 'vcreport/report/reporter'
require 'vcreport/report/sample'
require 'vcreport/report/sample/vcf'
require 'vcreport/report/sample/vcf_reporter'
require 'vcreport/report/sample/vcf_collection'
require 'vcreport/report/sample/cram'
require 'vcreport/report/sample/cram_reporter'
require 'vcreport/job_manager'
require 'pathname'

module VCReport
  module Report
    class SampleReporter < Reporter
      # @param sample_dir  [Pathname]
      # @param config      [Config]
      # @param job_manager [JobManager, nil]
      def initialize(sample_dir, config, job_manager)
        @sample_dir = sample_dir
        @config = config
        @finish_path = @sample_dir / 'finish'
        @name = @sample_dir.basename.to_s
        @job_manager = job_manager
        super(@job_manager, targets: [], deps: @finish_path)
      end

      # @return [Sample]
      def parse
        end_time = File::Stat.new(@finish_path).mtime
        metrics_dir = @sample_dir / 'metrics'
        chr_regions = @config.chr_regions
        vcfs = chr_regions.filter_map do |chr_region|
          # VCF is supposed to be gzipped
          vcf_path = @sample_dir / "#{@name}.#{chr_region.id}.g.vcf.gz"
          Sample::VcfReporter.new(vcf_path, chr_region, metrics_dir, @job_manager)
            .try_parse
        end
        vcf_collection = Sample::VcfCollection.new(
          Sample::Vcf::BcftoolsStatsReporter::BCFTOOLS_IMAGE_URI, vcfs
        )
        cram_path = @sample_dir / "#{@name}.dedup.cram"
        cram = Sample::CramReporter.new(
          cram_path, chr_regions, @config.ref_path, metrics_dir, @job_manager
        ).try_parse
        Sample.new(@name, end_time, vcf_collection, cram)
      end
    end
  end
end
