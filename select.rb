#!ruby
# -*- encoding: utf-8 -*-
require 'yaml'
require 'optparse'
require 'sqlite3'
require_relative 'stock_analyzer'
require_relative 'contrib/ruby-progressbar-0.9/progressbar'

class ConfigError < StandardError; end

class Stock

  attr_reader :name,:code,:market_cap,:history

  def initialize(summary,history)
    @name, @code, @market_cap = 
      summary[:name],
      summary[:symbol].to_i,
      summary[:market_cap]
    @history = history
   end

  def self.make(summary)
    tgt_table = "StockPrice#{summary[:symbol]}"
    command =<<SQL
select date, close from #{tgt_table} 
    where date <= '#{@idate}' 
    order by date desc 
    limit #{$period} 
SQL
    history = @con.execute(command).reverse.collect { |x|
      sy,sm,sd = x[0].split('-').collect {|y| y.to_i }
      [Date.new(sy,sm,sd).jd,x[1]]
    }
    stock = Stock.new(summary,history)
  rescue
    nil
  end
end

def read_configure
  	conf = YAML.load_file 'configure.yaml'
    select = conf['SELECT']
    @work_dir = conf['WORK_DIR']
    if !File.exist?(@work_dir) || File.ftype(@work_dir) != "directory"
      raise ConfigError, "invalid WORK_DIR"
    end
    $period = select['PERIOD']
    $market_cap_min = select['MARKET_CAP_MIN'].to_i
    $saya_soukan_range = select['SAYA_SOUKAN_RANGE'].collect! { |x| x.to_f }
end

def sqlite_connect
  dbname = @work_dir + "/stock.sqlite3"
  @con = SQLite3::Database.open(dbname)
end

def read_stocks
  @stocks = []
  colums = [:name,:symbol,:market_cap]
   
  command =  "select #{colums.join(',')} from toushou1_summary"

  res = @con.execute(command)
	pbar = ProgressBar.new('Read stocks',res.size)
  res.each { |s|
    pbar.inc
    summary = {} 
    colums.each_with_index { |x,ind|  
       summary[x] = s[ind]
    }
    mked = Stock::make(summary)
    if  mked != nil; @stocks << mked; end
  }
end

opt = OptionParser.new

opt.on("-v","show version") { |v|  
  puts "version 0.1.0"
  exit
}

@idate = Date.today
opt.on("-d VAL", "target date(%y-%m-%d)") { |v|  
   	@idate = Date.parse(v)
}

opt.parse!(ARGV)

begin

read_configure
sqlite_connect
read_stocks

o = File.open("#{@work_dir}/selected.txt",'w')
o.puts @idate.to_s

pbar = ProgressBar.new('Select pairs',@stocks.size*(@stocks.size-1)/2)

@stocks.each { |a|
	@stocks.each { |b|
		if a.code >= b.code; next; end
    pbar.inc

    if a.market_cap < $market_cap_min || b.market_cap < $market_cap_min
       next 
    end

    begin

      correl = StockAnalyzer::correl(a.history,b.history)

      if correl < $saya_soukan_range[0] || $saya_soukan_range[1] < correl
        next
      end

    rescue
      next
    end

		o.puts "#{a.code} #{b.code} #{correl.round(3)}  ; #{a.name} #{b.name}"
    o.flush

  }
}

puts ''

rescue => e
  puts ''
  puts "[#{e.class.name}] #{e.message}"
  e.backtrace.each { |x|
    puts x
  }
ensure
  if @con && !@con.closed?
    @con.close
  end
end

