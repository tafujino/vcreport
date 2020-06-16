# frozen_string_literal: true

require 'vcreport/settings'
require 'pathname'

module VCReport
  module Metrics
    class << self
      # @param dir [String]
      def run(dir)
        dir = Pathname.new(dir)
        Scan.sample_dirs(dir).each do |sample_dir|

        end
      end
    end
  end
end
