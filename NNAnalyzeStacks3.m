% This program will categorize frames in tiff stacks and save predictions and scores.
% Usage:
% Load in neural network variable-nunchucknet7s is latest one
% Make sure you have a folder titled “NNStacks” in directory
% Add movies (and any ignore files) that you want to analyze to the folder (no limit on number of movies)
% Run program
% Mac user caveat:
% Change all “/” to “/” 

clc
tic

net=nunchucknet9s;

fclose('all'); %closes opened files to prevent running into problems with rmdir

if exist('NNStacks')==0 %Checks for the existance of NNStacks
    disp('NNStacks folder not found: Aborting')
    return
end

if exist('NNStacks/Run_Summary')==7 %Deletes run summary folder if already present
    rmdir(strcat(pwd,'/NNStacks/Run_Summary'),'s')
end

mkdir ('NNStacks', "Run_Summary") %makes Run Summary folder
sumFileID=fopen(strcat(pwd,'/NNStacks/Run_Summary/','output.txt'),'w'); %open outputfile

[numStacks,folderNames]=splitStack(sumFileID); %splits stacks and prepares images for NN analysis

disp('______________Stacks Analysed:_________________________')
fprintf(sumFileID,'%s\n','______________Stacks Analysed:_________________________');

path=strcat(pwd,'/NNStacks/');
edges=[-180:5:180];
runAnglesFiltered=[];


for i=1:numStacks
    
    name=folderNames{i}; %Name of file with "Split" appended to it
    disp(strcat('>>> ',name(1:end-5),':'))
    fprintf(sumFileID,'%s\n',strcat('>>> ',name(1:end-5),':'));
    
    stack_ds=imageDatastore(strcat(path,folderNames(i))); %creates imagedatastore fed to NN
    [preds,scores] = classify(net,stack_ds); %Gets predictions and scores
    
    [predsDouble]=convertToDouble(preds); %converts from categorical to double
    
    % This next portion will remove predictions that have been categorized
    % as "ignore" via a file
    clear ignoredFrames 
    
    vars=char(who); %gets list of all variables as strings
    if exist(strcat(name(1:end-5),'_ignore'))==1 % if ignore variable exists
        eval(strcat('ignoredFrames=',name(1:end-5),'_ignore;')); %saves array as ignoredFrames
        
        disp(strcat('Ignore array found:',num2str(numel(ignoredFrames)),' frames ignored'))
        fprintf(sumFileID,'%s\n',strcat('Ignore array found:',num2str(numel(ignoredFrames)),' frames ignored'));
        
        predsDouble(ignoredFrames)=NaN; %sets predictions for ignore frames to NaN
    else
        [predsDouble,ignoredFrames]=ignoreFramesFile(predsDouble,name,sumFileID); %checks/reads ignore frames file
    end

   
    %Next section will filter out images with low (1.5std away) scores
    clear predsFiltered
    clear scoresFiltered
    
    [predsFiltered,scoresFiltered,scores,maxScores,framesFiltered]=filterPreds(predsDouble,scores,ignoredFrames,sumFileID);
    
    
    %Following portion will save all important variables
    saveFolder=strcat(name(1:end-5),'_NNAnalysis');
    
    if exist(strcat('NNStacks/',saveFolder))==7 %Deletes previous analysis folders
        %disp("True")
        %disp(saveFolder)
        rmdir(strcat(pwd,'/NNStacks/',saveFolder),'s')
    end
 
    mkdir ('NNStacks', saveFolder)
    savePath=strcat(path,saveFolder,'/',name(1:end-5),'_NNAngles.mat');
    save(savePath,'predsDouble');
    savePath=strcat(path,saveFolder,'/',name(1:end-5),'_NNScores.mat');
    save(savePath,'maxScores');
    savePath=strcat(path,saveFolder,'/',name(1:end-5),'_NNScoresFiltered.mat');
    save(savePath,'scoresFiltered');
    savePath=strcat(path,saveFolder,'/',name(1:end-5),'_NNAnglesFiltered.mat');
    save(savePath,'predsFiltered');
    savePath=strcat(path,saveFolder,'/',name(1:end-5),'_NNAnglesFiltered.csv');
    csvwrite(savePath,predsFiltered)
    
    saveHist(predsFiltered,name,saveFolder,path,sumFileID); %creates movie hist and saves it
    
    runAnglesFiltered=cat(2,runAnglesFiltered,predsFiltered);
    
    writeNewStacks(name,stack_ds,predsDouble,maxScores,framesFiltered)
    
    rmdir(strcat(pwd,'/NNStacks/',folderNames(i)),'s') %removes split folders
    
end

fit=runHist(runAnglesFiltered); %creates and saves summary histogram

disp('________________Completed_______________________________')
fprintf(sumFileID,'%s\n','________________Completed_______________________________');

time=toc;
disp(strcat("Elapsed time: ", num2str(time/60),' mins'))
fprintf(sumFileID,'%s\n',strcat("Elapsed time: ", num2str(time/60),' mins'));
fclose('all'); %closes all opened files

%%
%------------------Functions----------------------
function [num,out]=splitStack(sumFileID)
%This function splits the stack into individual images and prepares them to
%run though the neuralnetwork (changes resolution and type to true color)

stacks=dir('NNStacks/*.tif*'); %tif stacks in the folder
numStacks=length(stacks) %number of stacks in the folder
folders=strings(1,numStacks); %contain folder names for analysis function

for k=1:numStacks %will split up every stack 
    stackName=stacks(k).name; %gets the file name of the stack
    
    stackPath = strcat(pwd,'/NNStacks/',stackName); %path of stack file

    endin=strfind(stackName,'.');
    folderName=strcat(stackName(1:endin-1),'Split'); %foldername based on stack name
    folders(k)=folderName;
    
    if exist(strcat('NNStacks/', folderName))==7 %Skips if split folder is present
        disp(strcat(folderName, ": Split Folder already present"))
        fprintf(sumFileID,'%s\n',strcat(folderName, ": Split Folder already present"));
        continue
    end
    
    mkdir ('NNStacks', folderName); %folder wehere split is going to be saved to
    folderPath=strcat(pwd,'/NNStacks/',folderName,'/'); %path to save folder
    
    info = imfinfo(stackPath); %info about stack 
    numFrames= numel(info); %number of frames in the stack

    for i = 1:numFrames %saves each modified frame as individual file
        if i<10 %name for individual frame files-needed for image dataStores
            name=strcat('000',num2str(i));
        elseif i<100 && i>9
            name=strcat('00',num2str(i));
        elseif i<1000 && i>99
            name=strcat('0',num2str(i));
        else
            name=num2str(i);
        end

        A = imread(stackPath, i, 'Info', info); %reads specific frame
        A(201:227,201:227)=0; %changes resolution from 200x200 to 277x277
        A = cat(3, A,A,A); %changes from 8bit to truecolor
        fileName=strcat(folderPath,name,'.tif'); %filename is frame number
        imwrite(A,fileName); %writes frame
    end
end
num=numStacks;
out=folders;
end
function [predsDouble]=convertToDouble(preds)
    %This next portion will convert the predictions from a categorical
    %array to a double array
    
    preds=string(preds);
    predsSize=numel(preds);
    predsDouble=zeros(1,predsSize);

    for j=1:predsSize
        predsDouble(j)=eval(preds(j));
        predsDouble(j)=str2num(strcat(num2str(predsDouble(j)),'.5'));
    end
    
    
end
function [predsDouble,ignoredFrames]=ignoreFramesFile(predsDouble,name,sumFileID)
%This function will check and read ignore frame files
    if exist(strcat('NNStacks/',name(1:end-5),'_ignore.txt'))==2 % if ignore file exists
        fileID=fopen(strcat('NNStacks/',name(1:end-5),'_ignore.txt')); %opens file
        ignoredFrames=fscanf(fileID,'%d'); %reads file
        disp(strcat('Ignore file found:',num2str(numel(ignoredFrames)),' frames ignored'))
        fprintf(sumFileID,'%s\n',strcat('Ignore file found:',num2str(numel(ignoredFrames)),' frames ignored'));
        predsDouble(ignoredFrames)=NaN; %sets predictions of ignored frames to NaN
    else
        ignoredFrames=[0];
    end
end
function [predsFiltered,scoresFiltered,scores,maxScores,framesFiltered]=filterPreds(predsDouble,scores,ignoredFrames,sumFileID)
    %Next section will filter out images with low (1.5std away) scores
    clear maxScores
    clear framesFiltered
    
    predsSize=numel(predsDouble);
    excluded=0; %count for excluded images start
    maxScores=zeros(1,predsSize); %initializing array that will contain highscores
    predsFiltered=zeros(1,predsSize);
    scoresFiltered=zeros(1,predsSize);
    
    for j=1:predsSize %gets score of prediction (highest score)
        highScore=max(scores(j,:)); %highscore corresponds to pred score
        
        if isnan(predsDouble(j)) %sets maxScore to NaN if pred is NaN
            maxScores(j)=NaN; %that way it avoids NaN frames
            scores(j,:)=NaN;
        else
            maxScores(j)=highScore;
        end
         
    end
    
    
    for j=1:predsSize %filters out low score frames

        if maxScores(j)>(nanmean(maxScores)-1.5*nanstd(maxScores))
            scoresFiltered(j)=maxScores(j); %saves values for frames with high enough scores
            predsFiltered(j)=predsDouble(j);
        else%sets excluded frames to NaN
            excluded=excluded+1;
            framesFiltered(excluded)=j;
            if exist('ignoredFrames')==1 %accounts for ignored frames
                if ismember(j,ignoredFrames)==true
                  %avoids double counting frames
                    excluded=excluded-1;
                end
            end
            scoresFiltered(j)=NaN;
            predsFiltered(j)=NaN;
            
        end
    end
    
    disp(strcat('meanScore:',num2str(nanmean(maxScores)),' stdScore:',num2str(nanstd(maxScores)),' treshold:',num2str(nanmean(maxScores)-1.5*nanstd(maxScores))))
    fprintf(sumFileID,'%s\n',strcat('meanScore:',num2str(nanmean(maxScores)),' stdScore:',num2str(nanstd(maxScores)),' treshold:',num2str(nanmean(maxScores)-1.5*nanstd(maxScores))));
    disp(strcat(num2str(excluded),' frames excluded due to low scores'))
    fprintf(sumFileID,'%s\n',strcat(num2str(excluded),' frames excluded due to low scores'));
end
function out=saveHist(predsFiltered,name,saveFolder,path,sumFileID)
%This function will create and save histograms for each movie
    [fit, gof] =truncFoldNorm(predsFiltered);


    edges=[0:5:180]; %for histogram
    
    f = figure('visible', 'off'); %creates figure without showing it
    hold on
    %f=figure
    histogram(abs(predsFiltered),edges); 
    plot(fit);
    xlim([0 180])
    xlabel('Angle(degrees)');
    ylabel('Counts');
    title(strcat(name(1:end-5),': Filtered Angles'),'Interpreter', 'none');
    dim = [.70 .5 .3 .3];
    str = {'Fit values:',strcat('\mu:',num2str(fit.m)),strcat('\sigma:',num2str(fit.sigma)),strcat('R^2:',num2str(gof.rsquare))};
    annotation('textbox',dim,'String',str,'FitBoxToText','on');
    hold off
    
    savePath=strcat(path,saveFolder,'/',name(1:end-5),'_AnglesFilteredHistogram');
    %saveas(f,savePath,'fig');
    saveas(f,savePath,'jpeg'); %saves as pdf
    
    savePath=strcat(path,saveFolder,'/',name(1:end-5),'_Fit');
    save(savePath,'fit');
    
    disp(strcat('\mu:',num2str(fit.m),',\sigma:',num2str(fit.sigma),',R^2:',num2str(gof.rsquare)))
    fprintf(sumFileID,'%s\n',strcat('\mu:',num2str(fit.m),',\sigma:',num2str(fit.sigma),',R^2:',num2str(gof.rsquare)));
    
    close %closes figure so that they don't stick around
end
function out=runHist(runAnglesFiltered)
%This portion will plot and save the summary histogram 
%It will also save sumHistCounts

[fit, gof] =truncFoldNorm(runAnglesFiltered);

edges=0:5:180; %for histogram
%f=figure('visible', 'on'); %creates figure that will show up
f=figure;
hold on

histogram(abs(runAnglesFiltered),edges);
plot(fit)
xlim([0 180]);
xlabel('Angle (degrees)');
ylabel('Counts');
title('NNAnalysis Summary')

dim = [.70 .5 .3 .3];
str = {'Fit values:',strcat('\mu:',num2str(fit.m)),strcat('\sigma:',num2str(fit.sigma)),strcat('R^2:',num2str(gof.rsquare))};
annotation('textbox',dim,'String',str,'FitBoxToText','on');


savePath=strcat(pwd,'/NNStacks/Run_Summary/RunHistogram');
saveas(f,savePath,'fig');
saveas(f,savePath,'jpg');

savePath=strcat(pwd,'/NNStacks/Run_Summary/RunAnglesFiltered');
save(savePath,'runAnglesFiltered');

savePath=strcat(pwd,'/NNStacks/Run_Summary/RunFit');
save(savePath,'fit');

savePath=strcat(pwd,'/NNStacks/Run_Summary/RunAnglesFiltered.csv');
csvwrite(savePath,runAnglesFiltered)

hold off

out=fit;

end
function writeNewStacks(name,stack_ds,predsDouble,maxScores,framesFiltered)

    numFrames=numel(stack_ds.Files); %number of frames for the movie
 
    
    for k=1:numFrames %loops through frames of stack
        savePath=strcat(pwd,'/NNStacks/',name(1:end-5),'_NNAnalysis/',name(1:end-5),'_NNAnglesInserted.tif');
        img=readimage(stack_ds,k); %reads image from split folder
        
        text=strcat(num2str(predsDouble(k)),' | ',num2str(round(maxScores(k),2))); %text that will be written
        if ismember(k,framesFiltered) %adds * if ignored
            text=strcat(text,'*');
        end
        
        img=insertText(img,[5,5],text); %inserts text
        
        img=img(1:200,1:200); %changes it back to 200x200 and grey scale
        
        if k~=1 %writes stack by appending to the stack each consecutive image
            imwrite(img,savePath,'WriteMode','append'); 
        else
            imwrite(img,savePath);
        end
    end

end
function [fitResult, gof] =truncFoldNorm(bendAngle)

edges=(0:5:180); %for binning
centers=(0:5:177.5)+2.5; %for binning

mba = abs(bendAngle); %taking abs_value of the end to end bending angle
%edges=(0:10:180); %for binning
%centers=(0:10:175) + 5; %for binning
counts= histcounts(mba, edges); %for binning
weights=sqrt(counts);

% Fit options for the TFnormal fit
start = [2000 0 50];
lower = [0 0 0];
upper = [1000000 5 10000];



[xData, yData] = prepareCurveData(centers,counts);

% Set up fittype and options.
% I've double checked in mathematica, the following expression is correctly typed.
ft = fittype('c*(1/sqrt(2*pi*sigma^2))*(exp(-(-x-m)^2/(2*sigma^2))+exp(-(2*pi-x-m)^2/(2*sigma^2))+exp(-(x-m)^2/(2*sigma^2))+exp(-(-2*pi+x-m)^2/(2*sigma^2)))','independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares','StartPoint' ,start,'Lower' ,lower, 'Upper', upper);
opts.Display = 'Off';
opts.Weights = weights;

% Fit model to data.
[fitResult, gof] = fit( xData, yData, ft, opts );

coeffs = coeffvalues(fitResult);
conf=confint(fitResult);

fitResult.m;
fitResult.sigma;

end