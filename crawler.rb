require 'httparty'
require 'nokogiri'
require 'byebug'
require 'watir'
require 'webdrivers'
require 'pry'

# class BtcScraper

	# def initialize
	LOCAL_BITCOINS_COP_QUICK_BUY_URL = "https://localbitcoins.com/instant-bitcoins/?action=buy&country_code=CO&amount=&currency=COP&place_country=CO&online_provider=SPECIFIC_BANK&find-offers=Search"
	LOCAL_BITCOINS_COP_QUICK_SELL_URL = "https://localbitcoins.com/instant-bitcoins/?action=sell&country_code=CO&amount=&currency=COP&place_country=CO&online_provider=SPECIFIC_BANK&find-offers=Search"
	LOCAL_BITCOINS_USD_QUICK_BUY_URL = "https://localbitcoins.com/instant-bitcoins/?action=buy&country_code=US&amount=&currency=USD&place_country=US&online_provider=ZELLE&find-offers=Search"
	SETFX_USD_TRM_URL = "http://www.set-fx.com/index.html"
	def scrape_page(url)
		scrape = Nokogiri::HTML(HTTParty.get(url))
	end
	@TRM = 0
	def get_usd_trm
		p 'calculando trm'
		a =  Time.now
		page = scrape_page(SETFX_USD_TRM_URL)
		browser = Watir::Browser.start('http://www.set-fx.com/index.html', browser = :firefox)
		begin
			Watir::Wait.until(timeout: 10) {browser.element(css: "#barraTuristaPromedio").text.include? '$'}
		rescue Watir::Wait::TimeoutError => e
			p e
		end
		live_trm = browser.element(css: "#barraTuristaPromedio").text
		day_trm = browser.element(css: "#trmPrice").text
		p live_trm
		p day_trm
		p 'trm calculada'
		b = Time.now
		p "#{b - a} seconds"
		live_trm.empty? ? trm = day_trm.delete('.').to_f : trm = browser.element(css: "#barraTuristaPromedio").text[2..]&.delete(',').to_f
		# trm = browser.element(css: "#barraTuristaPromedio").text[2..]&.delete(',').to_f || browser.element(css: "#trmPrice").text[2..].delete(',').to_f
		byebug
		trm
	end
		
	# end
	
	def get_trm
		trm = HTTParty.post("https://arses-currency-exchange1.p.rapidapi.com/getRealTimeCurrencyRate/COP/", 
		headers: {"x-rapidapi-host": "arses-currency-exchange1.p.rapidapi.com",
		"x-rapidapi-key": "77a8ff910fmshc138d14fb3cf3cdp160c46jsn220e7871ac0e",
		"content-type": "application/x-www-form-urlencoded"})
		trm.parsed_response['detail']['USD']['cop-per-unit'].to_f.round(2) if trm.parsed_response['detail'] && trm.parsed_response['detail']['USD']['cop-per-unit']
	end

	def get_trm_fallback
		trm = HTTParty.get("https://currency-exchange.p.rapidapi.com/exchange?from=USD&to=COP", 
			headers: {"x-rapidapi-host": "currency-exchange.p.rapidapi.com",
			"x-rapidapi-key": "77a8ff910fmshc138d14fb3cf3cdp160c46jsn220e7871ac0e",
			"content-type": "application/x-www-form-urlencoded"}).to_f
	end

	def get_btc_in_usd
		response = HTTParty.get("https://localbitcoins.com/api/equation/btc_in_usd")
		btc_in_usd = response.parsed_response['data'].to_f
	end

	def get_quick_sell_offers
		page = scrape_page(LOCAL_BITCOINS_COP_QUICK_SELL_URL)
		get_offers page
	end
	
	def get_quick_buy_cop_offers
		page = scrape_page(LOCAL_BITCOINS_COP_QUICK_BUY_URL)
		get_offers page
	end

	def get_offers page
		filas = page.css('tr.clickable')
		ofertas = filas.css('tr').map{ |f| f.css('td.column-price').text.match(/(\d+,*\d*,*\d*)/)[1].delete(',').to_f/@TRM if f.css('td')[1].text.downcase.match?(/bancolombia|davivienda|nequi/) &&
																			 f.css('td.column-limit').text.match(/(-|least) (\d+,*\d*,*\d*)/).captures.last.delete(',').to_f >= 1000000}.compact

		ofertas
	end

  def get_quick_buy_offers
    page = scrape_page(LOCAL_BITCOINS_USD_QUICK_BUY_URL)
    ofertas = page.css('td.column-price').map{|o| o.children.text.strip[0...-4].delete(',').to_f}
	end
	
	def calculate
		@TRM = get_trm
		unless @TRM
			@TRM = get_trm_fallback
		end
		@Bitstamp = get_btc_in_usd
		p Time.now
		p "TRM = #{@TRM}"
		p "Bitstamp = #{@Bitstamp} -----> $#{(@Bitstamp*@TRM).round} COP"
		cop_offers = get_quick_sell_offers
		quick_buy_offers = get_quick_buy_cop_offers
		usd_offers = get_quick_buy_offers

		best_cop = cop_offers.first.round(2)
		best_buy_cop = quick_buy_offers.first.round(2)
		best_usd = usd_offers.first.round(2)
		p "Best offer in COP today is #{best_cop}: #{((@Bitstamp/best_cop -1)*100).round(2)}% "
		p "Best quick buy offer in cop right now is #{best_buy_cop}: #{((@Bitstamp/best_buy_cop -1)*100).round(2)}%" 
		p "SPREAD for posting: #{((best_buy_cop/best_cop -1)*100).round(2)}%"
		p "Best offer in USD today is #{best_usd}: #{((best_usd/@Bitstamp -1)*100).round(2)}%"
		p "Spread for today is: #{((best_usd/best_cop-1)*100).round(2)}%"
	end
	
	# private 

# end

calculate