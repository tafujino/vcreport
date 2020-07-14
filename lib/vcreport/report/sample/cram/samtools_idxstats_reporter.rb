# frozen_string_literal: true

require 'pathname'
require 'csv'
require 'vcreport/settings'
require 'vcreport/edam'
require 'vcreport/report/reporter'
require 'vcreport/report/sample/cram/samtools_idxstats'
require 'vcreport/job_manager'
require 'vcreport/cwl'

module VCReport
  module Report
    class Sample
      class Cram
        class SamtoolsIdxstatsReporter < Reporter
          TARGET_CHROMOSOMES = ((1..22).to_a + %w[X Y]).freeze
          CWL_SCRIPT_PATH = "#{HUMAN_RESEQ_DIR}/Tools/samtools-idxstats.cwl"

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
            program_name = CWL.script_docker_path(CWL_SCRIPT_PATH)
            SamtoolsIdxstats.new(@samtools_idxstats_path, program_name, target_chrs)
          end

          # @return [Boolean]
          def run_metrics
            FileUtils.mkpath @out_dir
            job_definition = { in_cram: CWL.file_field(@cram_path, edam: Edam::Type::CRAM) }
            CWL.run(CWL_SCRIPT_PATH, job_definition, @out_dir)
          end
        end
      end
    end
  end
end
