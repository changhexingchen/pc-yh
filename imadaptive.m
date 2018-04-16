function out = imadaptive(img,s,t,sigma,fillpara)
% out = imadaptive(img,s,t,sigma)
% ���ڻ���ͼ������Ӧ��ֵ��
%
% Parameters��
% s = 10      - ����Ӧ�뾶��Ҫ���ڷָ����İ뾶��һ��sԽ��Խ�ܷ�ӳϸ�ڣ���������Ҳ
%               ���Щ��ֵԽСϸ�ڱ����ԣ�����Ҳ��Щ
% t = 0.99    - �ָ����,���Դ���1��ֵԽ������Խ�٣������ź�Ҳ�ᶪʧ
% sigma = 1.5 - �˲�������ֵԽ���˵���������뾶Խ��,ϸ��Ҳ�ᶪʧ
% fillpara=1    - �������ϵ��������Ǵ���Ҷ�У�����ͼ��ֵ��Ϊ1���ɣ������
%               �����Ҷȷֲ������ȵ�ͼ�񣬿�����Ϊ0.5����
%
%
% Reference��
% Roth D B G. Adaptive Thresholding using the Integral Image[J]. Journal of 
% Graphics Gpu & Game Tools, 2007, 12(2):13-21.

% ˵����
% ����Ӧ��ֵ�ָ�ʵ��������˼·����һ�־���ο�������������������ͨ������ͼ����
% ÿ�����ص�ķָ���ֵ(BW=I>T);��һ��˼·���ƶ�ñ�任��ֱ�Ӷ�ԭʼͼ����е�ͨ
% �˲����˲����ͼ��;��Ǳ���ͼ��(BW = I>t*I2);������˼·������һ���ģ����Ǽ�
% ��ÿ��������Χ�����أ�����ʹ��ǰ�ߡ�

if ~exist('s','var')||isempty(s)
    % ͼ��ߴ�ϴ�ʱЧ�����Ǻ�����,����Լ�����s��С
%     nhoodSize =  2*floor(size(img)/16)+1;
%     padSize =(nhoodSize-1)/2;
    padSize = [10 10];
elseif size(s,2)==1
     padSize = [s s];
else
    padSize = s;
end
if ~exist('t','var')||isempty(t),t=1;end
if ~exist('sigma','var')||isempty(sigma),sigma=1;end
if ~exist('fillpara','var')||isempty(fillpara),fillpara=1;end

%Ԥ����
if 3==size(img,3)
    img = rgb2gray(img);
end
img = im2double(img);
I = imfillnan(img,[],fillpara);
I = padarray(I,padSize,'replicate','both');%��Ե��չ

% ��˹�˲�
I = imgaussfilt(I,sigma);%��˹�˲�

% ��ֵ�˲�
% h = fspecial('average', [10 10]);
% I=filter2(h,I);

% �������ͼ
intImg = integralImage(I);
intImg = intImg(2:end,2:end);

% ����ͼ��ʽ�˲�,���Ǿ�ֵ�˲�
% intA, filterSize, normFactor, outType, outSize
% B = integralBoxFilter(intImg,[s s]);

% ����Ӧ��ֵ��
[w,h] = size(intImg);
ws = padSize(1);
hs = padSize(2);
for i=1+ws:w-ws
    for j=1+hs:h-hs
        x1=i-ws;
        x2=i+ws;
        y1=j-hs;
        y2=j+hs;
        count=(x2-x1)*(y2-y1);
        sum=intImg(x2,y2)-intImg(x2,y1)-intImg(x1,y2)+intImg(x1,y1);
        if(I(i,j)*count)<=(sum*t)
            out(i-ws,j-hs)=0;
        else
            out(i-ws,j-hs)=1;
        end
    end
end
% out = imclose(out,strel('disk',3));
% imshow(out);
% T = adaptthresh(img,'Statistic','mean');
% T = adaptthresh(img,0);
% imshow(img>T);
end

function intI = getintimg(I)
% �������ͼ
[w,h]=size(I);
intImg=zeros([w h]);
for i=1:w
    sum=0;
    for j=1:h
        sum=sum+I(i,j);
        if i==1
            intImg(i,j)=sum;
        else
            intImg(i,j)=intImg(i-1,j)+sum;
        end
    end
end
intI = intImg;
end

