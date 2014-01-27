#!/ruby
# -*- encoding: utf-8 -*-
require 'yaml'
require 'optparse'
require 'sqlite3'
require_relative 'yahoojp_finance_scraping.rb'
require_relative 'contrib/ruby-progressbar-0.9/progressbar'

@code_range  = [1301,9999]
@code_toyota = '7203.T'

class String
  def extract_value
   	o = match(/-{0,1}([0-9],{0,1})+(\.[0-9]+){0,1}/)
    if o == nil
      self
    else
      o[0].split(',').inject("") { |x,y| x << y }.to_i
    end
  end
end

class ConfigError < StandardError; end

def read_configure
 	conf = YAML.load_file 'configure.yaml'
	@db_sdate = conf['DB']['START_DATE']
  @work_dir = conf['WORK_DIR']
  if !File.exist?(@work_dir) 
    Dir.mkdir @work_dir 
  elsif File.ftype(@work_dir) != "directory"
    raise ConfigError, "WORK_DIR must be directory"
  end
end 

def quote (code) 
  begin
	qt = YahooJPStock::Quote.new(code)
  rescue
    return nil
  end
 
	if qt.name[1] == nil 
		return nil 
	end	
	r = {:name=>qt.name,:symbol=>qt.symbol,:market=>qt.market}
	o = qt.output

  [:outstand_margin_buy,:oustand_margin_sell,
		:last_trade_price,:minimum_shares,:market_cap].each { |k|
     	r[k] = [o[k][0], o[k][1].extract_value]
	}
  concat = {:outstand_margin_buy =>"(株)",
			  :oustand_margin_sell=>"(株)",
			  :last_trade_price   =>"(円)",
			  :minimum_shares     =>"(株)",
			  :market_cap		  =>"(百万円)"}
	concat.each { |k,v| 
		r[k][0] << v
	}
	return r 
end

def sqlite_connect
  dbname = @work_dir + "/stock.sqlite3"
  if File.exist?(dbname) 
     @con = SQLite3::Database.open(dbname)
  else
     @con = SQLite3::Database.new(dbname) 
     @opts[:s] = true
  end
end

def renew_summary_table
  q = quote(@code_toyota)
  toushou1 = q[:market][1]	

  command =<<SQL
select name from sqlite_master where type = 'table'
SQL

  exist_tables = @con.execute(command).flatten

  tgt_table = 'toushou1_summary_column_jp'
  if exist_tables.include? tgt_table
    @con.execute("drop table #{tgt_table}")
  end
  command =<<SQL
create table #{tgt_table} 
(					
name 	text,
symbol text,
market text,
outstand_margin_buy text, 
oustand_margin_sell text,
last_trade_price text,
minimum_shares text,
market_cap text
)
SQL
  
  @con.execute command

  pcommand =<<SQL
  insert into #{tgt_table} VALUES (?,?,?,?,?,?,?,?)
SQL
 
begin
  stmt = @con.prepare pcommand
  
	stmt.execute q[:name][0],
	q[:symbol][0],
	q[:market][0],
	q[:outstand_margin_buy][0],
	q[:oustand_margin_sell][0],
	q[:last_trade_price][0],
	q[:minimum_shares][0],
	q[:market_cap][0]
ensure
  stmt.close unless stmt.closed?
end

tgt_table = 'toushou1_summary'
  if exist_tables.include? tgt_table
    @con.execute("drop table #{tgt_table}")
  end
  command =<<SQL
create table #{tgt_table} 
(					
name 	text,
symbol text,
market text,
outstand_margin_buy integer, 
oustand_margin_sell integer,
last_trade_price integer,
minimum_shares integer,
market_cap integer
)
SQL

  @con.execute command

  pcommand =<<SQL
  insert into #{tgt_table} VALUES (?,?,?,?,?,?,?,?)
SQL
 
begin
  stmt = @con.prepare pcommand

	pbar = ProgressBar.new('R. summaries',@code_range.last-@code_range.first)

	for c in @code_range.first..@code_range.last	
		pbar.inc
		code = c.to_s + ".T"

		if (q = quote(code)) == nil or q[:market][1] != toushou1
			next
		end
	
		stmt.execute q[:name][1],
		q[:symbol][1],
		q[:market][1],
		q[:outstand_margin_buy][1],
		q[:oustand_margin_sell][1],
		q[:last_trade_price][1],
		q[:minimum_shares][1],
		q[:market_cap][1]
	end
	puts ''
ensure
  stmt.close unless stmt.closed?
end
end

def remove_all_histories
  command =<<SQL
select name from sqlite_master where type = 'table'
SQL
  exist_tables = @con.execute(command).flatten

  delete_tables = []
	exist_tables.each { |x| 
		if x != 'toushou1_summary' && x != 'toushou1_summary_column_jp' 
			delete_tables << x 
		end
	}
	
	pbar = ProgressBar.new('D. histories',delete_tables.size)
	delete_tables.each { |x|
		pbar.inc
    @con.execute("drop table #{x}")
	}
	puts ''
end

def renew_histories
  command =<<SQL
select name from sqlite_master where type = 'table'
SQL
  exist_tables = @con.execute(command).flatten

  t_tables = []
	exist_tables.each { |x| 
		if x != 'toushou1_summary' && x != 'toushou1_summary_column_jp' 
			t_tables << x 
		end
	}

	symbols = @con.execute('select symbol from toushou1_summary').flatten

	pbar = ProgressBar.new('C. histories',symbols.size)


	symbols.each { |code| 
    pbar.inc
    code = code.to_i
		if code < @code_range[0] || @code_range[1] < code
			next
		end 
		name,sdate = "StockPrice#{code}", @db_sdate
		
    if t_tables.include? name
			day = @con.execute("select max(date) from #{name}").flatten[0]
      if day == nil
        next
      end
			sy,sm,sd = day.split('-').collect { |x| x.to_i }
	    sdate = Date.new(sy,sm,sd) + 1 	
	  else 
       @con.execute "create table #{name} (date text, close integer)"
    end
 
    case sdate.wday
    when 0
      sdate = sdate + 1
    when 6
      sdate = sdate + 2
    end

    if Date.today < sdate; next; end;
    
		output = YahooJPStock::History.new("#{code}.T",sdate,Date.today).output
		output.shift
		revo = output.inject([]) { |x,y|
			sy,sm,sd = y[0].scan(/[0-9]+/).collect { |x| x.to_i }
      x.unshift [Date.new(sy,sm,sd).strftime("%Y-%m-%d"), y[6].delete(',')]
		}
begin
		stmt = @con.prepare "insert into #{name} VALUES (?,?)"
		for o in revo
			stmt.execute o[0],o[1] 
		end
ensure
    stmt.close unless stmt.closed?
		t_tables.delete name
end
  }
	#t_tables.each { |x|
	#@con.execute("drop table #{x}")
	#}
	puts ''
end

opt = OptionParser.new
@opts = {}
Version = '1.0.1'
Description = {:s =>"renew summaries of stocks",
               :t =>"renew histrical prices of stocks",
               :v =>"show version"}

Description.each { |k,v|
	opt.on("-#{k}", v) {|v| @opts[k] = true }
}

opt.parse!(ARGV)

if @opts[:v]
  puts "version 0.1.0"
  exit
end

begin

read_configure

sqlite_connect

if @opts[:s]
  renew_summary_table
end

if @opts[:t]
  remove_all_histories
end

renew_histories

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


