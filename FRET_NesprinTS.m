% TENSION SENSOR FRET CALCULATION PROGRAM ------ v2.0; JULY 2019 ----------
% Author: Tamal Das, TIFR Hyderabad --- Contact: tdas@tifrh.res.in --------
% This program has been custom written for Nesprin Tension Sensor ---------
% But it can be adapted for other FRET-based or ratio-metric sensors ------
% -------------------------------------------------------------------------
% Step 1: Input parameters ------------------------------------------------
% -------------------------------------------------------------------------
% CutoffIn is an important parameter; have to be adjusted for every image, 
% It should be just enough to filter the noise but not higher -------------
CutoffDon = 455;
CutoffFRET = 455;
CutoffAcc = 910;
% Integrated contribution of Donor emission to FRET Channel: Predetermined
IntCalib = 0.3753; % You need the spectra file: Specific to FRET; here it is obtained by dividing the sum emission of mTFP1 between 530-630 nm (FRET Channel) by that between 460-500 nm (Donor Channel)
isSmooth = 0; % set this to zero for smoothening the image in matlab
outSmooth = 1; % For smoothened output set 1
h = (1/9)*ones(3,3); % Smoothening kernel for the FRET image
isSelectRoI = 1; % Do you want select a RoI from the image?
isPDFreqd = 0; % Do you need to plot the pdf of FRET index distribution?

% -------------------------------------------------------------------------
% Step 2: Read the FRET, Donor, and Acceptor files ------------------------
% -------------------------------------------------------------------------
% FRET Image -----------------------------------------------
[FlName,PName] = uigetfile('.tif','Please input FRET file');
flnamefull = strcat(PName,'/',FlName);
imFRET = double((imread(flnamefull)));
if isSmooth == 0
    imFRET2D = imfilter(imFRET,h);
else
    imFRET2D = imFRET;
end
[m,n] = size(imFRET);
imFRET = reshape(imFRET,m*n,1);

% Donor Image -----------------------------------------------
[FlName,PName] = uigetfile('.tif','Please input Donor file');
flnamefull = strcat(PName,'/',FlName);
imDonor = double((imread(flnamefull)));
if isSmooth == 0
    imDonor2D = imfilter(imDonor,h);
else
    imDonor2D = imDonor;
end
imDonor = reshape(imDonor,m*n,1);

% Acceptor Image -----------------------------------------------
[FlName,PName] = uigetfile('.tif','Please input Acceptor file');
flnamefull = strcat(PName,'/',FlName);
imAcc = double((imread(flnamefull)));
if isSmooth == 0
    imAcc2D = imfilter(imAcc,h);
else
    imAcc2D = imAcc;
end
imAcc = reshape(imAcc,m*n,1);

% -------------------------------------------------------------------------
% Step 3: Generate the FRET image and smoothen the output, if specified ---
% -------------------------------------------------------------------------
% Initially assigning a non-sensical FRET values to all points ------------
stupVal = -1; imRatio2D = stupVal*ones(m,n); 
for i=1:m
    for j=1:n
        if (imDonor2D(i,j)>=CutoffDon) && (imAcc2D(i,j)>=CutoffAcc)
            numER = (imFRET2D(i,j)-IntCalib*imDonor2D(i,j));
            denomER = imFRET2D(i,j)+imDonor2D(i,j);
            imRatio2D(i,j)=numER/denomER;
        end
    end
end
% Smoothening the output---------------------------------------------------
if outSmooth == 1
    imRatioS2D = imfilter(imRatio2D,h); % imRatioS = imfilter(imRatioS,h);
else
    imRatioS2D = imRatio2D;
end
% -------------------------------------------------------------------------
% Plot the 2D distribution of FRET index ----------------------------------
figure(1)
clims = [0 1];
imagesc(imRatioS2D,clims);
colormap jet
FigHandle = figure(1); figwidth = 512; figheight = figwidth;
set(FigHandle, 'Position', [200, 200, figwidth, figheight]);
% Save FRET map in as .png file with a specific name ----------------------
lenFl = length(FlName); trunFileName = FlName(1:lenFl-4);
imFileName = strcat('FRETMap',trunFileName,'.png');
set(gca,'XTick',[]); set(gca,'YTick',[]); set(gca,'Position',[0 0 1 1])
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 m n])
print(imFileName,'-dpng','-r1');

%--------------------------------------------------------------------------
% Step 4: Interactive selection of RoI for mean FRET calculation ----------
% -------------------------------------------------------------------------
if isSelectRoI == 1
    str1 = 'Left click and hold to begin drawing.';
    str2 = '\nRelease Mouse Button when Completed';
    msg = strcat(str1,str2); msgPrompt = sprintf(msg);
    uiwait(msgbox(msgPrompt));
    hFH = imfreehand();
    % Create a binary image ("mask") from the ROI object 
    % and multiply with FRET image ----------------------------------------
    binaryImage = hFH.createMask(); xy = hFH.getPosition;
    binaryFRET2D = binaryImage.*imRatio2D;
    % Filter out non-sensical values from the Binary Image ----------------
    % and Calculate the mean FRET index -----------------------------------
    binaryFRET = reshape(binaryFRET2D,m*n,1);
    rowstodelete = any(binaryFRET==0|binaryFRET==stupVal,2);
    binaryFRET(rowstodelete) = [];

    meanFRETindex = mean(binaryFRET);  display(meanFRETindex)
else
    imRatio = reshape(imRatio2D,m*n,1);
    rowstodelete = any(imRatio==stupVal,2);
    imRatio(rowstodelete)=[];
    meanFRETindex = mean(imRatio);  display(meanFRETindex)
end

% -------------------------------------------------------------------------
% Step 5 (OPTIONAL): Probability density plot -----------------------------
% -------------------------------------------------------------------------
if isPDFreqd == 1
    figure(2)
    numbin = 51; binsize = 1/(numbin-1); bins = 0:binsize:1;
    freq = histc(binaryFRET,bins);
    sumfreq = sum(freq); pdf = freq/sumfreq; pdfmax = max(pdf);
    % Heat map pdf --------------------------------------------------------
    cmscat = jet(numbin);
    for i=1:numbin
        cc = cmscat(i,:);
        h = bar(bins(i),pdf(i),binsize);
        set(h, 'FaceColor', cc,'EdgeColor','none');
        hold on
    end
    hold off
    axis([0,1,0,1.2*pdfmax]);
    xlabel('FRET Index','FontSize',12,'FontWeight','bold');
    ylabel('PDF', 'FontSize',12, 'FontWeight','bold');
    ax = gca; set(ax, 'FontSize',12,'FontWeight','bold');
    ax.XTick = [0 0.2 0.4 0.6 0.8 1.0];
    FigHandle = figure(2);
    figwidth = 512;
    figheight = figwidth/2;
    set(FigHandle, 'Position', [100, 100, figwidth, figheight]);
    histFileName = strcat('Hist',trunFileName,'.png');
    saveas(gcf,histFileName)
end

% -------------------------------------------------------------------------
% THE END -----------------------------------------------------------------









