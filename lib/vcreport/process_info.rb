# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'vcreport/settings'

module VCReport
  class ProcessInfo
    # @return [Integer]
    attr_reader :pid

    # @return [Integer]
    attr_reader :pgid

    # @param pid  [Integer]
    # @param pgid [Integer]
    def initialize(pid, pgid)
      @pid = pid
      @pgid = pgid
    end

    def terminate_all
      Process.kill '-TERM', @pgid
    rescue Errno::ESRCH
      # do nothing
    end

    def active?
      Process.kill 0, @pid
      true
    rescue Errno::ESRCH
      false
    end

    class << self
      # The status of the process (and its child processes) related to
      # the directory. Fixes an inconsistency dectected.
      # @param dir [String, Pathname]
      # @return    [ProcessInfo, nil]
      def status(dir)
        return nil unless File.exist?(pid_path(dir))

        psinfo = load_file(dir)
        return psinfo if psinfo.active?

        terminate(psinfo, dir)
        nil
      end

      # @param psinfo [ProcessInfo, nil]
      # @param dir    [String, Pathname]
      def terminate(psinfo, dir)
        psinfo.terminate_all
        remove_file(dir)
      end

      # @param dir [String, Pathname]
      def store_current_process(dir)
        pid = Process.pid
        pgid = Process.getpgid(pid)
        ps = { pid: pid,  pgid: pgid }
        File.write(pid_path(dir), YAML.dump(ps))
      end

      private

      # @param dir [Pathname]
      # @return    [ProcessInfo]
      def load_file(dir)
        h = YAML.load_file(pid_path(dir))
        ProcessInfo.new(h[:pid], h[:pgid])
      end

      # @param dir [String, Pathname]
      def remove_file(dir)
        return unless File.exist?(pid_path(dir))

        FileUtils.remove_entry_secure(pid_path(dir))
      end

      # @param dir [String, Pathname]
      # @return    [Pathname]
      def pid_path(dir)
        Pathname.new(dir) / MONITOR_PROCESS_INFO_PATH
      end
    end
  end
end
