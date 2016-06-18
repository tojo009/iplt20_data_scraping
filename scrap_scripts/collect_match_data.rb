require 'nokogiri'
require 'watir'
require 'mysql'

connection = Mysql.new('localhost','root','password','ipl_dummy_db')
browser    = Watir::Browser.new(:phantomjs)
year_array = (2008..2016)
matches    = (1..75)

year_array.each do |year|
    matches.each do |match_number|
        begin
            browser.goto("http://www.iplt20.com/match/#{year}/#{match_number}")
            #browser.goto("http://www.iplt20.com/match/2008/47")
            #browser.link(:text,"Scorecard").when_present.click
            
            document = Nokogiri::HTML(browser.html)
            
            if document.css('div[class="scoreboard"]').css('p[class="superOver"]').text.eql?("Super Over")
                puts "SuperOver"
            #-----------------------------------SUPER OVER-----------------------------------------#    
                super_over                 = true
                (team_a_super_over_score,
                team_a_super_over_wickets) = document.css('div[class="runs"]')[0].text.split("/")
                (team_a_score,
                team_a_wickets)            = document.css('div[class="teamScore"]').css('span')[0].text.split("/")
                (team_b_super_over_score,
                team_b_super_over_wickets) = document.css('div[class="runs"]')[1].text.split("/")
                (team_b_score,
                team_b_wickets)            = document.css('div[class="teamScore"]').css('span')[1].text.split("/")
            #-----------------------------------SUPER OVER-----------------------------------------#    
            else
                puts "Not super Over"
            #-------------------------------------NORMAL-------------------------------------------#
                super_over                = false
                team_a_super_over_score   = "0"
                team_a_super_over_wickets = "0"
                (team_a_score,
                team_a_wickets)           = document.css('div[class="runs"]')[0].text.split("/")
                team_b_super_over_score   = "0"
                team_b_super_over_wickets = "0"
                (team_b_score,
                team_b_wickets)           = document.css('div[class="runs"]')[1].text.split("/")
            end
            #-------------------------------------NORMAL-------------------------------------------#
            
            #Common values be it super over or not
            team_a_name             = document.css('div[class="scoreboard"]').css('[class="team"]')[0].text
            team_a_runrate          = document.css('div[class="runRate"]').css('span')[1].text #some other span present in the begining
            (team_a_overs_played,
            team_a_total_overs)     = document.css('div[class="overs"]').css('span')[0].text.split("/")
            team_b_name             = document.css('div[class="scoreboard"]').css('[class="team"]')[1].text
            team_b_runrate          = document.css('div[class="runRate"]').css('span')[2].text #some other span present in the begining
            (team_b_overs_played,
            team_b_total_overs)     = document.css('div[class="overs"]').css('span')[1].text.split("/")
            
            match_result            = document.css('div[class="summary"]').text
            match_type              = document.css('div[class="matchNav"]').css('span').text.chomp(" ").chomp("-")
            
            # Winner found by looking the div under team scores, its either winner last or winner first
            if document.css('div[class="teamScores"]').css('div[class="winner last"]').empty?
                winner = team_a_name
            elsif (match_result.include?("abandoned")) || match_result.include?("No Result")
                winner = "TIE"
            else
                winner = team_b_name
            end
            
            # Margin of victory
            if match_result.include?("wickets")
                victory_margin_by_wickets = match_result[/\d+/]
                victory_margin_by_runs    = 0
            elsif match_result.include?("runs")
                victory_margin_by_runs    = match_result[/\d+/]
                victory_margin_by_wickets = 0
            else
                victory_margin_by_runs    = 0
                victory_margin_by_wickets = 0
            end
                    
            #Consider all out wickets    
            if team_a_wickets.nil?
                team_a_wickets = 10
            end
            
            if team_b_wickets.nil?
                team_b_wickets = 10
            end
            
            puts "The winner is #{winner} margin by runs #{victory_margin_by_runs} --margin by#{victory_margin_by_wickets}"
            puts "#{match_type} #{match_result}"
            puts "#{team_a_runrate} #{team_b_runrate} #{team_a_name} #{team_b_name}"
            puts "#{team_a_super_over_score} #{team_a_super_over_wickets} #{team_b_super_over_score} #{team_b_super_over_wickets} #{team_a_score} #{team_a_wickets} #{team_b_score} #{team_b_wickets} "
            puts "#{team_a_overs_played} #{team_a_total_overs} #{team_b_overs_played} #{team_b_total_overs}"
            
            insert_data = "CALL insert_match_data(\"#{super_over}\",\"#{team_a_name}\",#{team_a_super_over_score},#{team_a_super_over_wickets},
                                                  #{team_a_score},#{team_a_wickets},#{team_a_runrate},#{team_a_overs_played},#{team_a_total_overs},
                                                  \"#{team_b_name}\",#{team_b_super_over_score},#{team_b_super_over_wickets},
                                                  #{team_b_score},#{team_b_wickets},#{team_b_runrate},#{team_b_overs_played},#{team_b_total_overs},
                                                  \"#{match_result}\",\"#{match_type}\",\"#{winner}\",#{victory_margin_by_runs},
                                                  #{victory_margin_by_wickets},#{match_number},#{year})"  
            insert_data=insert_data.gsub(/-/,"0").gsub(/,,/,",0,") #remove the - incase of abandoned or no result match
            puts "#{insert_data}"
            connection.query(insert_data)
        
        rescue NoMethodError
            puts "continue to next--"
        end
        
    end
end
connection.close