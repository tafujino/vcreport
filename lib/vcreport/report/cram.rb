# frozen_string_literal: true

require 'vcreport/report/cram/samtools_idxstats'
require 'vcreport/report/cram/samtools_idxstats_reporter'
require 'vcreport/report/cram/samtools_flagstat'
require 'vcreport/report/cram/samtools_flagstat_reporter'

module VCReport
  module Report
    class Cram
      # @return [SamtoolsIdxstats]
      attr_reader :samtools_idxstats

      # @return [SamtoolsFlagstat]
      attr_reader :samtools_flagstat

      # @param samtools_idxstats_report [SamtoolsIdxstats, nil]
      # @param samtools_flagstat_report [SamtoolsFlagstat, nil]
      def initialize(
            samtools_idxstats,
            samtools_flagstat
          )
        @samtools_idxstats = samtools_idxstats
        @samtools_flagstat = samtools_flagstat
      end

      class << self
        # @param cram_path       [Pathname]
        # @param metrics_dir     [Pathname]
        # @param metrics_manager [MetricsManager, nil]
        # @return                [Cram]
        def run(cram_path, metrics_dir, metrics_manager)
          samtools_idxstats =
            SamtoolsIdxstatsReporter.new(cram_path, metrics_dir, metrics_manager).run
          samtools_flagstat =
            SamtoolsFlagstatReporter.new(cram_path, metrics_dir, metrics_manager).run
          Cram.new(
            samtools_idxstats,
            samtools_flagstat
          )
        end
      end
    end
  end
end
