#!ruby
# -*- encoding: utf-8 -*-
require 'yaml'
require 'optparse'
require 'sqlite3'
require 'rsruby'
require_relative 'stock_analyzer'
require_relative 'contrib/ruby-progressbar-0.9/progressbar'

class RInterface
   @@r = RSRuby::instance
   def self.cmpo0(history)
       history.find_all { |x| x[0] > @@start }.collect { 
        |y| Date.jd(y[0]).strftime("%Y/%m/%d") }.join('","') 
   end
   def self.cmpo1(history)
       history.find_all { |x| x[0] > @@start }.collect { 
         |y| y[1] }.join(',')
   end

   def self.plot (a,b,saya)
    @@start = $idate.jd - $view_period
      
     @@r.eval_R(<<-RSCRIPT)
      axaxis  <- as.Date(c("#{cmpo0(a[:history])}"))
      a       <- c(#{cmpo1(a[:history])}) 
      bxaxis  <- as.Date(c("#{cmpo0(b[:history])}"))
      b       <- c(#{cmpo1(b[:history])}) 


      png("#{$work_dir}/#{saya[:image]}",width = 600, height = 600)
      layout(matrix(c(1,2),2,1,byrow=TRUE)) 
    
      xl <- c(head(axaxis,1),tail(axaxis,1))
      yl <- c(min(c(min(a)/head(a),min(b)/head(b))),max(c(max(a)/head(a),max(b)/head(b))))

      plot(axaxis,a/head(a),
      xlim=xl,ylim=yl,
      xaxt="n",yaxt="n",type="l",xlab="",ylab="",
      col=1,lty=1,lwd=2)

      par(new=T)
     
      plot(bxaxis,b/head(b,1),
      xlim=xl,ylim=yl,
      xaxt="n",type="l",
      col=2,lty=1,lwd=2,
      xlab="Date",ylab="KABUKA (-)")

      axis.Date(1,axaxis,format="%y-%m")

      sayaxaxis  <- as.Date(c("#{cmpo0(saya[:history])}"))
      saya       <- c(#{cmpo1(saya[:history])}) 
      mvaxaxis   <- as.Date(c("#{cmpo0(saya[:mva_history])}"))
      mva        <- c(#{cmpo1(saya[:mva_history])}) 
      bolbxaxis  <- as.Date(c("#{cmpo0(saya[:bollinger2sig][0])}"))
      bolb       <- c(#{cmpo1(saya[:bollinger2sig][0])}) 
      boltxaxis  <- as.Date(c("#{cmpo0(saya[:bollinger2sig][1])}"))
      bolt       <- c(#{cmpo1(saya[:bollinger2sig][1])}) 

      xl <- c(head(sayaxaxis,1),tail(sayaxaxis,1))
      yl <- c(min(c(min(saya),min(mva)),min(bolb)),max(c(max(saya),max(mva),max(bolt))))

      plot(sayaxaxis,saya,
      xlim=xl,ylim=yl,
      xaxt="n",yaxt="n",type="l",xlab="",ylab="",
      col=1,lty=1,lwd=2)

      par(new=T)

      plot(mvaxaxis,mva,
      xlim=xl,ylim=yl,
      xaxt="n",yaxt="n",type="l",xlab="",ylab="",
      col=2,lty=3,lwd=2)

      par(new=T)

      plot(bolbxaxis,bolb,
      xlim=xl,ylim=yl,
      xaxt="n",yaxt="n",type="l",xlab="",ylab="",
      col=2,lty=1,lwd=2)

      par(new=T)

      plot(boltxaxis,bolt,
      xlim=xl,ylim=yl,
      xaxt="n",type="l",
      col=2,lty=1,lwd=2,
      xlab="Date",ylab="SAYA (YEN)")

      axis.Date(1,sayaxaxis,format="%y-%m")

      dev.off()
    RSCRIPT
=begin


              mva_history:mva,
              sigma_hisroty:sigma,
              bollinger2sig:bollinger2sig})



      xaxis   <- as.Date(c("12/1/1","12/2/1"))
      a       <- c(1,2)
      b       <- c(3,2)
      print(length(xaxis))
      print(lengthma))
      print(length(b))
  
      print("#{$work_dir}/#{saya[:image]}")
      png("#{$work_dir}/#{saya[:image]}",width = 900, height = 900)
      par(cex.lab=1.5)
      layout(matrix(c(1,2,3,4,5,6),3,2,byrow=TRUE)) 

      lnCol   <- c(1,2)
      lnType  <- c(1,1)
      matplot (xaxis,cbind(a/head(a,1),b/head(b,1)),
      xaxt="n",type="l",
      col=lnCol,lty=lnType,lwd=2,
      xlab="Date",ylab="KABUKA (YEN)")

      axis.Date(1,xaxis,format="%y-%m")
      legend("topleft",
      c("#{a[:symbol]}","#{b[:symbol]}"),
      col = lnCol,
      lty = lnType,
      lwd = 2)
      
      plot(a,b,
        xlab="#{a[:symbol]} KABUKA (YEN)",
        ylab="#{b[:symbol]} KABUKA (YEN)")
      points(tail(a,1),
           tail(b,1),col="red",pch=3,cex=2)

      dev.off()
    RSCRIPT

	png("#{$work_dir}/#{l[0...4].join('-')}.png",width = 900, height = 900)
	par(cex.lab=1.5)
	layout(matrix(c(1,2,3,4,5,6),3,2,byrow=TRUE)) 

	lnCol   <- c(1,2)
	lnType  <- c(1,1)
    matplot (dates_t,cbind(aprice/head(aprice,1),bprice/head(bprice,1)),
		xaxt="n",type="l",
		col=lnCol,lty=lnType,lwd=2,
		xlab="Date",ylab="KABUKA (YEN)")
    axis.Date(1,dates_t,format="%y-%m")
	legend("topleft",
		c("#{a.symbol}","#{b.symbol}"),
		col = lnCol,
		lty = lnType,
		lwd = 2)
	plot(aprice,bprice,
		xlab="#{a.symbol} KABUKA (YEN)",
		ylab="#{b.symbol} KABUKA (YEN)")
	points(tail(aprice,1),
		   tail(bprice,1),col="red",pch=3,cex=2)

    hist (adiff,main="",xlab="#{a.symbol} DIFF (YEN)", breaks="Scott")
    hist (bdiff,main="",xlab="#{a.symbol} DIFF (YEN)", breaks="Scott")

    matplot (dates_t,cbind(saya_t,saya_m_t,
		saya_m_t+2*saya_sd_t,saya_m_t-2*saya_sd_t),
		xaxt="n",type="l",lwd=2,xlab="Date",ylab="SAYA (YEN)")
    axis.Date(1,dates_t,format="%y-%m")

    hist (saya_t_nmd,main="", xlab="SAYA KAIRIRITU", breaks="Scott")

    dev.off()
    hwriteImage("#{l[0...4].join('-')}.png",rp,br=TRUE,
		width=900,height=900)
=end
   end
end

def read_configure
  	conf = YAML.load_file 'configure.yaml'
    select = conf['SELECT']
    report = conf['REPORT']
    $work_dir = conf['WORK_DIR']
    if !File.exist?($work_dir) || File.ftype($work_dir) != "directory"
      raise ConfigError, "invalid WORK_DIR"
    end
    $period = select['PERIOD']
    $dma = select['DMA']
    $view_period = report['VIEW_PERIOD']
end

def sqlite_connect
  dbname = $work_dir + "/stock.sqlite3"
  $con = SQLite3::Database.open(dbname)
  
  $column = [:name,:symbol,:market_cap,:last_trade_price,:minimum_shares,
             :outstand_margin_buy,:oustand_margin_sell]
  command =<<SQL
select #{$column.join(',')} from toushou1_summary_column_jp
SQL
  $column_jp = {}
  $con.execute(command).flatten.each_with_index { |x,ind|
    $column_jp[$column[ind]] = x
  }
  $column_jp[:minimum_shares] = '単元株数<br>(株)'
  $column_jp[:market_cap] = '時価総額<br>(百万円)'
  
  $column_jp[:outstand_margin_rate] = '信用倍率'
  $column_jp[:purchase_price] = '購入価格<br>(円)'
  $column_jp[:purchase_day] = '購入日<br>(日)'
  $column_jp[:retention_period] = '保持日数<br>(日)'

end

def read_stock(symbol)
  command =<<SQL
select #{$column.join(',')} from toushou1_summary
where symbol = #{symbol}
SQL
  stock = {} 
  $con.execute(command).flatten.each_with_index { |x,ind|
    stock[$column[ind]] = x
  }

  stock[:outstand_margin_rate] = (stock[:oustand_margin_sell] != 0)?
       (stock[:outstand_margin_buy].to_f/stock[:oustand_margin_sell].to_f).round(2) : '-'

  tgt_table = "StockPrice#{symbol}"
  command =<<SQL
select date, close from #{tgt_table} 
where date <= '#{$idate}' 
order by date desc 
limit #{$period} 
SQL
  stock[:history] = $con.execute(command).reverse.collect { |x|
    sy,sm,sd = x[0].split('-').collect {|y| y.to_i }
    [Date.new(sy,sm,sd).jd,x[1]]
  }
  stock[:last_trade_price] = stock[:history].last[1]
  stock
rescue
  nil
end

def make_saya(a,b)
  saya_history = StockAnalyzer::make_saya_history(a[:history],b[:history],a[:num],b[:num])
  u_history, v_history = StockAnalyzer::make_kaisa_histories(a[:history],b[:history])
  k_history = StockAnalyzer::make_saya_history(u_history,v_history,a[:num],b[:num])
  ab = StockAnalyzer::correl(a[:history],b[:history])
  as = StockAnalyzer::correl(a[:history],saya_history)
  bs = StockAnalyzer::correl(b[:history],saya_history)
  uv = StockAnalyzer::correl(u_history,v_history)
  uk = StockAnalyzer::correl(u_history,k_history)
  vk = StockAnalyzer::correl(v_history,k_history)

  ab,as,bs,uv,uk,vk = [ab,as,bs,uv,uk,vk].collect { |x| x.round(2) } 

  saya = {history:saya_history,ab:ab,as:as,bs:bs,AB:uv,AS:uk,BS:vk}
 
  mva, sigma = StockAnalyzer::make_mva_history(saya_history,$dma), 
               StockAnalyzer::make_sigma_history(saya_history,$dma)
  bollinger2sig = StockAnalyzer::make_bollinger_bands(mva,sigma,2);

  saya.merge! ({last_trade_price:saya_history[1].last,
              purchase_price:a[:purchase_price]*a[:num] - b[:purchase_price]*b[:num],
              last_trade_sigma:sigma.last[1],
              symbol:"#{a[:symbol]}_#{b[:symbol]}",
              image:"#{[a[:symbol],b[:symbol],a[:num],b[:num]].join('-')}.png",
              mva_history:mva,
              sigma_hisroty:sigma,
              bollinger2sig:bollinger2sig})
end

opt = OptionParser.new
$ifname = nil
$holding = false

$idate = Date.today
opt.on("-f VAL","pair list filename") { |v| $ifname = v }
opt.on("-p","is holding file?") { $holding = true }
opt.on("-d VAL", "target date(%y-%m-%d)") { 
  $idate = Date.parse(v)
}

opt.parse!(ARGV)

begin

raise "pair list file is not given" unless $ifname

num_line = 0
File.open($ifname,'r').each { |line|
	num_line = num_line + 1
}

read_configure
sqlite_connect

o = File.open("#{$work_dir}/report-#{File.basename($ifname,'.*')}.html",'w')
o.puts <<HTML
<html>
<header>
<meta http-equiv="Content-Type" content='text/html; charset=utf-8'>
<meta http-equiv='Content-Style-Type' content='text/css'>
<title>j-saya:report</title>
<style type="text/css">
<!--
tr{
  text-align: center;
}
-->
</style>
</header>
<body>
HTML

pbar = ProgressBar.new('Report',num_line)
count = 1 

File.open($ifname,'r').each_with_index do |line,ind|
	pbar.inc

  next if ind == 0
   
  l = line.split ' '
  next if l.empty?

  a, b = {}, {}
  [a,b].each_with_index { |c,j|
    c[:symbol], c[:num] = l[j],l[j+2].to_i
    c[:purchase_price] = l[j+4].to_i if $holding
    c.merge!(read_stock(c[:symbol]))

    sy,sm,sd = l[6].split('-').collect {|y| y.to_i }
    c[:purchase_day] = l[6]
    sy,sm,sd = l[6].split('-').collect {|y| y.to_i }
    c[:retention_period] = Date.today.jd - Date.new(sy,sm,sd).jd
  }
  
  next unless [a,b].all? { |c| c[:history] != nil }

  [[a,b],[b,a]].each { |x,y|
	  x[:link] = "http://stocks.finance.yahoo.co.jp/stocks/chart/?code=#{x[:symbol]}.T&t=ay&q=l&c1=#{y[:symbol]}&bc="
  }

  saya = make_saya(a,b)



o.puts <<HTML

【#{count}】<a href="#{a[:link]}">#{a[:symbol]}</a>-<a href="#{b[:link]}">#{b[:symbol]}</a><br>

<table border='1'>
<tr>
<td>#{$column_jp[:symbol]}</td><td>#{$column_jp[:name]}</td><td>#{$column_jp[:last_trade_price]}</td>
#{"<td>#{$column_jp[:purchase_price]}</td><td>#{$column_jp[:purchase_day]}</td><td>#{$column_jp[:retention_period]}</td>" if $holding}
<td>#{$column_jp[:minimum_shares]}</td><td>#{$column_jp[:market_cap]}</td><td>#{$column_jp[:outstand_margin_rate]}</td>
</tr>
<tr>
<td>#{a[:symbol]}</td><td>#{a[:name]}</td><td>#{a[:last_trade_price]}</td>
#{"<td>#{a[:purchase_price]}</td><td rowspan='2'>#{a[:purchase_day]}</td><td rowspan='2'>#{a[:retention_period]}</td>" if $holding}
<td>#{a[:minimum_shares]}</td><td>#{a[:market_cap]}</td><td>#{a[:outstand_margin_rate]}</td>
</tr>
<tr>
<td>#{b[:symbol]}</td><td>#{b[:name]}</td><td>#{b[:last_trade_price]}</td>
#{"<td>#{b[:purchase_price]}</td>" if $holding}
<td>#{b[:minimum_shares]}</td><td>#{b[:market_cap]}</td><td>#{b[:outstand_margin_rate]}</td>
</tr>
</table>
<br>
<table border='1'>
<tr>
<td rowspan='2'>サヤ値<br>(円)</td><td rowspan='2'>購入値<br>(円)</td><td rowspan='2'>サヤσ<br>(円)</td>
<td colspan='6'>相関係数</td>
</tr>
<tr>
<td>ab</td><td>as</td><td>bs</td><td>AB</td><td>AS</td><td>BS</td>
</tr>
<tr>
<td>#{saya[:last_trade_price]}</td><td>#{saya[:purchase_price]}</td><td>#{saya[:last_trade_sigma]}</td>
<td>#{saya[:ab]}</td><td>#{saya[:as]}</td><td>#{saya[:bs]}</td><td>#{saya[:AB]}</td><td>#{saya[:AS]}</td><td>#{saya[:BS]}</td>
</tr>
</table>

<img border="0" src='#{saya[:image]}' alt='#{saya[:image]}' width="600" height="600"></img><br>

HTML

RInterface.plot(a,b,saya)

  count+=1
end

o.puts <<HTML
</body>
</html>
HTML

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


