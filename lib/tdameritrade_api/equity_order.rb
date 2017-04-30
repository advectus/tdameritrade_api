module TDAmeritradeApi
  module EquityOrder
    EQUITYORDER_URL='https://apis.tdameritrade.com/apps/100/EquityTrade'

    ACTION_TYPE=[:sell, :buy, :sellshort, :buytocover]
    EXPIRE_TYPE=[:day, :moc, :day_ext, :gtc, :gtc_ext, :am, :pm]
    ORDER_TYPE=[:market, :limit, :stop_market, :stop_limit, :tstoppercent, :tstopdollar]
    ROUTING_TYPE=[:auto, :inet, :ecn_arca]
    SPINSTRUCTIONS_TYPE=[:none, :fok, :aon, :dnr, :aon_dnr]

    # for conditional orders
    CONDITIONALORDER_URL='https://apis.tdameritrade.com/apps/100/ConditionalEquityTrade'
    ORDER_TICKET=[:oca, :ota, :ott, :otoca, :otota]

    EDITORDER_URL='https://apis.tdameritrade.com/apps/100/EditOrder'

    CANCELORDER_URL='https://apis.tdameritrade.com/apps/100/OrderCancel'

    # +submit_order+ submit equity order
    # +options+ may contain any of the params outlined in the API docs
    def submit_order(order_info, conditional=false)
      validate_order_options(order_info, conditional)
      request_params = build_order_request_params(order_info)
      #request_params[:symbol] = request_params[:symbol].to_s.upcase

      if !conditional then
        uri = URI.parse EQUITYORDER_URL
      else
        uri = URI.parse CONDITIONALORDER_URL
      end

      built_query = URI.encode_www_form(request_params)
      puts built_query
      another_query = built_query.gsub!('&','~')
      p another_query
      yet_another_query = CGI.escape(another_query)
      puts yet_another_query
      uri.query = URI.encode_www_form({source: @source_id, orderstring: yet_another_query})
      p uri

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      parsed_response = Nokogiri::XML::Document.parse response.body
      p response.body

    rescue Exception => e
      raise TDAmeritradeApiError, "error in submit_order() - #{e.message}" if !e.is_ctrl_c_exception?
    end

    def edit_order(order_info, conditional=false)
      # validate_order_options(order_info, conditional)
      request_params = build_order_request_params(order_info)

      uri = URI.parse EDITORDER_URL

      built_query = URI.encode_www_form(request_params)
      uri.query = built_query.gsub!('&','~').gsub!('source=EDRI~','source=EDRI&orderstring=')
      p uri

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

    parsed_response = Nokogiri::XML::Document.parse response.body

    p response.body

    rescue Exception => e
      raise TDAmeritradeApiError, "error in edit_order() - #{e.message}" if !e.is_ctrl_c_exception?
    end

    def cancel_order(order_info)
      request_params = build_order_request_params(order_info)

      uri = URI.parse CANCELORDER_URL

      uri.query = URI.encode_www_form(request_params)

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      parsed_response = Nokogiri::XML::Document.parse response.body

      p response.body

    rescue Exception => e
      raise TDAmeritradeApiError, "error in cancel_order() - #{e.message}" if !e.is_ctrl_c_exception?
    end

    def get_order_status(order_options)
    end

    private

    def todays_date
      Date.today
    end

    def parse_last_trade_date(date_string)
      DateTime.parse(date_string)
    rescue
      0
    end

    def date_s(date)
      date.strftime('%Y%m%d')
    end

    def validate_order_options(options, conditional)
      if (conditional && !(options.has_key?(:totlegs) && 1 < options[:totlegs] && options[:totlegs] < 4))
        raise TDAmeritradeApiError, "For conditional orders totlegs must be 2 or 3: #{options[:totlegs]}"
      end

      (0..3).each do |leg|
          next if conditional && leg == 0
          next if !conditional && leg > 0
          subscript = leg == 0 ? "" : leg

          if !(options.has_key?(:"quantity#{subscript}") && options[:"quantity#{subscript}"].is_a?(Integer))
            raise TDAmeritradeApiError, "You must provide a quantity#{subscript}: #{options[:"quantity#{subscript}"]}"
          end

          if options.has_key?(:clientorderid) && !options[:clientorderid].is_a?(Integer)
            raise TDAmeritradeApiError, "Option clientorderid must be Integer: #{options[:clientorderid]}"
          end

          ## TODO Add more:

          if !options.has_key?(:"action#{subscript}") || ACTION_TYPE.index(options[:"action#{subscript}"]).nil?
            raise TDAmeritradeApiError, "Invalid equity trade option for action#{subscript}: #{options[:"action#{subscript}"]}"
          end
       end

    end

    def build_order_request_params(options)
      options[:accountid] = @accounts[0][:account_id]
      puts options
      options
    end
  end
end
