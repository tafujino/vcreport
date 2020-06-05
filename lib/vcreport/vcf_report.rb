# frozen_string_literal: true

module VCReport
  class VcfReport
    # @return [String]
    attr_reader :chr_region

    # @return [Integer]
    attr_reader :num_snps

    # @return [Integer]
    attr_reader :num_indels

    # @return [Float]
    attr_reader :ts_tv_ratio
  end

  def initialize(chr_region, num_snps, num_indels, ts_tv_ratio)
    @chr_region = chr_region
    @num_snps = num_snps
    @num_indels = num_indels
    @ts_tv_ratio = ts_tv_ratio
  end

  class << self
    def load_bcftools_stats(path)

    end
  end
end
