# frozen_string_literal: true

require 'vcreport/job_manager'
require 'vcreport/report/reporter'
require 'vcreport/report/cram'
require 'vcreport/report/cram/samtools_idxstats'
require 'vcreport/report/cram/samtools_idxstats_reporter'
require 'vcreport/report/cram/samtools_flagstat'
require 'vcreport/report/cram/samtools_flagstat_reporter'
require 'vcreport/report/cram/picard_collect_wgs_metrics'
require 'vcreport/report/cram/picard_collect_wgs_metrics_reporter'

module VCReport
  module Report
    class CramReporter < Reporter
      # @param cram_path   [Pathname]
      # @param chr_regions [Array<ChrRegion>]
      # @param ref_path    [Pathname]
      # @param metrics_dir [Pathname]
      # @param job_manager [JobManager, nil]
      # @return            [Cram]
      def initialize(cram_path, chr_regions, ref_path, metrics_dir, job_manager)
        @cram_path = cram_path
        @chr_regions = chr_regions
        @ref_path = ref_path
        @metrics_dir = metrics_dir
        @job_manager = job_manager
        super(@job_manager)
      end

      # @return [Cram]
      def parse
        samtools_idxstats = Cram::SamtoolsIdxstatsReporter.new(
          @cram_path, @metrics_dir, @job_manager
        ).try_parse
        samtools_flagstat = Cram::SamtoolsFlagstatReporter.new(
          @cram_path, @metrics_dir, @job_manager
        ).try_parse
        picard_collect_wgs_metrics = @chr_regions.map do |chr_region|
          Cram::PicardCollectWgsMetricsReporter.new(
            @cram_path, chr_region, @ref_path, @metrics_dir, @job_manager
          ).try_parse
        end.compact
        Cram.new(
          @cram_path,
          samtools_idxstats,
          samtools_flagstat,
          picard_collect_wgs_metrics
        )
      end
    end
  end
end
