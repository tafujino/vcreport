# frozen_string_literal: true

require 'fileutils'
require 'vcreport/chr_region'

module VCReport
  module Report
    class Vcf
      class BcftoolsStats
        # @return [Pathname]
        attr_reader :path

        # @return [ChrRegion]
        attr_reader :chr_region

        # @return [Integer]
        attr_reader :num_snps

        # @return [Integer]
        attr_reader :num_indels

        # @return [Float]
        attr_reader :ts_tv_ratio

        def initialize(path, chr_region, num_snps, num_indels, ts_tv_ratio)
          @path = path
          @chr_region = chr_region
          @num_snps = num_snps
          @num_indels = num_indels
          @ts_tv_ratio = ts_tv_ratio
        end
      end
    end
  end
end
