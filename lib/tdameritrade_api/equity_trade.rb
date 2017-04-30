require 'httparty'
require 'nokogiri'
require 'tdameritrade_api/constants'
require 'tdameritrade_api/tdameritrade_api_error'

module TDAmeritradeApi
  module EquityTrade
    include Constants
    EQUITY_TRADE_URL = 'https://apis.tdameritrade.com/apps/100/EquityTrade'

    #https://apis.tdameritrade.com/apps/100/EquityTrade?source=<#sourceID#>
    #&orderstring=action%3Dbuy%7Equantity%3D400%7Esymbol%3DDELL%7Eordtype%3DLimit%7 Eprice%3D27.49%7Eactprice%3D%7Etsparam%3D%7Eexpire%3Dday%7Espinstructions%3Dnon e%7Erouting%3Dauto%7Edisplaysize%3D%7Eexmonth%3D%7Eexday%3D%7Eexyear%3D%7Ea ccountid%3D123456789
    ###
    #
    # buytoopen, buytoclose, selltoopen, selltoclose
    # ordertype market, limit, stop_market, stop_limit
    # expire: day, gtc
    ###
    def create_trade(account_id, action, quantity, symbol, order_type, price, options={})
      orderstring = CGI.escape("accountid=782527840~action=#{action}~quantity=#{quantity}~symbol=#{symbol.upcase!}~ordtype=#{order_type}~price=#{price}~expire=day_ext")

      request_params = build_trade_params(orderstring, options)

      uri = URI.parse EQUITY_TRADE_URL
      uri.query = URI.encode_www_form(request_params)

      puts uri

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: DEFAULT_TIMEOUT)
      if response.code != 200
        fail "HTTP response #{response.code}: #{response.body}"
      end

      puts response

      w = Nokogiri::XML::Document.parse response.body
      result = {
        result:      w.css('result').text,
        error:       w.css('error').text,
        account_id:  w.css('account-id').text,
        orderstring: w.css('order-wrapper orderstring').text,
        symbol:      w.css('order-wrapper order security symbol').text,
      }
      result
    rescue Exception => e
      raise TDAmeritradeApiError, e.message
    end

    private

    def build_trade_params(orderstring, options)
      {source: @source_id, orderstring: orderstring}.merge(options)
    end

  end
end
