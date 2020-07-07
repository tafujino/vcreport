# frozen_string_literal: true

require 'vcreport/report/cram/samtools_idxstats'
require 'vcreport/report/cram/samtools_flagstat'

module VCReport
  module Report
    class Cram
      # @return [SamtoolsIdxstats]
      attr_reader :samtools_idxstats_report

      # @return [SamtoolsFlagstat]
      attr_reader :samtools_flagstat_report

      # @param samtools_idxstats_report [SamtoolsIdxstats, nil]
      # @param samtools_flagstat_report [SamtoolsFlagstat, nil]
      def initialize(
            samtools_idxstats_report,
            samtools_flagstat_report
          )
        @samtools_idxstats_report = samtools_idxstats_report
        @samtools_flagstat_report = samtools_flagstat_report
      end

      class << self
        # @param cram_path       [Pathname]
        # @param metrics_dir     [Pathname]
        # @param metrics_manager [MetricsManager, nil]
        # @return                [Cram]
        def run(cram_path, metrics_dir, metrics_manager)
          samtools_idxstats_report =
            SamtoolsIdxstats.run(cram_path, metrics_dir, metrics_manager)
          samtools_flagstat_report =
            SamtoolsFlagstat.run(cram_path, metrics_dir, metrics_manager)
          Cram.new(
            samtools_idxstats_report,
            samtools_flagstat_report
          )
        end
      end
    end
  end
end
