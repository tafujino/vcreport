# frozen_string_literal: true

require 'fileutils'
require 'rake'
require 'vcreport/metrics/vcf'

module VCReport
  module Report
    class Vcf
      extend Rake::DSL

      # @return [String]
      attr_reader :chr_region

      # @return [Integer, nil]
      attr_reader :num_snps

      # @return [Integer, nil]
      attr_reader :num_indels

      # @return [Float, nil]
      attr_reader :ts_tv_ratio

      def initialize(chr_region, num_snps = nil, num_indels = nil, ts_tv_ratio = nil)
        @chr_region = chr_region
        @num_snps = num_snps
        @num_indels = num_indels
        @ts_tv_ratio = ts_tv_ratio
      end

      class << self
        # @param vcf_stats   [Stats::Vcf]
        # @param chr_region  [String]
        # @return            [VcfReport, nil]
        def run(vcf_stats, chr_region)
          bcftools_stats_path = vcf_stats.bcftools_stats_path
          if bcftools_stats_path.exist?
            load_bcftools_stats(chr_region, bcftools_stats_path)
          else
            VCReport.new(chr_region)
          end
        end

        private

        # @param chr_region          [String]
        # @param bcftools_stats_path [Pathname]
        # @return                    [VcfReport]
        def load_bcftools_stats(chr_region, bcftools_stats_path)
          field = File.readlines(bcftools_stats_path, chomp: true).reject do |line|
            line =~ /^#/
          end.map do |line|
            line.split("\t")
          end.group_by(&:first)
          sn = field['SN'].map.to_h { |_, _, k, v| [k, v.to_i] }
          num_snps = sn['number of SNPs:']
          num_indels = sn['number of indels:']
          ts_tv_ratio = field['TSTV'].first[4].to_f
          VcfReport.new(chr_region, num_snps, num_indels, ts_tv_ratio)
        end
      end
    end
  end
end
