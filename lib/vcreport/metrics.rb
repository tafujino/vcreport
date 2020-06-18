# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/scan'
require 'vcreport/metrics/vcf'
require 'pathname'

module VCReport
  module Metrics
    class << self
      # @param dir [String]
      def run(dir)
        dir = Pathname.new(dir)
        Scan.sample_dirs(dir).each do |sample_dir|
          Scan.vcf_paths(sample_dir).each do |vcf_path|

          end
        end
      end
    end
  end
end
