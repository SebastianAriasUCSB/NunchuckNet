clc
close

tic

%This portion is to create and display a single nunchuck with the specified angle
%{
angle=180*rand
image=nunImage(angle);
imshow(image)
%imwrite(image,'D:\Documents\Research\Fygenson Lab Stuff\Post-Florida\NeuralNetworks\0tests\angletest.tif'); %writes image to right folder

%}

%This portion creates the folders and a pecific number of nunchucks with random angles

N=5 %number of images per angle that will be made
binSize=5 %angle bin size
numOfBins=360/binSize %number of angles that 180 will be split into

makeFolders(binSize) %makes folders with given bin size

for i=1:numOfBins%numOfAngles
    parfor j=1:N
    angle=(i-1)*binSize+(binSize/2)+binSize*rand-binSize/2-180;
    image=nunImage(angle);
    savePath=strcat('FakeNunchuckImages/',num2str(-1*((i-1)*binSize+(binSize/2)-180)),'/',num2str(j),')',num2str(-angle),'.tif'); %path where the image will be saved
    imwrite(image,savePath); %writes image to right folder
    end
end


%image=nunImage(180*rand);

runTime=toc;

strcat(num2str(N*numOfBins),' images in: ',num2str(toc/60),' mins')


%}

%________________________FUNCTIONS_______________________________
function out=nunImage(nunchuckAngle)
image=zeros(200,'uint8'); %blank canavas for 8bit image 

[image,center]=nunchuck(image,nunchuckAngle); %creates a nunchuck on the image

image=backTube(image,center); %adds background tubes

image=diffusion(image); %applies diffusion to image in order to make it less jagged

image=noise(image); %adds noise to image 

image=reformatImages(image); %necessary for training

out=image;

end


function [out,center]=nunchuck(image,angleNun) %creates a nunchuch in the image/

center=[round(40*rand+80),round(40*rand+80)]; %randomized center (40x40 square)
angleArm=360*rand; %intial angle at which first arm will come out
brightness=randi(50,'uint8')+uint8(90); %brightness for the first arm
image1=arm(image,angleArm,brightness,35,center); %draws first arm
angleNun=180-angleNun; %switched how the angle is defined 
angleArm=angleArm+angleNun; %angle of second arm according to nunchuck angle desired
brightness=randi(30,'uint8')+uint8(30); %brightness for the second arm
image2=arm(image,angleArm,brightness,25,center); %creates the new arm at desired angle
    %the dimmer arm has a smaller minimum length -last two numbers-to recreate single labeled arm
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
        while center(1)<120 && center(1)>80
            center(1)=round(200*rand); %randomized center
        end
        while center(2)<120 && center(2)>80
            center(2)=round(200*rand); %randomized center
        end
        angleArm=findAngle(center,nunCenter)-350*rand-5;
        %image(center(2)-1:center(2)+1,center(1)-1:center(1)+1)=uint8(255);
        brightness=100*rand+30;
        size=rand*35;
        image=arm(image,angleArm,brightness,size,center);
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
for i=1:200
    for j=1:200
        image(i,j)=image(i,j)+randi(40,'uint8')+uint8(40);
    end 
end

%next loop will increase each pixel to simulate differences in image
%brightness
brightnessIncrease=uint8(40*rand); %random amount that each pixel will be increased by
for i=1:200
    for j=1:200
        if image(i,j)+brightnessIncrease>255 %does not let a pixel get over 255
            continue
        end
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


function out=arm(image,angleInitial,brightness,size,center)

point=center; %center of nunchuck
length=70*rand+size; %size of arm-depending on input and random variable
angle=angleInitial;%initial angle of the arm-input

%from Amber's filament simulation program
n_steps=round(length)-1;%number of pixels
sigma_i=3.7;%the sigma of the Gaussian distribution from which we draw bend angle of each step

theta_i=normrnd(0,sigma_i,[1,n_steps]);
theta_i(1)=angle;

running_sum=cumsum(theta_i);%the cumulative sum of angles for each filament
x=zeros(1,n_steps);%make empty arrays for storing x and y coordinates for random walks
y=zeros(1,n_steps);

for i=1:n_steps
    if i==1
        x=point(1)+cosd(running_sum(i));
        y=point(2)+sind(running_sum(i));
    else
        x(i)=x(i-1)+cosd(running_sum(i));
        y(i)=y(i-1)+sind(running_sum(i));
    end
    
    if i==1 %does not mark first point to create the characteristic void in the middle of the nunchuck
        continue
    end
    if round(x(i))-1<1 || round(x(i))+1>200 || round(y(i))-1<1 || round(y(i))+1>200
        break
    end
    image(round(y(i))-1:round(y(i))+1,round(x(i))-1:round(x(i))+1)=uint8(brightness);%marks a 2x2 area at next point with input brightness
end
out=image;
end

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