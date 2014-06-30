%Graphical User interface_2 code for the mitochondria function. The
%foundation of this gui was using the guide code built into Matlab. The
%structure of how this gui tracks data is that there is a 'data' field in
%the structure 'handles'. Inside the 'data' field, there are the different
%fields such as 'name', 'loPics', 'freq', etc. These will be updated as
%the values in the textboxes area adjusted. To calculate the movement of
%the mitochondria, click the calculate button and it will call the
%'mitochondria' function. To clear all current data, click the clear
%button.
function varargout = interface_2(varargin)
% INTERFACE_2 MATLAB code for interface_2.fig
%      INTERFACE_2, by itself, creates a new INTERFACE_2 or raises the existing
%      singleton*.
%
%      H = INTERFACE_2 returns the handle to a new INTERFACE_2 or the handle to
%      the existing singleton*.
%
%      INTERFACE_2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INTERFACE_2.M with the given input arguments.
%
%      INTERFACE_2('Property','Value',...) creates a new INTERFACE_2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before interface_2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to interface_2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help interface_2

% Last Modified by GUIDE v2.5 30-Jun-2014 13:19:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @interface_2_OpeningFcn, ...
    'gui_OutputFcn',  @interface_2_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before interface_2 is made visible.
function interface_2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to interface_2 (see VARARGIN)

% Choose default command line output for interface_2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
initialize_gui(hObject, handles, false);

% UIWAIT makes interface_2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = interface_2_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%% Main Button, calls mitochondria tracking function
function calculate_Callback(hObject, eventdata, handles)
% hObject    handle to calculate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%gives busy status
set(handles.busyStatus, 'String', 'Busy');
%pauses matlab enough to display the Busy string
pause(.05);

%stores data variables into function workspace
name = handles.data.name;
numPics = [handles.data.loPics handles.data.hiPics];
incr = get(handles.incrementMenu, 'Value');
freq = handles.data.freq;
ratio = handles.data.ratio;
areaThresh = [handles.data.loArea handles.data.hiArea];
lifetime = handles.data.lifetime;
columns = handles.data.columns;
rows = handles.data.rows;
%if the current directory is not selected, will set the full name of the
%file to include the path to the directory
if (handles.data.current)
    fullName = name;
    file_path = strcat(pwd,filesep);
else
    %ensures there is at least one filesep at the end of brwose path
    if(~exist(handles.data.browsePath,'dir'))
        errordlg('Stack Location folder does not exist','File Error');
        set(handles.busyStatus, 'String', '');
        return
    end
    if ~strcmp((handles.data.browsePath(end)),filesep)
        file_path = strcat(handles.data.browsePath,filesep);
    else
        file_path = handles.data.browsePath;
    end
    fullName = strcat(file_path,name);
    %'\' is an escape character so therefore must use '\\' for the imread
    %function in the mitochondria function to work
    doublesep = strcat(filesep,filesep);
    fullName = strrep(fullName, filesep,doublesep);
end

%Ensures that a save name exists
if(handles.data.currentName)
    saveName = name;
    %replaces illegal save characters with underscores
    if ~isempty(saveName)&&(any(saveName(regexp(saveName,'\W'))))
        saveName(regexp(saveName,'\W')) = '_';
    end
    %removes and preceding underscores or if the name is empty, just leave
    %it be
    while ~isempty(saveName)&&((strcmp(saveName(1),'_'))||(any(regexp(saveName(1),'\d'))))
       saveName(1)=[];
   end
else
    saveName = handles.data.saveName;
    if ~isempty(saveName)&&(any(saveName(regexp(saveName,'\W')))||any(saveName(regexp(saveName(1),'[^a-z|^A-Z]'))))
        errordlg('Save Name is not valid (Must be alphanumeric or ''_'' and must start with a letter)','Save Name Error' )
        set(handles.busyStatus, 'String', '');
        return
    end
    if(isempty(saveName))
        errordlg('No save name written','Save Name Error');
        set(handles.saveNameSelect, 'SelectedObject', handles.currentName);
        handles.data.currentName=1;
        guidata(hObject,handles)
        set(handles.busyStatus, 'String', '');
        return
    end
end

%Ensures that the save path exists.
if (handles.data.currentSave)
    fullSaveName = saveName;
else
    if(isempty(handles.data.browseSavePath))
        errordlg('No save path selected','Save Path Error');
        set(handles.saveDirSelect, 'SelectedObject', handles.currentSave);
        handles.data.currentSave=1;
        guidata(hObject,handles)
        set(handles.busyStatus, 'String', '');
        return
    end
    if(~exist(handles.data.browseSavePath,'dir'))
        errordlg('Save destination folder does not exist','Save Path Error');
        set(handles.saveDirSelect, 'SelectedObject', handles.currentSave);
        handles.data.currentSave=1;
        guidata(hObject,handles)
        set(handles.busyStatus, 'String', '');
        return
    end
    file_save_path = strcat(handles.data.browseSavePath,filesep);
    fullSaveName = strcat(file_save_path,saveName);
end
if any(~isfinite(numPics))
    errordlg('Picture numbers must be numeric','Input Error');
    set(handles.busyStatus, 'String', '');
    return
end
%checks if all needed images exist
inc = numPics(1):incr:numPics(2);
errorString = '';
missingFiles = false;
suspectFullName = strcat(file_path,name);
doublesep = strcat(filesep,filesep);
suspectFullName = strrep(suspectFullName, filesep,doublesep);
for i = (inc)
    suspect = strcat(fullName,sprintf('%04d.tif',i));
    if (~exist(suspect,'file'))
        
        errorString = strcat(errorString,suspectFullName,sprintf('%04d.tif',i),'\n ');
        missingFiles = true;
    end
end
if missingFiles
    fig = figure('Units','Normalized','Position',[.3 .3 .4 .4]);
    defaultBackground = get(fig,'Color');
    
    h = uicontrol('Style','edit','Units','Normalized','Position',[.10 .10 .8 .8],...
        'min',0,'max',2,'enable','inactive');
    str = sprintf(errorString);
    set(h,'String',str) % display the string
    
    uicontrol('Style','text',...
        'Units','Normalized',...
        'Position',[.3 .9 .4 .05],...
        'BackgroundColor',defaultBackground,...
        'String','These Files Do Not Exist')
    set(handles.busyStatus, 'String', '');
    return
end
if (numPics(2)<numPics(1))
    %Ensures the numbers go up
    errordlg('Last picture number must be after first picture number','Input Error');
elseif (numPics(1)<0)
    %Ensures first pic number is >=0
    errordlg('first picture number must be non negative','Input Error');
elseif ((numPics(2)-numPics(1))/incr<1)
    %Ensures at least two pictures are evaluated
    errordlg('Please select an interval and increment that evaluates at least 2 pictures','Input Error');
elseif (freq<=0)
    %ensures frequency is positive
    errordlg('Period value must be positive','Input Error');
elseif ~isfinite(freq)
    errordlg('Period must be numeric', 'Input Error');
elseif (ratio<=0)
    %ensures the ratio of micron to pixel is positive
    errordlg('Ratio must be positive','Input Error');
elseif ~isfinite(ratio)
    errordlg('Ratio must be numeric', 'Input Error');
elseif (any(~isfinite(areaThresh)))
    errordlg('Areas must be numeric','Input Error');
elseif (areaThresh(1)>=areaThresh(2))
    %ensures the lower area threshold is strictly lower than the upper area
    %threshold
    errordlg('Lower area must be strictly smaller than upper area','Input Error');
elseif (areaThresh(1)<=0)
    %ensures the areas are positive
    errordlg('Areas must be positive','Input Error');
elseif (lifetime < 0)
    %ensures that the lifetime is positive
    errordlg('Minimum lifetime must be non negative','Input Error');
elseif ~isfinite(lifetime)
    errordlg('Lifetime must be a number','Input Error');
elseif (floor((numPics(2)-numPics(1))/incr) < lifetime*freq/incr)
    %ensures that enough frames will be evaulated to exceed the min
    %lifetime
    errordlg('Minimum lifetime too high or number of Pics too low','Input Error');
elseif (columns<0)
    errordlg('Columns must be positive','Input Error');
elseif ~isfinite(columns)
    errordlg('Columns must be a number','Input Error');
elseif (rows<0)
    errordlg('Rows must be positive','Input Error');
elseif ~isfinite(rows)
    errordlg('Rows must be a number','Input Error');
else
    %if all things are good, start to calculate
    
    %clear the plot
    set(handles.Histogram,'Visible','off');
    set(get(handles.Histogram,'Children'),'Visible','off');
    set(handles.Histogram2,'Visible','off');
    set(get(handles.Histogram2,'Children'),'Visible','off');
    axes(handles.Centroid);
    cla;
    set(gca,'Visible','on');
    set(get(gca,'Children'),'Visible','on');
    colorbar off
    axes(handles.Centroid2);
    cla;
    set(gca,'Visible','on');
    set(get(gca,'Children'),'Visible','on');
    colorbar off
    axes(handles.Quiver);
    cla;
    set(handles.netGraph, 'SelectedObject', handles.netCentroid);
    set(handles.totGraph, 'SelectedObject', handles.totCentroid);
    handles.data.showCent = 1;
    handles.data.showCent2 = 1;
    %calculate the net distances and plot the centroid movement scatter
    %plot
    [netDist,totDist, netAngle] = mitochondria_2(fullName,numPics,incr,freq,ratio,...
        areaThresh,lifetime,handles.Centroid,handles.Centroid2,handles.Quiver,columns,rows);
    %remove the NaNs
    netDist = netDist(~isnan(netDist));
    %saves distance data
    handles.data.netDist = netDist;
    totDist = totDist(~isnan(totDist));
    handles.data.totDist = totDist;
    netAngle = netAngle(~isnan(netAngle));
    handles.data.netAngle = netAngle;
    %Title of graph
    axes(handles.Centroid);
    centroidTitle = sprintf('%s\n %s',name,' log(net distance) of centroids');
    title(centroidTitle);
    %shows the limits of the centroid movement
    limits = get(gca,'Clim');
    handles.data.loLimit = limits(1);
    handles.data.hiLimit = limits(2);
    set(handles.loLimit, 'String', handles.data.loLimit);
    set(handles.hiLimit, 'String', handles.data.hiLimit);
    
    axes(handles.Centroid2);
    centroidTitle = sprintf('%s\n %s',name,'log(total distance) of centroids');
    title(centroidTitle);
    
    axes(handles.Quiver);
    quiverTitle = sprintf('%s\n %s',name,' Net movement of mitochondria by sector');
    title(quiverTitle);
    
    %plots histogram, the number 40 is arbitrary
    handles.data.bins_temp = 40;
    handles.data.bins = 40;
    handles.data.bins2 = 40;
    plot_histogram(handles,1);
    plot_histogram(handles,0);
    set(handles.bins_temp, 'String', handles.data.bins_temp);
    
    %Calculates the quartiles
    quarts = quantile(log(netDist(netDist>0)),[0 .25 .5 .75 1]);
    handles.data.min = quarts(1);
    handles.data.q1 = quarts(2);
    handles.data.q2 = quarts(3);
    handles.data.q3 = quarts(4);
    handles.data.max = quarts(5);
    handles.data.avg = mean(log(netDist(netDist>0)));
    
    quarts = quantile(log(totDist),[0 .25 .5 .75 1]);
    handles.data.min2 = quarts(1);
    handles.data.q12 = quarts(2);
    handles.data.q22 = quarts(3);
    handles.data.q32 = quarts(4);
    handles.data.max2 = quarts(5);
    handles.data.avg2 = mean(log(totDist));
    
    %Displays their values
    set(handles.minimum, 'String', strcat('Min: ',num2str(handles.data.min)));
    set(handles.quart1, 'String', strcat('Q1: ',num2str(handles.data.q1)));
    set(handles.quart2, 'String', strcat('Q2: ',num2str(handles.data.q2)));
    set(handles.quart3, 'String', strcat('Q3: ',num2str(handles.data.q3)));
    set(handles.maximum, 'String', strcat('Max: ',num2str(handles.data.max)));
    set(handles.meanShow, 'String', strcat('Mean: ',num2str(handles.data.avg)));
    
    set(handles.minimum2, 'String', strcat('Min: ',num2str(handles.data.min2)));
    set(handles.quart12, 'String', strcat('Q1: ',num2str(handles.data.q12)));
    set(handles.quart22, 'String', strcat('Q2: ',num2str(handles.data.q22)));
    set(handles.quart32, 'String', strcat('Q3: ',num2str(handles.data.q32)));
    set(handles.maximum2, 'String', strcat('Max: ',num2str(handles.data.max2)));
    set(handles.meanShow2, 'String', strcat('Mean: ',num2str(handles.data.avg2)));
    
    set(handles.meanShow, 'Value', 0);
    set(handles.meanShow2, 'Value', 0);
    set(handles.quartDisplay, 'Value', 0);
    set(handles.quartDisplay2, 'Value', 0);
    
    %display centroid graphs
    set(handles.netGraph, 'SelectedObject', handles.netCentroid);
    set(handles.totGraph, 'SelectedObject', handles.totCentroid);
    set(handles.Histogram,'Visible','off');
    set(get(handles.Histogram,'Children'),'Visible','off');
    set(handles.Histogram2,'Visible','off');
    set(get(handles.Histogram2,'Children'),'Visible','off');
    
    
    plot_rose(handles);
    
    
    
    
    strNetDistance = strcat(saveName,'NetDistance');
    eval(sprintf('%s=netDist;',strNetDistance));
    
    strTotDistance = strcat(saveName,'TotDistance');
    eval(sprintf('%s=totDist;',strTotDistance));
    
    
    strNetAngle = strcat(saveName,'NetAngle');
    eval(sprintf('%s=netAngle;',strNetAngle));
    
    %saves the parameters used in the evaluation
    structName = strcat(saveName,'Parameters');
    eval(sprintf('%s.numPics=numPics;',structName));
    eval(sprintf('%s.incr=incr;',structName));
    eval(sprintf('%s.period=1/freq;',structName));
    eval(sprintf('%s.ratio=ratio;',structName));
    eval(sprintf('%s.areaThresh=areaThresh;',structName));
    eval(sprintf('%s.lifetime=lifetime;',structName));
    eval(sprintf('%s.stackLoc=fullfile(file_path,name);',structName));
    %Saves the variables into a .mat file
    file = strcat(fullSaveName,'Data');
    save(file,sprintf('%s',strNetDistance),sprintf('%s',strTotDistance),sprintf('%s',strNetAngle),sprintf('%s',structName));
end
%clears busy status
set(handles.busyStatus, 'String', '');
guidata(hObject,handles)

%% Internal Functions
function initialize_gui(fig_handle, handles, isreset)
% If the data field is present and the reset flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to reset the data.
if isfield(handles, 'data') && ~isreset
    return;
end
%Sets all data fields to initial values
handles.data.name = 'Enter stack name';
handles.data.saveName = ''; %custom save name of data
handles.data.loPics  = 0;
handles.data.hiPics  = 100;
handles.data.freq  = 1;
handles.data.ratio  = 1;
handles.data.loLimit  = 0;
handles.data.hiLimit  = 0;
handles.data.browsePath = '';
handles.data.browseSavePath = ''; %Refers to save directory path
handles.data.current = 1;
handles.data.currentSave = 1; %Whether or not the current directory is selected
handles.data.currentName = 1; %whether or not the save name is the same as the current name
handles.data.showCent = 1;
handles.data.showCent2 = 1;
handles.data.bins = 1;
handles.data.bins2 = 1;
handles.data.bins_temp = 1;
handles.data.loArea = 0.9;
handles.data.hiArea = 22.5;
handles.data.lifetime = 9;
handles.data.columns = 4;
handles.data.rows = 4;
handles.data.netDist = [];
handles.data.totDist = [];
handles.data.netAngle = [];
handles.data.min = 0;
handles.data.q1 = 0;
handles.data.q2 = 0;
handles.data.q3 = 0;
handles.data.max = 0;
handles.data.avg = 0; %the max distance traveled
handles.data.min2 = 0;
handles.data.q12 = 0;
handles.data.q22 = 0;
handles.data.q32 = 0;
handles.data.max2 = 0;
handles.data.avg2 = 0; %the max distance traveled

%Sets all the textboxes to reflect values
set(handles.name, 'String', handles.data.name);
set(handles.saveName, 'String', handles.data.saveName);
set(handles.loPics, 'String', handles.data.loPics);
set(handles.hiPics, 'String', handles.data.hiPics);
set(handles.period, 'String', 1/handles.data.freq);
set(handles.ratio, 'String', handles.data.ratio);
set(handles.loLimit, 'String', handles.data.loLimit);
set(handles.hiLimit, 'String', handles.data.hiLimit);
set(handles.browsePath, 'String', handles.data.browsePath);
set(handles.browseSavePath, 'String', handles.data.browseSavePath);
set(handles.bins_temp, 'String', handles.data.bins);
set(handles.loArea, 'String', handles.data.loArea);
set(handles.hiArea, 'String', handles.data.hiArea);
set(handles.lifetime, 'String', handles.data.lifetime);
set(handles.columns, 'String', handles.data.columns);
set(handles.rows, 'String', handles.data.rows);
set(handles.minimum, 'String', strcat('Min: ',num2str(handles.data.min)));
set(handles.quart1, 'String', strcat('Q1: ',num2str(handles.data.q1)));
set(handles.quart2, 'String', strcat('Q2: ',num2str(handles.data.q2)));
set(handles.quart3, 'String', strcat('Q3: ',num2str(handles.data.q3)));
set(handles.maximum, 'String', strcat('Max: ',num2str(handles.data.max)));
set(handles.meanShow, 'String', strcat('Mean: ',num2str(handles.data.avg)));
set(handles.minimum2, 'String', strcat('Min: ',num2str(handles.data.min2)));
set(handles.quart12, 'String', strcat('Q1: ',num2str(handles.data.q12)));
set(handles.quart22, 'String', strcat('Q2: ',num2str(handles.data.q22)));
set(handles.quart32, 'String', strcat('Q3: ',num2str(handles.data.q32)));
set(handles.maximum2, 'String', strcat('Max: ',num2str(handles.data.max2)));
set(handles.meanShow2, 'String', strcat('Mean: ',num2str(handles.data.avg2)));
set(handles.busyStatus, 'String', '');

%Sets the selection and checkbox to initial value
set(handles.dirSelect, 'SelectedObject', handles.currentDir);
set(handles.netGraph, 'SelectedObject', handles.netCentroid);
set(handles.totGraph, 'SelectedObject', handles.totCentroid);
set(handles.saveDirSelect, 'SelectedObject', handles.currentSave);
set(handles.saveNameSelect, 'SelectedObject', handles.currentName);
set(handles.quartDisplay, 'Value', 0);
set(handles.quartDisplay2, 'Value', 0);
set(handles.meanShow, 'Value', 0);
set(handles.meanShow2, 'Value', 0);
set(handles.incrementMenu, 'Value',1);
%clears Centroid graph
axes(handles.Centroid)
cla
title('log(net distance) of centroids');
set(gca,'Color',[0 0 0],'XTickLabel',[],'YTickLabel',[]);
colorbar('location','southoutside')
colorbar off
axis([0 1392 0 1040])
daspect([1,1,1])
set(handles.Centroid,'Visible','on');

axes(handles.Centroid2)
cla
title('log(tot distance) of centroids');
set(gca,'Color',[0 0 0],'XTickLabel',[],'YTickLabel',[]);
colorbar('location','southoutside')
colorbar off
axis([0 1392 0 1040])
daspect([1,1,1])
set(handles.Centroid2,'Visible','on');

%clears Histogram graph
axes(handles.Histogram)
cla
title('Number of Mitochondria vs log(netdistance))');
ylabel('number of Mitochondria');
xlabel('log(netdistance(\mum))')
set(handles.Histogram,'Visible','off');
set(get(handles.Histogram,'Children'),'Visible','off');

axes(handles.Histogram2)
cla
title('Number of Mitochondria vs log(totdistance))');
ylabel('number of Mitochondria');
xlabel('log(totdistance(\mum))')
set(handles.Histogram2,'Visible','off');
set(get(handles.Histogram2,'Children'),'Visible','off');

%clears quiver graph
axes(handles.Quiver)
cla
title('Net motion of mitochondria by sector');
set(gca,'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);
box on
% Update handles structure

axes(handles.Rose)
rose([1 1],1);
cla
title('Net Angle Histogram');


guidata(handles.figure1, handles);

function plot_lines(handles,isNet)
if(isNet)
    graph = handles.Histogram;
    mini = handles.data.min;
    q1 = handles.data.q1;
    q2 = handles.data.q2;
    q3 = handles.data.q3;
    maxi = handles.data.max;
    
else
    graph = handles.Histogram2;
    mini = handles.data.min2;
    q1 = handles.data.q12;
    q2 = handles.data.q22;
    q3 = handles.data.q32;
    maxi = handles.data.max2;
end
%plots to histogram plot
axes(graph);
%gets the max and min of the graph
yL = get(gca, 'YLim');
%draws 5 lines at the min, quartiles and max
line([mini mini], yL, 'Color', 'k','LineWidth',1);
line([q1 q1], yL, 'Color', 'g','LineWidth',1);
line([q2 q2], yL, 'Color', 'r','LineWidth',1);
line([q3 q3], yL, 'Color', 'g','LineWidth',1);
line([maxi maxi], yL, 'Color', 'k','LineWidth',1);


function plot_average(handles,isNet)
if(isNet)
    graph = handles.Histogram;
    avg = handles.data.avg;
else
    graph = handles.Histogram2;
    avg = handles.data.avg2;
end
%plots to histogram plot
axes(graph);
%gets the max and min of the graph
yL = get(gca, 'YLim');
%draws 5 lines at the min, the quartiles and the max
line([avg avg], yL, 'Color', 'c','LineWidth',1.5);

function plot_histogram(handles,isNet)

if(isNet)
    graph = handles.Histogram;
    titled = 'Number of Mitochondria vs log(netdistance))';
    xlab = 'log(netdistance(microns))';
    data = handles.data.netDist;
    bins = handles.data.bins;
    show = handles.data.showCent;
else
    graph = handles.Histogram2;
    titled = 'Number of Mitochondria vs log(totdistance))';
    xlab = 'log(totdistance(microns))';
    data = handles.data.totDist;
    bins = handles.data.bins2;
    show = handles.data.showCent2;
end
%plots to histogram
axes(graph);
cla
%plots histogram with current number of bins
hist(log(data),bins);
name = handles.data.name;
histogramTitle = sprintf('%s\n %s',name,titled);
title(histogramTitle);
ylabel('number of Mitocondria');
xlabel(xlab);
if(show)
    set(graph,'Visible','off');
    set(get(graph,'Children'),'Visible','off');
end

function plot_rose(handles)
%plots to histogram
axes(handles.Rose);
cla
%plots histogram with current number of bins
rose(degtorad(handles.data.netAngle),30);
name = handles.data.name;
histogramTitle = sprintf('%s\n %s',name,' net angle histogram');
title(histogramTitle);


%% Buttons/Selections/Checkboxes
%   Most of the comments in this section are the preexisting ones from
%   using the guide command
function clear_Callback(hObject, eventdata, handles)
% hObject    handle to clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%just resets the entire gui
initialize_gui(gcbf, handles, true);

% --- Executes when selected object is changed in dirSelect.
function dirSelect_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in dirSelect
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
% --- Executes when selected object changed in dirSelect.

%if the current directory option is selected, store that info
if (hObject == handles.currentDir)
    handles.data.current = 1;
else
    handles.data.current = 0;
end
guidata(hObject,handles)

% --- Executes on button press in browse.
function browse_Callback(hObject, eventdata, handles)
% hObject    handle to browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%browsePath will store the string of the folder selected
browsePath = uigetdir;
%if the browser window is cancelled, browsePath = 0
if(browsePath == 0)
    %if nothing is selected then see if there already exists a path, if not
    %then assume current directory is wanted
    if (isempty(handles.data.browsePath))
        set(handles.dirSelect, 'SelectedObject', handles.currentDir);
        handles.data.current = 1;
    end
    %if there is something, then just leave everything as is
else
    %if a path is selected, save the path and set directory to that path.
    handles.data.browsePath = browsePath;
    set(handles.dirSelect, 'SelectedObject', handles.otherDir);
    handles.data.current = 0;
end
set(handles.browsePath, 'String', handles.data.browsePath);
guidata(hObject,handles)

% --- Executes on button press in browseSave.
function browseSave_Callback(hObject, eventdata, handles)
% hObject    handle to browseSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%browseSavePath will store the string of the folder selected
browseSavePath = uigetdir;
%if the browser window is cancelled, browseavePath = 0
if(browseSavePath == 0)
    %if nothing is selected then see if there already exists a path, if not
    %then assume current directory is wanted
    if (isempty(handles.data.browseSavePath))
        set(handles.saveDirSelect, 'SelectedObject', handles.currentSave);
        handles.data.currentSave = 1;
    end
    %if there is something, then just leave everything as is
else
    %if a path is selected, save the path and set directory to that path.
    handles.data.browseSavePath = browseSavePath;
    set(handles.saveDirSelect, 'SelectedObject', handles.otherSave);
    handles.data.currentSave = 0;
end
set(handles.browseSavePath, 'String', handles.data.browseSavePath);
guidata(hObject,handles)

% --- Executes on button press in saveCent.
function saveCent_Callback(hObject, eventdata, handles)
% hObject    handle to saveCent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(handles.data.currentName)
    saveName = handles.data.name;
else
    saveName = handles.data.saveName;
end
if(~handles.data.currentSave)
    if(~exist(handles.data.browseSavePath,'dir'))
        errordlg('Save destination folder does not exist','Error');
        return
    end
    savePath = strcat(handles.data.browseSavePath,'\');
    saveName = strcat(savePath,saveName);
end


lim = get(handles.Centroid,'CLim');
axes(handles.Centroid);
set(gca,'Visible','on');
set(get(gca,'Children'),'Visible','on');
if(~handles.data.showCent)
    colorbar('location','southoutside')
end
%create a new figure
data = figure;
%set background to white
set(gcf,'color','w');
%copy the centroid plot to the new figure
a = copyobj(handles.Centroid,data);
%set the axes nicely in the fiture
set(a,'Units','normalized');
set(a,'Position',[.13 .30 .7 .7]);
%replot the color bar
colorbar('location','southoutside')
%make the name for the save file, of the form:
%'stackname'Centroid 'lowerbound' 'upperbound'.tiff
name = strcat(saveName,'NetDistCentroid');
name = sprintf('%s lower%1.1f upper%1.1f',name,lim(1),lim(2));
name = strrep(name, '.','_');
%save the figure.
set(gcf, 'InvertHardCopy', 'off');
print (data,name, '-dtiff');
if(~handles.data.showCent)
    axes(handles.Centroid);
    set(gca,'Visible','off');
    set(get(gca,'Children'),'Visible','off');
    colorbar off;
end

% --- Executes on button press in saveHist.
function saveHist_Callback(hObject, eventdata, handles)
% hObject    handle to saveHist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(handles.data.currentName)
    saveName = handles.data.name;
else
    saveName = handles.data.saveName;
end
if(~handles.data.currentSave)
    if(~exist(handles.data.browseSavePath,'dir'))
        errordlg('Save destination folder does not exist','Error');
        return
    end
    savePath = strcat(handles.data.browseSavePath,'\');
    saveName = strcat(savePath,saveName);
end

set(handles.Histogram,'Visible','on');
set(get(handles.Histogram,'Children'),'Visible','on');
%Create a new figure
data = figure;
%set the background of the figure to white
set(gcf,'color','w');
%copy the histogram plot to the figure
a = copyobj(handles.Histogram,data);
set(a,'Units','normalized');
%set the axes into the figure in a good place
set(a,'Position',[.1 .1 .8 .8 ]);
%create the name for the save file.
%of the form: 'stackname'Histogram '# of bins'.tif
name = strcat(saveName,'NetDistHistogram');
name = sprintf('%s %d bins',name,handles.data.bins);
set(gcf, 'InvertHardCopy', 'off');
%save file
print (data,name, '-dtiff');
if(handles.data.showCent)
    set(handles.Histogram,'Visible','off');
    set(get(handles.Histogram,'Children'),'Visible','off');
end
% --- Executes on button press in saveCent.
function saveCent2_Callback(hObject, eventdata, handles)
% hObject    handle to saveCent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(handles.data.currentName)
    saveName = handles.data.name;
else
    saveName = handles.data.saveName;
end
if(~handles.data.currentSave)
    if(~exist(handles.data.browseSavePath,'dir'))
        errordlg('Save destination folder does not exist','Error');
        return
    end
    savePath = strcat(handles.data.browseSavePath,'\');
    saveName = strcat(savePath,saveName);
end

lim = get(handles.Centroid2,'CLim');
axes(handles.Centroid2);
set(gca,'Visible','on');
set(get(gca,'Children'),'Visible','on');
if(~handles.data.showCent2)
    colorbar('location','southoutside')
end
%create a new figure
data = figure;
%set background to white
set(gcf,'color','w');
%copy the centroid plot to the new figure
a = copyobj(handles.Centroid2,data);
%set the axes nicely in the fiture
set(a,'Units','normalized');
set(a,'Position',[.13 .30 .7 .7 ]);
%replot the color bar
colorbar('location','southoutside')
%make the name for the save file, of the form:
%'stackname'Centroid 'lowerbound' 'upperbound'.tiff
name = strcat(saveName,'TotDistCentroid');
name = sprintf('%s lower%1.1f upper%1.1f',name,lim(1),lim(2));
name = strrep(name, '.','_');
%save the figure.
set(gcf, 'InvertHardCopy', 'off');
print (data,name, '-dtiff');
if(~handles.data.showCent2)
    axes(handles.Centroid2);
    set(gca,'Visible','off');
    set(get(gca,'Children'),'Visible','off');
    colorbar off;
end

% --- Executes on button press in saveHist.
function saveHist2_Callback(hObject, eventdata, handles)
% hObject    handle to saveHist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(handles.data.currentName)
    saveName = handles.data.name;
else
    saveName = handles.data.saveName;
end
if(~handles.data.currentSave)
    if(~exist(handles.data.browseSavePath,'dir'))
        errordlg('Save destination folder does not exist','Error');
        return
    end
    savePath = strcat(handles.data.browseSavePath,'\');
    saveName = strcat(savePath,saveName);
end

set(handles.Histogram2,'Visible','on');
set(get(handles.Histogram2,'Children'),'Visible','on');
%Create a new figure
data = figure;
%set the background of the figure to white
set(gcf,'color','w');
%copy the histogram plot to the figure
a = copyobj(handles.Histogram2,data);
set(a,'Units','normalized');
%set the axes into the figure in a good place
set(a,'Position',[.1 .1 .8 .8 ]);
%create the name for the save file.
%of the form: 'stackname'Histogram '# of bins'.tif
name = strcat(saveName,'totDistHistogram');
name = sprintf('%s %d bins',name,handles.data.bins2);
set(gcf, 'InvertHardCopy', 'off');
%save file
print (data,name, '-dtiff');
if(handles.data.showCent2)
    set(handles.Histogram2,'Visible','off');
    set(get(handles.Histogram2,'Children'),'Visible','off');
end
% --- Executes on button press in updateCentroid.

% --- Executes on button press in saveQuiver.
function saveQuiver_Callback(hObject, eventdata, handles)
% hObject    handle to saveQuiver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Create a new figure
data = figure;
%set the background of the figure to white
set(gcf,'color','w');
%copy the histogram plot to the figure
a = copyobj(handles.Quiver,data);
set(a,'Units','normalized');
%set the axes into the figure in a good place
set(a,'Position',[.1 .1 .8 .8 ]);
%create the name for the save file.
%of the form: 'stackname'netMovement '# of bins'.tif
name = strcat(handles.data.name,'netMovement');
name = sprintf('%s %d rows %d columns',name,handles.data.rows,handles.data.columns);
set(gcf, 'InvertHardCopy', 'off');
%save file
print (data,name, '-dtiff');

% --- Executes on button press in saveRose.
function saveRose_Callback(hObject, eventdata, handles)
% hObject    handle to saveRose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Create a new figure
data = figure;
%set the background of the figure to white
set(gcf,'color','w');
%copy the histogram plot to the figure
a = copyobj(handles.Rose,data);
set(a,'Units','normalized');
%set the axes into the figure in a good place
set(a,'Position',[.1 .1 .8 .8 ]);
%create the name for the save file.
%of the form: 'stackname'Histogram '# of bins'.tif
name = strcat(handles.data.name,'netAngleHistogram');
set(gcf, 'InvertHardCopy', 'off');
%save file
print (data,name, '-dtiff');

function updateCentroid_Callback(hObject, eventdata, handles)
% hObject    handle to updateCentroid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(~isfinite(handles.data.loLimit)||~isfinite(handles.data.hiLimit))
   errordlg('Limits must be numeric','Input Error');
   return
end
if (handles.data.loLimit >= handles.data.hiLimit)
    %ensures the lower limit is strictly lower than the upper limit
    errordlg('lower limit must be strictly lower than upper limit','Error');
    return
end
%changes the colorbar limits of the centroid plot
set(handles.Centroid,'CLim',[handles.data.loLimit handles.data.hiLimit]);

% --- Executes on button press in updateHistogram.
function updateHistogram_Callback(hObject, eventdata, handles)
% hObject    handle to updateHistogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfinite(handles.data.bins_temp)||(handles.data.bins_temp < 1)
    %ensures that there is a positive number of bins
    errordlg('Must be a positive number of bins','Error');
    return
end
handles.data.bins = handles.data.bins_temp;
%plots the histogram
plot_histogram(handles,1);
%checks if the quartiles were displayed, if so re plot
if(get(handles.quartDisplay,'Value'))
    plot_lines(handles,1);
end
if(get(handles.meanShow,'Value'))
    plot_average(handles,1);
end
guidata(hObject,handles)


% --- Executes on button press in updateHistogram2.
function updateHistogram2_Callback(hObject, eventdata, handles)
% hObject    handle to updateHistogram2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfinite(handles.data.bins_temp)||(handles.data.bins_temp < 1)
    %ensures that there is a positive number of bins_temp
    errordlg('Must be a positive number of bins','Error');
    return
end
if (handles.data.bins_temp < 1)
    %ensures that there is a positive number of bins_temp
    errordlg('Must be a positive number of bins','Error');
    return
end
%plots the histogram
handles.data.bins2 = handles.data.bins_temp;
plot_histogram(handles,0);
%checks if the quartiles were displayed, if so re plot
if(get(handles.quartDisplay,'Value'))
    plot_lines(handles,0);
end
if(get(handles.meanShow,'Value'))
    plot_average(handles,0);
end
guidata(hObject,handles)

% --- Executes on button press in updateCentroid2.
function updateCentroid2_Callback(hObject, eventdata, handles)
% hObject    handle to updateCentroid2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(~isfinite(handles.data.loLimit)||~isfinite(handles.data.hiLimit))
   errordlg('Limits must be numeric','Input Error');
   return
end
if (handles.data.loLimit >= handles.data.hiLimit)
    %ensures the lower limit is strictly lower than the upper limit
    errordlg('lower limit must be strictly lower than upper limit','Error');
    return
end
%changes the colorbar limits of the centroid plot
set(handles.Centroid2,'CLim',[handles.data.loLimit handles.data.hiLimit]);

% --- Executes on button press in quartDisplay.
function quartDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to quartDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%if the show option is selected for the quartiles then plot the lines

if (get(hObject,'Value') == get(hObject,'Max'))
    plot_lines(handles,1);
else
    %else replot the histogram (cla is inherent in plot_histogram)
    plot_histogram(handles,1);
    if (get(handles.meanShow,'Value'))
        plot_average(handles,1);
    end
end
if(handles.data.showCent)
    set(handles.Histogram,'Visible','off');
    set(get(handles.Histogram,'Children'),'Visible','off');
end
% Hint: get(hObject,'Value') returns toggle state of quartDisplay

% --- Executes on button press in quartDisplay2.
function quartDisplay2_Callback(hObject, eventdata, handles)
% hObject    handle to quartDisplay2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%if the show option is selected for the quartiles then plot the lines
if (get(hObject,'Value') == get(hObject,'Max'))
    plot_lines(handles,0);
else
    %else replot the histogram (cla is inherent in plot_histogram)
    plot_histogram(handles,0);
    if (get(handles.meanShow2,'Value'))
        plot_average(handles,0);
    end
end
if(handles.data.showCent2)
    set(handles.Histogram2,'Visible','off');
    set(get(handles.Histogram2,'Children'),'Visible','off');
end
% Hint: get(hObject,'Value') returns toggle state of quartDisplay2

% --- Executes on selection change in incrementMenu.
function incrementMenu_Callback(hObject, eventdata, handles)
% hObject    handle to incrementMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns incrementMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from incrementMenu


% --- Executes during object creation, after setting all properties.
function incrementMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to incrementMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

%Sets the menu options to 1-5, value will also be 1-5
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String', {'Every 1', 'Every 2nd', 'Every 3rd', 'Every 4th', 'Every 5th'});


% --- Executes when selected object is changed in saveDirSelect.
function saveDirSelect_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in saveDirSelect
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

%if the current directory option is selected, store that info
if (hObject == handles.currentSave)
    handles.data.currentSave = 1;
else
    handles.data.currentSave = 0;
end
guidata(hObject,handles)

% --- Executes when selected object is changed in saveNameSelect.
function saveNameSelect_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in saveNameSelect
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

%if the current directory option is selected, store that info
if (hObject == handles.currentName)
    handles.data.currentName = 1;
else
    handles.data.currentName = 0;
end
guidata(hObject,handles)


% --- Executes on button press in meanShow2.
function meanShow2_Callback(hObject, eventdata, handles)
% hObject    handle to meanShow2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(hObject,'Value') == get(hObject,'Max'))
    plot_average(handles,0);
else
    %else replot the histogram (cla is inherent in plot_histogram)
    plot_histogram(handles,0);
    if (get(handles.quartDisplay2,'Value'))
        plot_lines(handles,0);
    end
end
if(handles.data.showCent2)
    set(handles.Histogram2,'Visible','off');
    set(get(handles.Histogram2,'Children'),'Visible','off');
end
% Hint: get(hObject,'Value') returns toggle state of meanShow2


% --- Executes on button press in meanShow.
function meanShow_Callback(hObject, eventdata, handles)
% hObject    handle to meanShow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(hObject,'Value') == get(hObject,'Max'))
    plot_average(handles,1);
else
    %else replot the histogram (cla is inherent in plot_histogram)
    plot_histogram(handles,1);
    if (get(handles.quartDisplay,'Value'))
        plot_lines(handles,1);
    end
end
if(handles.data.showCent)
    set(handles.Histogram,'Visible','off');
    set(get(handles.Histogram,'Children'),'Visible','off');
end
% Hint: get(hObject,'Value') returns toggle state of meanShow



% --- Executes when selected object is changed in netGraph.
function netGraph_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in netGraph
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
if (hObject == handles.netCentroid)
    axes(handles.Centroid);
    set(gca,'Visible','on');
    set(get(gca,'Children'),'Visible','on');
    colorbar('location','southoutside')
    set(handles.Histogram,'Visible','off');
    set(get(handles.Histogram,'Children'),'Visible','off');
    handles.data.showCent = 1;
else
    axes(handles.Centroid);
    set(gca,'Visible','off');
    set(get(gca,'Children'),'Visible','off');
    colorbar off;
    set(handles.Histogram,'Visible','on');
    set(get(handles.Histogram,'Children'),'Visible','on');
    handles.data.showCent = 0;
end
guidata(hObject,handles)
% handles    structure with handles and user data (see GUIDATA)

% --- Executes when selected object is changed in totGraph.
function totGraph_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in totGraph
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if (hObject == handles.totCentroid)
    axes(handles.Centroid2);
    set(gca,'Visible','on');
    set(get(gca,'Children'),'Visible','on');
    colorbar('location','southoutside')
    set(handles.Histogram2,'Visible','off');
    set(get(handles.Histogram2,'Children'),'Visible','off');
    handles.data.showCent2 = 1;
else
    axes(handles.Centroid2);
    set(gca,'Visible','off');
    set(get(gca,'Children'),'Visible','off');
    colorbar off;
    set(handles.Histogram2,'Visible','on');
    set(get(handles.Histogram2,'Children'),'Visible','on');
    handles.data.showCent2 = 0;
end
guidata(hObject,handles)

%% Textboxes
function name_Callback(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
name = (get(hObject, 'String'));
handles.data.name = name;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function loPics_Callback(hObject, eventdata, handles)
% hObject    handle to loPics (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loPics = str2double(get(hObject, 'String'));

handles.data.loPics = loPics;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function loPics_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loPics (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function hiPics_Callback(hObject, eventdata, handles)
% hObject    handle to hiPics (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hiPics = str2double(get(hObject, 'String'));

handles.data.hiPics = hiPics;
guidata(hObject,handles)
% Hints: get(hObject,'String') returns contents of hiPics as text
%        str2double(get(hObject,'String')) returns contents of hiPics as a double


% --- Executes during object creation, after setting all properties.
function hiPics_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hiPics (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function period_Callback(hObject, eventdata, handles)
% hObject    handle to period (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
period = str2double(get(hObject, 'String'));

handles.data.freq = 1/period;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function period_CreateFcn(hObject, eventdata, handles)
% hObject    handle to period (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ratio_Callback(hObject, eventdata, handles)
% hObject    handle to ratio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ratio = str2double(get(hObject, 'String'));

handles.data.ratio = ratio;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function ratio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ratio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function loLimit_Callback(hObject, eventdata, handles)
% hObject    handle to loLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loLimit = str2double(get(hObject, 'String'));

handles.data.loLimit = loLimit;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function loLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function hiLimit_Callback(hObject, eventdata, handles)
% hObject    handle to hiLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hiLimit = str2double(get(hObject, 'String'));

handles.data.hiLimit = hiLimit;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function hiLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hiLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function browsePath_Callback(hObject, eventdata, handles)
% hObject    handle to browsePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
browsePath = (get(hObject, 'String'));
handles.data.browsePath = browsePath;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function browsePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to browsePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function bins_temp_Callback(hObject, eventdata, handles)
% hObject    handle to bins_temp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bins_temp = str2double(get(hObject, 'String'));
handles.data.bins_temp = bins_temp;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bins_temp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bins_temp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function loArea_Callback(hObject, eventdata, handles)
% hObject    handle to loArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loArea = str2double(get(hObject, 'String'));

handles.data.loArea = loArea;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function loArea_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function hiArea_Callback(hObject, eventdata, handles)
% hObject    handle to hiArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hiArea = str2double(get(hObject, 'String'));

handles.data.hiArea = hiArea;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function hiArea_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hiArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lifetime_Callback(hObject, eventdata, handles)
% hObject    handle to lifetime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
lifetime = str2double(get(hObject, 'String'));

handles.data.lifetime = lifetime;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function lifetime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lifetime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function rows_Callback(hObject, eventdata, handles)
% hObject    handle to rows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
rows = str2double(get(hObject, 'String'));

handles.data.rows = rows;
guidata(hObject,handles)
% Hints: get(hObject,'String') returns contents of rows as text
%        str2double(get(hObject,'String')) returns contents of rows as a double

% --- Executes during object creation, after setting all properties.
function rows_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function columns_Callback(hObject, eventdata, handles)
% hObject    handle to columns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
columns = str2double(get(hObject, 'String'));

handles.data.columns = columns;
guidata(hObject,handles)
% Hints: get(hObject,'String') returns contents of columns as text
%        str2double(get(hObject,'String')) returns contents of columns as a double

% --- Executes during object creation, after setting all properties.
function columns_CreateFcn(hObject, eventdata, handles)
% hObject    handle to columns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function browseSavePath_Callback(hObject, eventdata, handles)
% hObject    handle to browseSavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
browseSavePath = (get(hObject, 'String'));
handles.data.browseSavePath = browseSavePath;
if ~isempty(browseSavePath)
    set(handles.saveDirSelect, 'SelectedObject', handles.otherSave);
    handles.data.current = 0;
else
    set(handles.saveDirSelect, 'SelectedObject', handles.currentSave);
    handles.data.current = 1;
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function browseSavePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to browseSavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function saveName_Callback(hObject, eventdata, handles)
% hObject    handle to saveName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveName = (get(hObject, 'String'));
if ~isempty(saveName)
    set(handles.saveNameSelect, 'SelectedObject', handles.otherName);
    handles.data.currentName = 0;
else
    set(handles.saveNameSelect, 'SelectedObject', handles.currentName);
    handles.data.currentName = 1;
end
handles.data.saveName = saveName;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function saveName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on name and none of its controls.
function name_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    handles.data.name = get(hObject,'String');
    guidata(interface_2,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on browseSavePath and none of its controls.
function browseSavePath_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to browseSavePath (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    browseSavePath = (get(hObject, 'String'));
    handles.data.currentSave = 0;
    handles.data.browseSavePath = browseSavePath;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on saveName and none of its controls.
function saveName_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to saveName (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    saveName = (get(hObject, 'String'));
    handles.data.currentName = 0;
    handles.data.saveName = saveName;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on lifetime and none of its controls.
function lifetime_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lifetime (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    lifetime = str2double((get(hObject, 'String')));
    handles.data.lifetime = lifetime;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on loArea and none of its controls.
function loArea_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to loArea (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    loArea = str2double((get(hObject, 'String')));
    handles.data.loArea = loArea;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on hiArea and none of its controls.
function hiArea_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to hiArea (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    hiArea = str2double((get(hObject, 'String')));
    handles.data.hiArea = hiArea;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on ratio and none of its controls.
function ratio_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ratio (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    ratio = str2double((get(hObject, 'String')));
    handles.data.ratio = ratio;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on period and none of its controls.
function period_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to period (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    period = str2double((get(hObject, 'String')));
    handles.data.freq = 1/period;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on incrementMenu and none of its controls.
function incrementMenu_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to incrementMenu (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on loPics and none of its controls.
function loPics_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to loPics (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    loPics = str2double((get(hObject, 'String')));
    handles.data.loPics = loPics;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on hiPics and none of its controls.
function hiPics_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to hiPics (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    hiPics = str2double((get(hObject, 'String')));
    handles.data.hiPics = hiPics;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on browsePath and none of its controls.
function browsePath_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to browsePath (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    browsePath = (get(hObject, 'String'));
    handles.data.current = 0;
    handles.data.browsePath = browsePath;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on browse and none of its controls.
function browse_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to browse (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    browse_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on browseSave and none of its controls.
function browseSave_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to browseSave (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    browseSave_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on calculate and none of its controls.
function calculate_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to calculate (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    calculate_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on clear and none of its controls.
function clear_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to clear (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    clear_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on saveCent and none of its controls.
function saveCent_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to saveCent (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    saveCent_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on saveHist and none of its controls.
function saveHist_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to saveHist (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    saveHist_Callback(hObject,eventdata,handles)
end

% --- Executes on key press with focus on updateCentroid and none of its controls.
function updateCentroid_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to updateCentroid (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    updateCentroid_Callback(hObject,eventdata,handles)
end

% --- Executes on key press with focus on updateHistogram and none of its controls.
function updateHistogram_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to updateHistogram (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    updateHistogram_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on columns and none of its controls.
function columns_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to columns (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    columns = str2double((get(hObject, 'String')));
    handles.data.columns = columns;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on rows and none of its controls.
function rows_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to rows (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    figure(interface_2)
    rows = str2double((get(hObject, 'String')));
    handles.data.rows = rows;
    guidata(hObject,handles)
    calculate_Callback(handles.calculate,eventdata,handles);
end


% --- Executes on key press with focus on saveCent2 and none of its controls.
function saveCent2_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to saveCent2 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    saveCent2_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on saveHist2 and none of its controls.
function saveHist2_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to saveHist2 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    saveHist2_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on saveQuiver and none of its controls.
function saveQuiver_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to saveQuiver (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    saveQuiver_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on saveRose and none of its controls.
function saveRose_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to saveRose (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    saveRose_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on bins_temp and none of its controls.
function bins_temp_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to bins_temp (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on loLimit and none of its controls.
function loLimit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to loLimit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on hiLimit and none of its controls.
function hiLimit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to hiLimit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on updateCentroid2 and none of its controls.
function updateCentroid2_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to updateCentroid2 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    updateCentroid2_Callback(hObject,eventdata,handles)
end


% --- Executes on key press with focus on updateHistogram2 and none of its controls.
function updateHistogram2_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to updateHistogram2 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(eventdata.Key,'return'))
    updateHistogram2_Callback(hObject,eventdata,handles)
end
