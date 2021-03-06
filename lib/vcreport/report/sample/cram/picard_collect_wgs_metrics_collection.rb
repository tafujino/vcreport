# frozen_string_literal: true

require 'pathname'
require 'vcreport/report/table'
require 'vcreport/report/sample/cram/picard_collect_wgs_metrics'
require 'vcreport/report/sample/cram/picard_collect_wgs_metrics_reporter'

module VCReport
  module Report
    class Sample
      class Cram
        class PicardCollectWgsMetricsCollection
          # @return [String]
          attr_reader :program_name

          # @return [Array<PicardCollectWgsMetrics>]
          attr_reader :picard_collect_wgs_metrics

          # @param picard_collect_wgs_metrics [Array<PicardCollectWgsMetrics>]
          def initialize(picard_collect_wgs_metrics)
            @picard_collect_wgs_metrics = picard_collect_wgs_metrics
          end

          # @return [Boolean]
          def empty?
            @picard_collect_wgs_metrics.empty?
          end

          # @return [Table, nil]
          def program_table
            return nil if empty?

            program_name = CWL.script_docker_path(
              PicardCollectWgsMetricsReporter::CWL_SCRIPT_PATH
            )
            Table.program_table(program_name)
          end
        end
      end
    end
  end
end
