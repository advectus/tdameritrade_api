module TDAmeritradeApi
  module OptionChain
    OPTION_CHAIN_URL='https://apis.tdameritrade.com/apps/200/OptionChain'

    # symbol=CSCO
    # expire=201611
    # quotes=true
    def get_option_chain(symbol, options={})
      request_params = build_oc_params(symbol, options)

      uri = URI.parse OPTION_CHAIN_URL
      uri.query = URI.encode_www_form(request_params)

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      oc_hash = {"error"=>"failed"}
      result_hash = Hash.from_xml(response.body.to_s)
      if result_hash['amtd']['result'] == 'OK' then
        oc_hash = result_hash['amtd']['option_chain_results']
      end

      oc_hash
    rescue Exception => e
      raise TDAmeritradeApiError, "error in get_option_chain() - #{e.message}" if !e.is_ctrl_c_exception?
    end

    private

    def build_oc_params(symbol, options)
      {source: @source_id, symbol: symbol}.merge(options)
    end
  end
end
