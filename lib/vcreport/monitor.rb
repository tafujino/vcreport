# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/config'
require 'vcreport/process_info'
require 'vcreport/system'
require 'pathname'
require 'fileutils'
require 'thor'

module VCReport
  module Monitor
    extend Thor::Shell

    class << self
      # @param dir              [String]
      # @param job_manager      [JobManager]
      # @param metrics_interval [Integer] in seconds
      def start(dir, config, job_manager, interval = DEFAULT_INTERVAL)
        if ProcessInfo.status(dir)
          say_status 'already running', dir, :yellow
          exit 1
        end
        say_status 'start', dir, :green
        Process.daemon(true)
        ProcessInfo.store_current_process(dir)
        system = System.instance
        system.dir = dir
        system.monitor = true
        system.monitor_logger.info 'Start monitoring'
        loop do
          system.monitor_logger.info 'Start periodical reporting'
          begin
            Report.run(dir, config, job_manager)
          rescue => e
            system.monitor_logger.error e.to_s
          end
          system.monitor_logger.info 'End periodical reporting'
          sleep(interval)
        end
      end

      # @param dir [String, Pathname]
      # @return    [ProcessInfo, nil]
      def status(dir)
        ProcessInfo.status(dir)
      end

      def stop_self
        system = System.instance
        System.instance.monitor_logger.info 'End monitoring' if system.monitor
        exit 0
      end

      # @param dir [String, Pathname]
      # @return    [Symbol] :success, :fail or :not_running
      def stop(dir)
        psinfo = ProcessInfo.status(dir)
        return :not_running unless psinfo

        begin
          # stop the daemon and its child processes
          ProcessInfo.terminate(psinfo, dir)
          :success
        rescue => e
          warn e.message
          :fail
        end
      end
    end
  end
end
