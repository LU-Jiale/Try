% Image and Visual Computing Assignment 2: Face Verification & Recognition
%==========================================================================
%   In this assignment, you are expected to use the previous learned method
%   to cope with face recognition and verification problem. The vl_feat, 
%   libsvm, liblinear and any other classification and feature extraction 
%   library are allowed to use in this assignment. The built-in matlab 
%   object-detection functionis not allowed. Good luck and have fun!
%
%                                               Released Date:   31/10/2017
%==========================================================================

%% Initialisation
%==========================================================================
% Add the path of used library.
% - The function of adding path of liblinear and vlfeat is included.
%==========================================================================
clear all
clc

% Hyperparameter of experiments
resize_size=[64 64];


%% Part I: Face Recognition: Who is it?
%==========================================================================
% The aim of this task is to recognize the person in the image(who is he).
% We train a multiclass classifer to recognize who is the person in this
% image.
% - Propose the patches of the images
% - Recognize the person (multiclass)
%==========================================================================


disp('Recognition :Extracting features..')

Xtr = []; Ytr = [];
Xva = []; Yva = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading the training data
% -tr_img_sample/va_img_sample:
% The data is store in a N-by-3 cell array. The first dimension of the cell
% array is the cropped face images. The second dimension is the name of the
% image and the third dimension is the class label for each image.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load('./data/face_recognition/face_recognition_data_tr.mat')
load('./data/face_recognition/face_recognition_data_va.mat')


for i =1:length(tr_img_sample)
    temp = single(tr_img_sample{i,1})/255;
    temp1 = vl_hog(temp, 8);
    temp2 = vl_lbp(temp, 8);
    Xtr = [Xtr;temp1(:)' temp2(:)' ];
    Ytr = [Ytr;tr_img_sample{i,3}];
end

for i =1:length(va_img_sample)
    temp = single(va_img_sample{i,1})/255;
    temp1 = vl_hog(temp, 8);
    temp2 = vl_lbp(temp, 8);
    Xva = [Xva;temp1(:)' temp2(:)' ];
    Yva = [Yva;va_img_sample{i,3}];
end

%% Train the recognizer and evaluate the performance
Xtr = double(Xtr);
Xva = double(Xva);

% Train the recognizer
% model = fitcknn(Xtr,Ytr,'NumNeighbors',5);
% [l,prob] = predict(model,Xva);
model = train(double(Ytr), sparse(Xtr));
[l,acc1,d] = predict(ones(size(Yva,1),1),sparse(Xva),model);
prob2 = 1./(1+exp(-d));
prob = [1-prob2, prob2];

% Compute the accuracy
acc = mean(l==Yva)*100;


fprintf('The accuracy of face recognition is:%.2f \n', acc)
% Check your result on the raw images and try to analyse the limits of the
% current method.


%% Visualization the result of face recognition

data_idx = [1,30,50]; % The index of image in validation set
nSample = 3; % number of visualize data. maximum should be 3
% nPairs = length(data_idx); % unconment to get full size of 
visualise_recognition(va_img_sample,prob,Yva,data_idx,nSample )


%% Part II: Face Verification: 
%==========================================================================
% The aim of this task is to verify whether the two given people in the
% images are the same person. We train a binary classifier to predict
% whether these two people are actually the same person or not.
% - Extract the features
% - Get a data representation for training
% - Train the verifier and evaluate its performance
%==========================================================================


disp('Verification:Extracting features..')


Xtr = []; Ytr = [];
Xva = []; Yva = [];
load('./data/face_verification/face_verification_tr.mat')
load('./data/face_verification/face_verification_va.mat')
load('./data/face_verification/Yale_64x64.mat')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading the training data
% -tr_img_pair/va_img_pair:
% The data is store in a N-by-4 cell array. The first dimension of the cell
% array is the first cropped face images. The second dimension is the name 
% of the image. Similarly, the third dimension is another image and the
% fourth dimension is the name of that image.
% -Ytr/Yva: is the label of 'same' or 'different'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% You should construct the features in here. (read, resize, extract)


% BoW visual representation (Or any other better representation)
% Step 1: Represent each image with bag of words
fprintf('Using Bag of words representation for images\n') 
if ~exist('vocab.mat', 'file')
      fprintf('No existing visual word vocabulary found. Computing one from training images\n')
      
      num_of_words = 100; %Larger values will work better (to a point) but be slower to compute
      
      vocab = codebook(tr_img_pair, num_of_words);
      save('vocab.mat', 'vocab');
      load('vocab.mat');
else 
      load('vocab.mat');
end       
train_image = bags_of_words(tr_img_pair,vocab);
test_image  = bags_of_words(va_img_pair,vocab);

%%  Step 2: Classify each test image by training and using the appropriate classifier
fprintf('Using SVM classifier to predict test set categories\n');

model = train(double(Ytr), sparse(train_image));
[l,acc1,d] = predict(ones(size(Yva,1),1),sparse(test_image),model);
prob2 = 1./(1+exp(-d));
prob = [1-prob2, prob2];

% Compute the accuracy
acc = mean(l==Yva)*100;
     
fprintf('The accuracy of face verification is:%.2f \n', acc)

%% Visualization the result of face verification

data_idx = [100,200,300]; % The index of image in validation set
nPairs = 3; % number of visualize data. maximum is 3
% nPairs = length(data_idx); 
visualise_verification(va_img_pair,prob,Yva,data_idx,nPairs )
