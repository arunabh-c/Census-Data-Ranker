README
1) In order to run the code run, place all files in local matlab folder and run mndatamapper.m

2) List.txt lists the topics that the code collects and compute growth data for. Add or substract topics from that list as per your choice.
More topics (and their key) to explore can be understood and found here: http://factfinder.census.gov/faces/nav/jsf/pages/searchresults.xhtml?refresh=t

3) All the inputs to tweak your run can be changed in mndatamapper.m, lines 9 to 18. All the output in the command window gets saved in Output.txt If graph
switch is on, 1 graph corresponding to every topic in List.txt gets saved as jpg. The city statistics and city list from the entire analysis 
is available as arrays: (Cities + raw_dump) for post processing.

4) File bachmapper.m takes user inputs from mndatamapper and carries out data collection + cleaning + filtering + ranking and returns final results to mndatamapper.m.

When bachmapper polls census api for a state, this is how the data looks like: 
http://api.census.gov/data/2011/acs5?get=NAME,B01003_001E&for=county+subdivision:*&in=state:51&key=4baa464337455269a3801069ef66d4cfa2e0878b

5) If multiple topics from List.txt being analyzed, then mndatamapper combines ranking of each topic to produce an aggregate final ranking.
Final Ranking is done this way:

Growth in Rent  Growth in Jobs   =>   Add Rankings             => Arrange combined rankings
1)Boston        1) Boston             Boston= (1 + 1) = 2       1) Boston = 2
2)NYC           2) DC                 DC = (3 + 2) = 5          2) DC = 5
3)DC            3) NYC                NYC =(2 + 3) = 5          2) NYC = 5

6) Pop_Filter.m takes ranked city list from bachmapper.com and eliminates cities that do not fall within hi & lo population limits. It retrieves population data of the
End_Year (defined in mndatamapper.m) for this task. Population filtered city list is then returned to bachmapper.m

7) All code has been commented and explained as much as possible.