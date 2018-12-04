%{
Things to change:
	Pecentage in line 14 - so that you test a small number of images (72,000 should be fine)
	NN used in line 16
%}


%%
nunAlex_ds=imageDatastore('FakeNunchuckImages','IncludeSubfolders',true,'LabelSource','foldernames');

%% 

[smalltest,bigtest] = splitEachLabel(testImgs,0.5,'Randomize');
preds=classify(nunchucknet9s,smalltest); 
correctans=smalltest.Labels;
results=(correctans==preds);
numCorrect=sum(results==1);
percentageCorrect=(numCorrect/numel(correctans))*100

%% 

groupOrder=[-177:5:0,2:5:177]; %order in which the groups will be displayed-must match var type
groupOrder=categorical(groupOrder);
[cmat,labels]=confusionmat(smalltest.Labels,preds,'Order',groupOrder);
heatmap(labels,labels,cmat);
xlabel('Predicted Angles');
ylabel('Correct Angles');
colormap default