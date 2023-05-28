%函数定义行，函数名称（与文件名称一致）、输入和输出
function varargout = gui(varargin)
% 最后修改是在GUIDE v2.5 11-Sep-2018 17:39:53

%在此 gui 中，可以分别加载左图像和右图像并选择 p 值。
%还可以选择生成视差图或仅加载生成的视差图以节省时间。最后你可以看到虚拟映像 。
%清除按钮是重置所有参数.



% 开始初始化代码 - 不要编辑
%图形文件的一些初始信息，使用structure结构数据的形式存储一些数据，layout是布局，callback是回调
%两个If语句处理输入与输出
%这段代码是伴随图像文件初始化的一些数据生成的，不需要修改
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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
% 结束初始化代码 - 不要编辑


% 在gui可见之前执行
%openingfun可以说是这个程序的第一个回调函数
%当打开第一个图形文件时，所有的控件数据都设置好了后，图形界面呈现在电脑屏幕之前，这个时候会运行openingfun
%hObject是执行回调控件对象的句柄
function gui_OpeningFcn(hObject, ~, handles, varargin)
% 此函数没有输出参数，请参阅 OutputFcn。
%可以把一些初始化的数据写到这个位置，这样运行界面的时候，会有一些初始化的管理

% 选择gui的默认命令行输出
handles.output = hObject;
% 更新句柄结构
guidata(hObject, handles);

% UIwaite使UI等待用户响应。
%当程序执行到uiwait时，程序会处于等待中，直到遇到uiresume函数，才会执行uiwait之后的程序。
% uiwait(handles.figure1);
%axes是MATLAB中GUI界面的重要控件之一，可以用来显示图片
axes(handles.axes2); %坐标控件
imshow(imread('img/tum.jpg'))%对读取的图像进行显示

% 此函数的输出将返回到命令行。
%输出函数outputfun有输出参数
%是在上面的打开函数返回控制之后，然后把控制权返回给命令行窗口之前，执行这里函数的内容
%执行结果会输出到命令行窗口中
function varargout = gui_OutputFcn(~, ~, handles) 
% 从句柄结构获取默认命令行输出
varargout{1} = handles.output;


%还有get和set函数，get是获得按钮上的属性值，set是设置它的属性名称为某一个属性值
%callback回调函数有三个输出参数，第一个参数是hObject,是点击对象的句柄
% 第二个参数evendata是一个保留字段
% 第三个参数handles是一个结构数组，包含了整个界面控件信息以及数据信息
%value值相当于每一个下拉菜单选项的索引值，会默认的，自上而下，给每一个选项添加一个索引值，第一条就是1，以此类推
%min与max默认值为0和1，有这样一个规则，当最大值和最小值之差不为一时，value值可以设置为空0

% 在弹出式菜单中更改选择时执行 
function popupmenu1_Callback(hObject, ~, handles)
% contents = cellstr(get(hObject,'String')) 以单元格数组的形式返回弹出菜单1的内容
%cellstr()是将字符数组转换成cell类型为string的cell array的函数
% contents{get(hObject,'Value')} 从弹出菜单 1 返回所选项
str = get(hObject, 'String');  %获得string值命名给str这个变量
val = get(hObject,'Value');    %获得控件上的索引值，命名给val
%switch的使用：switch变量
%                  case 结果组1
%                      语句1....后面一样
%              end
switch str{val}       %str这个变量时元胞数组，使用大括号
    case 'L1'
        I1 = imread('img/L1.jpg');
    case 'L2'
        I1 = imread('E:/changchunligong/work hardly/Image-based-Rendering-master/img/L2.jpg');
end
%handles:1.添加新字段并赋值:handles.Name = X(Name可以自定，X为需要保存的值)
%        2.更改变量属性：set（handles.Name, ' ', ' '）
%        3.保存数据：guidata(hObject,handles);
handles.popupmenu1 = I1;
%为指定工作区的变量赋值，例如assignin(ws,var,val) 将值 val 赋给工作区 ws 中的变量 var
assignin('base', 'I1', I1);
%保存数据
guidata(hObject, handles);


% 在对象创建期间设置所有属性后执行。
%creatfun会在按钮新建的时候，初始化一些数据或内容
function popupmenu1_CreateFcn(hObject, ~, ~)
% 弹出菜单控件在 Windows 上通常具有白色背景
%       See ISPC and COMPUTER.
%使用if和end写了一个判断语句
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 在弹出菜单2中的选择更改时执行。
function popupmenu2_Callback(hObject, ~, handles)
% 弹出菜单2的hObject句柄(see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% 使用句柄和用户数据处理结构 (see GUIDATA)

% 提示:  contents = cellstr(get(hObject,'String')) 以单元格数组的形式返回弹出菜单 2 内容
%        contents{get(hObject,'Value')} 从弹出菜单2返回所选项目
str = get(hObject, 'String');
val = get(hObject,'Value');
handles.im = val;
switch str{val}
    case 'R1'
        I2 = imread('img/R1.jpg');
    case 'R2'
        I2 = imread('img/R2.jpg');
end

handles.popupmenu2 = I2;
assignin('base', 'I2', I2);
guidata(hObject, handles);


% 在对象创建期间设置所有属性后执行。
function popupmenu2_CreateFcn(hObject, ~, ~)
% 弹出菜单控件在 Windows 上通常具有白色背景。
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%获取 p 值
%P值的可编辑文本框的tag是edit1
function edit1_Callback(hObject, ~, handles)
% Hints: get(hObject,'String') 以文本形式返回 edit1 的内容
%        str2double(get(hObject,'String')) 以双精度形式返回 edit1 的内容
%str 包含表示实数或复数值的文本。str 可以是字符向量、字符向量元胞数组或字符串数组。
p = str2double(get(hObject,'String'));
%isnan(A)判断数组的元素是否是NaN,
%若A的元素为NaN（非数值），在对应位置上返回逻辑1（真），否则返回逻辑0（假）
if isnan(p)
    p = 0;
    set(hObject,'String','');
    %创建错误对话框errordlg
    errordlg('Input must be a number', 'Error');
elseif (p>1 || p<0)
    p = 0;
    set(hObject,'String','');
    errordlg('Input must between 0 and 1', 'Error');
end
assignin('base', 'p', p);
handles.edit1 = p;
guidata(hObject, handles);


% 在对象创建期间，在设置所有属性后执行
function edit1_CreateFcn(hObject, ~, ~)
% 编辑控件在 Windows 上通常具有白色背景。
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% 在单选按钮 1 中按下按钮时执行。生成视差图
%单选按钮1的tag是radiobutton1
function radiobutton1_Callback(hObject, ~, handles)
% Hint: get(hObject,'Value') 返回单选按钮1的切换状态
disp1 = get(hObject,'Value'); %获得索引值赋值给disp1
handles.radiobutton1 = disp1; %添加新字段并赋值
guidata(hObject, handles); %保存数据


% 在单选按钮中按下按钮时执行2.加载视差图
function radiobutton2_Callback(hObject, ~, handles)
% Hint: get(hObject,'Value') returns toggle state of radiobutton2返回单选按钮2的切换状态
disp2 = get(hObject,'Value');
handles.radiobutton2 = disp2;
guidata(hObject, handles);



%downsample ratio的值的可编辑文本框的tag是edit5
function edit5_Callback(hObject, ~, handles)
% Hints: get(hObject,'String') 以文本形式返回 edit5 的内容
%        str2double(get(hObject,'String')) 以双精度形式返回 edit5 的内容
ratio = str2double(get(hObject,'String'));
if isnan(ratio)
    ratio = 0;
    set(hObject,'String','');
    errordlg('Input must be a number', 'Error');
%||和|一样表示或，但是更智能一点，举个例子A||B，如果A为真则A||B就为真，不会判断B的真假
%||只能对标量操作，而|可对矩阵操作。
elseif (ratio>1 || ratio<0)
    ratio = 0;
    set(hObject,'String','');
    errordlg('Input must between 0 and 1', 'Error');
end
handles.edit5 = ratio;
guidata(hObject, handles);




% 在对象创建期间设置所有属性后执行。
function edit5_CreateFcn(hObject, ~, ~)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 在按钮5中按下按钮时执行。显示虚拟映像
% ==的意思是判断是否相等；！=判断是否是不相等的
function pushbutton5_Callback(hObject, ~, handles)
p = handles.edit1;
disp2 = handles.radiobutton2;
if disp2 == 1
    load_dis = true;
    ratio = 0.5;
else
    load_dis = false;
    ratio = handles.edit5;
end
I1 = handles.popupmenu1;
I2 = handles.popupmenu2;
if  handles.im == 2
    dispaiy_range = [-500,620];
    choose_img = true;
    Np = 700;
else
    dispaiy_range = [-426,450];
    choose_img = false;
    Np = 1400 ;
end
tic
output_img = free_viewpoint(I1, I2, 'choose_img', choose_img,'load_disparityMap',load_dis, ...
    'p', p, 'down_ratio',ratio ,'disparity_range', dispaiy_range,'Np',Np);
elapsed_time = toc;
time = sprintf('Running time :  %f ',elapsed_time);
set(handles.text3, 'String',time);
guidata(hObject, handles);


% --- Executes on button press in pushbutton6. Clear 
function pushbutton6_Callback(~, ~, ~)
close(gcbf) 
gui


% --- Executes during object creation, after setting all properties.
function text5_CreateFcn(~, ~, ~)
% hObject    handle to text5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text10_CreateFcn(~, ~, ~)
% hObject    handle to text10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text7_CreateFcn(~, ~, ~)
% hObject    handle to text7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
