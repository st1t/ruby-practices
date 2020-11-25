#!/usr/bin/env /usr/bin/ruby
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
  require 'etc'

  def execute
    option = AppOption.new
    filtered_files = filter_files(current_directory_files(option.has?(:all)), option)
    blocks = files_blocks(filtered_files)
    print_files(blocks, filtered_files, option.has?(:long))
  end

  private

  def current_directory_files(all_flag)
    files = {}
    Dir.foreach('.') do |f|
      files[:"#{f}"] = File::Stat.new(f)
    end
    all_flag ? files : filter_hidden_files(files)
  end

  def files_blocks(files)
    blocks = 0
    files.each do |f|
      blocks += f[6]
    end
    blocks
  end

  def filter_files(files, option)
    filtered_hidden_files = option.has?(:all) ? files : filter_hidden_files(files)
    filtered_long_files = filter_long_files(filtered_hidden_files, option.has?(:long))
    filter_reverse_files(filtered_long_files, option.has?(:reverse), option.has?(:long))
  end

  def print_files(blocks, rows, long_flag)
    rows.each_with_index do |row, i|
      if long_flag
        puts "合計 #{blocks}" if i.zero?
        puts "#{row[0]}#{row[1]} #{row[2]} #{row[3]} #{row[4]} #{row[5]} #{row[7]} #{row[8]}"
      elsif i == rows.length - 1
        print "#{row[0]} \n"
      else
        print "#{row[0]} "
      end
    end
  end

  def filter_hidden_files(files)
    hash = {}

    filtered_files = files.find_all do |file|
      !/^\./.match(:"#{file[0]}")
    end

    filtered_files.each do |file|
      hash[":#{file[0]}"] = file[1]
    end
  end

  # input: {:"ls.rb"=>#<File::Stat>,:"test.rb"=>#<File::Stat>}
  def filter_long_files(files, long_flag)
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
    row.push(fstat.nlink, user_name(fstat.uid), group_name(fstat.gid))
    row.push(fstat.size, fstat.blocks, created_time(fstat.mtime))
    row << file[0].to_s.gsub(/^:/, '')
  end

  def user_name(uid)
    Etc.getpwuid(uid).name
  end

  def group_name(gid)
    Etc.getgrgid(gid).name
  end

  def created_time(time)
    time.strftime('%m月 %d %H:%M').to_s
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

  def filter_reverse_files(files, reverse_flag, long_flag)
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
