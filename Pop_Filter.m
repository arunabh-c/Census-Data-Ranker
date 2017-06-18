function [ip_arr] = Pop_Filter(End_Year, state, city_list, ip_arr, pl, ph, pcs)

%This file retrieves population of all cities from the list of states in
%'state' for the year 'End_Year'. After population data retrieval, it loops through every
% city to check if it fits within the low(pl) and high(ph) population
% limits. if it does not, it zeros out that citys statistic. The population
% filtered dataset is returned as 'ip_arr'

%Preparing url to enquire census.gov for the year + state + population dataset
urlprfxa = 'http://api.census.gov/data/';
urlprfxb = '/acs5?get=NAME,';
urlsfx = '&for=county+subdivision:*&in=state:';
file = 'B01003_001E';
prev_st_city_count = [0,0];%placeholder array to maintain total cities counted as we loop through states

%Cycle through every state
for j =1:size(state,2)
    prev_st_city_count(1) = prev_st_city_count(2);%moved to next state, update the total city count
    key = strcat(num2str(state(j)),'&key=4baa464337455269a3801069ef66d4cfa2e0878b');
    read_attempt_counter = 0;
    while read_attempt_counter < 10%If first read attempt fails, 10 attempts will be made for same read
        if read_attempt_counter > 0
            disp('Pop Filter: Waiting for 10 seconds before re-attempting...');
            pause(10);
        end
        try
            %reading and retrieving population data for End_Year and state
            raw_data = urlread(strcat(urlprfxa, num2str(End_Year), urlprfxb, file, urlsfx, key));
            read_attempt_counter = 10;%read successful, set the counter to prevent repeat reads
        catch read_error
            disp('Pop Filter: url read attempt failed..');
            warning(read_error.message)
        end
        read_attempt_counter = read_attempt_counter + 1;
    end
    
    %crop raw data
    raw_data = raw_data(43:length(raw_data)-1);
    raw_data = strrep(raw_data,strcat(', ', state), '');
    %crop raw data
    
    %arrange raw data into city wise list
    start_of_row = regexp(raw_data, '[');
    
    %increment previous city count by new list of cities of the nth state
    prev_st_city_count(2) = prev_st_city_count(1) + size(start_of_row,2);
    
    for i=1:length(start_of_row)%Cycle through each city in the city list
        
        %Extract population data
        if i == length(start_of_row)
            temp_data = raw_data ( start_of_row(i) + 1 : length(raw_data) - 1 );%last row
        else
            temp_data = raw_data ( start_of_row(i) + 1 : start_of_row(i+1) - 4 );%every other row
        end
        
        data_pos_b = regexp(temp_data, '"');
        city_counter = prev_st_city_count(1) + i;
        
        %increment master list of cities from all states polled
        City_Name{city_counter} = [strrep(temp_data(2:data_pos_b(2)-1),' County', '')];
        
        if strfind(temp_data, '",null,"') > 0%if the cropped data string has the word null,
            X(city_counter) = 1;% then theres no data, put filler of 1
            %disp(strcat('Pop filter: Null pop data found @ ', City_Name{city_counter}));
        else
            data_pos_a = regexp(temp_data, '","');%else extract population count
            if str2num(temp_data(data_pos_a(1)+3:data_pos_a(2)-1)) >= 1%check if population number is a valid number
                X(city_counter) = str2num(temp_data(data_pos_a(1)+3:data_pos_a(2)-1));%save population count in folder X
            else
                X(city_counter) = 1;%irrecognizable data, set filler value of 1
                %disp(strcat('Pop filter: Invalid pop found @ ', City_Name{city_counter}));
            end
        end
        for k=1:length(city_list)%cycle through provided city list and find matching city
            if strfind(city_list{k}, City_Name{city_counter}) > 0 & (length(city_list{k}) == length(City_Name{city_counter}))
                %Check if city fits population limits
                if X(city_counter) < pl || X(city_counter) > ph
                    ip_arr(k,:) = zeros(1,size(ip_arr,2));%zero out the city statistic if it does not fit within limits
                    break;
                elseif pcs == 1
                        ip_arr(k,:) = ip_arr(k,:)/X(city_counter);% if population within limits and per capita  switch is true, calculate per capita data
                    end
                end
            end
        end
    end
end