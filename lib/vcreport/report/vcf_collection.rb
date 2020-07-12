# frozen_string_literal: true

require 'fileutils'
require 'vcreport/chr_region'
require 'vcreport/report/vcf'

module VCReport
  module Report
    # @return [String]
    attr_reader :program_name

    # @return [Array<Vcf>]
    attr_reader :vcfs

    class VcfCollection
      # @param vcfs [Array<Vcf>]
      def initialize(program_name, vcfs)
        @program_name = program_name
        @vcfs = vcfs
      end

      # @return [Table]
      def program_table
        Table.program_table(@program_name)
      end

      # @return [Boolean]
      def empty?
        @vcfs.empty?
      end

      # @return [Table, nil]
      def bcftools_stats_table
        return nil if @vcfs.empty?

        header = ['chr. region', '# of SNPs', '# of indels', 'ts/tv']
        type = %i[string integer integer float]
        rows = @vcfs.map do |vcf|
          [vcf.chr_region.desc, vcf.num_snps, vcf.num_indels, vcf.ts_tv_ratio]
        end
        Table.new(header, rows, type)
      end

      # @return [Table]
      def vcf_path_table
        path_table('input file', &:vcf_path)
      end

      # @return [Table]
      def bcftools_stats_path_table
        path_table('metrics file', &:bcftools_stats_path)
      end

      private

      # @param caption [String]
      # @return        [Table, nil]
      def path_table(caption)
        return nil if @vcfs.empty?

        header = ['chr. region', caption]
        type = %i[string verbatim]
        rows =
          @vcfs.map do |vcf|
          [vcf.chr_region.desc, (yield vcf).expand_path]
        end
        Table.new(header, rows, type)
      end
    end
  end
end
