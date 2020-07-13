# frozen_string_literal: true

require 'fileutils'
require 'vcreport/chr_region'
require 'vcreport/report/vcf/bcftools_stats'

module VCReport
  module Report
    class Vcf
      # @return [Pathname]
      attr_reader :vcf_path

      # @return [ChrRegion]
      attr_reader :chr_region

      # @return [BcftoolsStats, nil]
      attr_reader :bcftools_stats

      def initialize(vcf_path, chr_region, bcftools_stats)
        @vcf_path = vcf_path
        @chr_region = chr_region
        @bcftools_stats = bcftools_stats
      end
    end
  end
end
