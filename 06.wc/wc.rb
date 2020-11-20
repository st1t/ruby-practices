#!/usr/bin/env /usr/bin/ruby
# frozen_string_literal: true

# AppOption class is a class to parse input options
class AppOption
  require 'optparse'

  def initialize
    @options = {}
    OptionParser.new do |o|
      o.on('-l', '--lines', 'print the newline counts') { @options[:lines] = true }
      o.on('-h', '--help', 'show this help') { |_| puts o }
      o.parse!(ARGV)
    end
  end

  def has?(name)
    @options.include?(name)
  end
end

# Wc class is a class that mimics the ls command
class Wc
  def execute
    option = AppOption.new

    if !ARGV.empty?
      parse_result = parse_arguments(ARGV)
    elsif standard_input?
      parse_result = parse_standard_input($stdin.readlines)
    else
      return
    end
    print_wc_result(parse_result, option.has?(:lines))
  end

  private

  def standard_input?
    !(File.pipe?($stdin) || File.select([$stdin], [], [], 0)).nil?
  end

  def parse_arguments(files)
    array = []
    files.each do |file|
      wf = WcFile.new(file)
      array << [file, wf.number_of_lines, wf.number_of_words, wf.number_of_bytes]
    end
    array
  end

  def parse_standard_input(lines)
    number_of_words = 0
    number_of_bytes = 0

    lines.each do |line|
      number_of_words += number_of_words(line)
      number_of_bytes += line.size
    end
    [lines.size, number_of_words, number_of_bytes]
  end

  def number_of_words(line)
    line.split(/\n|\t|\s+|　+/).length
  end

  # result variable: [1, 1, 5] : using standard input
  # result variable: [["test.rb", 5, 16, 74]] : using arguments
  def print_wc_result(results, line_flag)
    if results[0][0].instance_of?(String)
      line_flag ? print_wc_line(results) : print_wc_stdin(results)
    elsif results[0][0].instance_of?(Integer)
      puts line_flag ? results[0] : "#{results[0]} #{results[1]} #{results[2]}"
    end
  end

  def print_wc_line(results)
    sum_lines = 0
    results.each do |r|
      puts "#{r[1]} #{r[0]}"
      sum_lines += r[1]
    end
    puts "#{sum_lines} 合計"
  end

  def print_wc_stdin(results)
    sum_lines = 0
    sum_words = 0
    sum_bytes = 0
    results.each do |r|
      puts "#{r[1]} #{r[2]} #{r[3]} #{r[0]}"
      sum_lines += r[1]
      sum_words += r[2]
      sum_bytes += r[3]
    end
    puts "#{sum_lines} #{sum_words} #{sum_bytes} 合計"
  end
end

class WcFile
  def initialize(file)
    @file = file
  end

  def number_of_lines
    lines = []
    File.open(@file) do |f|
      f.each_line do |line|
        lines << line
      end
    end
    lines.length
  end

  def number_of_words
    count = 0
    File.open(@file) do |f|
      f.each_line do |line|
        line.gsub!(/[\n|\t|\s|　]/, ',')
        array = line.split(/,/)
        count += array.length
      end
    end
    count
  end

  def number_of_bytes
    File.new(@file).size
  end
end

Wc.new.execute
