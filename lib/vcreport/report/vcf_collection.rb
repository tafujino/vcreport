# frozen_string_literal: true

require 'fileutils'
require 'vcreport/chr_region'
require 'vcreport/report/vcf'

module VCReport
  module Report
    # @return [Array<Vcf>]
    attr_reader :vcfs

    class VcfCollection
      # @param vcfs [Array<Vcf>]
      def initialize(vcfs)
        @vcfs = vcfs
      end

      # @return [Table]
      def bcftools_stats_table
        header = ['chr. region', '# of SNPs', '# of indels', 'ts/tv']
        type = %i[string integer integer float]
        rows = @vcfs.map do |vcf|
          [vcf.chr_region.desc, vcf.num_snps, vcf.num_indels, vcf.ts_tv_ratio]
        end
        Table.new(header, rows, type)
      end

      # @return [Table]
      def vcf_path_table
        path_table(&:vcf_path)
      end

      # @return [Table]
      def bcftools_stats_path_table
        path_table(&:bcftools_stats_path)
      end

      private

      # @return [Table]
      def path_table
        header = ['chr. region', 'file']
        type = %i[string verbatim]
        rows = @vcfs.map do |vcf|
          [vcf.chr_region.desc, (yield vcf).expand_path]
        end
        Table.new(header, rows, type)
      end
    end
  end
end
