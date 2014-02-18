#!ruby
# -*- encoding: utf-8 -*-
require 'yaml'
require 'optparse'
require 'sqlite3'
require_relative 'stock_analyzer'
require_relative 'contrib/ruby-progressbar-0.9/progressbar'

class ConfigError < StandardError; end

class Stock

  attr_reader :name,:code,:market_cap,
    :last_trade_price,:minimum_shares,
    :history

  def initialize(summary,history)
    @name, @code, @market_cap, @last_trade_price, @minimum_shares = 
      summary[:name],
      summary[:symbol].to_i,
      summary[:market_cap].to_i,
      summary[:last_trade_price].to_i,
      summary[:minimum_shares].to_i
    @history = history
   end

  def self.make(summary)
    tgt_table = "StockPrice#{summary[:symbol]}"
    command =<<SQL
select date, close from #{tgt_table} 
    where date <= '#{$idate}' 
    order by date desc 
    limit #{$period} 
SQL
    history = $con.execute(command).reverse.collect { |x|
      sy,sm,sd = x[0].split('-').collect {|y| y.to_i }
      [Date.new(sy,sm,sd).jd,x[1]]
    }
    stock = Stock.new(summary,history)
  rescue
    nil
  end
end

module StockAnalyzer 
  def self.holding (a,b,cost)
		m = []
		[a,b].each { |x|
			m << (x.last_trade_price*x.minimum_shares).to_f
		}
		scale = 3*([m[0]/m[1],m[1]/m[0]].max.to_i + 1)
		pairs = []
		(1..scale).each { |x|
		 	(1..scale).each { |y| 
				if [m[0]*x,m[1]*y].max < cost	
					pairs << [x*a.minimum_shares,y*b.minimum_shares]
				end
			}
		}
		sorted = pairs.sort { |s,t|
			(s[0]*a.last_trade_price - s[1]*b.last_trade_price).abs <=>
				(t[0]*a.last_trade_price - t[1]*b.last_trade_price).abs 
		}.first(1)
		return sorted
  end
end

def read_configure
  	conf = YAML.load_file 'configure.yaml'
    select = conf['SELECT']
    $work_dir = conf['WORK_DIR']
    if !File.exist?($work_dir) || File.ftype($work_dir) != "directory"
      raise ConfigError, "invalid WORK_DIR"
    end
    $period = select['PERIOD']
    $market_cap_min = select['MARKET_CAP_MIN'].to_i
    $trade_cost_max = select['TRADE_COST_MAX'].to_i
     
    soukan = select['SOUKAN']
    $stock_soukan = soukan['STOCK'].collect { |x| x.to_f }
    $stock_saya_soukan = soukan['STOCK_SAYA'].collect! { |x| x.to_f }
    $kaisa_soukan = soukan['KAISA'].collect { |x| x.to_f }
    $kaisa_kaisasaya_soukan = soukan['KAISA_KAISASAYA'].collect { |x| x.to_f }
end

def sqlite_connect
  dbname = $work_dir + "/stock.sqlite3"
  $con = SQLite3::Database.open(dbname)
end

def read_stocks
  $stocks = []
  colums = [:name,:symbol,:market_cap,:last_trade_price,:minimum_shares]
   
  command =  "select #{colums.join(',')} from toushou1_summary"

  res = $con.execute(command)
	pbar = ProgressBar.new('Read stocks',res.size)

  res.each { |s|
    pbar.inc
    summary = {} 
    colums.each_with_index { |x,ind|  
       summary[x] = s[ind]
    }
    mked = Stock::make(summary)
    $stocks << mked unless mked == nil
  }
  puts ''
end

opt = OptionParser.new

opt.on("-v","show version") { |v|  
  puts "version 0.1.0"
  exit
}

$idate = Date.today
opt.on("-d VAL", "target date(%y-%m-%d)") { |v|  
   	$idate = Date.parse(v)
}

opt.parse!(ARGV)

begin

read_configure
sqlite_connect
read_stocks

o = File.open("#{$work_dir}/selected.txt",'w')
o.puts $idate.to_s

pbar = ProgressBar.new('Select pairs',$stocks.size*($stocks.size-1)/2)

$stocks.each { |a|
	$stocks.each { |b|
		if a.code >= b.code; next; end
    pbar.inc

    if a.market_cap < $market_cap_min || b.market_cap < $market_cap_min
       next 
    end

    begin

      ab = StockAnalyzer::correl(a.history,b.history)
      next if ab < $stock_soukan[0] || $stock_soukan[1] < ab

      StockAnalyzer::holding(a,b,$trade_cost_max).each { |m,n| 
        saya_history = StockAnalyzer::make_saya_history(a.history,b.history,m,n)
        as = StockAnalyzer::correl(a.history,saya_history)

        next if as < $stock_saya_soukan[0] || $stock_saya_soukan[1] < as 

        bs = StockAnalyzer::correl(b.history,saya_history)
        next if bs < $stock_saya_soukan[0] || $stock_saya_soukan[1] < bs 

        u_history, v_history = StockAnalyzer::make_kaisa_histories(a.history,b.history)

        uv = StockAnalyzer::correl(u_history,v_history)
        next if uv < $kaisa_soukan[0] || $kaisa_soukan[1] < uv 
        
        k_history = StockAnalyzer::make_saya_history(u_history,v_history,m,n)

        uk = StockAnalyzer::correl(u_history,k_history)
        next if uk < $kaisa_kaisasaya_soukan[0] || $kaisa_kaisasaya_soukan[1] < uk

        vk = StockAnalyzer::correl(v_history,k_history)
        next if vk < $kaisa_kaisasaya_soukan[0] || $kaisa_kaisasaya_soukan[1] < vk
        
        ab,as,bs,uv,uk,vk = [ab,as,bs,uv,uk,vk].collect { |x| x.round(2) } 

        o.puts "#{a.code} #{b.code} #{m} #{n} " + 
               "; #{a.name} #{b.name}" +
               "#{ab} #{as} #{bs} " +
               "#{uv} #{uk} #{vk} "
        o.flush
      }
    rescue
      next
    end

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
  if $con && !$con.closed?
    $con.close
  end
end

