clear all
close all
clc

delete('Output.txt');%Output rankings (and image files) dumped here in same folder
diary('Output.txt');


State = ({'OH','NY'});%Define list of states. '*' means all states
Final_Rankings_Size = 100;%Change this number to change how many you want to see in all rankings. Smaller numbers make scrolling easier
Start_Year = 2013;%Start Year for stats. B23025_004E, Labor Force Employed not available for 2010 and below. Remove that fron List.txt and change start year to 2009
End_Year = 2014;%Stop Year. Can't be > 2014.
%if end_year = start_year, program will compute and rank cities according
%to per capita numbers for end_year. If doing per capita ranking for 1
%year, dont forget to remove 'B01003_001E, Total Population' from List.txt
Pop_Lo_Limit = 5000;%Lower Population limit. Can't be less than 1. Avoid numbers < 1000 as small rural townships pollute growth trends. Smaller limit means more cities and hence longer processing duration
Pop_Hi_Limit = 100000000;%Higher Population limit. Can't be less than 1. Avoid numbers < 1000 as small rural townships pollute growth trends
graph_switch = 1;%0 to turn off graphs, 1 to turn on graphs

Input = importdata('List.txt',',');
Sample_Size = End_Year - Start_Year + 1;

for i=1:length(Input)
    row = char(Input(i));
    disp(strcat('Starting growth measurement in ',row(13:length(row))));

    [Cities, op, raw_dump] = bachmapper(Sample_Size, row(1:11), row(13:length(row)), i, Start_Year, State, Final_Rankings_Size, Pop_Lo_Limit, Pop_Hi_Limit, graph_switch);
    %raw_dump contains raw data. columns are lowest year to highest year left to
    %right. Rows are Cities in alphabetical order. Example of city list found here: http://api.census.gov/data/2011/acs5?get=NAME,B01003_001E&for=county+subdivision:*&in=state:51&key=4baa464337455269a3801069ef66d4cfa2e0878b
    %Use Cities + raw_dump to do further data processing

    if i ==1
        ft = op;
        Original_City_List = Cities;
    else
        disp(strcat('Adding calculated rankings to final tally..'));
        for k =1:length(Cities)% loop through list of cities to ensure each ranking is aligned to the right city
            if ( strfind(Cities{k}, Original_City_List{k}) > 0)  & (length(Cities{k}) == length(Original_City_List{k}))
                ft(k) = ft(k) + op(k);
            else
                %disp(strcat('City mismatch found while tallying final rankings.'));
                for ss=1:length(Original_City_List)%cycle through original city list and find matching city
                    if strfind(Original_City_List{ss}, Cities{k}) > 0 & (length(Original_City_List{ss}) == length(Cities{k}))
                        ft(ss) = ft(ss) + op(k);
                        break;
                    end
                end
            end
        end
    end
end
disp(strcat('Performing combined tallying and ranking..'));
[sorted_fset, index] = sort(ft);

disp('Cities in order of overall performance');
disp('      ');
disp(strcat('     #     ', '       City        County      State     '));
disp('      ');

if Final_Rankings_Size > size(Cities,2)
    Final_Rankings_Size = size(Cities,2);
end

for i=1:Final_Rankings_Size
    disp([i, Cities(index(i))]);%, sorted_fset(i)
end

diary off;