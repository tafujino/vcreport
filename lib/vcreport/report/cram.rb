# frozen_string_literal: true

require 'vcreport/report/table'
require 'vcreport/report/cram/samtools_idxstats'
require 'vcreport/report/cram/samtools_flagstat'
require 'vcreport/report/cram/picard_collect_wgs_metrics'

module VCReport
  module Report
    class Cram
      # @return [SamtoolsIdxstats, nil]
      attr_reader :samtools_idxstats

      # @return [SamtoolsFlagstat, nil]
      attr_reader :samtools_flagstat

      # @return [Array<PicardCollectWgsMetrics>]
      attr_reader :picard_collect_wgs_metrics

      # @param cram_path                  [Pathname]
      # @param samtools_idxstats_report   [SamtoolsIdxstats, nil]
      # @param samtools_flagstat_report   [SamtoolsFlagstat, nil]
      # @param picard_collect_wgs_metrics [Array<PicardCollectWgsMetrics>]
      def initialize(
            cram_path,
            samtools_idxstats,
            samtools_flagstat,
            picard_collect_wgs_metrics
          )
        @cram_path = cram_path
        @samtools_idxstats = samtools_idxstats
        @samtools_flagstat = samtools_flagstat
        @picard_collect_wgs_metrics = picard_collect_wgs_metrics
      end

      # @return [Table]
      def path_table
        Table.single_file_table(@cram_path)
      end
    end
  end
end
