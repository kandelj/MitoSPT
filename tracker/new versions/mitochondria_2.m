function [netdistances,totdistances,netangle] = mitochondria_2 (name, numimages,incr,hz,ratio,...
    areaThresh, minlifetime, axes1, axes2,axes3,columns,rows)
%mitochondria2 Track mitochondrial movement in a cell.
%   [NETDISTANCES, LOGSPEEDS] = mitochondria(NAME,NUMIMAGES,HERTZ,RATIO,... 
%   AREATHRESH, LFETIMEMIN, AXES1) with AREATHRESH = [AREAMIN AREAMAX]
%   tracks the movement of mitochondria in a cell by examining a stack of
%   images. The images in the stack must be named with NAME and then a 4 digit
%   number and then '.tif'. For example: NAME0000.tif
%   NUMIMAGES is just the number of images in the stack that are to be
%   examined for mitochondrial movement. HERTZ is the number of pictures
%   taken per second. RATIO is the number of microns per pixel edge,
%   therefore there are RATIO^2 square microns in a pixel. AREATHRESH is a
%   2 element array that contains AREAMIN and AREAMAX. These areas are the
%   boundaries of the size of the objects the function will be considering.
%   MINLIFETIME is the minimum lifetime required for objects to be
%   considered in calculations. AXES1 is the axes that the centroid plot
%   will be plotted on. AXES2 is the axes that the total distance centroid plot 
%   will be plotted on. These will be provided by default in the interface
%   code.
%   
inc = numimages(1):incr:numimages(2);
numPics = length(inc);
%formating name of stack
stackName = strcat(name,'%04d.tif');
%Adjusts the area from square microns to pixels
areaThresh = areaThresh./(ratio^2);
%Initalizes arrays for future use
Pics = cell(1,numPics);
maxobjects = zeros(1,numPics);
allcentroidx = zeros(1,numPics);
allcentroidy = zeros(1,numPics);
%the code for the waitbar, and making it blue
h = waitbar(0,sprintf('0/%d',numPics),'Name','Processing Image Stack...');
set(findobj(h,'type','patch'), 'edgecolor',[0 0 1],'facecolor',[0 0 1])
for i = 1:numPics;
    %stores the name of each picture into the cell array
    Pics{i} = sprintf(stackName,inc(i));
    %loads the image
    Image = imread(Pics{i});
    %finds the connected components of the image, 8-connected neighborhood
    CC = bwconncomp(Image,8);
    %gets the areas from CC
    stats = regionprops(CC, 'Area');
    areas = [stats.Area];
    %bigones are the objects greater than a given pixel major axis length
    bigones = intersect(find((areas >= areaThresh(1))),find((areas <= areaThresh(2))));
    %labelmatrix labels each object, if bigones is not in the label matrix,
    %throw it out
    %now we have a new image, called newimage, with our wanted larger objects
    newimage = ismember(labelmatrix(CC),bigones);
    %changes to uint8
    newimage = im2uint8(newimage);
        
    clear CC areas;
    %find the boundaries of the objects in the new image, label the objects
    [~,L,~,~] = bwboundaries(newimage, 'noholes');
        
    %HERE IS WHERE WE MATCH UP OBJECTS
    %now we need to compare each of the objects to objects of the previous
    %image and renumber them
    
    %finds objects in newimage
    CCnew = bwconncomp(newimage, 8);
    %gets all of the pixels to one array
    allpixels = vertcat(CCnew.PixelIdxList{:});
    %for each image after the first
    if (i >= 2)
        %finds the pixels of overlap between objects
        overlaps = intersect(allpixels,oldpixels);
        %mapping gives all old object labels in the left column and all new        
        %ones in the right column--enables detection of all fusion and fission
        mapping = unique([oldlabels(overlaps) L(overlaps)], 'rows');
        
        %gives the unique new object numbers        
        uniquenew = unique(mapping(:,2));
        %gives the unique old object numbers
        uniqueold = unique(mapping(:,1));
        
        %how many times each new object is mapped to the old ones, i.e. fusion        
        fusionhist = hist(mapping(:,2),uniquenew);
        %how many times each old object is mapped to the new ones, i.e. fission
        fissionhist = hist(mapping(:,1),uniqueold);
        
        %gives the indices of the new objects which appear more than once        
        fusionindices = (fusionhist ~= 1);
        %indices of old objects which appear more than once
        fissionindices = (fissionhist ~=1);
        
        %which new object numbers these are
        fusionobjects = uniquenew(fusionindices);
        %gives these "old" object numbers which have undergone fission
        fissionobjects1 = uniqueold(fissionindices);
        
        %puts a 1 corresponding to each old object number which has undergone
        %fission
        yesfission = ismember(mapping(:,1),fissionobjects1);
        %gives the corresponding new object numbers
        newfissionobjects = mapping(yesfission,2);
                
        %%now we have a list: fusionobjects and newfissionobjects, which are
        %%all of the "new" object numbers which have fused or resulted from
        %%fission. we need to treat these objects specially.
        specialobjects = unique(vertcat(fusionobjects, newfissionobjects));
        
        %now we need to also relabel the connected pixels
        %for each value in L, meaning for each object found
        for ii = 1:max(L(:))
            %if this object overlaps at all with an old object
            if (any(L(overlaps) == ii))
                %if this object is  not flagged as the result of fission or
                %fusion--it is just the same object from the previous frame
                if (~ismember(ii,specialobjects))                
                    %find the corresponding old object number, overwrite
                    oldlabel = mapping((mapping(:,2)) == ii,1);
                    %remaps the new object to have the old object label +
                    %10000(to prevent this overwriting from being the same 
                    %as a flagged object number
                    mapping((mapping(:,2) == ii), 2) = oldlabel + 100000;
                    %we also do this for all connected pixels--the entire object
                    %find is used instead of logical indexing because the
                    %amount of array entries that will be equal to ii are
                    %very sparse and find is faster for such situations
                    L(find(L == ii)) = oldlabel + 100000;
                
                else %if the object has undergone fusion or fission
                    %if the object has undergone fusion
                    if (ismember(ii,fusionobjects))
                        %fused objects get an extra 300000 tacked on to
                        %the new number
                        mapping((mapping(:,2) == ii), 2) = ii + 300000;
                        %same with all connected pixels
                        %find is used here intentionally, same reason as
                        %above
                        L(find(L == ii)) = ii + 300000;
                    %if the object has undergone fission
                    elseif (ismember(ii,newfissionobjects))
                        %fissioned objects get an extra 400000 tacked on to
                        %the new number
                        mapping((mapping(:,2) == ii), 2) = ii + 400000;
                        %same with all connected pixels
                        L(find(L == ii)) = ii + 400000;
                    end
                end
            else
                %if this object has no overlaps--it's not in the mapping matrix
                %tack on an extra 200000
                L(find(L == ii)) = ii + 200000;
            end
        end
        %now we need to remove the dummy indices
        %remove the dummy variables for the overlapping objects, the fission/fusion
        L(L >= 100000) = L(L >= 100000) - 100000;
        
        %if there are any remaining objects, meaning new ones
        if (any(L(:) >= 100000))
            %finds the object numbers of the new objects
            newobjects = unique(L(find(L >= 100000)));
            %for each new,non-overlapping object
            for jj = 1:numel(newobjects)
                %renumber the index to be the max of previously numbered objects
                %without dummy indices, plus the index of the new object
                L(find(L == newobjects(jj))) = maxobjects(i-1) + jj;
            end
        end
        %maxobjects is the max total objects ever, and is equal to the highest
        %object index in L
        maxobjects(i) = max(max(L(:)),maxobjects(i-1));
    else
        %for the first image
        %sets the max amount of objects to current max
        maxobjects(i) = max(L(:));
    end
    clear oldpixels oldlabels
    %saves all of the pixel numbers for the object
    oldpixels = allpixels;
    %gets the object labels for the image and saves them
    oldlabels = L;
    
    %gets information about these new objects
    stats = regionprops(L, 'Centroid');
    %gets the centroid coordinates for each object, saving the x-coordinates as
    %centroidx, and the ycoordinates as centroidy
    centroid = [stats.Centroid];
    centroidx = centroid(1:2:end);
    centroidy = centroid(2:2:end);
    %saves centroid coordinates for each object
    allcentroidx(1:length(centroidx),i) = centroidx(:);
    allcentroidy(1:length(centroidy),i) = centroidy(:);
    
    try
        waitbar(i/numPics,h,sprintf('%d/%d',i,numPics))
    catch err
        h = waitbar(i/numPics,sprintf('%d/%d',i,numPics),'Name','Processing Image Stack...');
        set(findobj(h,'type','patch'), 'edgecolor',[0 0 1],'facecolor',[0 0 1])
    end
end
close(h)

%overwrites any default (0,0) coordinates to NaN--this applies to object A where
%objects A and B have fused to become object B, or an object has disappeared.
allcentroidx(allcentroidx == 0) = NaN;
allcentroidy(allcentroidy == 0) = NaN;

%inializes array for future use
numLabels = max(L(:));
firstframe = zeros(1,numLabels);
lastframe = zeros(1,numLabels);
allobjects = cell(1,numLabels);
alldistances=zeros(1,numLabels);
%processes data for all final objects (objects in last frame)
for m = 1:numLabels
    %each index in allobjects references a 2xnumframes array which has the
    %xcoordinates of the centroid in the first row and ycoordinates in the
    %second row
    object = [allcentroidx(m,:); allcentroidy(m,:)];
    %finds the indices where the object is present
    nonans = find(~isnan(allcentroidx(m,:)));
    %gets the index where the object is first present
    firstframe(m) = nonans(1);
    %gets the last index where the object appears
    lastframe(m) = nonans(end);
    %stores all paths in a cell
    allobjects{m} = object;
    
    %Initializes the distance array
    distance = zeros(1,numPics);
    %the distance for frame 1 is NaN since the object is not yet moving
    distance(1) = NaN;
    %for each frame beyond frame one, the distance traveled between the
    %last 2 frames is calculated
    ll = 2:numPics;
    distance(ll) = sqrt((allcentroidx(m,ll) - allcentroidx(m,ll-1)).^2 + ...
        (allcentroidy(m,ll) - allcentroidy(m,ll-1)).^2);
    %all of the distances are then stored into an array, with each column
    %representing a new object. this is pixels per frame
    alldistances(1:length(distance),m) = distance;
end

%vectorizes the calculation of netdistance
mm = 1:numLabels;
%gets the indices of the centroids, the 'allcentroid' arrays will always be
%of height numLabels, so lastframe/firstframe denote the column number, and
%then add the number of rows by using numLabels
finalframe = (lastframe-1)*numLabels + mm;
initialframe = (firstframe-1)*numLabels + mm;
%calculates the net distance traveled thus far, from the first
%frame the object is present to the last frame
netdistance= sqrt((allcentroidx(finalframe) - allcentroidx(initialframe)).^2 + ...
    (allcentroidy(finalframe) - allcentroidy(initialframe)).^2);
%net distance in microns
netdistances = netdistance * ratio;
%The total distance traveled by the mitochondria
totdistances = nansum(alldistances) * ratio;
totdistances(totdistances == 0) = NaN;

netangle = atan2d((allcentroidy(initialframe) - allcentroidy(finalframe)), ...
    (allcentroidx(initialframe) - allcentroidx(finalframe)));
%gets the absolute angle of the net path
netangle(isnan(totdistances))=NaN;
netdistances(isnan(totdistances))=NaN;

%converts the lifetime min from seconds to hz
lifetimemin = minlifetime*hz/incr;

%the array of all lifetimes for the mitochondria
lifetime = lastframe - firstframe;

%height of the axes
axesHeight = 1040;
axesWidth = 1392;

%initializing arrays
lastcentroidx = zeros(1,maxobjects(end));
lastcentroidy = zeros(1,maxobjects(end));
for g = 1:maxobjects(end)
    %last centroids for all objects
    lastcentroidx(g) = allcentroidx(g,lastframe(g));
    lastcentroidy(g) = allcentroidy(g,lastframe(g));
end
x_min = min(lastcentroidx(lifetime >= lifetimemin));
x_max = max(lastcentroidx(lifetime >= lifetimemin));
y_min = min(lastcentroidy(lifetime >= lifetimemin));
y_max = max(lastcentroidy(lifetime >= lifetimemin));

x_diff = x_max-x_min;
y_diff = y_max - y_min;

ratio_x = axesWidth/x_diff;
ratio_y = axesHeight/y_diff;
scaling = min(ratio_x,ratio_y);
lastcentroidx = (lastcentroidx- x_min) * scaling;
lastcentroidy = (lastcentroidy- y_min) * scaling;
if (ratio_x>ratio_y)
    centering = (axesWidth-x_diff*scaling)/2;
    lastcentroidx = lastcentroidx + centering;
else
    centering = (axesHeight-y_diff*scaling)/2;
    lastcentroidy = lastcentroidy + centering;
end
%plots the net distance centroid evolvement
plot_centroid(1)
plot_centroid(0)
plot_quiver
netdistances = netdistances(lifetime>=lifetimemin);
totdistances = totdistances(lifetime>=lifetimemin);
netangle = netangle(lifetime>=lifetimemin);
    function plot_centroid(isNet)
        %plot all centroids with a cool-warm color code based on their net distance
        %traveled
        
        %sets the axes given as an argument as the current axes
        %also sets distance array to desired one
        if (isNet)
            distances = netdistances;
            axes(axes1);
        else
           
            distances = totdistances;
            axes(axes2);
        end
        
        hold on
        %the limits of the color bar
        limits = [-6.5 2.2];
        %clears the tick marks
        set(gca,'Color',[0 0 0],'XTickLabel',[],'YTickLabel',[]);
       
        %plots the centroid of all objects, color coding their logs according to
        %how far they traveled
        scatter(lastcentroidx(lifetime >= lifetimemin),...
            axesHeight- (lastcentroidy(lifetime >= lifetimemin)),300,...
            log(distances(lifetime >= lifetimemin)),'.')
        caxis(limits)
        %misc axes dimensions
        axis([0 axesWidth 0 axesHeight])
        daspect([1,1,1])
        colorbar('location','southoutside')
        hold off
    end
    function plot_quiver
        %plot all centroids with a cool-warm color code based on their net distance
        %traveled
        axes(axes3)
        
        hold on
        xInc = axesWidth/columns;
        yInc = axesHeight/rows;
        xDim = xInc/2:xInc:(2*columns-1)*xInc/2;
        yDim = yInc/2:yInc:(2*rows-1)*yInc/2;
        [X, Y] = meshgrid(xDim,yDim);
        finalcentroidy = axesHeight-lastcentroidy;
        column = cell(rows,columns);
        row = cell(rows,columns);
        u = zeros(rows,columns);
        v = zeros(rows,columns);
        for iii = 1:columns
            column{iii} = (lastcentroidx>((iii-1)*xInc)&lastcentroidx<(iii*xInc)&lifetime >= lifetimemin);
            
        end
        for iv = 1:rows
           row{iv} = (finalcentroidy>((iv-1)*yInc)&finalcentroidy<(iv*yInc)&lifetime >= lifetimemin); 
        end
        for r = 1:rows
            for c = 1:columns
                angles = netangle(row{r}&column{c});
                traveled = netdistances(row{r}&column{c});
                u(r,c) = nansum(traveled.*cosd(angles));
                v(r,c) = nansum(traveled.*sind(angles));
            end
        end
        

        
        %clears the tick marks
        set(gca,'XTickLabel',[],'YTickLabel',[]);
        
        %plots the centroid of all objects, color coding their logs according to
        %how far they traveled
        scatter(lastcentroidx(lifetime >= lifetimemin),...
            axesHeight- (lastcentroidy(lifetime >= lifetimemin)),100,'b.')
        quiver(X,Y,u,v,'r','LineWidth',1.2);
        
        xL=get(gca,'XLim');
        yL=get(gca,'YLim');
        for l = 1:columns
            line([xInc*l xInc*l], yL, 'Color', 'k','LineWidth',.5);
        end
        for lll = 1:rows
            line(xL, [yInc*lll yInc*lll], 'Color', 'k','LineWidth',.5);
        end
        %misc axes dimensions
        axis([0 axesWidth 0 axesHeight])
        daspect([1,1,1])
        hold off
    end
end