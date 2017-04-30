module TDAmeritradeApi
  module QuoteNews
    QUOTE_NEWS_URL='https://apis.tdameritrade.com/apps/100/QuoteNews'

    # symbol=CSCO
    def get_quote_news(symbol, options={})
      request_params = build_qn_params(symbol, options)

      uri = URI.parse QUOTE_NEWS_URL
      uri.query = URI.encode_www_form(request_params)

      puts uri

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      qn_hash = {"error"=>"failed"}
      puts qn_hash
      puts response
      puts response.body
      result_hash = Hash.from_xml(response.body.to_s)
      puts result_hash
      puts result_hash['amtd']
      puts result_hash['amtd']['XML_MULTISYMBOL_NEWS']
      if result_hash['amtd']['result'] == 'OK' then
        qn_hash = result_hash['amtd']
      end

      qn_hash
    rescue Exception => e
      raise TDAmeritradeApiError, "error in get_quote_news() - #{e.message}" if !e.is_ctrl_c_exception?
    end

    private

    def build_qn_params(symbol, options)
      {source: @source_id, symbol: symbol, format: "compact", submit: "Submit"}.merge(options)
    end
  end
end
