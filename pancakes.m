%% Automated stacking
% January 24, 2020
% Author: Jason Au
% Licence: GPL-3.0-or-later 

% This script should allow automatic identification and selection of
% end-diastolic frames, and stitch them back together for a 'stacked' image

% New additions Jan 24, 2020
% - Make frame 1/1200 be one less (to accomodate loop 1:end-1
% - Added title of each file to the Figure window
% - Removed saving png files as png backups. Saves 40% processing time
% - Extended the search range of red box before blue ECG spike to 17 pxls
% - Added legal


%% Legal
% Pancakes.exe: Automated image extraction from ultrasound .avi files
%     Copyright (C) 2020  Jason Au
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <https://www.gnu.org/licenses/>.
%
%     jason.au@uwaterloo.ca
%     250 Laurelwood Dr., Waterloo ON, Canada N2J 0E2


%% Pancakes.exe
% Clean your workspace!
clear all;
close all;
fontSize = 22;

% Dialogue box
a1 = questdlg('How many files are you stacking?','Pancakes','One','Multiple','One');

switch a1
    case 'One'
        % Select the file
        [baseFileName, folderName, FilterIndex] = uigetfile('*.*','Select avi file');
        movieFileName = fullfile(folderName, baseFileName);
        
        % Extract basic file information
        v = VideoReader(movieFileName);
        frames = v.NumberOfFrames;
        vHeight = v.Height;
        vWidth = v.Width;
        framesWritten = 0;
        vs = 1;
        
        % Prepare analysis figure
        tmptitle = sprintf('%s', baseFileName);
        figure('Name',tmptitle,'NumberTitle','off');
        set(gcf,'units','normalized','outerposition',[0 0 1 1]);
        
        %         % Save individual frames as a precaution
        %         writeToDisk = true;
        %         [folder, baseFileName, extensions] = fileparts(movieFileName);
        %         folder = pwd;
        %         outputFolder = sprintf('%s/Stacked frames for %s', folder, baseFileName);
        %         if ~exist(outputFolder, 'dir')
        %             mkdir(outputFolder);
        %         end
        
        % Loop through all frames to find end diastole on the ECG
        % Set empty saves
        meanGrayLevels = zeros(frames, 1);
        meanRedLevels = zeros(frames, 1);
        meanGreenLevels = zeros(frames, 1);
        meanBlueLevels = zeros(frames, 1);
        
        % Set acquisition log to 0
        bluelog = 0;
        extractedFrames = 0;
        
        for i = 1:frames-1
            % If the preceding frame was captured, skip the next two (red box is 2
            % pixels wide)
            if bluelog == 1
                bluelog = 2;
                continue
            end
            
            if bluelog == 2;
                bluelog = 0;
                continue
            end
            
            % Extract a single frame and display it
            tmpFrame = read(v, i);
            hImage = subplot(2,2,1);
            image(tmpFrame);
            caption = sprintf('Frame %4d of %d.', i, frames-1);
            title(caption, 'FontSize', fontSize);
            drawnow;
            
            % Determine if ECG stable or moving
            % red(:,:,1) = 248; blue(:,:,3) = 160
            ecgroi = tmpFrame(365:end, 1:569, 1);
            ecgend = tmpFrame(365:end, 571:572, 1);
            
            % Case when the ECG marker is still moving across the screen
            if any(ecgroi(:) > 200)
                %Get red box position
                [r,c] = find(ecgroi > 200);
                redcol = c(1);
                %Get blue spike positions
                ecgblue = tmpFrame(368:385, 1:569, 3);
                [bluer,bluec] = find(ecgblue > 120);
                
                %Find frames whose red positions are within 10 pixels of blue spike
                bluelog = 0;
                for j = 1:length(bluec);
                    if abs(redcol - bluec(j)) < 10
                        bluelog = 1;
                    end
                end
                
                %If red box is within 10 pixels of blue spike, save frame, and
                %export
                if bluelog == 1
                    vStacked(:,:,:,vs) = tmpFrame;
                    vs = vs+1;
                    
                    %                     % Write to output file
                    %                     outputBaseFileName = sprintf('Frame %4.4d.png', i);
                    %                     outputFullFileName = fullfile(outputFolder, outputBaseFileName);
                    %                     %text(5,15,outputBaseFileName,'FontSize',20);
                    %                     frameWithText = getframe(gca);
                    %                     imwrite(frameWithText.cdata, outputFullFileName, 'png');
                    
                end
                
            elseif any(ecgend(:) > 200)
                %Get red box position
                ecgred = tmpFrame(365:end, 555:end, 1);
                [r,c] = find(ecgred > 200);
                redcol = c(1);
                
                %First look for blue spikes in the 17 pixels left of box
                ecgblue = tmpFrame(368:385, 555:end, 3);
                [bluer,bluec] = find(ecgblue > 120);
                bluelog = 0;
                for j = 1:length(bluec);
                    if abs(redcol - bluec(j)) < 17
                        bluelog = 1;
                    end
                end
                
                %If red box is within 17 pixels of blue spike, save frame, and
                %export
                if bluelog == 1
                    vStacked(:,:,:,vs) = tmpFrame;
                    vs = vs+1;
                    
                    %                     % Write to output file
                    %                     outputBaseFileName = sprintf('Frame %4.4d.png', i);
                    %                     outputFullFileName = fullfile(outputFolder, outputBaseFileName);
                    %                     frameWithText = getframe(gca);
                    %                     imwrite(frameWithText.cdata, outputFullFileName, 'png');
                    %
                else
                    %Next look in the next frame to see if blue spike is within a
                    %certain area
                    tmpblue = read(v,i+1);
                    ecgblue = tmpblue(368:385, 555:end, 3);
                    [bluer,bluec] = find(ecgblue > 120);
                    for j = 1:length(bluec);
                        if abs(redcol - bluec(j)) < 10
                            bluelog = 1;
                        end
                    end
                    
                    if bluelog == 1
                        vStacked(:,:,:,vs) = tmpFrame;
                        vs = vs+1;
                        
                        %                         % Write to output file
                        %                         outputBaseFileName = sprintf('Frame %4.4d.png', i);
                        %                         outputFullFileName = fullfile(outputFolder, outputBaseFileName);
                        %                         %text(5,15,outputBaseFileName,'FontSize',20);
                        %                         frameWithText = getframe(gca);
                        %                         imwrite(frameWithText.cdata, outputFullFileName, 'png');
                        %
                    end
                end
                
                
                
            end
            
            if bluelog == 1
                tmpint = length(extractedFrames);
                extractedFrames(i) = 1;
                hPlot = subplot(2,2,2);
                hold off;
                plot(extractedFrames, 'ro');
                grid on;
                title('Indication of when frames are extracted', 'FontSize', fontSize);
                if i < 10
                    xlabel('Frame Number');
                    ylabel('Was the frame extracted?');
                    ylim([0,2]);
                end
                
                if length(extractedFrames) == 1
                else
                    frameinterval(i) = i - tmpint;
                    hPlot = subplot(2,2,4);
                    hold off;
                    plot(frameinterval, 'bo');
                    grid on;
                    title('Interval between extracted frames', 'FontSize', fontSize);
                    if i < 20
                        xlabel('Frame Number');
                        ylabel('Inter-frame interval');
                        ylim([0,20]);
                    end
                end
                
            end
            
            % Indicate Progress
            progressIndication = sprintf('Wrote frame %4d of %d.', i, frames);
            disp(progressIndication);
            framesWritten = framesWritten+1;
        end
        
        formatSpec = '%s_stacked.dcm';
        dicomwrite(vStacked, sprintf(formatSpec,baseFileName));
        
        
        finishedMessage = sprintf('Done! It wrote %d frames to folder\n"%s"', framesWritten, outputFolder);
        disp(finishedMessage);
        
    case 'Multiple'
        % Select the files
        [filenames, pathname] = uigetfile('*.*','Select avi file','Multiselect','on');
        path = char(pathname);
        [row files_selected] = size(filenames);
        filenames = cellstr(filenames);
        
        % Loop through selected files
        for f = 1:files_selected
            clearvars -EXCEPT files_selected filenames pathname path row files_selected f a1 fontSize
            tempfile = char(filenames(f));
            
            movieFileName = fullfile(path, tempfile);
            
            % Extract basic file information
            v = VideoReader(movieFileName);
            frames = v.NumberOfFrames;
            vHeight = v.Height;
            vWidth = v.Width;
            framesWritten = 0;
            vs = 1;
            
            % Prepare analysis figure
            tmptitle = sprintf('%s', tempfile);
            figure('Name',tmptitle,'NumberTitle','off');
            set(gcf,'units','normalized','outerposition',[0 0 1 1]);
            
            
%             % Save individual frames as a precaution
%             writeToDisk = true;
%             [folder, baseFileName, extensions] = fileparts(movieFileName);
%             folder = pwd;
%             outputFolder = sprintf('%s/Stacked frames for %s', folder, baseFileName);
%             if ~exist(outputFolder, 'dir')
%                 mkdir(outputFolder);
%             end
            
            % Loop through all frames to find end diastole on the ECG
            % Set empty saves
            meanGrayLevels = zeros(frames, 1);
            meanRedLevels = zeros(frames, 1);
            meanGreenLevels = zeros(frames, 1);
            meanBlueLevels = zeros(frames, 1);
            
            % Set acquisition log to 0
            bluelog = 0;
            extractedFrames = 0;
            
            for i = 1:frames-1
                % If the preceding frame was captured, skip the next two (red box is 2
                % pixels wide)
                if bluelog == 1
                    bluelog = 2;
                    continue
                end
                
                if bluelog == 2;
                    bluelog = 0;
                    continue
                end
                
                % Extract a single frame and display it
                tmpFrame = read(v, i);
                hImage = subplot(2,2,1);
                image(tmpFrame);
                caption = sprintf('Frame %4d of %d.', i, frames);
                title(caption, 'FontSize', fontSize);
                drawnow;
                
                % Determine if ECG stable or moving
                % red(:,:,1) = 248; blue(:,:,3) = 160
                ecgroi = tmpFrame(365:end, 1:569, 1);
                ecgend = tmpFrame(365:end, 571:572, 1);
                
                % Case when the ECG marker is still moving across the screen
                if any(ecgroi(:) > 200)
                    %Get red box position
                    [r,c] = find(ecgroi > 200);
                    redcol = c(1);
                    %Get blue spike positions
                    ecgblue = tmpFrame(368:385, 1:569, 3);
                    [bluer,bluec] = find(ecgblue > 120);
                    
                    %Find frames whose red positions are within 10 pixels of blue spike
                    bluelog = 0;
                    for j = 1:length(bluec);
                        if abs(redcol - bluec(j)) < 10
                            bluelog = 1;
                        end
                    end
                    
                    %If red box is within 10 pixels of blue spike, save frame, and
                    %export
                    if bluelog == 1
                        vStacked(:,:,:,vs) = tmpFrame;
                        vs = vs+1;
                        
%                         % Write to output file
%                         outputBaseFileName = sprintf('Frame %4.4d.png', i);
%                         outputFullFileName = fullfile(outputFolder, outputBaseFileName);
%                         %text(5,15,outputBaseFileName,'FontSize',20);
%                         frameWithText = getframe(gca);
%                         imwrite(frameWithText.cdata, outputFullFileName, 'png');
%                         
                    end
                    
                elseif any(ecgend(:) > 200)
                    %Get red box position
                    ecgred = tmpFrame(365:end, 555:end, 1);
                    [r,c] = find(ecgred > 200);
                    redcol = c(1);
                    
                    %First look for blue spikes in the 17 pixels left of box
                    ecgblue = tmpFrame(368:385, 555:end, 3);
                    [bluer,bluec] = find(ecgblue > 120);
                    bluelog = 0;
                    for j = 1:length(bluec);
                        if abs(redcol - bluec(j)) < 17
                            bluelog = 1;
                        end
                    end
                    
                    %If red box is within 10 pixels of blue spike, save frame, and
                    %export
                    if bluelog == 1
                        vStacked(:,:,:,vs) = tmpFrame;
                        vs = vs+1;
                        
%                         % Write to output file
%                         outputBaseFileName = sprintf('Frame %4.4d.png', i);
%                         outputFullFileName = fullfile(outputFolder, outputBaseFileName);
%                         %text(5,15,outputBaseFileName,'FontSize',20);
%                         frameWithText = getframe(gca);
%                         imwrite(frameWithText.cdata, outputFullFileName, 'png');
%                         
                    else
                        %Next look in the next frame to see if blue spike is within a
                        %certain area
                        tmpblue = read(v,i+1);
                        ecgblue = tmpblue(368:385, 555:end, 3);
                        [bluer,bluec] = find(ecgblue > 120);
                        for j = 1:length(bluec);
                            if abs(redcol - bluec(j)) < 10
                                bluelog = 1;
                            end
                        end
                        
                        if bluelog == 1
                            vStacked(:,:,:,vs) = tmpFrame;
                            vs = vs+1;
                            
%                             % Write to output file
%                             outputBaseFileName = sprintf('Frame %4.4d.png', i);
%                             outputFullFileName = fullfile(outputFolder, outputBaseFileName);
%                             %text(5,15,outputBaseFileName,'FontSize',20);
%                             frameWithText = getframe(gca);
%                             imwrite(frameWithText.cdata, outputFullFileName, 'png');
%                             
                        end
                    end
                    
                    
                    
                end
                
                if bluelog == 1
                    tmpint = length(extractedFrames);
                    extractedFrames(i) = 1;
                    hPlot = subplot(2,2,2);
                    hold off;
                    plot(extractedFrames, 'ro');
                    grid on;
                    title('Indication of when frames are extracted', 'FontSize', fontSize);
                    if i < 10
                        xlabel('Frame Number');
                        ylabel('Was the frame extracted?');
                        ylim([0,2]);
                    end
                    
                    if length(extractedFrames) == 1
                    else
                        frameinterval(i) = i - tmpint;
                        hPlot = subplot(2,2,4);
                        hold off;
                        plot(frameinterval, 'bo');
                        grid on;
                        title('Interval between extracted frames', 'FontSize', fontSize);
                        if i < 20
                            xlabel('Frame Number');
                            ylabel('Inter-frame interval');
                            ylim([0,20]);
                        end
                    end
                    
                end
                
                % Indicate Progress
                progressIndication = sprintf('Wrote frame %4d of %d.', i, frames);
                disp(progressIndication);
                framesWritten = framesWritten+1;
            end
            
            formatSpec = '%s_stacked.dcm';
            %dicomwrite(vStacked, sprintf(formatSpec,baseFileName(1:end-4)));
            dicomwrite(vStacked, sprintf(formatSpec,baseFileName));
            
            
            finishedMessage = sprintf('Done! It wrote %d frames to folder\n"%s"', framesWritten, outputFolder);
            disp(finishedMessage);
        end
end
