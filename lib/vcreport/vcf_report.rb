# frozen_string_literal: true

require 'fileutils'
require 'rake'

module VCReport
  class VcfReport
    extend Rake::DSL

    BCFTOOLS_IMAGE_URI = 'docker://biocontainers/bcftools:v1.9-1-deb_cv1'

    # @return [String]
    attr_reader :chr_region

    # @return [Integer]
    attr_reader :num_snps

    # @return [Integer]
    attr_reader :num_indels

    # @return [Float]
    attr_reader :ts_tv_ratio

    def initialize(chr_region, num_snps, num_indels, ts_tv_ratio)
      @chr_region = chr_region
      @num_snps = num_snps
      @num_indels = num_indels
      @ts_tv_ratio = ts_tv_ratio
    end

    class << self
      # @param vcf_path    [Pathname]
      # @param chr_region  [String]
      # @param metrics_dir [Pathname]
      # @return            [VcfReport, nil]
      def run(vcf_path, chr_region, metrics_dir)
        bcftools_stats_dir = metrics_dir / 'bcftools-stats'
        FileUtils.mkpath bcftools_stats_dir unless bcftools_stats_dir.exist?
        vcf_basename = vcf_path.basename
        bcftools_stats_path = bcftools_stats_dir / "#{vcf_basename}.bcftools-stats"
        container_data_dir = '/data'
        vcf_path = vcf_path.readlink if vcf_path.symlink?
        sh <<~COMMAND.squish
          singularity exec
          --bind #{vcf_path.dirname}:#{container_data_dir}
          #{BCFTOOLS_IMAGE_URI}
          bcftools stats
          #{container_data_dir}/#{vcf_basename}
          > #{bcftools_stats_path}
          2> #{bcftools_stats_path}.log
        COMMAND
        load_bcftools_stats(chr_region, bcftools_stats_path)
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
        ts_tv_ratio = field['TSTV'][4].to_f
        VcfReport.new(chr_region, num_snps, num_indels, ts_tv_ratio)
      end
    end
  end
end
