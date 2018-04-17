function [gridArray,outMmesh ]= gridpoint(pointCloudData,gridSize)
%generate grid of points
    [width,height,minX,minY,maxX,maxY] = calculatesize(pointCloudData,gridSize);
    widthStripsArray = cut2strips(pointCloudData,width,minX,maxX,gridSize,1);
    gridArray = cell(height,width);
    for i = 1:width
        widthStrip = widthStripsArray{i};
       [ heightStripsArray ,meshGrid]= cut2strips(widthStrip,height,minY,maxY,gridSize,2);
        gridArray(:,i) = heightStripsArray';
        outMmesh(:,i) = meshGrid';
    end
end

function [stripsArray,meshGrid] = cut2strips(pointData,nStrips,startValue,endValue,pxielSize,type)
%cut point into strips
%type==1, cut by x coordinate;
%type==2, cut by y coordinate;
    stripsArray(1:nStrips) = {[]};
    meshGrid = zeros(1,nStrips);
    if isempty(pointData)
        return;
    end
    pointData = sortrows(pointData,type);%��x��������
    nPoint = size(pointData,1);
    valueArray = pointData(:,type);%�ָ�����ݣ��簴x����y����
    cutStart = startValue;
    cutEnd = startValue + pxielSize;
    iPoint=1;
    value = valueArray(1);
    isEndPoint = false;%�Ƿ���������һ����
    for i = 1:nStrips,%�ֳ�nStrips��
        strip = [];
        iStripPoint = 0;
        while value<cutEnd,
            iStripPoint = iStripPoint+1;
            strip(iStripPoint,:) = pointData(iPoint,:);
            if iPoint<nPoint,
                iPoint = iPoint+1;   
                value = valueArray(iPoint);
            else
                isEndPoint = true;
                break;
            end
        end  
        stripsArray(i) = {strip};
        meshGrid(i) = size(strip,1);
        cutStart = cutEnd;
        cutEnd = cutEnd + pxielSize;
        if isEndPoint,
            break;
        end
    end
end

function [width,height,minX,minY,maxX,maxY] = calculatesize(pointCloudData,pxielSize)
%calcullate width and height of inage
xAraay = pointCloudData(:,1);
yArray = pointCloudData(:,2);
minX = min(xAraay);
maxX = max(xAraay);
minY = min(yArray);
maxY = max(yArray);
width =  ceil((maxX - minX)/pxielSize);
height = ceil((maxY - minY)/pxielSize);
end