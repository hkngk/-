function Merkmale = harris_detektor(input_image, varargin)
%% Input parser
    P = inputParser;
    %图像片段的大小
    P.addOptional('segment_length', 15, @isnumeric);
    % 在角和边之间加权的优先级
    P.addOptional('k', 0.05, @isnumeric);
    % 检测拐角的阈值
    P.addOptional('tau', 1000000, @isnumeric);
    % 平铺大小
    P.addOptional('tile_size', [200,200], @isnumeric);
    % 平铺中的最大特征数
    P.addOptional('N', 10, @isnumeric);
    % 两个特征的最小像素间距
    P.addOptional('min_dist', 20, @isnumeric);
    % 是否绘图
    P.addOptional('do_plot', true, @islogical);
    % 读取输入
    P.parse(varargin{:});
    segment_length = P.Results.segment_length;
    k = P.Results.k;
    tau = P.Results.tau;
    N = P.Results.N;
    min_dist = P.Results.min_dist;
    do_plot = P.Results.do_plot;
    tile_size = P.Results.tile_size;
    % 通过 numel 函数获取 tile_size 元素数量，判断其是否为 1，
    % 如果是，则将 tile_size 的值重复一次，形成长度为 2 的行向量 tile_size=[tile_size,tile_size]，并重新赋给 tile_size 变量。
    % 这样做的目的是为了确保在 tile_size 变量作为矩形块大小时，它的长度和宽度相等，
    if numel(tile_size) == 1
        tile_size=[tile_size,tile_size];
    end
%     input_image = double(input_image);

%% sobel 滤波器
% Sobel 滤波器是一种常用的图像滤波器，用于检测图像中的边缘信息。它是一种基于矩阵卷积的操作，可以对图像进行卷积操作，通常由两个矩阵组成
% 
    % wx 和 wy 分别是 Sobel 滤波器在 x 方向和 y 方向的卷积核，分别用于检测图像在 x 方向和 y 方向上的梯度信息
    % wx 是一个 3x3 的矩阵，被称为滤波器或卷积核
    wx = [1,0,-1;2,0,-2;1,0,-1];
    wy = [1,2,1;0,0,0;-1,-2,-1];
    % conv2 函数用于二维卷积操作，'same' 表示输出与输入图像大小一致。
    % 对输入图像 input_image 应用卷积核 wx 进行二维卷积操作，并保持输出大小与输入图像相同（即使用 'same' 选项）
    % Fx 和 Fy 分别表示输入图像在 x 方向和 y 方向上的梯度值
    Fx = conv2(input_image,wx,'same');
    Fy = conv2(input_image,wy,'same');
 
%% 加权 harris 矩阵
    % Gaussian 滤波器是一种线性平滑滤波器，用于对图像进行平滑操作，去除噪声和细节，并保留边缘信息。
    % 生成一个gaussian滤波器大小segment_length×1，即是一个列向量.segment_length/5 指定了 Gaussian 滤波器的标准差。
    % fspecial 函数是一个用于生成各种基本滤波器的 Matlab 函数
    w=fspecial('gaussian',[segment_length,1],segment_length/5);
    % Fx 元素的平方与 Gaussian 滤波器对输入图像进行卷积，并将卷积结果保存在 G11 矩阵中。这里使用了同样大小的 Gaussian 滤波器 w 进行卷积，
    G11 = conv2(w,w,Fx.*Fx,'same');
    G22 = conv2(w,w,Fy.*Fy,'same');
    G12 = conv2(w,w,Fx.*Fy,'same');
% 将每个梯度元素平方后再使用高斯卷积，得到类似于卷积核小于高斯滤波器强烈响应的权重矩阵。
% 最后，通过这些权重矩阵进行 Hessian 矩阵的计算，sobel滤波器和gaussian滤波器都是为计算Hessian矩阵做铺垫，以用于后续的角点检测。
%% harris 检测器
    % 根据之前计算得到的 G11、G22、G12权重矩阵计算 Hessian 矩阵H。k 是一个可调节的参数。
    % 这个公式可以计算每个像素点对应的 Hessian 矩阵的特征值，从而判断该像素点是否为角点。
    H = G11.*G22 - G12.^2 - k*((G11+G22).^2);   
    % 获取输入图像的大小信息
    size_image = size(input_image); 
    % segment_length 表示网格的边长，而 ceil() 函数表示向上取整，计算网格 mesh 的边缘到中心位置的距离，最终结果保存在变量 c 中。
    c = ceil(segment_length/2);
    % 创建一个与输入图像 input_image 大小相同的零矩阵 mesh。该零矩阵 mesh 的每个元素都为 0，表示该网格上不存在角点。
    mesh = zeros(size_image); 
    % 将网格 mesh 放置在原始图像的中心位置，并且确保其不会越界。
    % 使用网格 mesh 来描述可能包含角点的区域，变量 c 的取值决定了可能包含角点的区域大小。
    % 将网格 mesh 的中心位置以及与中心位置相距不超过 c 的区域标记为 1，表示这些区域可能包含角点。网格坐标范围为 [c,m−c] 和[c,n−c]
    mesh(c:size_image(1)-c,c:size_image(2)-c) = 1;
    % 将网格 mesh 中可能包含角点的区域与角点测量值矩阵 H 相乘，然后将结果保存在矩阵 corners 中。
    % mesh .* H 的结果对应着可能包含角点的区域的角点测量值，其中非零的元素表示角点区域。
    % 如果在网格 mesh 中某个位置出现了角点，则 corners 矩阵的相应位置会标记为角点。
    % corners 矩阵记录了标记角点的区域，其中非零元素在网格 mesh 中标记的为 1，并且在角点测量值矩阵 H 中具有较大的值，
    % 因此这些位置可能表示角点的位置。
    corners = mesh .* H;
    % 将角点测量值小于某个阈值 tau 的像素位置标记为非角点区域，标记为 0，
    % 以过滤掉角点测量值较小的区域，即只保留那些具有较大角点测量值的像素位置。
    corners(corners<tau) = 0;
    % 先通过 zeros 函数创建两个大小分别为原始图像高度x min_dist 和 min_dist x (原始图像宽度+2× min_dist) 的全零矩阵 m1 和 m2
    m1 = zeros(size_image(1),min_dist);
    m2 = zeros(min_dist,size_image(2)+2*min_dist);
    % 将 m1 矩阵分别添加到 corners 矩阵的左右两侧，以在 corners 矩阵左右两侧增加宽度为 min_dist 的全零边界，并将扩充后的矩阵保存回 corners
    % 在 corners 的两侧和上下添加了边界，确保后续进行非最大值抑制时能够考虑到边界像素。不会忽略边界的角点，从而产生更准确的角点检测结果。
    
    %非最大值抑制（NMS）：通过移除非最大值像素来减少特征点（如角点或边缘）的数量，并提高其空间精度
    % 在角点检测中，非极大值抑制的目的是避免多个相邻像素被标记为角点
    % 遍历角点测量值矩阵的每个像素点，若其角点测量值大于其邻域像素（周围一定半径内）的角点测量值，则保留该像素点。
    % 否则，该像素点角点测量值较小，可能不是真正的角点，应该抑制。

    corners = [m1,corners,m1];
    corners = [m2;corners;m2];
    % 按降序排列强度的所有特征
    % 使用 corners(:) 将 corners 矩阵展开成一个列向量，并按照角点测量值从大到小进行排序，
    % 返回排好序的列向量 sorted_list 和角点像素在原始图像中的索引值 sorted_index。
    % sort 函数是排序函数，B = sort(A, dim, direction)，A 表示待排序的数组，dim 表示根据哪个维度进行排序
    % direction 表示排序方向，可选值为 'ascend'（升序，即默认值）和 'descend'（降序）
    [sorted_list,sorted_index] = sort(corners(:),'descend');
    % 使用 sorted_list==0 选出角点测量值为 0 的位置，并将这些位置从 sorted_index 中移除，以确保不会将角点测量值为 0 的像素认为是真正的角点。
    sorted_index(sorted_list==0) = [];
    %建立循环矩阵
    % meshgrid 是网格生成函数，用于根据指定的区间和步长，在二维平面上生成网格点坐标矩阵
    % 生成了一个(−min_dist) 到 （min_dist） 范围内的网格点坐标矩阵。x 和 y 分别是两个n×n 的矩阵
    [x,y] = meshgrid(-min_dist:min_dist,-min_dist:min_dist);
    % 生成一个大小为n×n 的二维圆形矩阵 Cake。每个元素表示对应的网格点是否落在以原点为圆心、半径为 min_dist 的圆外
    % 对于矩阵中的第 i 行第j 列(坐标为（x i,j,y i,j) 的网格点），如果其对应的点到原点的欧几里得距离大于 min_dist，
    % 则该元素值为 0，表示其对应的像素点不需要进行角点处理；圆形区域内的元素值为 1，表示其对应的像素点需要进行角点处理
    % 可以从一个正方形的网格中筛选出所有落在圆形区域内的网格点。这个过程可以用于对图像中感兴趣的区域进行选取
    Cake = sqrt(x.^2 + y.^2)> min_dist;
    % 准备
    % numel 用于计算一个数组或矩阵中所有元素的总数。计算变量 sorted_index 中元素的个数，并将结果赋值给变量 sorted_number。
    sorted_number = numel(sorted_index);
    % 根据给定的图像大小以及指定的切片大小，计算出需要的切片块数，然后创建一个相应大小的矩阵 AKKA（切片块矩阵）
    % 创建了一个大小为(size_image(1)/tile_size(1))X(size_image(2)/tile_size(2)的零矩阵 AKKA
    % 图像中每个切片块的大小由变量 tile_size 指定，它是一个大小为 1×2 的数组，其中第一个元素表示每个切片块的行数，第二个元素表示每个切片块的列数
    AKKA = zeros(ceil(size_image(1)/tile_size(1)),ceil(size_image(2)/tile_size(2)));
    % min{⋅,⋅} 表示取两个参数中的最小值
    % 创建了一个2Xmin(numel(AKKA)*N,sorted_number)的全零矩阵。该矩阵通常被用来存储从图像中提取出的一些视觉特征
    % 根据输入参数 AKKA 和 N，计算出需要的特征数量，并创建一个大小相应的零矩阵 Merkmale。然后，Merkmale 可以用于存储从图像中提取的关键特征，
    Merkmale = zeros(2,min(numel(AKKA)*N,sorted_number));
    % feature_count 被用来计数处理过程中提取的特征数量，feature_count 的初始值设置为 1，表示默认情况下已提取的特征数量为 1，
    feature_count = 1;
    % 控制特征之间的距离
    % 遍历了一个已排序的角点索引数组 sorted_index
    for  current_point = 1:sorted_number
        % 从sorted_index中读取当前索引 current_index
        current_index = sorted_index(current_point);
        % 如果该索引指示点图像中不是角点（即 corners(current_index) 的值为 0），则当前循环被中止，并继续处理下一个索引。
        if(corners(current_index)==0)
            continue;
        % 否则，当前索引对应的像素被视为一个角点
        % ind2sub 用于将线性索引转换成等效的行列索引。使用ind2sub 函数将角点图像 corners 中的线性索引 current_index 转换为相应的行列坐标。
        % row 和 col 分别表示 current_index 对应的像素在 corners 矩阵中的行和列坐标。
        % 这些坐标用于计算该像素所在的 AKKA 切片矩阵的行列索引，并更新相应的元素数量。
        else
            [row,col]=ind2sub(size(corners),current_index);
        end
        % 计算了当前角点像素所属的 AKKA 切片矩阵中的行索引。从当前像素行坐标中减去一个偏移量 min_dist,再减去1,再除以行切片大小 tile_size(1)
        % 这个 -1 是为了将矩阵索引从1开始的MATLAB语法转换为从0开始的数组语法
        % floor 函数将计算结果向下取整.将行索引加 1 是因为 MATLAB 中的数组索引是从 1 开始的。
        AKKA_row = floor((row-min_dist-1) / tile_size(1))+1;
        AKKA_col = floor((col-min_dist-1) / tile_size(2))+1;
        % 更新了 AKKA 切片矩阵中第 AKKA_row 行、第 AKKA_col 列的元素，将其加 1。
        % 这行代码加 1 的作用是将当前角点像素计入相应的 AKKA 切片块中的像素数量中
        % 将输入图像分割成多个相同大小的矩形区域，并在对每个图像区域执行角点检测时，将检测出的角点计入相应的 AKKA 切片矩阵中。
        % 这种方法可以将输入图像的计算量分配到多个处理器上，从而加速角点检测的处理过程。
        AKKA(AKKA_row,AKKA_col) = AKKA(AKKA_row,AKKA_col)+1;
        % 将当前角点像素周围一定范围内的像素区域与 Cake 矩阵相乘，并将结果复制回角点图像 corners 的对应像素区域
        corners(row-min_dist:row+min_dist,col-min_dist:col+min_dist) = corners(row-min_dist:row+min_dist,col-min_dist:col+min_dist).*Cake;
        % 控制平铺中的要素数量 
        % 如果 AKKA(AKKA_row,AKKA_col) 计数器的值等于预设阈值 N，则说明当前 AKKA 切片矩阵内的角点密度较高
        if AKKA(AKKA_row,AKKA_col)==N
            % 将清除当前 AKKA 切片矩阵内的角点，将其像素值设置为 0.这个操作通过将与当前 AKKA 切片矩阵重叠的角点像素位置置为 0 来实现。
            corners( (AKKA_row-1)*tile_size(1)+min_dist+1 : min( size(corners,1) , AKKA_row*tile_size(1)+min_dist ), ...
                    (AKKA_col-1)*tile_size(2)+min_dist+1 : min( size(corners,2) , AKKA_col*tile_size(2)+min_dist ) ) = 0;   
        end
        % 保存特征点
        % 每个角点的坐标存储为一个二元组 (col-min_dist,row-min_dist)，其含义是该角点像素在 corners 矩阵中的列行坐标（注意需要减去一个偏移量 min_dist，以得到原始图像中的坐标）。
        Merkmale(:,feature_count)=[col-min_dist;row-min_dist];
        % feature_count 是一个记录当前已经检测到的特征点数量的计数器变量，
        % feature_count = feature_count+1; 将这个计数器加一，表示已经成功检测到了一个新的特征点。
        feature_count = feature_count+1;
    end
    % 取 Merkmale 矩阵的所有行，且取其中第一列到第 feature_count-1 列的子矩阵。
    % 得到了一个 2×(feature count−1) 的矩阵，其中每列包含一个特征点的坐标信息。
    % feature_count 的值是新检测到的特征点的数量加一，因此 feature_count-1 表示有效的特征点数量。
    % 由于检测到的特征点数量不固定，Merkmale 矩阵的第二维的大小也是不确定的。
    % 因此，每当有新特征点被检测出时，都需要重新截取 Merkmale 矩阵的有效部分，以保证 Merkmale 矩阵的第二维大小正确，且不包含无效的特征点信息。
    Merkmale = Merkmale( : , 1:feature_count-1 );
     
%% plot the result
    % 在需要显示图像时执行以下代码块
    if do_plot
        %  创建一个新的图像窗口，并命名为 harris_detector
        figure('Name','harris_detector');
        % 设置当前图像窗口的颜色映射为灰度图。
        colormap('gray');
        %  将输入图像 input_image 显示在这个图像窗口上
        imagesc(input_image);
        % 保持这个图像窗口的当前显示状态，以便在后续操作时继续在这个图像窗口上绘制图形
        hold on;
        % 在图像窗口中绘制散点，其中第一个参数 Merkmale(1,:) 表示使用 Merkmale 矩阵的第一行作为横坐标，
        % 第二个参数 Merkmale(2,:) 表示使用 Merkmale 矩阵的第二行作为纵坐标，第三个参数 'r' 表示散点的颜色为红色，
        % 第四个参数 '+' 表示散点的形状为加号。
        % 这样就在输入图像上标记了检测到的角点，便于调试和观察检测结果。
        scatter(Merkmale(1,:),Merkmale(2,:),'r','+');
    end
end