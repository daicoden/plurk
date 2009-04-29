module Plurk
  class << self
    @@api_host = 'http://www.plurk.com'
    def login(username,password)
      user = Plurk::Base.new(username,password)
      user.login ? user : nil
    end
    
    def plurks_for(nick_or_user, options = {})
      nick,user = nick_or_user, nick_or_user # For code readibility
      uid = (nick_or_user.class == Plurk::Base) ? user.uid : Plurk.nickname_to_uid(nick)
      options[:from_date]       ||= Time.now
      options[:date_offset]     ||= Time.now
      options[:fetch_responses] ||= false
      
      params = {
        :user_id         => uid,
        :from_date       => options[:from_date].getgm.strftime("%Y-%m-%dT%H:%M:%S"),
        :date_offset     => options[:date_offset].getgm.strftime("%Y-%m-%dT%H:%M:%S"),
        :fetch_responses => options[:fetch_responses],
      }
      data = statuses(plurk_to_json(request("/TimeLine/getPlurks", :method => :post, :params => params )))
      data = data.first(options[:limit]) unless options[:limit].nil?
      return data 
    end
    
    def statuses(doc)
      doc.inject([]) { |statuses, status| statuses << Status.new(status); statuses }
    end
    
    def plurk_to_json(json)
      /new Date\((\".+?\")\)/.match(json)
      json = json.gsub(/new Date\((\".+?\")\)/, Regexp.last_match[1]) if Regexp.last_match
      return JSON.parse(json)
    end
    
    def request(path, options = {})
      begin
        agent = WWW::Mechanize.new
        #agent.cookie_jar = @cookies
        
        case options[:method].to_s
          when "get"
            agent.get(@@api_host+path, options[:params])
          when "post"
            agent.post(@@api_host+path, options[:params])
        end
        return agent.current_page.body
      rescue WWW::Mechanize::ResponseCodeError => ex
        raise Unavailable, ex.response_code
      end
    end
    
    ############################################
    # Temporary function until plurk team gets #
    # back to me with an API url.              #
    def nickname_to_uid(nickname) ##############
      page = request("/#{nickname}",:method => :get)
      uid = nil
      unless( (page =~ /\"user_id\": (.[0-9]*)/) == nil )
        uid = $1
      end
      return uid
    end
    
  end
end