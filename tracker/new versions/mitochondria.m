function [netdistances] = mitochondria (name, numimages,hz,ratio,...
    areaThresh, minlifetime, centroidAxes)
%mitochondria Track mitochondrial movement in a cell.
%   [NETDISTANCES] = mitochondria(NAME,NUMIMAGES,HERTZ,RATIO,... 
%   AREATHRESH, LFETIMEMIN, CENTROIDAXES) with AREATHRESH = [AREAMIN AREAMAX]
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
%   considered in calculations. CENTROIDAXES is the axes that the centroid plot
%   will be plotted on. This will be provided by default in the interface
%   code.
%   NETDISTANCES will be an array of the net distances traveled by the
%   mitochondrial objects that were considered by this function. It will be
%   a 1xN array where N is the amount of objects that existed longer than
%   the minimum life time.
%   Authors: Judith Kandel, Philip Chou

%formating name of stack
stackName = strcat(name,'%04d.tif');
%Adjusts the area from square microns to pixels
areaThresh = areaThresh./(ratio^2);
%Initalizes arrays for future use
Pics = cell(1,numimages);
maxobjects = zeros(1,numimages);
allcentroidx = zeros(1,numimages);
allcentroidy = zeros(1,numimages);
for i = 1:numimages;
    %stores the name of each picture into the cell array
    Pics{i} = sprintf(stackName,i-1);
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
end

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
    distance = zeros(1,numimages);
    %the distance for frame 1 is NaN since the object is not yet moving
    distance(1) = NaN;
    %for each frame beyond frame one, the distance traveled between the
    %last 2 frames is calculated
    ll = 2:numimages;
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
%those objects that have not traveled anywhere, meaning they appeared
%and then disappeared, have a NaN net distance
netdistance(netdistance == 0) = NaN;
%and net distance in microns
netdistances = netdistance * ratio;

%plots the centroid evolvement
plot_centroid

%Discards the netdistances that had a lifetime shorter than the minimum
%lifetime. Lifetime and lifetime min arrays are calculated in plot_centroid
netdistances = netdistances(lifetime>=lifetimemin);

    function plot_centroid
        %plot all centroids with a cool-warm color code based on their net distance
        %traveled
        
        %Dimensions of the axes
        axesHeight = 1040;
        axesWidth = 1392;
        
        %sets the axes given as an argument as the current axes
        axes(centroidAxes)
        hold on
        
        %converts the lifetime min from seconds to hz
        lifetimemin = minlifetime*hz;
        
        %the array of all lifetimes for the mitochondria
        lifetime = lastframe - firstframe;
        
        %the limits of the color bar
        limits = [-6.5 2.2];
        %initializing arrays
        lastcentroidx = zeros(1,maxobjects(end));
        lastcentroidy = zeros(1,maxobjects(end));
        for g = 1:maxobjects(end)
            %last centroids for all objects
            lastcentroidx(g) = allcentroidx(g,lastframe(g));
            lastcentroidy(g) = allcentroidy(g,lastframe(g));
        end
        %determines the bounds of the centroids themselves
        x_min = min(lastcentroidx(lifetime >= lifetimemin));
        x_max = max(lastcentroidx(lifetime >= lifetimemin));
        y_min = min(lastcentroidy(lifetime >= lifetimemin));
        y_max = max(lastcentroidy(lifetime >= lifetimemin));
        %Finds their ranges
        x_diff = x_max-x_min;
        y_diff = y_max - y_min;
        %Finds the ratio between the range of the centroids and the axes
        %itself
        ratio_x = axesWidth/x_diff;
        ratio_y = axesHeight/y_diff;
        %Use the smaller one to keep aspect ratio
        scaling = min(ratio_x,ratio_y);
        %Scale the centroid positions
        lastcentroidx = (lastcentroidx- x_min) * scaling;
        lastcentroidy = (lastcentroidy- y_min) * scaling;
        %Center the cell
        if (ratio_x>ratio_y)
            centering = (axesWidth-x_diff*scaling)/2;
            lastcentroidx = lastcentroidx + centering;
        else
            centering = (axesHeight-y_diff*scaling)/2;
            lastcentroidy = lastcentroidy + centering;
        end
        %clears the tick marks
        set(gca,'Color',[0 0 0],'XTickLabel',[],'YTickLabel',[]);
        
        %plots the centroid of all objects, color coding their logs according to
        %how far they traveled
        scatter(lastcentroidx(lifetime >= lifetimemin),...
            axesHeight- (lastcentroidy(lifetime >= lifetimemin)),100,...
            log(netdistances(lifetime >= lifetimemin)),'.')
        caxis(limits)
        
        %misc axes dimensions
        axis([0 axesWidth 0 axesHeight])
        daspect([1,1,1])
        colorbar('location','southoutside')
        hold off
    end

end