%Graphical User interface_d code for the mitochondria function.
%Authors: Philip Chou.
%The foundation of this gui was using the guide code built into Matlab. The
%structure of how this gui tracks data is that there is a 'data' field in
%the structure 'handles'. Inside the 'data' field, there are the different
%fields such as 'name', 'loPics', 'freq', etc. These will be updated as
%the values in the textboxes are adjusted. To calculate the movement of
%the mitochondria, click the calculate button and it will call the
%'mitochondria' function. To clear all current data, click the clear
%button.
%The graphical interface_d will save the net distances traveled and the evaluation parameters
%to the currentdirectory.
%NOTE: It will save the ORIGINAL net distance traveled, on the other
%hand both the centroid plot and the histogram plot the LOG(net distance)
%traveled. (natural log)

%% Default functions created through the guide code
%essential to start the GUI, do not edit unless you are familiar with guide
function varargout = interface_d(varargin)
% INTERFACE_D MATLAB code for interface_d.fig
%      INTERFACE_D, by itself, creates a new INTERFACE_D or raises the existing
%      singleton*.
%
%      H = INTERFACE_D returns the handle to a new INTERFACE_D or the handle to
%      the existing singleton*.
%
%      INTERFACE_D('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INTERFACE_D.M with the given input arguments.
%
%      INTERFACE_D('Property','Value',...) creates a new INTERFACE_D or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before interface_d_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to interface_d_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help interface_d

% Last Modified by GUIDE v2.5 04-Jun-2014 09:42:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @interface_d_OpeningFcn, ...
    'gui_OutputFcn',  @interface_d_OutputFcn, ...
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
% --- Executes just before interface_d is made visible.
function interface_d_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to interface_d (see VARARGIN)

% Choose default command line output for interface_d
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
initialize_gui(hObject, handles, false);

% UIWAIT makes interface_d wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = interface_d_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%% Main 'Calculate' Button, calls mitochondria tracking function
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
%if the current directory is not selected, will set the full name of the
%file to include the path to the directory
if (handles.data.current)
    fullName = name;
else
    %ensures there is at least one \ at the end of brwose path
    if(~exist(handles.data.browsePath,'dir'))
        errordlg('Stack Location folder does not exist','File Error');
        set(handles.busyStatus, 'String', '');
        return
    end
    if ~strcmp((handles.data.browsePath(end)),'\')
        file_path = strcat(handles.data.browsePath,'\');
    else
        file_path = handles.data.browsePath;
    end
    fullName = strcat(file_path,name);
    %'\' is an escape character so therefore must use '\\' for the imread
    %function in the mitochondria function to work
    fullName = strrep(fullName, '\','\\');
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
   while ~isempty(saveName)&&(strcmp(saveName(1),'_'))
       saveName(1)=[];
   end
else
    if(isempty(handles.data.saveName))
        errordlg('No save name written','Save Name Error');
        set(handles.busyStatus, 'String', '');
        return
    end
    saveName = handles.data.saveName;
end

%Ensures that the save path exists.
if (handles.data.currentSave)
    fullSaveName = saveName;
else
    if(isempty(handles.data.browseSavePath))
        errordlg('No save path selected','Save Path Error');
        set(handles.busyStatus, 'String', '');
        return
    end
    if(~exist(handles.data.browseSavePath,'dir'))
        errordlg('Save destination folder does not exist','Save Path Error');
        set(handles.busyStatus, 'String', '');
        return
    end
    file_path = strcat(handles.data.browseSavePath,'\');
    fullSaveName = strcat(file_path,saveName);
end
%checks if all needed images exist
inc = numPics(1):incr:numPics(2);
for i = (inc)
    suspect = strcat(fullName,sprintf('%04d.tif',i));
    if (~exist(suspect,'file'))
        file_path = strcat(file_path,name);
        errordlg(strcat('Does Not Exist: ',strcat(file_path,sprintf('%04d.tif',i))),'File Error');
        set(handles.busyStatus, 'String', '');
        return
    end
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
elseif (ratio<=0)
    %ensures the ratio of micron to pixel is positive
    errordlg('Ratio must be positive','Input Error');
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
elseif (floor((numPics(2)-numPics(1))/incr) < lifetime*freq/incr)
    %ensures that enough frames will be evaulated to exceed the min
    %lifetime
    errordlg('Minimum lifetime too high or number of Pics too low','Input Error');
else
    %if all things are good, start to calculate
    
    %clear the plot
    axes(handles.Centroid);
    cla;
    colorbar off
    cla(handles.Histogram);
    %calculate the net distances and plot the centroid movement scatter
    %plot
    try
        [netDist] = mitochondria_d(fullName,numPics,incr,freq,ratio,...
            areaThresh,lifetime,handles.Centroid);
    catch err
        wh=findall(0,'tag','TMWWaitbar');
        delete(wh);
        errordlg(err.message);
        set(handles.busyStatus, 'String', '');
        return
    end
    %remove the NaNs
    netDist = netDist(isfinite(netDist));
    %saves distance data
    handles.data.netDist = netDist;
    %Title of graph
    centroidTitle = strcat(name,': log(net distance) of centroids');
    title(centroidTitle);
    %shows the limits of the centroid movement
    limits = get(gca,'Clim');
    handles.data.loLimit = limits(1);
    handles.data.hiLimit = limits(2);
    set(handles.loLimit, 'String', handles.data.loLimit);
    set(handles.hiLimit, 'String', handles.data.hiLimit);
    
    %plots histogram, the number 40 is arbitrary
    handles.data.bins = 40;
    plot_histogram(handles);
    set(handles.bins, 'String', handles.data.bins);
    
    %Calculates the quartiles
    quarts = quantile(log(netDist),[0 .25 .5 .75 1]);
    handles.data.min = quarts(1);
    handles.data.q1 = quarts(2);
    handles.data.q2 = quarts(3);
    handles.data.q3 = quarts(4);
    handles.data.max = quarts(5);
    handles.data.avg = mean(log(netDist));
    %plots them
    set(handles.quartDisplay, 'Value', 1);
    plot_lines(handles);
    set(handles.meanShow, 'Value', 0);
    %Displays their values
    set(handles.minimum, 'String', strcat('Min: ',num2str(handles.data.min)));
    set(handles.quart1, 'String', strcat('Q1: ',num2str(handles.data.q1)));
    set(handles.quart2, 'String', strcat('Q2: ',num2str(handles.data.q2)));
    set(handles.quart3, 'String', strcat('Q3: ',num2str(handles.data.q3)));
    set(handles.maximum, 'String', strcat('Max: ',num2str(handles.data.max)));
    set(handles.meanShow, 'String', strcat('Mean: ',num2str(handles.data.avg)));
    %Saves data from function workspace to current directory
    %Not log, just the original distance
    str = strcat(saveName,'Distance');
    eval(sprintf('%s=netDist;',str));
    %saves the parameters used in the evaluation
    structName = strcat(saveName,'Parameters');
    eval(sprintf('%s.numPics=numPics;',structName));
    eval(sprintf('%s.incr=incr;',structName));
    eval(sprintf('%s.period=1/freq;',structName));
    eval(sprintf('%s.ratio=ratio;',structName));
    eval(sprintf('%s.areaThresh=areaThresh;',structName));
    eval(sprintf('%s.lifetime=lifetime;',structName));
    %Saves the variables into a .mat file
    file = strcat(fullSaveName,'Data');
    save(file,sprintf('%s',str),sprintf('%s',structName));
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
handles.data.name = ''; %name of stack
handles.data.saveName = ''; %custom save name of data
handles.data.loPics  = 0; %the first picture number
handles.data.hiPics  = 100; %the last picture number
handles.data.freq  = 1; %Frequency of pics in hz
handles.data.ratio  = 1; %ratio of microns to pixel length
handles.data.loLimit  = 0; %Refers to Centroid plot lower limit
handles.data.hiLimit  = 0; %Refers to Centroid plot upper limit
handles.data.browsePath = ''; %Refers to directory path
handles.data.browseSavePath = ''; %Refers to save directory path
handles.data.current = 1; %Whether or not the current directory is selected
handles.data.currentSave = 1; %Whether or not the current directory is selected
handles.data.currentName = 1; %whether or not the save name is the same as the current name
handles.data.bins = 1; %the number of bins that the histogram has
handles.data.loArea = 0.9; %Refers to the lower bound of area for considering objects
handles.data.hiArea = 22.5; %Refers to the upper bound of area for considering objects
handles.data.lifetime = 9; %The minimum lifetime required to consider objects
handles.data.netDist = []; %The netdistance traveled by the objects
handles.data.min = 0; %The minimum distance traveled
handles.data.q1 = 0; %The first quartile
handles.data.q2 = 0; %the second quartile
handles.data.q3 = 0; %the third quartle
handles.data.max = 0; %the max distance traveled
handles.data.avg = 0; %the max distance traveled

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
set(handles.bins, 'String', handles.data.bins);
set(handles.loArea, 'String', handles.data.loArea);
set(handles.hiArea, 'String', handles.data.hiArea);
set(handles.lifetime, 'String', handles.data.lifetime);
set(handles.minimum, 'String', strcat('Min: ',num2str(handles.data.min)));
set(handles.quart1, 'String', strcat('Q1: ',num2str(handles.data.q1)));
set(handles.quart2, 'String', strcat('Q2: ',num2str(handles.data.q2)));
set(handles.quart3, 'String', strcat('Q3: ',num2str(handles.data.q3)));
set(handles.maximum, 'String', strcat('Max: ',num2str(handles.data.max)));
set(handles.meanShow, 'String', strcat('Mean: ',num2str(handles.data.avg)));
set(handles.busyStatus, 'String', '');

%Sets the selections and checkboxes to initial value
set(handles.dirSelect, 'SelectedObject', handles.currentDir);
set(handles.saveDirSelect, 'SelectedObject', handles.currentSave);
set(handles.saveNameSelect, 'SelectedObject', handles.currentName);
set(handles.quartDisplay, 'Value', 0);
set(handles.meanShow, 'Value', 0);
set(handles.incrementMenu, 'Value',1);

%clears Centroid graph
axes(handles.Centroid)
cla
title('log(net distance) of centroids');
set(gca,'Color',[0 0 0],'XTickLabel',[],'YTickLabel',[]);
colorbar off
axis([0 1392 0 1040])
daspect([1,1,1])

%clears Histogram graph
axes(handles.Histogram)
cla
title('Number of Mitochondria vs log(netdistance))');
ylabel('number of Mitochondria');
xlabel('log(netdistance(\mum))')
box on

% Update handles structure
guidata(handles.figure1, handles);

function plot_lines(handles)
%plots to histogram plot
axes(handles.Histogram);
%gets the max and min of the graph
yL = get(gca, 'YLim');
%draws 5 lines at the min, the quartiles and the max
line([handles.data.min handles.data.min], yL, 'Color', 'k','LineWidth',1);
line([handles.data.q1 handles.data.q1], yL, 'Color', 'g','LineWidth',1);
line([handles.data.q2 handles.data.q2], yL, 'Color', 'r','LineWidth',1);
line([handles.data.q3 handles.data.q3], yL, 'Color', 'g','LineWidth',1);
line([handles.data.max handles.data.max], yL, 'Color', 'k','LineWidth',1);

function plot_average(handles)
%plots to histogram plot
axes(handles.Histogram);
%gets the max and min of the graph
yL = get(gca, 'YLim');
%draws 5 lines at the min, the quartiles and the max
line([handles.data.avg handles.data.avg], yL, 'Color', 'c','LineWidth',1.5);

function plot_histogram(handles)
%plots to histogram
axes(handles.Histogram);
cla
%plots histogram with current number of bins
netDist = handles.data.netDist;
hist(log(netDist),handles.data.bins);
name = handles.data.name;
histogramTitle = strcat(name,': Number of Mitochondria vs log(netdistance))');
title(histogramTitle);
ylabel('number of Mitochondria');
xlabel('log(netdistance(\mum))')


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

% --- Executes on button press in browse.
function browse_Callback(hObject, eventdata, handles)
% hObject    handle to browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%Makes the browse window go to the current folder, but on the computer
%%this was tested on, it took too long
% if(~exist(handles.data.browsePath,'dir'))
%     start = '';
% else
%     start = handles.data.browsePath;
% end
    
%browsePath will store the string of the folder selected
browsePath = uigetdir();
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

%create a new figure
data = figure;
%set background to white
set(gcf,'color','w');
%copy the centroid plot to the new figure
a = copyobj(handles.Centroid,data);
%set the axes nicely in the fiture
set(a,'Units','normalized');
set(a,'Position',[.13 .225 .74 .74 ]);
%replot the color bar
colorbar('location','southoutside')

%make the name for the save file, of the form:
%'stackname'Centroid 'lowerbound' 'upperbound'.tiff
name = strcat(saveName,'Centroid');
name = sprintf('%s lower%1.1f upper%1.1f',name,handles.data.loLimit,handles.data.hiLimit);
name = strrep(name, '.','_');
%save the figure.
set(gcf, 'InvertHardCopy', 'off');
print (data,name, '-dtiff');

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
%of the form: 'saveName'Histogram '# of bins'.tif
name = strcat(saveName,'Histogram');
name = sprintf('%s %d bins',name,handles.data.bins);
set(gcf, 'InvertHardCopy', 'off');
%save file
print (data,name, '-dtiff');

% --- Executes on button press in updateCentroid.
function updateCentroid_Callback(hObject, eventdata, handles)
% hObject    handle to updateCentroid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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
if (handles.data.bins < 1)
    %ensures that there is a positive number of bins
    errordlg('Must be a positive number of bins','Error');
    return
end
%plots the histogram
plot_histogram(handles);
%checks if the quartiles were displayed, if so re plot
if(get(handles.quartDisplay,'Value'))
    plot_lines(handles);
end
if(get(handles.meanShow,'Value'))
    plot_average(handles);
end

% --- Executes on button press in quartDisplay.
function quartDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to quartDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%if the show option is selected for the quartiles then plot the lines
if (get(hObject,'Value') == get(hObject,'Max'))
    plot_lines(handles);
else
    %else replot the histogram (cla is inherent in plot_histogram)
    plot_histogram(handles);
    if (get(handles.meanShow,'Value'))
        plot_average(handles);
    end
end
% Hint: get(hObject,'Value') returns toggle state of quartDisplay

% --- Executes on button press in meanShow.
function meanShow_Callback(hObject, eventdata, handles)
% hObject    handle to meanShow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(hObject,'Value') == get(hObject,'Max'))
    plot_average(handles);
else
    %else replot the histogram (cla is inherent in plot_histogram)
    plot_histogram(handles);
    if (get(handles.quartDisplay,'Value'))
        plot_lines(handles);
    end
end

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
if ~isfinite(loPics)
    %ensures it is a number
    set(hObject, 'String', handles.data.loPics);
    errordlg('Input must be a number','Error');
    return;
end

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
if ~isfinite(hiPics)
    %ensures it is a number
    set(hObject, 'String', handles.data.hiPics);
    errordlg('Input must be a number','Error');
    return;
end

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



function period_Callback(hObject, eventdata, handles)
% hObject    handle to period (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
period = str2double(get(hObject, 'String'));
if ~isfinite(period)
    %ensures it is a number
    set(hObject, 'String', 1/handles.data.freq);
    errordlg('Input must be a number','Error');
    return;
end

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
if ~isfinite(ratio)
    %ensures it is a number
    set(hObject, 'String', handles.data.ratio);
    errordlg('Input must be a number','Error');
    return;
end

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
if ~isfinite(loLimit)
    %ensures it is a number
    set(hObject, 'String', handles.data.loLimit);
    errordlg('Input must be a number','Error');
    return;
end

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
if ~isfinite(hiLimit)
    %ensures it is a number
    set(hObject, 'String', handles.data.hiLimit);
    errordlg('Input must be a number','Error');
    return;
end

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

function bins_Callback(hObject, eventdata, handles)
% hObject    handle to bins (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bins = str2double(get(hObject, 'String'));
if ~isfinite(bins)
    %ensures it is a number
    set(hObject, 'String', handles.data.bins);
    errordlg('Input must be a number','Error');
    return
end
handles.data.bins = bins;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bins_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bins (see GCBO)
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
if ~isfinite(loArea)
    %ensures it is a number
    set(hObject, 'String', handles.data.loArea);
    errordlg('Input must be a number','Error');
    return
end

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
if ~isfinite(hiArea)
    %ensures it is a number
    set(hObject, 'String', handles.data.hiArea);
    errordlg('Input must be a number','Error');
    return
end

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
if ~isfinite(lifetime)
    %ensures it is a number
    set(hObject, 'String', handles.data.lifetime);
    errordlg('Input must be a number','Error');
    return
end

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

function browseSavePath_Callback(hObject, eventdata, handles)
% hObject    handle to browseSavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
browseSavePath = (get(hObject, 'String'));
handles.data.browseSavePath = browseSavePath;
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
%Ensures there are no illegal characters when saving
if ~isempty(saveName)&&(any(saveName(regexp(saveName,'\W')))||any(saveName(regexp(saveName(1),'[^a-z|^A-Z]'))))
   set(hObject, 'String', handles.data.saveName);
   errordlg('Save Name is not valid (Must be alphanumeric or ''_'' and must start with a letter)','Save Name Error' )
   return
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
