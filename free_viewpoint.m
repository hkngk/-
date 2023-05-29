function [output_image]  = free_viewpoint(image1, image2, varargin)
% 此函数从两个真实图像之间的虚拟视点生成图像。输出图像的大小与输入图像的大小相同.
%% Input parser
P = inputParser;
% 选择图像集
% 通过 @(x) islogical(x) 进行判断输入参数是否为逻辑类型。
P.addOptional('choose_img', false, @(x) islogical(x) );
% 直接加载生成的视差图以节省时间
P.addOptional('load_disparityMap', false, @(x) islogical(x) );
% 根据分割和平面拟合优化视差图
P.addOptional('do_optimization', false, @(x) islogical(x) );
% 窗口大小
% isnumeric(x) 用于检查输入参数是否是数值类型，如果验证通过，则返回 true，否则返回 false
% 要同时满足x>=0 和x<=1 
P.addOptional('p', 0.5, @(x) isnumeric(x) && x>=0 && x<=1 );
% 两个特征之间相关性强度的较低阈值
P.addOptional('down_ratio', 0.3, @(x) isnumeric(x) && x>0 && x<=1 );
% 是否绘图
P.addOptional('disparity_range', [-426,450], @(x) isnumeric(x) && x(1)<x(2));
P.addOptional('Np', 1400, @(x) isnumeric(x));
% 读取输入
% 解析输入参数列表
P.parse(varargin{:});
% 通过 P.Results 获取其值，如果输入参数未给出，则使用默认值
choose_img = P.Results.choose_img;
load_disparityMap = P.Results.load_disparityMap;
do_optimization = P.Results.do_optimization;    
p = P.Results.p;
down_ratio = P.Results.down_ratio;
disparity_range = P.Results.disparity_range; 
Np= P.Results.Np;     

    %% 将RGB图像转换为灰度图像
    I1_gray = double(rgb_to_gray(image1));
    I2_gray = double(rgb_to_gray(image2));

    %% 利用Harris检测器提取特征点
    Merkmale1 = harris_detektor(I1_gray, ...
        'segment_length', 15, 'k', 0.05, 'tau', 100000, ...
        'tile_size', [200,200], 'N', 10, 'min_dist', 20, 'do_plot', false);
    Merkmale2 = harris_detektor(I2_gray,  ...
        'segment_length', 15, 'k', 0.05, 'tau', 100000, ...
        'tile_size', [200,200], 'N', 10, 'min_dist', 20, 'do_plot', false);

    %% 查找与NCC的通信
    Korrespondenzen = korrespondenzen(I1_gray, I2_gray, Merkmale1, Merkmale2, ...
        'window_length', 25, 'min_corr', 0.95, 'do_plot', false);

    %% 实现RanSaC算法以获得鲁棒对应
    [Korrespondenzen_robust,EF_robust] = ransac(I1_gray, I2_gray, Korrespondenzen, ...
        'epsilon', 0.7, 'p', 0.8, 'tolerance', 0.01, 'k', 8, 'do_plot', false);

    %% 实现八点算法估计本质矩阵和基本矩阵
    %load('K.mat');
    %achtpunktalgorithmus(Korrespondenzen_robust,K);

    %% 求投影坐标的两个线性变换，将极映射到x轴方向上的无穷远
    % [t1, t2] = estimateUncalibratedRectification(EF_robust, [Korrespondenzen_robust(2,:)',Korrespondenzen_robust(1,:)'], [Korrespondenzen_robust(4,:)',Korrespondenzen_robust(3,:)'],size(image2_gray));
    [t1, t2] = epipolar_rectification(EF_robust, [Korrespondenzen_robust(2,:)',Korrespondenzen_robust(1,:)'], [Korrespondenzen_robust(4,:)',Korrespondenzen_robust(3,:)'],size(I2_gray));

    %% 将变换应用于整个图像，使得所有核线对应于水平扫描线
    % [I1_Rect_,I2_Rect_] = rectifyStereoImages(image1,image2,t1,t2,'OutputView','valid');
    [I1_gray_rect,I2_gray_rect] = image_rectification(I1_gray,I2_gray,t1,t2,'OutputView','valid','do_plot', false);
    [I1_rgb_rect,I2_rgb_rect]   = image_rectification(image1,image2,t1,t2,'OutputView','valid','do_plot', false);

    %% 向下采样图像   
    I1_gray_rect_down = imresize(I1_gray_rect,down_ratio);
    I2_gray_rect_down = imresize(I2_gray_rect,down_ratio);
    
if ~load_disparityMap 
    %% 使用半全局算法计算视差图
    if p<=0.5
        disparity_map = disparity_computation(I1_gray_rect_down,I2_gray_rect_down, ...
            round([disparity_range(1),disparity_range(2)]*down_ratio), 'do_plot', false);
    else
        disparity_map = disparity_computation(I2_gray_rect_down,I1_gray_rect_down, ...
            round([-disparity_range(2),-disparity_range(1)]*down_ratio), 'do_plot', false);
        disparity_map = -disparity_map;
    end

%% 或者为了节省时间，直接加载生成的视差图和校正后的RGB图像
else
    down_ratio = 0.5;
    if choose_img
        I1_rgb_rect = imread('img/L1_rect.png');
        I2_rgb_rect = imread('img/R1_rect.png');
        if p<=0.5
            load 'img/L1_250_310.mat';
        else
            load 'img/R1_310_250.mat';
            disparity_map = -disparity_map;
        end
    else
        I1_rgb_rect = imread('img/L2_rect.png');
        I2_rgb_rect = imread('img/R2_rect.png');
        if p<=0.5
            load 'img/L2_213_225.mat';
        else
            load 'img/R2_225_213.mat';
            disparity_map = -disparity_map;
        end 
    end
end  


%% 对视差图进行上采样
disparity_map = imresize(disparity_map,1/down_ratio);

%% 显示视差图
figure;
imshow(disparity_map,down_ratio*disparity_range);
title('disparity map');
colorbar;

%% 根据分割和平面拟合优化视差图
if do_optimization
    
    %% 使用Hough参数分割线条   
    %% 使用区域增长算法对聚类进行分割
    [lines1, lines2] = line_segmentation(image1, image2, choose_img, 'do_plot', false);
    
    if p<=0.5  
        line  = lines2;
        [wall,~,~,~,~] = cluster_segmentation(image2, 'start_point', [1500,3000], 'reg_maxdist', 0.2, 'down_ratio', 0.2, ...
            'hsize', 15, 'sigma', 2.5, 'do_plot', true);    
        mesh = logical(line+wall);
        [~, mesh] = image_rectification(lines1,mesh,t1,t2,'OutputView','valid','do_plot', false);
    else
        line  =lines1;
        [wall,~,~,~,~] = cluster_segmentation(image1, 'start_point', [980,738], 'reg_maxdist', 0.2, 'down_ratio', 0.2, ...
            'hsize', 15, 'sigma', 2.5, 'do_plot', true);
        mesh = logical(line+wall);
        [mesh, ~] = image_rectification(mesh,lines2,t1,t2,'OutputView','valid','do_plot', false);
    end
    mesh = logical(mesh);
    figure('Name','mesh'),imshow(mesh);
    
    
%     load 'img/wall.mat';
%     load 'img/book.mat';

    %% optimize the desparity of the wall
    if choose_img
     wall_disparity = 180*down_ratio;
    else
     wall_disparity = 280*down_ratio;
    end
    
    
    [x,y] = meshgrid( 1:size(disparity_map,2) , 1:size(disparity_map,1) );
    [xq,yq] = meshgrid( 1: size(disparity_map,2)/(size(mesh,2)): size(disparity_map,2), ...
                        1: size(disparity_map,1)/(size(mesh,1)): size(disparity_map,1) );
    disparity_map = interp2(x,y,disparity_map,xq,yq);


    disparity_map(mesh)=-wall_disparity;
    
    %% 利用ransa算法对视差图进行平面拟合优化
%     disparity_map = ransac_plane(disparity_map,wall,3,'do_plot', true);
%     disparity_map = ransac_plane(disparity_map,book,3,'do_plot', true);
%     disparity_map = ransac_plane(disparity_map,box1,3,'do_plot', false);
%     disparity_map = ransac_plane(disparity_map,box2,3,'do_plot', false);
end

%% imshow the disparity map
figure;
imshow(disparity_map,down_ratio*disparity_range);
title('disparity map');
colorbar;

%% 3D reconstruction
reconstruction_3D(I1_rgb_rect, I2_rgb_rect, disparity_map, 'do_plot', false);

%% generate the image in the new viewpoint using depth-image-based rendering algorithm
if p<=0.5
    output_image_ = DIBR(I1_rgb_rect, disparity_map, p, Np,down_ratio,'do_plot', false);
else
    output_image_ = DIBR(I2_rgb_rect, disparity_map, p, Np,down_ratio,'do_plot', false);
end
    
%% upsample the image to the original size
output_image_ = double(output_image_);
[x,y] = meshgrid( 1:size(output_image_,2) , 1:size(output_image_,1) );
[xq,yq] = meshgrid( 1: size(output_image_,2)/(size(image1,2)+1): size(output_image_,2), ...
                    1: size(output_image_,1)/(size(image1,1)+1): size(output_image_,1) );
output_image(:,:,1) = interp2(x,y,output_image_(:,:,1),xq,yq);
output_image(:,:,2) = interp2(x,y,output_image_(:,:,2),xq,yq);
output_image(:,:,3) = interp2(x,y,output_image_(:,:,3),xq,yq);
output_image = uint8(output_image);
figure,imshow(output_image);title(['Virtual View 2000*3000 with p equal to ',num2str(p)]);
end

