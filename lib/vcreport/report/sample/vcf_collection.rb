# frozen_string_literal: true

require 'fileutils'
require 'vcreport/chr_region'
require 'vcreport/report/sample/vcf'

module VCReport
  module Report
    class Sample
      class VcfCollection
        # @return [String]
        attr_reader :program_name

        # @return [Array<Vcf>]
        attr_reader :vcfs

        # @param vcfs [Array<Vcf>]
        def initialize(program_name, vcfs)
          @program_name = program_name
          @vcfs = vcfs
        end

        # @return [Table, nil]
        def bcftools_stats_program_table
          return nil if @vcfs.map(&:bcftools_stats).compact.empty?

          Table.program_table(@program_name)
        end

        # @return [Table, nil]
        def bcftools_stats_table
          header = ['chr. region', '# of SNPs', '# of indels', 'ts/tv']
          type = %i[string integer integer float]
          rows = @vcfs.filter_map(&:bcftools_stats).map do |e|
            [e.chr_region.desc, e.num_snps, e.num_indels, e.ts_tv_ratio]
          end
          Table.new(header, rows, type)
        end

        # @return [Table]
        def vcf_path_table
          path_table('input file', &:vcf_path)
        end

        # @return [Table]
        def bcftools_stats_path_table
          path_table('metrics file') do |vcf|
            vcf.bcftools_stats&.path
          end
        end

        private

        # @param caption [String]
        # @return        [Table, nil]
        def path_table(caption)
          return nil if @vcfs.empty?

          header = ['chr. region', caption]
          type = %i[string verbatim]
          rows =
            @vcfs.filter_map do |vcf|
            path = yield vcf
            next unless path

            [vcf.chr_region.desc, File.expand_path(path)]
          end
          Table.new(header, rows, type)
        end
      end
    end
  end
end
