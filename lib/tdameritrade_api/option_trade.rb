module TDAmeritradeApi
  module OptionTrade
    OPTION_CHAIN_URL='https://apis.tdameritrade.com/apps/100/OptionTrade'

    # symbol=CSCO
    # expire=201611
    # quotes=true
    def create_options_trade(symbol, options={})

      action = options[:action] #buytoopen, buytoclose, selltoopen, selltoclose
      expire = "day"
      order_type = "limit"
      account_id = "782527840"
      quantity = options[:quantity]
      price = options[:price]
      orderstring = URI.escape("accountid=#{account_id}~action=#{action}~quantity=#{quantity}~price=#{price}~symbol=#{symbol}~ordtype=#{order_type}~expire=#{expire}")
      request_params = build_request_params(orderstring, options)

      uri = URI.parse OPTION_CHAIN_URL
      uri.query = URI.encode_www_form(request_params)

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      oc_hash = {"error"=>"failed"}
      puts response.body
      puts response.body.to_s
      result_hash = Hash.from_xml(response.body.to_s)
      if result_hash['amtd']['result'] == 'OK' then
        oc_hash = result_hash['amtd']['option_chain_results']
      end

      oc_hash
    rescue Exception => e
      raise TDAmeritradeApiError, "error in create_options_trade() - #{e.message}" if !e.is_ctrl_c_exception?
    end

    private

    def build_request_params(orderstring, options)
      {source: @source_id, orderstring: orderstring}.merge(options)
    end
  end
end
