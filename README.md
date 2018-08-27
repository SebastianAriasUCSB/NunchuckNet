# NunchuckNet
Neural network capable of analyzing nunchuck movies

Pre-requirements to use the program:
  Matlab Version: R2018a (or newer)
  Toolboxes:
    Neural Network Toolbox
    Computer Vision Toolbox
    Movie resolution: 200x200
    
How to use:
  Load in neural network variable (nunchucknet7s) and any ignore arrays
  Make sure you have a folder titled: “NNStacks” in NNAnalyzeStacks directory
  Add movies (and any ignore files) that you want to analyze to NNStacks (no limit on number of movies)
  Run program
  PC user caveat: Change all “/” to “\” 
  
Outputs
  Per movie
    moviename+“NNAngles”/“NNScores” - raw angles and score prediction 
    moviename+“NNAnglesFiltered”/“NNScoresFiltered”- angles/scores where predictions with low scores (1.5std away from mean)        have been removed (csv file also saved for filtered angles)
    “Moviename+“AnglesFilteredHistogram” - histogram of filtered angle predictions with truncated normal fit (jpg)
    moviename+“_Fit” - truncated normal fit to the folded filtered angles histogram  
  Run summary:
    output.txt- program output (Stacks Analysed, num of frames excluded/ignored, etc)
    RunAnglesFiltered- accumulation of filtered angles from all movies analyzed (csv file also saved)
    RunHistogram- angle histogram of all run angles with truncated normal fit(jpg,fig)
    RunFit-truncated normal fit to the folded RunAngles histogram
    
What it does:
  Splits up stack into individual images and stores them in new “split” folders temporarily
  Modifies images-changes resolution to 227x227 and converts it from 8bit to true color
  Uses NN7s to get angle predictions- changes preds from a categorical array to a double array where array index corresponds to frame number
  Filters angle predictions- removes predictions of frames that have a low score (1.5 stds lower than avg score)
  Creates histogram for filtered angles for each movie and fits to truncated normal distribution
  
Ignore Frames:
  Accepted forms of input:
    Array:
      Name: moviename+‘_ignore’
      Ex: ‘movie171211_7pm_4_sPP0At_ignore’
    Text File:
      Location: \NNStacks\ (same location as movies)
      Name: moviename+‘_ignore’
      Ex: ‘movie171211_7pm_4_sPP0At_ignore’
      1 frame number per line
  Note: variable takes precedence over file (i.e. if both are present program uses variable)

Other:
    Deletes previous analysis folders if past ones still present
    Skips stack splitting if previous “split” folder is already present - to decrease processing time when rerunning movies       multiple times in a row or when program is interrupted
