# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/generate'
require 'vcreport/sample_report'
require 'vcreport/progress_report'
require 'active_support'
require 'active_support/core_ext/string/filters'
require 'pathname'

module VCReport
  module Daemon
    class << self
      # @param data_dir [String]
      # @param report_dir [String]
      def run(data_dir, report_dir, interval = DEFAULT_INTERVAL)
        loop do
          Generate.run(data_dir, report_dir)
          warn "Sleep #{interval} seconds"
          sleep interval
        end
      end
    end
  end
end
