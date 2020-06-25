# frozen_string_literal: true

require 'vcreport/settings'
require 'pathname'
require 'fileutils'
require 'yaml'

module VCReport
  module Daemon
    class << self
      # @param dir              [String]
      # @param metrics_manager  [MetricsManager]
      # @param metrics_interval [Integer] in seconds
      def start(dir, metrics_manager, metrics_interval = DEFAULT_METRICS_INTERVAL)
        Process.daemon(true)
        store_pid(dir)
        loop do
          Report.run(dir, metrics_manager)
          sleep(metrics_interval)
        end
      end

      # @param dir [String, Pathname]
      # @return    [Hash { Symbol => Integer }, nil] { pid: ___, pgid: ___ }
      def status(dir)
        ps = load_pid(dir)
        return nil unless ps

        begin
          Process.kill 0, ps[:pid]
          ps
        rescue Errno::ESRCH
          nil
        end
      end

      # @param dir [String, Pathname]
      # @return    [Symbol] :success, :fail or :not_running
      def stop(dir)
        ps = status(dir)
        return :not_running unless ps

        begin
          # stop the daemon and its child processes for metrics calculation
          Process.kill '-TERM', ps[:pgid] if status(dir)
          FileUtils.remove_entry_secure(pid_path(dir))
          :success
        rescue e
          warn e.message
          :fail
        end
      end

      private

      # @param dir [String, Pathname]
      # @return    [Pathname]
      def pid_path(dir)
        Pathname.new(dir) / 'vcreport.process'
      end

      # @param dir [String, Pathname]
      # @return    [Hash{ Symbol => Integer }, nil] { pid: ___, pgid: ___ }
      def load_pid(dir)
        return nil unless File.exist?(pid_path(dir))

        YAML.load_file(pid_path(dir))
      end

      # @param dir [String, Pathname]
      def store_pid(dir)
        pid = Process.pid
        pgid = Process.getpgid(pid)
        ps = { pid: pid,  pgid: pgid }
        File.write(pid_path(dir), YAML.dump(ps))
      end
    end
  end
end
