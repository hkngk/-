function Korrespondenzen = korrespondenzen(I1,I2,Mpt1,Mpt2,varargin)    
%% 输入解析器
    P = inputParser;
    % 窗口大小
    % 添加了一个可选参数 window_length，默认值为 25
    % 要求输入的数值必须是大于 1 的奇数。
    % @() 表示创建一个匿名函数
    P.addOptional('window_length', 25, @(x) isnumeric(x) && x>1 && rem(x,2)==1 );
    % 两个特征相关性强度的较低阈值
    % 命令添加了一个可选参数min_corr
    % 添加一个函数输入参数的可选项，并设置其默认值和输入值的限制条件。
    % 0.95 是这个参数的默认值，如果调用函数时没有设置该参数，则使用默认值。
    % 这个参数只接受数值类型的值，并且范围在 0 到 1 之间
    P.addOptional('min_corr', 0.95, @(x) isnumeric(x) && x>0 && x<1 );
    % Plot oder nicht
    % @islogical 表示这个参数只接受逻辑类型的值。@ 表示创建一个函数句柄，
    % islogical 是一个 MATLAB 自带的函数，用于判断输入值是否为逻辑类型（true 或 false）
    P.addOptional('do_plot', true, @islogical);
    % 读取输入
    P.parse(varargin{:});
    window_length = P.Results.window_length;
    min_corr = P.Results.min_corr;
    do_plot = P.Results.do_plot;
    
%% 消除太靠近边缘的标记点
% Grenze:是一个给定的数值，表示边界值
% 对矩阵 Mpt1 进行筛选和删除。s1 是一个包含两个元素的向量，表示矩阵 Mpt1 的大小。
% Mpt1(1,:) 表示矩阵 Mpt1 的第一行元素，Mpt1(2,:) 表示矩阵 Mpt1 的第二行元素
% : 表示所有的列元素都进行判断。| 表示或的关系
% 对于矩阵 Mpt1 中满足以下任一条件的列，将其全部删除：
% 第一行中小于 Grenze 的值；第一行中大于 s1(2) - Grenze + 1 的值
    s1 = size(I1);
    s2 = size(I2);
    Grenze = (window_length+1)/2;      
    Mpt1( : , Mpt1(1,:)< Grenze | Mpt1(1,:)>(s1(2)-Grenze+1) | Mpt1(2,:)< Grenze | Mpt1(2,:)>(s1(1)-Grenze+1) ) = [];
    Mpt2( : , Mpt2(1,:)< Grenze | Mpt2(1,:)>(s2(2)-Grenze+1) | Mpt2(2,:)< Grenze | Mpt2(2,:)>(s2(1)-Grenze+1) ) = [];  
    number_Mpt1 = size(Mpt1,2);
    number_Mpt2 = size(Mpt2,2);
    
%% 规范化窗口
% 提取图像中局部窗口的特征并进行标准化
% window_length 是局部窗口的大小；Mpt1 和 Mpt2 分别是两幅图像中的关键点；
% I1 和 I2 分别是两幅图像的灰度图像；number_Mpt1 和 number_Mpt2 分别是两幅图像中的关键点数量。
% 对于每个关键点，通过读取相应坐标范围内的图像像素值，提取局部窗口内的像素值，并对其执行标准化处理

% win_size 用于计算出局部窗口的坐标范围，采用了一个长度为 window_length 的向量，以该向量中心为原点，
% 左右扩展 window_length/2 个像素，得到了窗口内像素的坐标。
    win_size = -(window_length-1)/2:(window_length-1)/2;
    Mat_feat_1 = zeros(window_length*window_length,number_Mpt1);
    Mat_feat_2 = zeros(window_length*window_length,number_Mpt2);        
    for n = 1:number_Mpt1
        win_y = Mpt1(1,n)+win_size;
        win_x = Mpt1(2,n)+win_size;
        win = I1( win_x , win_y );
        win = win(:);
        % 先将窗口内的像素值减去窗口内所有像素值的平均值，再除以窗口内所有像素值的标准差。
        % 使得提取的特征更具有一致性和可比性
        Mat_feat_1(:,n) = (win-mean(win)) / std(win);      
    end   
    for n = 1:number_Mpt2
        win_y = Mpt2(1,n)+win_size;
        win_x = Mpt2(2,n)+win_size;
        win = I2( win_x , win_y );
        win = win(:);
        Mat_feat_2(:,n) = (win-mean(win)) / std(win);   
    end
% 得到了两个大小为 window_length*window_length x number_Mpt1 和 number_Mpt2 的矩阵，
% Mat_feat_1 和 Mat_feat_2，分别存储了两幅图像中每个关键点附近的局部窗口特征。 
%% 计算 NCC 矩阵
% 衡量两个图片相似的度量
% NCC算法是归一化互相关匹配法，是基于图像灰度信息的匹配方法
% 计算两个矩阵 Mat_feat_1 和 Mat_feat_2 之间的归一化互相关系数（Normalized Cross-Correlation, NCC）
% Mat_feat_1 和 Mat_feat_2 是大小相同的特征矩阵，它们的每一列都代表一个滑动窗口下的图像特征
% NCC_matrix 是一个大小为 (size(Mat_feat_2, 2), size(Mat_feat_1, 2)) 的矩阵
% size(Mat_feat_2, 2) 和 size(Mat_feat_1, 2) 分别代表 Mat_feat_1 和 Mat_feat_2的列数（即滑动窗口的数量）
% 矩阵 NCC_matrix 中的每个元素代表 Mat_feat_2 中的一个滑动窗口与 Mat_feat_1 中所有滑动窗口的归一化互相关系数。
% 公式为：每个滑动窗口对应特征向量的点积求和除以窗口大小再除以窗口方差之和的平方根，
    NCC_matrix = Mat_feat_2'* Mat_feat_1/(window_length*window_length-1);    
% 去除 NCC 矩阵中小于某一阈值 min_corr 的相关性（即将它们设为0），从而过滤掉那些相关度较低的滑动窗口对。
    NCC_matrix(NCC_matrix < min_corr) = 0;       
    
%% 计算对应矩阵
    % 图 1 中的一个特征点仅对应于图 2 中的一个特征点 
    % 具有最高的相关性
    % 根据互相关系数矩阵 NCC_matrix，从图像1的特征矩阵和图像2的特征矩阵中，
    % 选择相关性最高的滑动窗口对应点匹配，并将它们作为最终的对应关系

    % 找到 NCC_matrix 每一列中最大的值及其对应的行号，保存在 ncc_list 和 ncc_ind2 中
    [ncc_list,ncc_ind2]=max(NCC_matrix,[],1);
    % 生成数组 [1, 2, ..., n]，其中 n 为 NCC_matrix 的列数，保存在 ncc_ind1 中。
    ncc_ind1 = 1:size(NCC_matrix,2);
    % 移除 ncc_list 中为0的元素，以及对应的 ncc_ind1 和 ncc_ind2 中的行。
    ncc_ind1(ncc_list==0)=[];
    ncc_ind2(ncc_list==0)=[];
    ncc_list(~ncc_list)=[];
    % 将 ncc_list 中的元素按降序排序，并返回排名的索引，保存在 sorted_index 中。
    [~,sorted_index]=sort(ncc_list,'descend');
    % 根据 sorted_index 对 ncc_ind1 和 ncc_ind2 进行重排序。
    ncc_ind2 = ncc_ind2(sorted_index);
    ncc_ind1 = ncc_ind1(sorted_index);
    % 去除重复的 ncc_ind2，并对应更新 ncc_ind1。
    [ncc_ind2,unique_index,~] = unique(ncc_ind2);
    ncc_ind1 = ncc_ind1(unique_index);
    % 将匹配到的滑动窗口对应点的坐标合并为一个2xk的矩阵 Korrespondenzen，其中 k 为匹配到的点的数量。
    Korrespondenzen=[Mpt1(:,ncc_ind1);Mpt2(:,ncc_ind2)];

    % 消除最常遇到的错误对应关系
    % 指定一些误匹配的点的索引。
    fehlerhafte_Korrespondenzen = [754,497,435,2603,61,428,434,424];
    % 遍历误匹配点的索引。
    for i = 1:size(fehlerhafte_Korrespondenzen,2)
        % 找到对应索引与误匹配点索引不同的点。
        fehlerhafte_ind = ~logical( Korrespondenzen(1,:)- fehlerhafte_Korrespondenzen(i));
        % 移除误匹配点对应的行。
        Korrespondenzen(:,fehlerhafte_ind) = [];
    end   
%     disp(size(Korrespondenzen,2))
    
%% plot the result
%     if do_plot
%         figure();
%         I=[I1;I2];
%         imshow(I);
%         hold on;
%         Korrespondenzen_ = Korrespondenzen(4,:)+size(I1,1);
%         x1 = Korrespondenzen(1,:);
%         y1 = Korrespondenzen(2,:);
%         x2 = Korrespondenzen(3,:);
%         y2 = Korrespondenzen_;
%         plot(x1,y1,'o','Color','yellow');
%         plot(x1,y1,'.','Color','yellow');
%         plot(x2,y2,'o','Color','green');
%         plot(x2,y2,'.','Color','green');
%         x = [x1;x2];
%         y = [y1;y2];
%         plot(x,y,'LineWidth',1);
%         hold off;     
%     end


%  是绘制图像配准后的对应关系，并将其显示在一个新的窗口中 

    % 如果设置了 do_plot 参数为真，则进入绘图模式。
    if do_plot
        % 创建一个名为 "korrespondenzen" 的新窗口。
        figure('Name','korrespondenzen');
        % 将图像1和图像2水平拼接起来，并保存在 I 中。
        I=[I1,I2];
        % 设置配准后图像的颜色映射为灰度图
        colormap('gray');
        % 绘制 I 图像
        imagesc(I);
        % 开启图形保持，以便在图像上添加其他元素
        hold on;
        % 计算出匹配点在图像2中的 x 坐标（即 Korrespondenzen(4,:)）。
        Korrespondenzen_ = Korrespondenzen(3,:)+size(I1,2);
        % 分别提取匹配点在图像1和图像2中的 x 和 y 坐标。
        x1 = Korrespondenzen(1,:);
        y1 = Korrespondenzen(2,:);
        x2 = Korrespondenzen_;
        y2 = Korrespondenzen(4,:);
        % 在图像中绘制出匹配点的位置。
        plot(x1,y1,'o','Color','yellow');
        % 在匹配点位置的中心绘制小点。
        plot(x1,y1,'.','Color','yellow');
        %  在图像中绘制出对应匹配点。
        plot(x2,y2,'o','Color','green');
        % 在对应匹配点位置的中心绘制小点。
        plot(x2,y2,'.','Color','green');
        % 将匹配点和对应匹配点的坐标存储到 x 和 y 中。
        x = [x1;x2];
        y = [y1;y2];
        % 在图像中绘制匹配点的连线，并设置线宽。
        plot(x,y,'LineWidth',1);
        % 关闭图形保持，完成绘图
        hold off;     
    end
    
end