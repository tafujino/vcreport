# frozen_string_literal: true

require 'vcreport/settings'
require 'pathname'
require 'fileutils'

module VCReport
  module Daemon
    class << self
      # @param dir      [String]
      # @param interval [Integer] in second
      def run(dir, interval = nil)
        interval ||= DEFAULT_INTERVAL
        Process.daemon(true)
        store_pid(dir)
        loop do
          yield
          sleep(interval)
        end
      end

      def status(dir)
        pid = load_pid(dir)
        return nil unless pid

        begin
          Process.kill 0, pid
          pid
        rescue Errno::ESRCH
          nil
        end
      end

      def stop(dir)
        pid = status(dir)
        return :not_running unless status(dir)

        begin
          Process.kill :TERM, pid if status(dir)
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
        Pathname.new(dir) / 'vcreport.pid'
      end

      # @param dir [String, Pathname]
      # @return    [Integer, nil]
      def load_pid(dir)
        return nil unless File.exist?(pid_path(dir))

        begin
          File.open(pid_path(dir)) do |f|
            return f.readline(chomp: true).to_i
          end
        rescue EOFError
          nil
        end
      end

      # @param dir [String, Pathname]
      def store_pid(dir)
        File.open(pid_path(dir), 'w') do |f|
          f.puts Process.pid
        end
      end
    end
  end
end
