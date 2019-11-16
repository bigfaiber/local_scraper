require 'httparty'
require 'nokogiri'
require 'byebug'
require 'watir'
require 'webdrivers'

# class BtcScraper

	# def initialize
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
		trm.parsed_response['detail']['USD']['cop-per-unit'].to_f.round(2)
	end

	def get_quick_sell_offers
		page = scrape_page(LOCAL_BITCOINS_COP_QUICK_SELL_URL)
    ofertas = page.css('td.column-price').map{|o| o.children.text.strip[0...-4].delete(',').to_f/@TRM}
  end

  def get_quick_buy_offers
    page = scrape_page(LOCAL_BITCOINS_USD_QUICK_BUY_URL)
    ofertas = page.css('td.column-price').map{|o| o.children.text.strip[0...-4].delete(',').to_f}
	end
	
	def calculate
		@TRM = get_trm
		p @TRM
		cop_offers = get_quick_sell_offers
		usd_offers = get_quick_buy_offers
		p "Best offer in COP today is #{cop_offers.first}"
		p "Best offer in USD today is #{usd_offers.first}"
		p "Spread for today is: #{((usd_offers.first/cop_offers.first).round(2)-1)*100}%"
	end
	
	# private 

# end

calculate