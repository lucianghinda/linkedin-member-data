#!/usr/bin/env ruby
# frozen_string_literal: true

# Rebuilds the "# Documentation" index inside the top namespace document that YARD
# generated, then writes llms.txt at the repo root with root-relative links.
#
# Run after `rake yard`. Needs doc/ to exist.

require "pathname"

class LlmGenerator
  # Set this when the namespace cannot be derived from lib/**/version.rb,
  # e.g. MAIN_DOCUMENT_OVERRIDE = File.join("doc", "MyGem.md")
  MAIN_DOCUMENT_OVERRIDE = File.join("doc", "LinkedIn", "MemberData.md")

  DOCUMENTATION_INDEX = /(?:^# Documentation[ \t]*\r?\n(?:[ \t]*\r?\n|-[ \t]+\[[^\n]*\]\([^\n]*\)[ \t]*\r?\n)*)+\z/
  VERSION_CONSTANT = /VERSION\s*=\s*["'][^"']+["']/

  def initialize(root: File.expand_path("..", __dir__), stdout: $stdout, stderr: $stderr)
    @root = root
    @stdout = stdout
    @stderr = stderr
  end

  def call
    return false unless main_document_path

    unless File.file?(main_document)
      stderr.puts "Missing #{main_document}"
      return false
    end

    content = "#{File.read(main_document).rstrip}\n".sub(DOCUMENTATION_INDEX, "").rstrip
    content = [content, "# Documentation", documentation_links].join("\n\n").rstrip << "\n"

    File.write(main_document, content)
    File.write(File.join(root, "llms.txt"), root_relative_links(content))
    stdout.puts "Updated #{main_document_path} (#{documentation_files.size} links)"
    true
  end

  private

  attr_reader :root, :stdout, :stderr

  # The namespace lives in the lib tree, not in the gem name: `jekyll-agent-markdown`
  # splits into three segments but `lib/jekyll/agent_markdown` is only two deep.
  def main_document_path
    return @main_document_path if defined?(@main_document_path)

    @main_document_path =
      if MAIN_DOCUMENT_OVERRIDE
        MAIN_DOCUMENT_OVERRIDE
      elsif namespace_segments.any?
        "#{File.join("doc", *namespace_segments)}.md"
      else
        stderr.puts "Cannot find lib/**/version.rb; set MAIN_DOCUMENT_OVERRIDE"
        nil
      end
  end

  def namespace_segments
    return @namespace_segments if defined?(@namespace_segments)

    version_file = Dir.glob(File.join(root, "lib", "**", "version.rb"))
                      .sort_by { |path| path.count(File::SEPARATOR) }
                      .find { |path| File.read(path).match?(VERSION_CONSTANT) }

    @namespace_segments =
      if version_file
        File.dirname(version_file)
            .delete_prefix(File.join(root, "lib"))
            .split(File::SEPARATOR)
            .reject(&:empty?)
            .map { |segment| segment.split("_").map(&:capitalize).join }
      else
        []
      end
  end

  def main_document
    File.join(root, main_document_path)
  end

  def documentation_root
    File.dirname(main_document_path)
  end

  # Every namespace YARD documented for this gem, not only the main module tree.
  def documentation_files
    Dir.glob(File.join(root, documentation_root, "**", "*.md")) - [main_document]
  end

  def documentation_links
    documentation_files.map do |path|
      relative_path = path.delete_prefix("#{File.join(root, documentation_root)}/")
      "- [#{relative_path}](#{relative_path})"
    end.join("\n")
  end

  def root_relative_links(content)
    # Leave fenced and inline code examples untouched when rebasing YARD links.
    content.split(/(```.*?```|~~~.*?~~~|`[^`\n]*`)/m).each_with_index.map do |part, index|
      next part if index.odd?

      part.gsub(/(?<!!)\[([^\]\n]+)\]\(([^)\s]+)\)/) do |link|
        label = Regexp.last_match(1)
        target = Regexp.last_match(2)
        next link if target.match?(%r{\A(?:[a-z][a-z\d+.-]*:|/|#)}i)

        path, suffix = target.split(/(?=[?#])/, 2)
        next link unless path.end_with?(".md")

        relative_path = Pathname.new(File.join(documentation_root, path)).cleanpath
        "[#{label}](#{relative_path}#{suffix})"
      end
    end.join
  end
end

exit(LlmGenerator.new.call ? 0 : 1) if $PROGRAM_NAME == __FILE__
