# frozen_string_literal: true

require 'optparse'
require 'date'

input_opts = ARGV.getopts('y:m:')
year = input_opts['y'].nil? ? Date.today.year : input_opts['y'].to_i
month = input_opts['m'].nil? ? Date.today.month : input_opts['m'].to_i

def print_header(year, month)
  puts "      #{month}月 #{year}年"
  puts ' 日 月 火 水 木 金 土'
end

# 指定された月の1日が日曜でない場合は空白で埋める
def print_space(year, month)
  return if Date.new(year, month, 1).sunday?

  (0..(Date.new(year, month, 1).wday - 1)).each do
    print '   '
  end
end

def space(day)
  day < 10 ? '  ' : ' '
end

def print_day(year, month)
  (1..Date.new(year, month, -1).day).each do |day|
    if Date.new(year, month, day).saturday?
      puts "#{space(day)}#{day}"
    else
      print("#{space(day)}#{day}")
    end
  end
end

print_header(year, month)
print_space(year, month)
print_day(year, month)
puts unless Date.new(year, month, -1).saturday?
