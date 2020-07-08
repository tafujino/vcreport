# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/process_info'
require 'pathname'
require 'fileutils'
require 'thor'

module VCReport
  module Daemon
    extend Thor::Shell

    class << self
      # @param dir              [String]
      # @param metrics_manager  [MetricsManager]
      # @param metrics_interval [Integer] in seconds
      def start(dir, metrics_manager, metrics_interval = DEFAULT_METRICS_INTERVAL)
        if ProcessInfo.load(dir)
          say_status 'already running', dir, :yellow
          exit 1
        end
        say_status 'start', dir, :green
        Process.daemon(true)
        ProcessInfo.store(dir)
        loop do
          Report.run(dir, metrics_manager)
          sleep(metrics_interval)
        end
      end

      # @param dir [String, Pathname]
      # @return    [ProcessInfo, nil]
      def status(dir)
        ProcessInfo.load(dir)
      end

      # @param dir [String, Pathname]
      # @return    [Symbol] :success, :fail or :not_running
      def stop(dir)
        psinfo = ProcessInfo.load(dir)
        return :not_running unless psinfo

        begin
          # stop the daemon and its child processes for metrics calculation
          Process.kill '-TERM', psinfo.pgid if status(dir)
          ProcessInfo.remove(dir)
          :success
        rescue => e
          warn e.message
          :fail
        end
      end
    end
  end
end
