%getting training images

nunAlex_ds=imageDatastore('FakeNunchuckImages','IncludeSubfolders',true,'LabelSource','foldernames');
[testImgs,trainImgs,validationImgs] = splitEachLabel(nunAlex_ds,0.2,0.793,'Randomize');
%numClasses = numel(categories(nunAlex_ds.Labels));

net=nunchucknet7s
layers=net.Layers;
%layers(end-2)=fullyConnectedLayer(numClasses);
%layers(end) = classificationLayer;


options = trainingOptions('sgdm','InitialLearnRate', 0.01,'LearnRateSchedule','piecewise', 'LearnRateDropPeriod',1,'LearnRateDropFactor',0.1,'Plots','training-progress','MaxEpochs',30,'MiniBatchSize',360,'Shuffle','every-epoch','ValidationData',validationImgs,'ValidationFrequency',100,'ValidationPatience',4)
[nunchucknet8s,info8s] = trainNetwork(trainImgs, layers, options);
