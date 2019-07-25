#!/usr/bin/env ruby -w

def meta?(line)
  line =~ /^[A-Z\s]+$/ ||
    line =~ /^\s*ruby\s+\d+.*$/ ||
      line =~ /^\s+[\d|\.]+$/ ||
        line =~ /[!]\s*$/ ||
          line =~ /:/
end

lines = File.readlines("Gemfile.lock").reject { |line| meta?(line) }.
  map { |line| line.split.first }.sort.uniq

puts lines
