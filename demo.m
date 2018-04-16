function demo(pcdFilePathOrData,minH,maxH,interval)
%
%
% 
% The program is written by Chen Qichao. You can redistribute or modify the
% program for any properties.
%
% mail : mailboxchen@foxmail.com
% Copyright (C) 2015 - 2018  Chen Qichao
% 2018.04.16

if size(minH,2)>1
    for i=1:2:size(minH,2)
        process(pcdFilePathOrData,minH(i),minH(i+1));
    end
else
    demo(pcdFilePathOrData,minH,maxH,interval);
end
end

function process(pcdFilePathOrData,minH,maxH,interval)
%
%��������
gridesize = 0.1;%������С,����0.05����0.1
denseLimit = 3000;%ͶӰ�ܶ�
sigma  = 5;%�˲�����
para = 0.5;
lLimit = 1;%������ֵ���˳���С�ĵ��ƾ���
cdist = 0.3;%�������

% �ж���������ļ�·�����ǵ��ƾ���
[row,col] = size(pcdFilePathOrData);
if row>1&&col>=4
    pcd = pcdFilePathOrData;
elseif row==1
    [path,filename,filetype]=fileparts(pcdFilePathOrData);
    if(filetype=='.las')
        A = LASreadAll(pcdFilePathOrData);
        pcd=[A.x,A.y,A.z,A.intensity];
        savepointcloud2file(pcd,filename,false);
    elseif(filetype=='.xyz')
        fid=fopen(pcdFilePathOrData,'r');
        pcd = readpointcloudfile2(pcdFilePathOrData);%��ȡȫ����
%         pointCloudData =  readpointcloudfile(fid,10000000);%��ȡָ��������
    else
        return;
    end
else 
    return;
end

if ~exist('minH','var')||isempty(minH)  minH = min(pcd(:,3));end
if ~exist('maxH','var')||isempty(maxH)  maxH = max(pcd(:,3));end
if ~exist('interval','var')||isempty(interval)  interval = maxH-minH;end
denseLimit = denseLimit*(interval/0.5);

% gridesize = 0.1;
% denseLimit = 3500;
numLimit = 3500*gridesize*gridesize;
for H1 = minH:interval:(maxH-interval)
    H2 = H1+interval;
    data = pcd(pcd(:,3)>=H1&pcd(:,3)<H2,:);
    [gridArray,outMmesh] = gridpoint(data,gridesize);
    outMmesh0 = outMmesh;
    
    filterMesh = imgaussfilt(outMmesh,sigma);%��˹�˲�����С�����ܶȲ�����Ӱ��
    outMmesh = outMmesh-filterMesh.*para;
    
%     mesh(outMmesh);
%     continue;
outMmesh(outMmesh<numLimit) = 0;
outMmesh(outMmesh>0)= 1;

[row,col] = find(outMmesh>0);
index = clustereuclid([row col],ceil(cdist/gridesize));
nc = unique(index);
for i=1:size(nc,1)
    tmpx = col(index==i);
    tmpy = row(index==i);
    cluster(i).data = [tmpx,tmpy];
%     figure(11);plot(tmpx,tmpy,'.','Color',[rand rand rand]);hold on;axis equal;
end
if size(nc,1)==0
    continue;
end
cluster = getclusterinfo(cluster);

 outMmesh2 = zeros(size(outMmesh));
 p = [];
 lLimit
for i=1:size(cluster,2)
    length = cluster(i).length;
    if length>(lLimit/gridesize)
        p = [p;cluster(i).data];
%         figure(11);plot(cluster(i).data(:,1),cluster(i).data(:,2),'.','Color',[rand rand rand]);hold on;axis equal;
    end
end
if size(p,1)==0
    continue;
end
zeroIdx = (p(:,1)-1).*size(outMmesh,1)+p(:,2);
 outMmesh2(zeroIdx) = 1;
 
 point = getpointfromgrid(gridArray,outMmesh,1,12);
 point2 = getpointfromgrid(gridArray,outMmesh2,1,12);
 
 strh1 = num2str(H1);
 strh2 = num2str(H2);
    savepointcloud2file(data,strcat(strh1,'~',strh2,'-����Ƭ'),0);%��Ƭ����
    savepointcloud2file(point,strcat(strh1,'~',strh2,'-�ܶ��˲�'),0);%�ܶ��˲�����
    savepointcloud2file(point2,strcat(strh1,'~',strh2,'-�����˲�'),0);%�����˲�����
%     figure(2);mesh(outMmesh0);axis equal;
%     figure(3);plot(data(:,1),data(:,2),'r.');axis equal;
%     figure(4);plot(point(:,1),point(:,2),'r.');axis equal;
%     figure(5);plot(point2(:,1),point2(:,2),'r.');axis equal;
%     
%     a=0;
end
end

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

function point = getpointfromgrid(gridArray,seg_I,num,type)
%
% -seg_I:���������ͼ�����
% -num;Ҫ��ȡ����������
% -type:������������λ����12������1��2λ��56������5��6λ��
[row,col] = size(seg_I);
point = zeros(10000,4);
np = 0;
for m = 1:row
    for n = 1:col
        if seg_I(m,n)~=num
            continue;
        end
        p = gridArray{m,n};
        if (type==56)&&(~isempty(p))
            x = p(:,5);
            y = p(:,6);
            h = p(:,3);
            ins = p(:,4);
            p = [x y h ins]; 
        elseif type==12&&(~isempty(p))
            x = p(:,1);
            y = p(:,2);
            h = p(:,3);
            ins = p(:,4);
            p = [x y h ins];
        end       
        if seg_I(m,n)==num&&(~isempty(p))
            preNp = np;
            np = np + size(p,1);
            point(preNp+1:np,:) = p;
        end        
    end
end
point = point(1:np,:);
end
