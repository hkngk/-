function gray_image = rgb_to_gray(input_image)
% 将RGB图像转换为灰度图像的函数。它的输入是一个RGB图像，输出是一个灰度图像。
    % 函数首先检查输入图像的维数是否大于2。如果维数大于2，则将图像转换为双精度类型
    if numel(size(input_image)) > 2
        gray_image = double(input_image);

        %RGB中加权平均值作为gray
        %RGB值和灰度的转换，实际上是人眼对于彩色的感觉到亮度感觉的转换，这是一个心理学问题，
        % 计算每个像素的灰度值：：Grey = 0.299*R + 0.587*G + 0.114*B
        %根据这个公式，依次读取每个像素点的R，G，B值，进行计算灰度值（转换为整型数），
        % 将灰度值赋值给新图像的相应位置，所有像素点遍历一遍后完成转换。
        gray_image = 0.299 * gray_image(:,:,1) + 0.587 * gray_image(:,:,2) +  0.114 * gray_image(:,:,3);
        % 计算完成后，将灰度图像转换为无符号8位整数类型，并将其返回。
        gray_image = uint8(gray_image);
    else 
        % 如果输入图像的尺寸小于等于2，则说明输入图像已经是灰度图像，不需要进行任何转换，直接将其返回
        gray_image = input_image;
    end
end