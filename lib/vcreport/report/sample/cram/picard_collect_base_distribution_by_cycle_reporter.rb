# frozen_string_literal: true

require 'vcreport/edam'
require 'vcreport/report/reporter'
require 'vcreport/report/sample/cram/picard_collect_base_distribution_by_cycle'
require 'csv'

module VCReport
  module Report
    class Sample
      class Cram
        class PicardCollectBaseDistributionByCycleReporter < Reporter
          CWL_SCRIPT_PATH = "#{HUMAN_RESEQ_DIR}/Tools/picard-CollectBaseDistributionByCycle.cwl"
          PDFTOPPM_IMAGE_PATH = 'docker://minidocks/poppler:0.56'

          # @param cram_path   [Pathname]
          # @param ref_path    [Pathname]
          # @param metrics_dir [Pathname]
          # @param job_manager [JobManager, nil]
          def initialize(
                cram_path,
                ref_path,
                metrics_dir,
                job_manager
              )
            @cram_path = cram_path
            @ref_path = ref_path
            @out_dir = metrics_dir / 'picard-CollectBaseDistributionByCycle'
            @out_path = @out_dir / "#{@cram_path.basename}.collect_base_dist_by_cycle"
            @chart_pdf_path, @chart_png_path = %w[pdf png].map do |ext|
              Pathname.new("#{@out_path}.chart.#{ext}")
            end
            super(job_manager, targets: @out_path, deps: @cram_path)
          end

          private

          # @return [PicardCollectBaseDistributionByCycle]
          def parse
            PicardCollectBaseDistributionByCycle.new(
              @out_path, @chart_pdf_path, @chart_png_path
            )
          end

          # @return [Boolean]
          def run_metrics
            FileUtils.mkpath @out_dir
            job_definition =
              {
                in_bam: CWL.file_field(@cram_path, edam: Edam::Type::BAM),
                reference: CWL.file_field(@ref_path, edam: Edam::Type::FASTA)
              }
            is_success = CWL.run(CWL_SCRIPT_PATH, job_definition, @job_manager, @out_dir)
            return is_success unless is_success

            tmp_path = "#{@chart_png_path}.tmp"
            container_data_dir = '/data'
            cmd = <<~COMMAND.squish
              #{SINGULARITY_PATH} exec
              --bind #{@chart_pdf_path.dirname}:#{container_data_dir}
              #{PDFTOPPM_IMAGE_PATH}
              pdftoppm #{container_data_dir}/#{@chart_pdf_path.basename}
              -png
              > #{tmp_path}
            COMMAND
            is_success = @job_manager.spawn(cmd)
            FileUtils.mv(tmp_path, @chart_png_path) if is_success
            is_success
          end
        end
      end
    end
  end
end
