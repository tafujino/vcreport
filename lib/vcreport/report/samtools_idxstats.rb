# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'csv'

module VCReport
  module Report
    class SamtoolsIdxstats
      TARGET_CHROMOSOMES = ((1..22).to_a + %w[X Y]).freeze

      class Chromosome
        # @return [String] "chr..." is supposed
        attr_reader :name

        # @return [Integer]
        attr_reader :length

        # @return [Integer] # of mapped reads
        attr_reader :num_mapped

        # @return [Integer] # of unmapped reads
        attr_reader :num_unmapped

        def initialize(name, length, num_mapped, num_unmapped)
          @name = name
          @length = length
          @num_mapped = num_mapped
          @num_unmapped = num_unmapped
        end
      end

      # @return [Chromosome]
      attr_reader :chromosomes

      # @param chromosomes [Array<Chromosome>]
      def initialize(chromosomes)
        @chromosomes = chromosomes.sort_by(&:name)
      end

      class << self
        # @param cram_path       [Pathname]
        # @param metrics_dir     [Pathname]
        # @param metrics_manager [MetricsManager, nil]
        # @return                [Report::SamtoolsIdxstats, nil]
        def run(cram_path, metrics_dir, metrics_manager)
          out_dir = metrics_dir / 'samtools-idxstats'
          samtools_idxstats_path = out_dir / "#{cram_path.basename}.idxstats"
          if out_path.exist?
            load_samtools_idxstats(samtools_idxstats_path)
          else
            metrics_manager&.post(samtools_idxstats_path) do
              run_samtools_idxstarts(cram_path, out_dir)
            end
            nil
          end
        end

        # @param samtools_idxstats_path [Pathname]
        # @return                       [Report::SamtoolsIdxstats]
        def load_samtools_idxstats(samtools_idxstats_path)
          rows = CSV.read(samtools_idxstats_path, col_sep: "\t")
          all_chrs = rows.map.to_h do |name, *args|
            [name, Chromosome.new(name, *args)]
          end
          target_names = TARGET_CHROMOSOMES.map { |x| "chr#{x}" }
          target_chrs = all_chrs.values_at(*target_names)
          SamtoolsIdxstats.new(target_chrs)
        end

        def run_samtools_idxstats(cram_path, out_dir)
          FileUtils.mkpath out_dir
          job_path = out_dir / 'job.yaml'
          store_job_file(
            job_path,
            { in_cram:
                { class: 'File',
                  format: 'http://edamontology.org/format_3462',
                  path: cram_path.expand_path } }
          )
          sh <<~COMMAND.squish
            cwltool
            --singularity
            --outdir #{out_dir}
            #{HUMAN_RESEQ_DIR}/Tools/samtools-idxstats.cwl
            #{job_path}
          COMMAND
        end

        def store_job_file(job_path, hash)
          File.write(job_path, YAML.dump(hash.deep_stringify_keys))
        end
      end
    end
  end
end
