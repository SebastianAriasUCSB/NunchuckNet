smallTest=imageDatastore('FakeNunchuckImages','IncludeSubfolders',true,'LabelSource','foldernames');

%[smallTest,bigTest] = splitEachLabel(testImgs,0.02,'Randomize');

preds=classify(nunchucknet9s,smallTest);
correctAns=smallTest.Labels;
results=(correctAns==preds);
numCorrect=sum(results==1);
percentageCorrect=(numCorrect/numel(correctAns))*100
