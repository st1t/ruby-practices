# frozen_string_literal: true

# AppOption class is a class to parse input options
class AppOption
  require 'optparse'

  def initialize
    @options = {}
    OptionParser.new do |o|
      o.on('-a', '--all', 'show all files') { @options[:all] = true }
      o.on('-l', '--long', 'show detailed information') { @options[:long] = true }
      o.on('-r', '--reverse', 'show in descending order') { @options[:reverse] = true }
      o.on('-h', '--help', 'show this help') { |_| puts o }
      o.parse!(ARGV)
    end
  end

  def has?(name)
    @options.include?(name)
  end
end

# Ls class is a class that mimics the ls command
class Ls
  def execute
    option = AppOption.new
    files = parse_options(current_directory_files, option)
    print_files(files)
  end

  private

  def current_directory_files
    files = {}
    Dir.foreach('.') do |f|
      files[:"#{f}"] = File::Stat.new(f)
    end
    files
  end

  def parse_options(files, option)
    all_files = parse_all_option(files, option.has?(:all))
    long_files = parse_long_option(all_files, option.has?(:long))
    parse_reverse_option(long_files, option.has?(:reverse), option.has?(:long))
  end

  def print_files(rows)
    rows.each do |row|
      puts "#{row[0]}#{row[1]} #{row[2]} #{row[3]} #{row[4]} #{row[5]} #{row[6]} #{row[7]}"
    end
  end

  # input: {:"ls.rb"=>#<File::Stat>,:".dummy"=>#<File::Stat>}
  def parse_all_option(files, all_flag)
    if all_flag
      files
    else
      hash = {}
      not_hidden_files(files).each do |file|
        hash[":#{file[0]}"] = file[1]
      end
    end
  end

  def not_hidden_files(files)
    files.find_all do |file|
      !/^\./.match(:"#{file[0]}")
    end
  end

  # input: {:"ls.rb"=>#<File::Stat>,:"test.rb"=>#<File::Stat>}
  def parse_long_option(files, long_flag)
    array = []
    files.each do |f|
      array << if long_flag
                 long_info_file(f)
               else
                 [f[0].to_s.gsub(/^:/, '')]
               end
    end
    array
  end

  # input: [:"ls.rb", #<File::Stat>]
  def long_info_file(file)
    row = []
    fstat = file[1]
    row.push(file_symbol(fstat), file_permission(fstat.mode.to_s(2)))
    row.push(fstat.nlink, fstat.uid, fstat.gid, fstat.size, fstat.mtime)
    row << file[0].to_s.gsub(/^:/, '')
  end

  def file_symbol(fstat)
    fstat.ftype.chars[0]
  end

  # input: "100000111111101"
  def file_permission(binary_code)
    binary_code_permission = binary_code.slice(-9, binary_code.length + 1).chars
    permission = ''

    binary_code_permission.each_slice(3).to_a.each do |a|
      permission += a[0].to_i == 1 ? 'r' : '-'
      permission += a[1].to_i == 1 ? 'w' : '-'
      permission += a[2].to_i == 1 ? 'x' : '-'
    end
    permission
  end

  def parse_reverse_option(files, reverse_flag, long_flag)
    if reverse_flag && long_flag
      files.sort do |a, b|
        b[7] <=> a[7]
      end
    elsif reverse_flag
      files.reverse
    else
      files.sort
    end
  end
end

Ls.new.execute
