# frozen_string_literal: true

require 'vcreport/metrics_manager'
require 'vcreport/report/reporter'
require 'vcreport/report/cram'
require 'vcreport/report/cram/samtools_idxstats'
require 'vcreport/report/cram/samtools_idxstats_reporter'
require 'vcreport/report/cram/samtools_flagstat'
require 'vcreport/report/cram/samtools_flagstat_reporter'

module VCReport
  module Report
    class CramReporter < Reporter
      # @param cram_path       [Pathname]
      # @param metrics_dir     [Pathname]
      # @param metrics_manager [MetricsManager, nil]
      # @return                [Cram]
      def initialize(cram_path, metrics_dir, metrics_manager)
        @cram_path = cram_path
        @metrics_dir = metrics_dir
        super(metrics_manager)
      end

      # @return [Cram]
      def parse
        samtools_idxstats = Cram::SamtoolsIdxstatsReporter.new(
          @cram_path, @metrics_dir, @metrics_manager
        ).run
        samtools_flagstat = Cram::SamtoolsFlagstatReporter.new(
          @cram_path, @metrics_dir, @metrics_manager
        ).run
        Cram.new(
          samtools_idxstats,
          samtools_flagstat
        )
      end
    end
  end
end
