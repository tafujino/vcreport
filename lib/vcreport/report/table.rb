# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/numeric/conversions'
require 'stringio'

module VCReport
  module Report
    class Table
      # @param header [Array<String>]
      # @param rows   [Array<Array>>]
      # @param type   [Array<Symbol>] :string, :integer, :float or :numeric
      def initialize(header, rows = [], type = [])
        @header = header
        @rows = rows
        @type = type
      end

      # @param row [Array]
      def push(*row)
        @rows << row
      end

      # @return [String]
      def markdown_text
        sio = StringIO.new
        sio.puts row_text(@header, is_header: true)
        sio.puts separator_text(@type)
        @rows.each do |row|
          sio.puts row_text(row, type: @type)
        end
        sio.string
      end

      private

      # @param type [Array<Symbol>] :string, :integer, :float or :numeric
      # @return     [String]
      def separator_text(type)
        type.map do |t|
          case t
          when :string, nil
            '---'
          when :integer, :float, :numeric
            '---:'
          else
            warn "Unknown type: #{t}"
            exit 1
          end
        end.then { |fields| render_fields(fields) }
      end

      # @param row       [Array]
      # @param type      [Array<Symbol>] :string, :integer, :float or :numeric
      # @param is_header [Boolean]
      # @return          [String]
      def row_text(row, type: [], is_header: false)
        fields = row.zip(type).map do |e, t|
          next e.to_s if is_header

          case t
          when :string, :float, :numeric, nil
            e.to_s
          when :integer
            e.to_s(:delimited)
          else
            warn "Unknown type: #{t}"
            exit 1
          end
        end
        render_fields(fields)
      end

      # @param fields [Array<String>]
      # @return       [String]
      def render_fields(fields)
        ['| ', fields.join(' | '), ' |'].join
      end
    end
  end
end
