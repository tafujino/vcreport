# frozen_string_literal: true

require 'vcreport/config'
require 'vcreport/job_manager'
require 'vcreport/report/reporter'
require 'vcreport/report/sample/cram'
require 'vcreport/report/sample/cram/samtools_idxstats'
require 'vcreport/report/sample/cram/samtools_idxstats_reporter'
require 'vcreport/report/sample/cram/samtools_flagstat'
require 'vcreport/report/sample/cram/samtools_flagstat_reporter'
require 'vcreport/report/sample/cram/picard_collect_wgs_metrics'
require 'vcreport/report/sample/cram/picard_collect_wgs_metrics_collection'
require 'vcreport/report/sample/cram/picard_collect_wgs_metrics_reporter'

module VCReport
  module Report
    class Sample
      class CramReporter < Reporter
        # @param cram_path   [Pathname]
        # @param config      [Config]
        # @param metrics_dir [Pathname]
        # @param job_manager [JobManager, nil]
        # @return            [Cram]
        def initialize(cram_path, config, metrics_dir, job_manager)
          @cram_path = cram_path
          @config = config
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
          picard_collect_wgs_metrics_config =
            @config.metrics.picard_collect_wgs_metrics
          intervals = picard_collect_wgs_metrics_config.intervals
          ref_path = @config.reference.path
          picard_collect_wgs_metrics = intervals.filter_map do |chr_region|
            Cram::PicardCollectWgsMetricsReporter.new(
              @cram_path,
              chr_region,
              ref_path,
              picard_collect_wgs_metrics_config,
              @metrics_dir,
              @job_manager
            ).try_parse
          end
          picard_collect_wgs_metrics_collection =
            Cram::PicardCollectWgsMetricsCollection.new(picard_collect_wgs_metrics)
          Cram.new(
            @cram_path,
            samtools_idxstats,
            samtools_flagstat,
            picard_collect_wgs_metrics_collection
          )
        end
      end
    end
  end
end
