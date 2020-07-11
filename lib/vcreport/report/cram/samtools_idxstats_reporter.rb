# frozen_string_literal: true

require 'pathname'
require 'csv'
require 'vcreport/report/reporter'
require 'vcreport/report/cram/samtools_idxstats'
require 'vcreport/job_manager'
require 'vcreport/settings'

module VCReport
  module Report
    class Cram
      class SamtoolsIdxstatsReporter < Reporter
        TARGET_CHROMOSOMES = ((1..22).to_a + %w[X Y]).freeze

        # @param cram_path       [Pathname]
        # @param metrics_dir     [Pathname]
        # @param job_manager [JobManager, nil]
        def initialize(cram_path, metrics_dir, job_manager)
          @cram_path = cram_path
          @out_dir = metrics_dir / 'samtools-idxstats'
          @samtools_idxstats_path = @out_dir / "#{@cram_path.basename}.idxstats"
          super(job_manager, targets: @samtools_idxstats_path, deps: @cram_path)
        end

        private

        # @return [SamtoolsIdxstats]
        def parse
          rows = CSV.read(@samtools_idxstats_path, col_sep: "\t")
          all_chrs = rows.map.to_h do |name, *args|
            args.map!(&:to_i)
            [name, SamtoolsIdxstats::Chromosome.new(name, *args)]
          end
          target_names = TARGET_CHROMOSOMES.map { |x| "chr#{x}" }
          target_chrs = all_chrs.values_at(*target_names)
          SamtoolsIdxstats.new(@samtools_idxstats_path, target_chrs)
        end

        # @return [Boolean]
        def run_metrics
          FileUtils.mkpath @out_dir
          job_definition =
            {
              in_cram:
                {
                  class: 'File',
                  format: 'http://edamontology.org/format_3462',
                  path: @cram_path.expand_path.to_s
                }
            }
          script_path = "#{HUMAN_RESEQ_DIR}/Tools/samtools-idxstats.cwl"
          run_cwl(script_path, job_definition, @out_dir)
        end
      end
    end
  end
end
