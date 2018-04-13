%% Load the training data
clear
% clc
% box = load('assignment_1_box.mat');
% box = box.pcl_train;
% load('R.mat');

%% Uncomment to load the test file
box = load('assignment_1_test_v2.mat');
box = box.test_set_v2;
% global model planelist planenorm 

xyz_cutting = [0.25,0.25,0.25];

% display the points as a point cloud and as an image
model = zeros(4,3);
linePoint=zeros(3,1);
planenorm = zeros(3,3);
modelNum = 0;
point_pre=[];
point_fuse = [];
rgb_fuse = [];
corner1 = [];
corner2 = [];
s=[];
% list = [31,30,28,27,24,22,21,18,15,12,9];
% Rot=[R3031;R2830;R2728;R2427;...
%     R2224;R2122;R1821;R1518;R1215;R912;R69;];
% Tran=[T3031;T2830;T2728;T2427;...
%     T2224;T2122;T1821;T1518;T1215;T912;T69;]*200.0;
% previous_frame = 0;
% checklist=[6,15,18,27,28,30,31];



for frameNum = 1:length(box)
    % extract a frame
    rgb = box{(frameNum)}.Color; % Extracting the colour data
    point = box{(frameNum)}.Location; % Extracting the xyz data
    
    %remove points far from box
    indx_xyz_no = find(isnan(point(:,1)));
    point(indx_xyz_no,:)=[];
    rgb(indx_xyz_no,:)=[];
    
    indx_xyz_no = find(abs(point(:,1) + 0.71) >xyz_cutting(1));
    point(indx_xyz_no,:)=[];
    rgb(indx_xyz_no,:)=[];
    
    indx_xyz_no = find(abs(point(:,2) + 0.30) >xyz_cutting(2));
    point(indx_xyz_no,:)=[];
    rgb(indx_xyz_no,:)=[];
    
    indx_xyz_no = find(abs(point(:,3) -0.78) >xyz_cutting(3));
    point(indx_xyz_no,:)=[];
    rgb(indx_xyz_no,:)=[];
    
    pc1 = pointCloud(point, 'Color', rgb); % Creating a point-cloud variable
    
    %remove hand
    indx_xyz_no = find(35<rgb(:,1) & rgb(:,1)<140 & 10<rgb(:,2) & ...
        rgb(:,2)<100 & 0<rgb(:,3) & rgb(:,3)<85);
    point(indx_xyz_no,:)=[];
    rgb(indx_xyz_no,:)=[];
    
    % remove background oise
    indx_xyz_no = [];
    for i = 1:length(point)
        point_temp = point;
        current_point = point_temp(i,:);
        point_temp(i,:) = [];
        point_dist = vecnorm(point_temp - current_point,2,2);
        index_noise = find(point_dist<0.007);
        if length(index_noise)<=15
            indx_xyz_no = [indx_xyz_no, i];
        end
    end
    
    point(indx_xyz_no,:)=[];
    rgb(indx_xyz_no,:)=[];
    
    pc = pointCloud(point, 'Color', rgb); % Creating a point-cloud
    figure(1)
    clf
    hold on
    pcshow(pc);
    figure(2)
    showPointCloud(pc1)
    pause(2)
    %% fit plane
    figure(1778365)
    clf
    hold on
    remaining = point*200;
    plot3(remaining(:,1),remaining(:,2),remaining(:,3),'k.')
    [NPts,W] = size(remaining);
    planelist = zeros(20,4);
    
%     find surface patches
%     here just get 4 first planes with more than 1000 data points 
%     Use normarlised rgb
    rgb_remaining = uint8((double(rgb)./sum(rgb,2)) * 255);
    planeNum = 0;
    planepointList = {};
    rgbpointList = {};
    while length(remaining) > 200
        % select a random small surface patch
        [oldlist, oldrgblist, plane] = select_patch(remaining, rgb_remaining,100);
        if(isempty(plane))
            break;
        end       
        planeNum = planeNum + 1;
        
        stillgrowing = 1;        
        while stillgrowing
            % find neighbouring points that lie in plane
            stillgrowing = 0;
            [newlist,rgb_list, remaining, rgb_remaining] = getallpoints(...
                plane,oldlist, oldrgblist,remaining,rgb_remaining, NPts);
            [NewL,W] = size(newlist);
            [OldL,W] = size(oldlist);
            figure(1778365)
            if planeNum == 1
                plot3(newlist(:,1),newlist(:,2),newlist(:,3),'r.')
                planepointList{1}=newlist;
                rgbpointList{1}=rgb_list;
            elseif planeNum==2
                plot3(newlist(:,1),newlist(:,2),newlist(:,3),'b.')
                planepointList{2}=newlist;
                rgbpointList{2}=rgb_list;
            elseif planeNum == 3
                plot3(newlist(:,1),newlist(:,2),newlist(:,3),'g.')
                planepointList{3}=newlist;
                rgbpointList{3}=rgb_list;
            else
                plot3(newlist(:,1),newlist(:,2),newlist(:,3),'m.')
                planepointList{4}=newlist;
                rgbpointList{4}=rgb_list;
            end
            pause(2)
            
            if NewL > OldL + 50
                % refit plane
                [newplane,fit] = fitplane(newlist);
                [newplane',fit,NewL];
                planelist(planeNum,:) = newplane';
                if fit > 0.4*NewL     % bad fit - stop growing
                    break
                end
                stillgrowing = 1;
                oldlist = newlist;
                oldrgblist = rgb_list;
                plane = newplane;
            end
        end
        % delete the surface with less than 100 points
        if length(newlist) < 600
            plot3(newlist(:,1),newlist(:,2),newlist(:,3),'k.')
            planelist(planeNum,:) = [];
            planeNum = planeNum - 1;        
        end
        pause(1)        
        ['**************** Segmentation Completed']     
    end
    figure(1778365)
    plot3(remaining(:,1),remaining(:,2),remaining(:,3),'y.')
    planelist(1:5,:);
    
    
    
    
%     take 2 planes with most points and perpendicular to each other if 
%     plane number if more than 2 
    if planeNum>=2
        planePoint1=planepointList{1};
        planePoint2=planepointList{2};
    end
    if planeNum > 2
        lengthList = zeros(planeNum);
        for i = 1:planeNum
            lengthList(i)=length(planepointList{i});
        end
        [v,maxIndex]=max(lengthList);
        planePoint1=planepointList{maxIndex};
        temp1=planelist(maxIndex,:);
        lengthList(maxIndex)=0;
        [v,maxIndex]=max(lengthList);
        temp2=planelist(maxIndex,:);
        angle = atan2(norm(cross(temp1,temp2)), dot(temp1,temp2));
        if abs(angle-90)>30
            lengthList(maxIndex)=0;
            [v,maxIndex]=max(lengthList);
            temp2=planelist(maxIndex,:);
            angle = atan2(norm(cross(temp1,temp2)), dot(temp1,temp2));
            if abs(angle-90)>30
                lengthList(maxIndex)=0;
                [v,maxIndex]=max(lengthList);
                temp2=planelist(maxIndex,:);
                planePoint2=planepointList{maxIndex};                
            else
                planePoint2=planepointList{maxIndex};
            end
        planeNum = 2;
        end
    end
    
    % Edge and corner extraction
    if planeNum >= 2
        save1 = planePoint1;
        save2 = planePoint2;
        % find edge
        P1 = [0, 0, -( planelist(1,4)/ planelist(1,3))];
        P2 = [0, 0, -( planelist(2,4)/ planelist(2,3))];
        [P,N,check]=plane_intersect(planelist(1,1:3),P1,planelist(2,1:3),P2);
        % shift the planes, make the plane with larger area at the top of
        % list
        modelNum = modelNum + 1;
        d = -norm(P-P*N'*N);
        mean_plane1 = mean(save1,1);
        mean_plane2 = mean(save2,1);
        dist1 = abs(norm(mean_plane1 - mean_plane1*N'*N) + d);
        dist2 = abs(norm(mean_plane2 - mean_plane2*N'*N) + d);
        if dist1>dist2
            temp = save1;
            save1 = save2;
            save2 = temp;
            temp = planelist(1,:);
            planelist(1,:) = planelist(2,:);
            planelist(2,:)=temp;
        end
        planelist(3,:) = [N,d];
        % refind edge, make sure the direction of the vector arre correct
        P1 = [0, 0, -( planelist(1,4)/ planelist(1,3))];
        P2 = [0, 0, -( planelist(2,4)/ planelist(2,3))];
        [P,N,check]=plane_intersect(planelist(1,1:3),P1,planelist(2,1:3),P2);
        linePoint = P;
        
        % project data to planes        
        pointProj1 = save1 - sum((save1 - P1).* planelist(1,1:3),2).* planelist(1,1:3);
        pointProj2 = save2 - sum((save2 - P2).* planelist(2,1:3),2).* planelist(2,1:3);
        point = [pointProj1;pointProj2];

        % project data to edge
        Q = sum((point-P).*N, 2).*N+P;
        [v, sortedIndex] = sort(Q(:,1));
        Q = Q(sortedIndex,:);
        corner1_pre = corner1;
        corner1 = Q(int32(length(Q)*0.99), :);
        corner2_pre = corner2;
        corner2 = Q(int32(length(Q)*0.01), :);   
        
       % get rotation and translation
        if modelNum >1 && frameNum - previous_frame ==1
            [rot,trans] = trarot(model,planelist);
            trans = (corner1+corner2-(rot*corner1_pre')'-(rot*corner2_pre')')/2;
            
            point_rot = (rot * point_pre')'  + trans;
            figure(1778365)
            point_rot = point_rot;
            plot3(point_rot(:,1),point_rot(:,2),point_rot(:,3),'k.')
            modelNum = 0;
            figure(122)
            hold on
            plot3(point(:,1),point(:,2),point(:,3),'r.')
            plot3(point_rot(:,1),point_rot(:,2),point_rot(:,3),'b.')
            figure(123)
            plot3(point_pre(:,1),point_pre(:,2),point_pre(:,3),'r.')
            figure(124)
            plot3(point(:,1),point(:,2),point(:,3),'b.')
        end
       
        % save previous plane        
        model = [planelist(1,:); planelist(2,:);planelist(3,:)];
        planenorm = [planelist(1,1:3);planelist(2,1:3);N];
        
        point_pre = point;
        
        % plot corner
        figure(1778365)
        plot3(corner1(:,1),corner1(:,2),corner1(:,3),'marker','o','markerfacecolor','y')
        plot3(corner2(:,1),corner2(:,2),corner2(:,3),'marker','o','markerfacecolor','y')
        vec_n = [corner2; corner2 + N*5; corner2 + N*10];
        vec_1 = [corner2; corner2 + planelist(1,1:3)*5; corner2 + planelist(1,1:3)*10];
        vec_2 = [corner2; corner2 + planelist(2,1:3)*5; corner2 + planelist(2,1:3)*10];
        plot3(vec_n(:,1),vec_n(:,2),vec_n(:,3),'r-')
        plot3(vec_1(:,1),vec_1(:,2),vec_1(:,3),'g-')
        plot3(vec_2(:,1),vec_2(:,2),vec_2(:,3),'b-')
        figure(1778365)
        plot3(Q(:,1),Q(:,2),Q(:,3),'c.')
        
        
    end
    % calculate mse    
%     q=planelist(1,:)/norm(planelist(1,1:3));
%     xyz_new=zeros(length(save1),4);
%     xyz_new(:,1:3)=save1;
%     e=xyz_new*q';
%     RMS=sqrt(mean(power(e,2)));
%     s=[s,RMS];
    previous_frame = frameNum;
    pause
end