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
      # @param metrics_dir [Pathname]
      # @return            [VcfReport, nil]
      def run(vcf_path, metrics_dir)
        bcftools_stats_dir = metrics_dir / 'bcftoosl-stats'
        FileUtils.mkpath bcftools_stats_dir unless bcftools_stats_dir.exist?
        vcf_basename = vcf_path.basename
        bcftools_stats_path = bcftools_stats_dir / "#{vcf_basename}.bcftools-stats"
        container_data_dir = '/data'
        ret = sh <<~COMMAND.squish
          singularity exec
          --bind #{vcf_path.dirname}:#{container_data_dir}
          #{BCFTOOLS_IMAGE_URI}
          bcftools stats
          #{container_data_dir}/#{vcf_basename}
          > #{bcftools_stats_path}
          2> #{bcftools_stats_path}.log
        COMMAND
        warn 'bcftools failed' unless ret

        load_bcftools_stats(bcftools_stats_path)
      end

      private

      def load_bcftools_stats(bcftools_stats_path)
      end
    end
  end
end
