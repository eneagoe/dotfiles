#!/usr/bin/env ruby
# frozen_string_literal: true

require "find"

root = Dir.pwd
groups = Hash.new { |h, k| h[k] = [] }

Find.find(root) do |path|
  rel = path.sub(/\A#{Regexp.escape(root)}\/?/, "")
  next if rel.empty?

  parts = rel.split(File::SEPARATOR)
  next if parts.any? { |p| p.start_with?(".") }
  next if parts.first == "node_modules"

  if File.directory?(path)
    next
  else
    parent = File.dirname(rel)
    parent = "." if parent == "."
    groups[parent] << File.basename(rel)
  end
end

groups.keys.sort.each do |dir|
  depth = dir == "." ? 0 : dir.split(File::SEPARATOR).length
  header = depth <= 1 ? "##" : "###"
  puts "#{header} #{dir}"
  groups[dir].sort.each do |file|
    puts "- [ ] #{file}"
  end
  puts
end
