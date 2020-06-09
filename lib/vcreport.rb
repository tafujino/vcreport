# frozen_string_literal: true

require 'vcreport/version'
require 'vcreport/daemon'
require 'vcreport/generate'
require 'thor'

module VCReport
  module CLI
    class Main < Thor
      def self.exit_on_failure?
        true
      end

      desc 'start [DATA_DIR] [REPORT_DIR]', 'Start a report daemon'
      def start(data_dir, report_dir)
        vcrepd_path = File.expand_path('vcrepd', File.dirname($PROGRAM_NAME))
        say 'Start a report daemon'
        say "Data directory: #{data_dir}"
        say "Report directory: #{report_dir}"
        ret = system "#{vcrepd_path} #{data_dir} #{report_dir}"
        unless ret
          warn 'Report dameon failed'
          exit 1
        end
      end

      desc 'list', 'list running daemons'
      def list
        processes = `ps -ef`.split("\n").map do |line|
          fields = line.chomp.split(/\s+/)
          pid = fields[1]
          cmd = fields[8..-1]
          pp cmd
          next nil unless cmd[0] =~ %r{(^|/)ruby$} && cmd[1] =~ %r{(^|/)vcrepd$}

          [pid, cmd[2], cmd[3]]
        end.compact
        if processes.empty?
          warn '(empty)'
          return
        end

        warn %w[PID DATA_DIR REPORT_DIR].join("\t")
        processes.each do |pid, data_dir, report_dir|
          warn [pid, data_dir, report_dir].join("\t")
        end
      end

      desc 'stop [DATA_DIR]', 'Stop a report daemon'
      def stop(data_dir)
      end

      desc 'generate [DATA_DIR] [REPORT_DIR]', 'Generate reports'
      def generate(data_dir, report_dir)
        Generate.run(data_dir, report_dir)
      end
    end
  end
end
