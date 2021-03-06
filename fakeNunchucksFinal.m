clc
close

tic


angle=0; %180*rand
image=nunImage(angle);
imshow(image)
%imwrite(image,'D:/Documents/Research/Fygenson Lab Stuff/Post-Florida/NeuralNetworks/0tests/angletest.tif'); %writes image to right folder

%}


%{
N=10 %number of images per angle that will be made
binSize=5 %angle bin size
numOfBins=360/binSize %number of angles that 180 will be split into

makeFolders(binSize) %makes folders with given bin size

for i=1:numOfBins%numOfAngles
    parfor j=1:N
    angle=(i-1)*binSize+(binSize/2)+binSize*rand-binSize/2-180;
    image=nunImage(angle);
    savePath=strcat('FakeNunchuckImages/',num2str(-1*((i-1)*binSize+(binSize/2)-180)),'/',num2str(j),')',num2str(-angle),'.tif'); %path to where the image will be saved
    imwrite(image,savePath); %writes image to right folder
    end
        
    %progress bar display    
    clc
    bi=round((i/(numOfBins*2))*100);
    bar=repmat('|',1,bi);
    empbar=repmat('_',1,50-bi);
    %disp(bar,num2str((i/72)*100))
    disp(strcat(bar,empbar,num2str(round(((i/numOfBins)*100),3)),"%"))
end


%image=nunImage(180*rand);

runTime=toc;

strcat(num2str(N*numOfBins),' images in: ',num2str(toc/60),' mins')


%}

%________________________FUNCTIONS_______________________________
function out=nunImage(nunchuckAngle)
image=zeros(200,'uint8'); %blank canavas for 8bit image 

%nunchuckAngle=180*rand

[image,center]=nunchuck(image,nunchuckAngle); %creates a nunchuck on the image

image=backTube(image,center);

%image=diffusion(image); %applies diffusion to image in order to make it less jagged

%image=noise(image); %adds noise to image

image=reformatImages(image);

out=image;

end


function [out,center]=nunchuck(image,angleNun) %creates a nunchuch in the image/

center=[round(40*rand+80),round(40*rand+80)]; %randomized center (40x40 square)
angleArm=360*rand; %intial angle at which first arm will come out

brightness1=randi(195,'uint8')+uint8(60);%brightness for the first(brighter arm) arm
brightness=double(brightness1);
brightness=normrnd(brightness/2,10); %picks second brightness usign a normal distribution
brightness2=uint8(brightness);
basebrightness=brightness2-0.8*rand*brightness2;

image1=arm(image,angleArm,brightness1,20,center,basebrightness); %draws first arm (originally 35)
angleNun=180-angleNun; %switched how the angle is defined 
angleArm=angleArm+angleNun; %angle of second arm according to nunchuck angle desired
%brightness=brightness/2; %brightness for the second arm should be half of brighter arm
image2=arm(image,angleArm,brightness2,20,center,basebrightness); %creates the new arm at desired angle (originally 25)
    %dimmer and shorter(most likely) -last two numbers-to recreate single labeled arm
    %image1(center(2)-20:center(2)+20,center(1)-20:center(1)+20)=uint8(50);
out=image1+image2; %adds two images to create a superposition of the arms


end 

function out=backTube(image,nunCenter) %creates a nunchuch in the image/

luck=0;
num=0;
limit=0.9; %initial threashold to determine whether arm will be drawn
if rand<limit
    luck=1;
end

while luck==1

    if rand<limit %chance that a tube will be drawn
        num=num+1;
        %center=[79,79];
        luck=1;
        center=[round(200*rand),round(200*rand)]; %randomized center
        while center(1)<nunCenter(1)+10 && center(1)>nunCenter(1)-10
            center(1)=round(200*rand); %randomized center
        end
        while center(2)<nunCenter(2)+10 && center(2)>nunCenter(2)-10
            center(2)=round(200*rand); %randomized center
        end
        angleArm=findAngle(center,nunCenter)-350*rand-5;
        %image(center(2)-1:center(2)+1,center(1)-1:center(1)+1)=uint8(255);
        brightness=225*rand+30;
        size=rand*15; %(originally 25)
        image=arm(image,angleArm,brightness,size,center,brightness);
    else
        luck=0;

    end
    limit=limit/2;
end
%image(80:120,80:120)=uint8(100);
num;
out=image;

end 

%{
function out=arm(image,angleInitial,brightness,size,center)

point=center; %center of nunchuck
length=30*rand+size; %size of arm-depending on input and random variable
%image(point(2)-1:point(2)+1,point(1)-1:point(1)+1)=uint8(brightness); 
    %-does not mark the center of the nunchuck
angle=angleInitial;%initial angle of the arm-input
angleBias=2*rand-1;%angle that will determine overall curvature of arm - random
pointOld=point;
for i=1:length
    angle=angle+angleBias/2; %increments angle each iteration to create curvature
    %{
    if rand<0.1
        angleBias=-angleBias
    end
    %}
    point(1)=pointOld(1)+i*cosd(angle); %finds next position of arm based on incremented angle
    point(2)=pointOld(2)+i*sind(angle);
    if (i==1) %does not mark first point to create the characteristic void in the middle of the nunchuck
        continue
    end
    if round(point(2))-1<1 || round(point(2))+1>200 || round(point(1))-1<1 || round(point(1))+1>200
        break
    end
    image(round(point(2))-1:round(point(2))+1,round(point(1))-1:round(point(1))+1)=uint8(brightness);
    %marks a 2x2 area at next point with input brightness
end
out=image;

end
%}

function out=diffusion(P)
%solves the 2D diffusion equation to spread out the nunchuck
Nt=round(15*rand+15); %number of time steps (random with min of 15)
dt=0.1; %time step size-arbitrary units
D=1; %diffusion coefficient
dx=1; %step size

P=im2double(P); %converts imnage to double in order to make the calculations

PNew=P; %douplicates image

for k=1:Nt %time loop
    for i=2:199 %space loops
        for j=2:199
            %if(ismember([j i],dots ,'rows')==1)
             %   continue
            %end
            PNew(i,j)=double(P(i,j))+(D*dt)/(dx^2)*(P(i+1,j)+P(i-1,j)+P(i,j+1)+P(i,j-1)-4*P(i,j));
            %finite difference method for diffusion equation
        end
    end
    P=PNew; %passes new values of image for next loop
end

P=im2uint8(P); %converts image back to 8bit

out=P;
end 


function out=noise(image)

%next loop adds a random value (20-30) to each pixel to simulate noise
noiseLevel=randi(20,'uint8')+20;
noiseBaseline=randi(noiseLevel/2,'uint8')+noiseLevel/3;
%noiseBaseline=noiseLevel/3
for i=1:200
    for j=1:200
        %image(i,j)=image(i,j)+randi(40,'uint8')+uint8(40);
        image(i,j)=image(i,j)+randi(noiseLevel,'uint8')+uint8(noiseBaseline);
    end 
end

%next loop will increase each pixel to simulate differences in image
%brightness
brightnessIncrease=uint8(40*rand); %random amount that each pixel will be increased by
for i=1:200
    for j=1:200
        image(i,j)=image(i,j)+brightnessIncrease;
    end 
end
out=image;
end


function out=findAngle(new,old)

out=acosd(dot(new-old,[1,0])/(norm(new-old)*norm([1,0])))+180;
if(new(2)<100)
    out=360-out;
end

end

function makeFolders(binSize)
numOfFolders=360/binSize;

if exist('FakeNunchuckImages')==7
    %disp("True")
    rmdir FakeNunchuckImages s
end
mkdir FakeNunchuckImages %makes inital folder

for i=1:numOfFolders
    angle=(i-1)*binSize+(binSize/2)-180; %so that folder name is in the middle of the bin
    %disp(angle)
    folderData=['FakeNunchuckImages/' num2str(angle)]; %path of new folder with name
    mkdir(folderData)
end
end

function out=reformatImages(img)
    img(201:227,201:227)=uint8(0);
    img = cat(3, img, img, img);
    out=img;
end



function out=arm(image,angleInitial,brightness,size,center,vertexBrightness) %Amber's arm function

point=[0,0];%because we must start random walk from the center before we perform the rotation
Length=70*rand+size; %size of arm-depending on input and random variable
angle=angleInitial;%initial angle of the arm-input

%from Amber's filament simulation program
n_steps=round(Length)-1;%number of pixels
sigma_i=3.7;%the sigma of the Gaussian distribution from which we draw bend angle of each step

theta_i=normrnd(0,sigma_i,[1,n_steps]);
theta_i(1)=0;

running_sum=cumsum(theta_i);%the cumulative sum of angles for each filament
x=zeros(1,n_steps);%make empty arrays for storing x and y coordinates for random walks
y=zeros(1,n_steps);

%in this for-loop, fill x and y arrays using the simulated angles
for i=1:n_steps
    if i==1
        x=point(1)+cosd(running_sum(i));
        y=point(2)+sind(running_sum(i));
    else
        x(i)=x(i-1)+cosd(running_sum(i));
        y(i)=y(i-1)+sind(running_sum(i));
    end
end

%smooth the x-y curve.
for counter=1:30
    x=smooth(x);y=smooth(y);
end

if length(x)<8%for "backtubes", Length could be very short, so we don't need to do this first rotation to "correct"
    R = [cosd(angle) -sind(angle); sind(angle) cosd(angle)];%rotation matrix
    rotated = (R*[x,y]')';

    %translate the filament so it starts at the desired point.
    x=rotated(:,1)+center(1);
    y=rotated(:,2)+center(2);
else
    %now measure the inital angle
    for i=1:3%look at three vectors each of Length 2 (or 3, between 3 neighboring dots)
        vector=[x(i+4)-x(i+2),y(i+4)-y(i+2)];
        initial_angle(i)=atand(vector(2)/vector(1));
    end
    off_angle=mean(initial_angle);%calculate the inital angle that the filament is off by
    R = [cosd(-off_angle) -sind(-off_angle); sind(-off_angle) cosd(-off_angle)];%rotation matrix so the filament is at 0 degrees
    rotated = (R*[x,y]')';

    %rotate to achieve the desired orientation. Note the handedness.
    R = [cosd(angle) -sind(angle); sind(angle) cosd(angle)];%rotation matrix
    rotated_again = (R*rotated')';

    %translate the filament so it starts at the desired point.
    x=rotated_again(:,1)+center(1);
    y=rotated_again(:,2)+center(2);
end

evalue=100; %1.8*rand+0.2; %value used in the exponetial that determines the arms initial brightness
for i=1:n_steps 
    if i==1 %does not mark first point to create the characteristic void in the middle of the nunchuck
        continue
    end
    if round(x(i))-1<1 || round(x(i))+1>200 || round(y(i))-1<1 || round(y(i))+1>200
        break
    end

    %if brightness2==-1
    %    image(round(y(i))-1:round(y(i))+1,round(x(i))-1:round(x(i))+1)=uint8(brightness);%marks a 2x2 area at next point with input brightness
    %else
        
        brightnessLevel=(brightness-vertexBrightness)*(1-exp(-(evalue)*(i-1)))+vertexBrightness;
        image(round(y(i))-1:round(y(i))+1,round(x(i))-1:round(x(i))+1)=uint8(brightnessLevel);%marks a 2x2 area at next point with input brightness
    %end
    
end
out=image;
end

%}

%{
Things of note:
-Includes randomized arm sizes (taking into account tendency for dimmer arm
to be shorter)
-Randomized arms curvature
-Difference in arm bnrightness
-Simulated noise
-Randomized image brightness
-Randomized nunchuck center position
%}