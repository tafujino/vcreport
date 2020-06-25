# frozen_string_literal: true

require 'yaml'
require 'fileutils'

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

    class << self
      # @param dir [String, Pathname]
      # @return    [ProcessInfo, nil]
      def load(dir)
        return nil unless File.exist?(pid_path(dir))

        h = YAML.load_file(pid_path(dir))
        ps = ProcessInfo.new(h[:pid], h[:pgid])
        begin
          Process.kill 0, ps.pid
          ps
        rescue Errno::ESRCH
          remove(dir)
          nil
        end
      end

      # @param dir [String, Pathname]
      def store(dir)
        pid = Process.pid
        pgid = Process.getpgid(pid)
        ps = { pid: pid,  pgid: pgid }
        File.write(pid_path(dir), YAML.dump(ps))
      end

      # @param dir [String, Pathname]
      def remove(dir)
        return unless File.exist?(pid_path(dir))

        FileUtils.remove_entry_secure(pid_path(dir))
      end

      private

      # @param dir [String, Pathname]
      # @return    [Pathname]
      def pid_path(dir)
        Pathname.new(dir) / 'vcreport.process'
      end
    end
  end
end
