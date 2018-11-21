Pre-requirements to use the program:
Matlab Version: R2018a (or later)
Toolboxes:
Neural Network Toolbox
Computer Vision Toolbox
Movie resolution: 200x200
Things to download:
nunchucknet9s.mat
NNAnalyzeStacks3.m
Mac user caveat: Change all “\” to “/”  (control+f)
How to use:
Load in neural network variable (nunchucknet9s.mat) 
(optional) Load in any ignore arrays (further explanation below) 
Create/verify that folder titled: “NNStacks” in matlab working directory  
NNAnalyzeStacks3.m should NOT be in NNStacks 
Add movies that you want to analyze into NNStacks folder 
There is no limit on number of movies that may be added but keep in mind the time requirement (30-60sec/ movie)
(Optional) Add ignore files to NNStacks
Run NNAnalyzeStacks
Outputs
Per movie (inside folder named after movie):
Raw angle prediction and scores: 
moviename+“_NNAngles”/“_NNScores0” 
Filtered angle predictions/scores (see below explanation): 
csv also exported
moviename+“_NNAnglesFiltered”/“_NNScoresFiltered”
abs(filtered prediction) histogram with fit: 
moviename+“AnglesFilteredHistogram” 
Prediction and score imprinted movie:
Filtered out predictions are marked with a “*”
Moviename+ “_NNAnglesInserted.tif” 
Four Fold Normal Fit:
moviename+“_Fit” 
Run summary:
Program output 
Includes: stacks analysed, num of frames excluded/filtered, meanScore, fit parameters
output.txt 
Data Structure:
Includes name, mba (predictions), score for all movies analysed
NN_nunchuck_data.mat
Aggregate angle predictions 
csv file also saved
RunAnglesFiltered.mat
Aggregate histogram with fit (jpg,fig):
RunHistogram.jpg/.fig
Aggregate Histogram Four Fold Normal Fit:
RunFit.mat
How it works (in a nutshell):
Splits up stack into individual images and stores them in new “split” folders temporarily
Modifies images-changes resolution to 227x227 and converts it from 8bit to true color (necessary to run through NN)
Uses NN to get angle predictions
Converts predictions from a categorical array to a double array
Array index corresponds to frame number
Filters angle predictions
Removes predictions of frames that have a low score (1.5 stds lower than avg score)
Saves all outputs
Ignore Frames:
Explanation: Integrated way of making the program skip specific frames of movies
Accepted forms of input:
Array (loaded in matlab variable):
Variable name: moviename+‘_ignore’
Ex: ‘movie171211_7pm_4_sPP0At_ignore’
Text File:
Location: \NNStacks\ (same location as movies)
Name: moviename+‘_ignore’
Ex: ‘movie171211_7pm_4_sPP0At_ignore’
1 frame number per line
Note: variable takes precedence over file (i.e. if both are present program uses the variable)
Other:
Deletes previous analysis folders if past ones still present
No need to delete output folders if running program
Skips stack splitting if previous “split” folder is already present 
 Decrease processing time when rerunning movies multiple times in a row or when program is interrupted or if deletion of split folders is skipped


