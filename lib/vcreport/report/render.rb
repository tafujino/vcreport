# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/report/paging'
require 'pathname'
require 'erb'
require 'redcarpet'
require 'thor'
require 'fileutils'

module VCReport
  module Report
    module Render
      extend Thor::Shell

      TEMPLATE_DIR = 'template'

      class << self
        # @param prefix            [String]
        # @param out_dir           [Pathname]
        # @param context           [Binding, nil]
        # @param paging            [Paging, nil]
        # @param overwrite         [Boolean]
        # @param use_markdown      [Boolean]
        # @param toc_nesting_level [Integer, nil]
        # @return                  [Pathname] HTML path
        def run(
              prefix,
              out_dir,
              context = nil,
              paging: nil,
              overwrite: true,
              use_markdown: true,
              toc_nesting_level: nil
            )
          if use_markdown
            render_markdown(
              prefix, out_dir, context, paging: paging, overwrite: overwrite
            )
          end
          render_html(
            prefix,
            out_dir,
            context,
            paging: paging,
            overwrite: overwrite,
            use_markdown: use_markdown,
            toc_nesting_level: toc_nesting_level
          )
        end

        # @param str    [String]
        # @param length [Integer]
        # @return       [String]
        def wrap_text(str, wrap_length = WRAP_LENGTH)
          str.each_line(chomp: true).map do |line|
            wrap_line(line, wrap_length)
          end.join("\n")
        end

        # @param src_path   [Pathname]
        # @param report_dir [Pathname]
        def copy_file(src_path, report_dir)
          dst_path = report_dir / File.basename(src_path)
          return if File.exist?(dst_path)

          FileUtils.cp src_path, dst_path
          say_status 'create', dst_path, :green
        end

        # @param text [String]
        # @param path [String, Pathname, nil]
        def markdown_link_text(text, path)
          if path
            "[#{text}](#{path})"
          else
            text
          end
        end

        private

        # @param line        [String]
        # @param wrap_length [Integer]
        # @return            [String]
        def wrap_line(line, wrap_length = WRAP_LENGTH)
          words = line.scan(/(?:[^\-\s])+(?:[\s\-]+|$)/)
          wrapped_words = [[]]
          line_length = 0
          words.each do |word|
            if wrapped_words.last.empty?
              wrapped_words.last << word
              if word.length > wrap_length
                wrapped_words << []
                line_length = 0
              end
            else
              if line_length + word.length > wrap_length
                wrapped_words << []
                line_length = 0
              end
              wrapped_words.last << word
              line_length += word.length
            end
          end
          wrapped_words.map(&:join).join("\n")
        end

        # @param prefix    [String]
        # @param out_dir   [Pathname]
        # @param context   [Binding, nil]
        # @param paging    [Paging, nil]
        # @param overwrite [Boolean]
        # @return          [Pathname]
        def render_markdown(prefix, out_dir, context = nil, paging: nil, overwrite: true)
          markdown_path = out_dir / "#{prefix}#{paging&.digits}.md"
          return if skip?(markdown_path, overwrite)

          context ||= binding
          %i[prev next].map do |m|
            context.local_variable_set(
              :"#{m}_html_path",
              paging&.send(m)&.digits&.then { |digits| "#{prefix}#{digits}.html" }
            )
          end
          template_path = "#{TEMPLATE_DIR}/#{prefix}.md.erb"
          render_erb(template_path, markdown_path, context) do |text|
            text.scan(/(!\[([^\]]*)\]\(([^\)]+)\))/).map do |pattern, label, path|
              dst_path = out_dir / File.basename(path)
              Render.copy_file(path, out_dir) unless dst_path.exist?
              [pattern, "![#{label}](#{dst_path.basename})"]
            end.each do |before, after|
              text.gsub!(before, after)
            end
            text
          end
          markdown_path
        end

        # @param prefix            [String]
        # @param out_dir           [Pathname]
        # @param context           [Binding, nil]
        # @param paging            [Paging, nil]
        # @param overwrite         [Boolean]
        # @param use_markdown      [Boolean]
        # @param toc_nesting_level [Integer, nil]
        # @return                  [Pathname]
        def render_html(
              prefix,
              out_dir,
              context = nil,
              paging: nil,
              overwrite: true,
              use_markdown: true,
              toc_nesting_level: nil
            )
          filename = "#{prefix}#{paging&.digits}"
          html_path = out_dir / "#{filename}.html"
          return if skip?(html_path, overwrite)

          context ||= binding
          if use_markdown
            set_markdown_variable_to_context(context, html_path, toc_nesting_level)
          end
          template_path = "#{TEMPLATE_DIR}/#{prefix}.html.erb"
          render_erb(template_path, html_path, context)
          html_path
        end

        # @param context           [Binding]
        # @param html_path         [String]
        # @param toc_nesting_level [Integer, nil]
        def set_markdown_variable_to_context(
              context, html_path, toc_nesting_level = nil
            )
          markdown_path = html_path.sub_ext('.md')
          markdown_text = File.read(markdown_path)
          context.local_variable_set(:content_body, content_html(markdown_text))
          return unless toc_nesting_level

          toc_body = toc_html(markdown_text, toc_nesting_level)
          context.local_variable_set(:toc_body, toc_body)
        end

        # @param markdown_text [String]
        # @return              [String]
        def content_html(markdown_text)
          markdown = Redcarpet::Markdown.new(
            Redcarpet::Render::HTML.new(with_toc_data: true),
            tables: true,
            fenced_code_blocks: true,
            disable_indented_code_blocks: false
          )
          markdown.render(markdown_text)
        end

        # @param markdown_text     [String]
        # @param toc_nesting_level [Integer, nil]
        # @return                  [String]
        def toc_html(markdown_text, toc_nesting_level)
          toc = Redcarpet::Markdown.new(
            Redcarpet::Render::HTML_TOC.new(nesting_level: toc_nesting_level)
          )
          toc.render(markdown_text)
        end

        # @param path      [String]
        # @param overwrite [Boolean]
        def skip?(path, overwrite)
          if File.exist?(path) && !overwrite
            say_status 'skip', path, :yellow
            true
          else
            false
          end
        end

        # @param template_path [Pathname]
        # @param out_path      [Pathname]
        # @param context       [Binding, nil]
        def render_erb(template_path, out_path, context = nil)
          template_path = File.expand_path(template_path, __dir__)
          erb = ERB.new(File.open(template_path).read, trim_mode: '-')
          context ||= binding
          text = erb.result(context)
          text = yield text if block_given?
          File.write(out_path, text)
          say_status 'create', out_path, :green
        end
      end
    end
  end
end
