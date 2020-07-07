# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/numeric/conversions'
require 'stringio'

class VCReport
  module Report
    class Table
      # @param header [Array]
      # @param rows   [Array<Array>>]
      # @param type   [Array<Symbol>] :string, :integer or :float
      def initialize(header, rows = [], align: [])
        @header = header
        @rows = rows
        @align = align
        @num_cols = header.length
        @num_rows = rows.length
      end

      # @param row [Array]
      def push(*row)
        @rows << row
      end

      # @return [String]
      def markdown_text
        sio = StringIO.new
        sio.puts row_text(@header)
        sio.puts separator_text(@type)
        @rows.each do |row|
          sio.puts row_text(row)
        end
        sio.string
      end

      private

      # @param type [Array<Symbol>] :string, :integer or :float
      # @return     [String]
      def separator_text(type)
        type.map do |t|
          case t
          when :string, nil
            '---'
          when :integer, :float
            '---:'
          else
            warn "Unknown type: #{t}"
            exit 1
          end
        end.then { |fields| render_fields(fields) }
      end

      # @param row  [Array]
      # @param type [Array<Symbol>] :string, :integer or :float
      # @return     [String]
      def row_text(row, type = [])
        fields = row.zip(type).map do |e, t|
          case t
          when :string, :float, nil
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
