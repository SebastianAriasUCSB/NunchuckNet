net=nunchucknet9s %Network that will be the basis of the training

%Create image datastore of all fake nunchucks with the label from the foldernames
fakeNun_ds=imageDatastore('FakeNunchuckImages','IncludeSubfolders',true,'LabelSource','foldernames');

%Split the image datastore into a three different datastores (Trainging, testing, validation)
[testImgs,trainImgs,validationImgs] = splitEachLabel(fakeNun_ds,0.2,0.793,'Randomize');

%numClasses = numel(categories(fakeNun_ds.Labels));


layers=net.Layers; %Gets the layers of the network

%layers(end-2)=fullyConnectedLayer(numClasses);
%layers(end) = classificationLayer;

%Training options
options = trainingOptions('sgdm','InitialLearnRate', 0.01,'LearnRateSchedule','piecewise', 'LearnRateDropPeriod',1,'LearnRateDropFactor',0.1,'Plots','training-progress','MaxEpochs',30,'MiniBatchSize',360,'Shuffle','every-epoch','ValidationData',validationImgs,'ValidationFrequency',100,'ValidationPatience',4)

%Begin neural network training
[nunchucknet10s,info10s] = trainNetwork(trainImgs, layers, options);
