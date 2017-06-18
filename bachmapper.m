function [City_Name, final_tally, rd] = bachmapper(Year, file, name, seq, start, state, frs, pl, ph, gs)

urlprfxa = 'http://api.census.gov/data/'; %url prefix a
urlprfxb = '/acs5?get=NAME,'; %url prefix b
urlsfx = '&for=county+subdivision:*&in=state:'; %url suffix

state_list = textread('State_List.txt', '%s', 'delimiter', '\n');

if char(state) == '*'
    state = {'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'};
end

state_num = zeros(1,numel(state));
file_name = '';
for j = 1:numel(state)%Prepare state number llist
    state_word_length = cellfun(@size,state, 'Uni', false);
    
    for i = 1:length(state_list)
        if (size(state_list{i},2) == state_word_length{j}(2))
            if (state_list{i} == char(state(j)))
                state_num(j) = i;
                key{j} = strcat(num2str(i),'&key=4baa464337455269a3801069ef66d4cfa2e0878b');%merge state number with key
                file_name = strcat(file_name,char(state(j)));
            end
        end
    end
end
prev_state_city_count = [0,0];
disp('Collecting and cleaning data..');
%Data Collection
for ss=1:size(state,2) %Looping through each state
    prev_state_city_count(1) = prev_state_city_count(2);
    for j=1:Year %Looping through each year
        read_attempt_counter = 0;
        while read_attempt_counter < 10%putting read in a while loop to ensure if one of the many reads fail, program doesnt crash and attempts atleast 10x
            if read_attempt_counter > 0
                disp('Bachmapper: Waiting for 10 seconds before re-attempting...');
                pause(10);
            end
            try
                raw_data = urlread(strcat(urlprfxa, num2str(start - 1 + j), urlprfxb, file, urlsfx, char(key(ss))));% reading data from api after compiling url
                read_attempt_counter = 10;
            catch read_error
                disp('Bachmapper: Url read attempt failed..');
                warning(read_error.message)
            end
            read_attempt_counter = read_attempt_counter + 1;
        end
        
        raw_data = raw_data(43:length(raw_data)-1);%raw data cropped of useless info
        raw_data = strrep(raw_data,strcat(', ', char(state(ss))), '');
        start_of_row = regexp(raw_data, '[');%raw data converted to list of cities
        prev_state_city_count(2) = prev_state_city_count(1) + size(start_of_row,2);%keeping count of cities
        for i=1:size(start_of_row,2)%Looping through each city
            city_counter = prev_state_city_count(1) + i;%unique city number for every city
            if i == size(start_of_row,2)
                temp_data = raw_data ( (start_of_row(i)) + 1 : length(raw_data) - 1 );%last row, relevant data extracted from raw_data
            else
                temp_data = raw_data ( (start_of_row(i)) + 1 : (start_of_row(i+1)) - 4 );%all but last row, relevant data extracted from raw_data
            end
            
            if j == 1 | city_counter > length(City_Name)%enter this section if storing data for first year or new city added this year not in previous years
                if strfind(char(temp_data), '",null,"') > 0%if data is null just put filler value into MDA
                    X(city_counter,j) = 1;%Main Data Array (MDA)
                    %disp(strcat('Batchmapper: Null data found @ ', temp_data));
                else
                    data_pos_a = regexp(temp_data, '","');
                    if str2num(temp_data(data_pos_a(1)+3:data_pos_a(2)-1)) > 0 | j == Year %if string is a valid number > 1 or we are in the last year
                        X(city_counter,j) = str2num(temp_data(data_pos_a(1)+3:data_pos_a(2)-1));%Entering statistic into MDA
                    else
                        X(city_counter,j) = 1;%not valid number just store filler value
                        %disp(strcat('Batchmapper: Invalid number data found @ ', temp_data));
                    end
                end
                data_pos_b = regexp(temp_data, '"');
                City_Name{city_counter} = [strrep(temp_data(2:data_pos_b(2)-1),' County', '')];%Create list of cities
                if city_counter > length(City_Name)%new city added this year not in previous years
                    disp('New city introduced from previous year data')
                    city_counter
                    length(City_Name)
                    X(city_counter,:)
                end
                
            elseif (city_counter <= length(City_Name))
                data_pos_b = regexp(temp_data, '"');%pick next line of data from url dump
                name_check = char(strrep(temp_data(2:data_pos_b(2)-1),' County', ''));%remove 'County' from this line
                
                item = 0;
                if (strfind(name_check, City_Name{city_counter}) > 0) & (length(City_Name{city_counter}) == length(name_check))%check if city name match
                    item = city_counter;
                else
                    for k =1:length(City_Name)%if not, then loop through all list of cities to find matching city
                        if ( strfind(name_check, City_Name{k}) > 0)  & (length(City_Name{k}) == length(name_check))
                            item = k;
                            break;
                        end
                    end
                end
                
                if item > 0
                    if strfind(temp_data, '",null,"') > 0
                        X(item,j) = X(item,j-1);%if data of matching city is null, just set the MDA statistic for this year same as last year
                    else
                        data_pos_a = regexp(temp_data, '","');
                        X(item,j) = str2num(temp_data(data_pos_a(1)+3:data_pos_a(2)-1));%Entering statistic into MDA
                    end
                end
            end
        end
    end
end
rd = X;%Raw Dump that is forwarded to raw_dump in mndatamapper.m for user needs

if Year > 1
    disp('Calculating growth ...');
    for i=Year-1:-1:1
        for j=1:size(X,1)
            if X(j,i) <= 1%Cities which had filler or 0 values for that year, their growth is defaulted to 0
                One_Year_Growth(j,i) = 0;
            else
                One_Year_Growth(j,i) = X(j,i+1)/X(j,i) - 1;
            end
        end
    end
    per_capita_switch = 0;
else%if only 1 year data is requested rank cities from highest value to lowest
    for j=1:size(X,1)
        if X(j) <= 1%Cities which had filler or 0 values for that year, their value is defaulted to 0
            One_Year_Growth(j,:) = 0;
        else
            One_Year_Growth(j,:) = X(j);
        end
    end
    per_capita_switch = 1;
end

disp('Applying Population Filter ...');
%Filtering out cities with population less than threshold
One_Year_Growth = Pop_Filter(start - 1 + Year, state_num, City_Name, One_Year_Growth, pl, ph, per_capita_switch);

Avg_Growth = mean(One_Year_Growth,2);%growth of all years averaged

min_limit = min(Avg_Growth) -1;%setting artificial least growth value to force cities with invalid data to bottom of ranking

tru_case_counter=0;
%This loops checks for cities whose growth were zeroed out by pop filter.
%Their growth is now defaulted to the minimum growth so they remain at the bottom of the rankings
for i=1:size(One_Year_Growth,1)
    if One_Year_Growth(i,:) == zeros(1,Year-1)
        Avg_Growth(i) = min_limit;
    else
        tru_case_counter=tru_case_counter+1;%tru_case_counter keeps a count of true cities or cities that successfully passed the population filter
    end
end

disp('Sorting & Plotting data ...');
[sorted_fset, index] = sort(Avg_Growth, 'descend');

%%%%%%%%Graph plot operations
if gs == 1
    plotStyle = {'b-','k:','r-', '-g', '-v', '-y', 'm.', '-.k', '-p', '-.r'};
    figure(seq);
    hold on;
    if length(City_Name) < 10
        display_size = length(City_Name);
    else
        display_size = 10;
    end
    
    if display_size>  tru_case_counter
        display_size = tru_case_counter;
    end
    
    if display_size > 0
        for i=1:display_size
            plot(100*(X(index(i),:)/X(index(i),1) -1), plotStyle{i});
            legendInf(i) = City_Name(index(i));
        end
        set(gca,'XTick',1:Year);
        
        countr = 1;
        for i=start:start + Year - 1
            xtix(countr) = i;
            countr = countr + 1;
        end
        
        set(gca,'XTickLabel',(xtix));
        xlabel('Year');
        if per_capita_switch == 1
            ylabel(strcat('Highest per capita in ',name));
        else
            ylabel(strcat('Percent Change in ',name));
        end
        legend(legendInf,'Location','northwest');
        
        saveas(gca,strcat(file_name,name,'.jpg'));
        
    end
end
%%%%%%%%Graph plot operations

[sorted_final, pre_final_tally] = sort(index);

for i=1:length(pre_final_tally)
    if pre_final_tally(i) <= tru_case_counter
        final_tally(i) = pre_final_tally(i);
    else
        final_tally(i) = tru_case_counter + 1;
    end
end

if frs >  tru_case_counter
    frs = tru_case_counter;%if final rankings size more than total number of ranked cities, reduce size to that
end

disp(strcat('Total cities analyzed for ', name, ': ', num2str(size(One_Year_Growth,1))));
disp(strcat('Total cities ranked for ', name, ': ', num2str(tru_case_counter)));
disp(strcat('Cities in order of highest average ', name, ' growth'));
disp('      ');
disp(strcat('     #    ', '     City Name     ', '         Average Growth(%)'));
disp('      ');

for i=1:frs
    disp([final_tally(index(i)), City_Name(index(i)), num2str(100*Avg_Growth(index(i)))]);
end