%Confusion matrix maker and plot

%Load angle data
correctAns=predsFiltered';
predictions=mba;

%Next portion will discretize angles
edges=-180:5:180; %bin edges for discretization
binAssignCorrect=discretize(correctAns,edges); %creates matrix with indeces of bins
binAssignPred=discretize(predictions,edges);

%Next portion will create confusion matrix and get labels
 %cmat-confusion matrix
 %labels-order of rows and columsn in confusion mat (bin index)
[cmat,labels]=confusionmat(binAssignCorrect,binAssignPred);
labels=labels*5-180-2.5; %converts labels from bin index to angles (middle of bin)

%Next portion will plot a heat mat of the confusion matrix with given labels
heatmap(labels,labels,cmat); %plots confusion matrix as heat map with labels 
title('Confusion Plot')
ylabel('NN7s Predictions');
xlabel('Normal Analysis');
colormap default