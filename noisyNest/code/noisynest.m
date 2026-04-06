%% This script presents frequency discrimination stimuli
sca;
clear all; 
clc;
%% Add paths
addpath(genpath("\\cup\gomez\data\auditory_behavior\freq_discrimination\code"))
%% Set subject parameters
sub = "test";
age = 'adults';
dataDir = "\noisyNest\data";
cd(fullfile(dataDir,age))
mkdir(sub)

%% Set some flags for stimulus presentation
% condition key:  
% 1) 150 Hz Notched Spectrum
% 2) 150 Hz Flat Spectrum
% 3) 2000 Hz Notched Spectrum
% 4) 2000 Hz Flat Spectrum
% 5) 4000 Hz Notched Spectrum
% 6) 4000 Hz Flat Spectrum

% If not completing entire experiment, choose a condition
conditions = [1,2,3,4,5,6]; 

% If not completing entire experiment, skip the demo (unless it is the
% first block), skip the practice trials and skip the instructions at the
% start of the experiment

skipStartExpInstructions = false;
skipDemo = false;
skipPractice = false;

% Only do demo if first block 
if sum(ismember(conditions, 1))
    skipPractice = true;
    skipStartExpInstructions = false;
    skipDemo = false;
else
    skipPractice = true;
    skipStartExpInstructions = true;
    skipDemo = true;
end

test_threshold = false; 
skipDemo = false; 
%% Load stimulus matrix
cd("\\noisyNest/code")
addpath(genpath("\noisyNest/code"))
load("stim_mat.mat")

%% Choose staircase method
staircase_method = "QuestPlus"; 

%% Set some parameters
fs = 44100;
stim_dur = 0.5; % seconds
iti = 0.5; % seconds

% Initialize dB_mat (if first run), otherwise load existing matrix
cd(fullfile(dataDir,age,sub))
allFiles = dir(); 
allFileNames = extractfield(allFiles,"name"); 
if ~contains(allFileNames,"data.mat")
    save("data.mat","dB_mat")
else
    load("data.mat","dB_mat")
end

% Initialize score matrix (if first run), otherwise load existing matrix 
variableInfo = who('-file', 'data.mat');
if ~ismember('score',variableInfo)
    score = zeros(size(stim_mat,1),size(stim_mat,2));c
    save("data.mat","score","-append")
else
    load("data.mat","score")
end

if strcmp(staircase_method, "QuestPlus")
    if ~ismember('thresholds',variableInfo)
        thresholds = zeros(size(stim_mat,1),1);
    else
        load("data.mat","thresholds")

    end
    if ~ismember('num_qp_trials',variableInfo)
        num_qp_trials =  zeros(size(stim_mat,1),1);
    else
        load("data.mat","num_qp_trials")
    end
end

% Load negative feedback audio
cd('\\cup\gomez\data\auditory_behavior\freq_discrimination\audio')
[no_y,fs] = audioread("no.wav");

%% Psychtoolbox Set Up
        
Screen('Preference', 'SkipSyncTests', 1);  % Set to 1 only if you're debugging
PsychDefaultSetup(2);
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseBeampositionQueryWorkaround');

screens = Screen('Screens');
screenNumber = max(screens);

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, 0.5);

% Get the size of the on screen window
[screenX, screenY] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Setup the text type for the window
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 36);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Change cursor type
ShowCursor('Hand')

% Load images of 3 cartoon eggs
cd('\\noisyNest\images')
files = dir();
fileNames = extractfield(files,"name");
eggs = fileNames(contains(fileNames,"egg_"));

% Randomize eggs
eggs = eggs(randperm(length(eggs)));

% Number of eggs that will be displayed each trial
numEggs = 3;

% Load image of nest
nest= "nest.png";

% Load image of bird
bird = "bird.png";

% Load image of mama bird
mama_bird = "mama_bird.png";

% Set starting position for the images (left to right)
eggxPositions = linspace(screenX * 0.275, screenX * 0.725, numEggs); % Horizontal positions
nestxPosition = eggxPositions (2);
mamaBirdxPosition = eggxPositions(2);

% Load images and get their initial sizes
eggImages = cell(1, numEggs);
eggTexs = zeros(1, numEggs);
eggOriginalSizes = zeros(numEggs, 2); % Store original sizes

cd("\\noisyNest/images")
% Eggs
for i = 1:numEggs
    [img, ~, alpha] = imread(eggs{i}); % Read the image - make sure background is transparent
    img(:,:,4) = alpha;
    eggImages{i} = img;
    eggTexs(i) = Screen('MakeTexture', window, eggImages{i}); % Create textures from images
    eggOriginalSizes(i, :) = size(eggImages{i}, 1:2); % Store the original width and height
end

eggHeight = eggOriginalSizes(1,1);
eggWidth = eggOriginalSizes(1,2);

% Nest
[img, ~, alpha] = imread(nest);
img(:,:,4) = alpha;
nestImage = img; % Read the image
nestTex = Screen('MakeTexture', window, nestImage); % Create texture from image
nestOriginalSize = size(nestImage);

nestHeight = nestOriginalSize(1);
nestWidth = nestOriginalSize(2);

% Bird
[img, ~, alpha] = imread(bird);
img(:,:,4) = alpha;
birdImage = img; % Read the image
birdTex = Screen('MakeTexture', window, birdImage); % Create texture from image
birdOriginalSize = size(birdImage);
birdHeight = birdOriginalSize(1);
birdWidth = birdOriginalSize(2);

% Mama bird
[img, ~, alpha] = imread(mama_bird);
img(:,:,4) = alpha;
mamaBirdImage = img; % Read the image
mamaBirdTex = Screen('MakeTexture', window, mamaBirdImage); % Create texture from image
mamaBirdOriginalSize = size(mamaBirdImage);
mamaBirdHeight = mamaBirdOriginalSize(1);
mamaBirdWidth = mamaBirdOriginalSize(2);

% Define the rectangle to display the image
eggRect = zeros(numEggs,4);
birdRect = zeros(numEggs,4);
for i = 1:numEggs
    eggRect(i,:) = [round(eggxPositions(i)-eggWidth/4 + 10), round(screenY*0.45  - eggHeight/4 + 10), round(eggxPositions(i) + eggWidth/4 - 10), round(screenY*0.45  + eggHeight/4 - 10)];
    birdRect(i,:) = [round(eggxPositions(i)-eggWidth/3.5), round(screenY*0.45  - eggHeight/3.5), round(eggxPositions(i) + eggWidth/3.5), round(screenY*0.45  + eggHeight/3.5)];
end
nestRect = [round(nestxPosition - nestWidth/2.5), round(screenY*0.6  - nestHeight/2.5), round(nestxPosition + nestWidth/2.5), round(screenY*0.6  + nestHeight/2.5)];
mamaBirdRect = [round(mamaBirdxPosition - mamaBirdWidth/7), round(screenY*0.6  - mamaBirdHeight/7), round(mamaBirdxPosition + mamaBirdWidth/7), round(screenY*0.6  + mamaBirdHeight/7)];

%% PsychPort Audio Initialization

% Initialize PsychPort Audio
InitializePsychSound()
panhandle = PsychPortAudio('Open',3,[],[],fs,2);

%% Demo - Show 2 eggs, one with noise + target and another with just noise

if ~skipDemo

    % Display text
    startText = sprintf('%s',"Press the spacebar to start");
    DrawFormattedText(window, startText,'center',screenY*0.5);

    % Flip the Screen
    Screen('Flip',window)

    % Wait for space bar press to start
    while true
        [keyIsDown, ~, keyCode] = KbCheck; % Check for key press
        if keyIsDown && keyCode(KbName('space')) % If space is pressed
            break; % Exit loop and proceed
        end
    end

    % Record experiment length
    startExpTime =  GetSecs();

    % Instructions
    instructionsText = sprintf('%s',["Mama bird has been patiently nesting all spring.\n"...
        "\n"...
        "Now it looks like some of her eggs are getting ready to hatch!\n"...
        "\n"...
        "Help mama bird figure out which of her eggs are ready to become hatchlings."]);
    continueText = sprintf('%s',"Press the spacebar to continue");

    % Draw text
    DrawFormattedText(window, instructionsText,'center',screenY*0.15);
    DrawFormattedText(window, continueText,'center',screenY*0.85);

    % Draw mama bird
    Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

    % Flip the Screen
    Screen('Flip',window)
    WaitSecs(0.5)

    % Clear any key presses
    clear KbCheck

    % Wait for space bar press to continue
    while true
        [keyIsDown, ~, keyCode] = KbCheck; % Check for key press
        if keyIsDown && keyCode(KbName('space')) % If space is pressed
            break; % Exit loop and proceed
        end
    end

    % Instructions continued
    instructionsText = sprintf('%s',["On the next screen you will see 2 eggs in Mama bird's nest.\n"...
        "\n"...
        "Only one egg is ready to hatch, and it will make a chirping sound.\n"...
        "\n"...
        "Listen closely for that egg!\n"]);

    continueText = sprintf('%s',"Press the spacebar to continue");

    % Draw text
    DrawFormattedText(window, instructionsText,'center',screenY*0.15);
    DrawFormattedText(window, continueText,'center',screenY*0.85);

    % Draw mama bird
    Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

    % Flip the Screen
    Screen('Flip',window)
    WaitSecs(0.5)

    % Clear any key presses
    clear KbCheck

    % Wait for space bar press to continue
    while true
        [keyIsDown, ~, keyCode] = KbCheck; % Check for key press
        if keyIsDown && keyCode(KbName('space')) % If space is pressed
            break; % Exit loop and proceed
        end
    end

    % Choose 150 Hz notched noise condition for the demo (condition_order = 1)
    i = 1;

    % Choose a random trial
    j = randi(size(stim_mat,2));

    % Define example trial for demo
    ex_trial = stim_mat{i,j,:};
    target_idx = corr_mat(i,j);
    target = ex_trial(target_idx);
    idxs = 1:3;
    noise_idxs = idxs;
    noise_idxs(target_idx) = [];
    noise_idx = noise_idxs(1);

    % Define rectangles to display to eggs
    demoEggRect = eggRect([1,3],:);
    demoBirdRect = birdRect([1,3],:);

    % Draw images (just 2 eggs for simplification and nest)
    Screen('DrawTexture',window,nestTex,[],nestRect);
    % for k = [1,2];
    %     Screen('DrawTexture', window,eggTexs(k),[],demoEggRect(k,:));
    % end

    % Draw Text
    text = sprintf('%s',"Listen for the egg that is ready to hatch!");
    DrawFormattedText(window, text,'center',screenY*0.1);

    % Flip to the screen to show the images
    Screen('Flip', window);

    % Animation settings - each egg will shake when clicke
    numShakes = 100; % Number of shaking frames
    shakeMagnitude = 10; % Max pixel displacement for the shake effect
    shakeSpeed = 0.1; % Speed of shaking (higher is faster)

    % Number of demo trials
    numDemoTrials = 3;
    numDemoRepeats = 3; % number of times each egg will make sound 

    for n = 1:numDemoTrials

        % Randomize eggs
        eggs = eggs(randperm(length(eggs)));

        % Make textures
        cd('\\noisyNest\images')
        for e = 1:numEggs
            [img, ~, alpha] = imread(eggs{e}); % Read the image - make sure background is transparent
            img(:,:,4) = alpha;
            eggImages{e} = img;
            eggTexs(e) = Screen('MakeTexture', window, eggImages{e}); % Create textures from images
        end

        % Randomize which egg is the target or distractor
        demo_egg_order = [1,2];
        demo_egg_order = demo_egg_order(randperm(length(demo_egg_order)));

        distractor_rect_idx = demo_egg_order(1);
        target_rect_idx = demo_egg_order(2);

        for r = 1:numDemoRepeats

            % Wait some time to display text
            WaitSecs(1)
    
            % Play the distractor
    
            % Load audio
            y_noise = stim_mat(i,j,noise_idx);
            y_noise = y_noise{1};
            y_noise = reshape(y_noise,size(y_noise,2),size(y_noise,3));
            y_noise = sum(y_noise,2);
    
            % Trim audio
            y_noise = y_noise(1:stim_dur*fs);
    
            % 2 audio channels
            y_noise = [y_noise,y_noise];
            y_noise = y_noise';
    
            % Load audio into buffer
            PsychPortAudio('FillBuffer',panhandle,y_noise);
    
            % Start playback
            PsychPortAudio( 'Start',panhandle,1,0,1)
    
            % Start the animation loop
            start = GetSecs();
    
            % Animate for the duration of the stimulus
            while GetSecs() - start < stim_dur
                % Randomly generate offsets for shaking
                offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)
    
                % Draw nest
                Screen('DrawTexture',window,nestTex,[],nestRect);
    
                % Draw shaking egg
                Screen('DrawTexture', window, eggTexs(distractor_rect_idx), [], [demoEggRect(distractor_rect_idx,1) + offsetX, demoEggRect(distractor_rect_idx,2) + offsetY, demoEggRect(distractor_rect_idx,3) + offsetX, demoEggRect(distractor_rect_idx,4) + offsetY]);
    
                % Draw the other egg
                Screen('DrawTexture', window, eggTexs(target_rect_idx), [],demoEggRect(target_rect_idx,:));
    
                % Draw text
                DrawFormattedText(window, text,'center',screenY*0.1);
    
                % Flip the screen to show the new frame
                Screen('Flip', window);
            end
    
            % Wait a little bit before presenting target
            WaitSecs(0.25)
    
            % Play the target
            y_target = stim_mat(i,j,target_idx);
            y_target = y_target{1};
            y_target = reshape(y_target,size(y_target,2),size(y_target,3));
    
            % Adjust dB of the sound to original SPL_dB
            y_target(:,2) = y_target(:,2) * 1/scaling_factors(i);
    
            % 2 channels
            y_target = sum(y_target,2);
            y_target = y_target';
    
            % Trim audio
            y_target = y_target(1:stim_dur*fs);
            y_target = [y_target;y_target];
    
            % Load audio into buffer
            PsychPortAudio('FillBuffer',panhandle,y_target);
    
            % Start playback
            PsychPortAudio('Start',panhandle,1,0,1)
    
            % Start the animation loop
            start = GetSecs();
    
            % Animate for the duration of the stimulus
            while GetSecs() - start < stim_dur
                % Randomly generate offsets for shaking
                offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)
    
                % Draw nest
                Screen('DrawTexture',window,nestTex,[],nestRect);
    
                % Draw shaking egg
                Screen('DrawTexture', window, eggTexs(target_rect_idx), [], [demoEggRect(target_rect_idx,1) + offsetX, demoEggRect(target_rect_idx,2) + offsetY, demoEggRect(target_rect_idx,3) + offsetX, demoEggRect(target_rect_idx,4) + offsetY]);
    
                % Draw the other egg
                Screen('DrawTexture', window, eggTexs(distractor_rect_idx), [],demoEggRect(distractor_rect_idx,:));
    
                % Draw text
                DrawFormattedText(window, text,'center',screenY*0.1);
    
                % Flip the screen to show the new frame
                Screen('Flip', window);
            end
    
            % Draw images
            Screen('DrawTexture',window,nestTex,[],nestRect);
            Screen('DrawTexture', window,eggTexs(distractor_rect_idx),[],demoEggRect(distractor_rect_idx,:));
            if r < numDemoRepeats
                Screen('DrawTexture', window,eggTexs(target_rect_idx),[],demoEggRect(target_rect_idx,:));
            else
                Screen('DrawTexture',window,birdTex,[],demoBirdRect(target_rect_idx,:))
            end

            % Draw text
            DrawFormattedText(window, text,'center',screenY*0.1);
    
            % Flip the screen
            Screen('Flip',window)
    
            % Display images for 1 sec
            WaitSecs(0.5)
        end

        % Wait a couple of seconds to reveal target egg 
        WaitSecs(2)
        
        % Press spacebar to continue

        % Draw Text
        DrawFormattedText(window, continueText,'center',screenY*0.85);

        % Flip the screen
        Screen('Flip',window) % Flip Screen
        WaitSecs(0.5)

        % Clear any key presses
        clear KbCheck

        % Wait for space bar press
        while true
            [keyIsDown, ~, keyCode] = KbCheck; % Check for key
            if keyIsDown && keyCode(KbName('space')) % If space is pressed
                break; % Exit loop and proceed
            end
        end

        
    end

    % Wait 1 second
    WaitSecs(1)
end
%% Practice

if ~skipPractice

    % Display Practice Instructions
    practiceText = sprintf('%s',["Next you will see 3 eggs in Mama bird's nest.\n"...
        "\n"...
        "Only one egg is ready to hatch, and it will make a chirping sound like before.\n"...
        "\n"...
        "You will hear each egg once. Then click on the egg that is ready to hatch.\n"...
        "\n"...
        "Let's practice!"]);

    % Continue Text
    continueText = sprintf('%s',"Press the spacebar to practice");

    % Draw Text
    DrawFormattedText(window, practiceText,'center',screenY*0.15);
    DrawFormattedText(window, continueText,'center',screenY*0.85);

    % Draw mama bird
    Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

    % Flip the screen
    Screen('Flip',window) % Flip Screen
    WaitSecs(0.5)

    % Clear any key presses
    clear KbCheck

    % Wait for space bar press
    while true
        [keyIsDown, ~, keyCode] = KbCheck; % Check for key
        if keyIsDown && keyCode(KbName('space')) % If space is pressed
            break; % Exit loop and proceed
        end
    end

    % Loop through 5 practice trials
    numPracticeTrials = 5;
    practice_score = zeros(1,numPracticeTrials);

    for t = 1:numPracticeTrials

        % Choose 150 Hz notched noise condition
        i = 1;

        % Choose a random trial
        j = randi(size(stim_mat,2));

        % Choose 3 random eggs
        eggs = [eggImgMat{i,j,:}];

        % Make textures
        cd('\\noisyNest\images')
        for e = 1:numEggs
            [img, ~, alpha] = imread(eggs{e}); % Read the image - make sure background is transparent
            img(:,:,4) = alpha;
            eggImages{e} = img;
            eggTexs(e) = Screen('MakeTexture', window, eggImages{e}); % Create textures from images
        end

        % Loop through each stimulus 2x
        numRepeats = 1;

        for r = 1:numRepeats

            for k = 1:size(stim_mat,3)

                % Load audio
                y = stim_mat(i,j,k);
                y = cell2mat(y);

                % Adjust dB of the target to original SPL_dB
                if k == corr_mat(i,j)
                    y(:,:,2) = y(:,:,2) * 1/scaling_factors(i);
                end

                % Add noise and target signals (target is just array of zeros
                % in noise conditions)
                y = sum(y,3);

                % Trim audio
                y = y(1:stim_dur*fs);

                % 2 audio channels
                y = [y;y];

                % Load audio into buffer
                PsychPortAudio('FillBuffer',panhandle,y);

                % Start playback
                PsychPortAudio('Start',panhandle,1,0,1)

                % Animate for the duration of the stimulus
                start = GetSecs();
                while GetSecs() - start < stim_dur
                    % Randomly generate offsets for shaking
                    offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                    offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)

                    % Draw nest
                    Screen('DrawTexture',window,nestTex,[],nestRect);

                    % Draw all the eggs
                    for n = 1:numEggs
                        Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
                    end

                    % Draw shaking egg
                    Screen('DrawTexture', window, eggTexs(k), [], [eggRect(k,1) + offsetX, eggRect(k,2) + offsetY, eggRect(k,3) + offsetX, eggRect(k,4) + offsetY]);

                    % Draw text
                    listenText = 'Listen!';
                    DrawFormattedText(window, listenText,'center',screenY*0.1);

                    % Flip the screen to show the new frame
                    Screen('Flip', window);

                end
                % Wait some time before each stimulus presentation
                WaitSecs(iti)
            end
        end

        % Draw nest and eggs in original position
        Screen('DrawTexture',window,nestTex,[],nestRect);
        for n = 1:numEggs
            Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
        end

        % Draw Text
        questionText = sprintf('%s',"Which egg is ready to hatch?");
        DrawFormattedText(window, questionText,'center',screenY*0.1);

        % Flip the screen to show the images
        Screen('Flip', window)

        % Wait for click
        valid_click = 0;

        while ~valid_click
            [clicks,x_click,y_click,whichButton,clickSecs] = GetClicks(window,[],[]);

            % Correct response and associated rectangle
            corr_resp = corr_mat(i,j);
            corr_rect = eggRect(corr_resp,:);

            for p = 1:length(eggImages)

                % Check if click was valid (was in one of the rectangles)
                if ismember(x_click,eggRect(p,1):eggRect(p,3)) && ismember(y_click,eggRect(p,2):eggRect(p,4))
                    valid_click = 1;
                end
            end

            % Check if click was correct
            if valid_click

                % Correct response
                if ismember(x_click,corr_rect(1):corr_rect(3)) && ismember(y_click,corr_rect(2):corr_rect(4))

                    % Record response
                    corr = 1;
                    practice_score(t) = corr;

                    % Display correct feedback

                    % Draw nest
                    Screen('DrawTexture',window,nestTex,[],nestRect);

                    % Draw all the eggs except correct one
                    for n = 1:numEggs
                        if n==corr_resp
                        else
                            Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
                        end
                    end

                    % Draw bird
                    Screen('DrawTexture',window,birdTex,[],birdRect(corr_resp,:))

                    % Flip to the screen
                    Screen('Flip', window);

                else
                    % Display incorrect feedback

                    % Draw nest
                    Screen('DrawTexture',window,nestTex,[],nestRect);


                    % Draw all the eggs
                    for n = 1:numEggs
                        Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
                    end

                    % Flip to the screen
                    Screen('Flip', window);

                    WaitSecs(0.5);

                    % Give negative feedback (audio of child saying "No!")

                    % Load audio into buffer
                    PsychPortAudio('FillBuffer',panhandle,no_y');

                    % Start playback
                    PsychPortAudio('Start',panhandle,1,0,1)
                    WaitSecs(length(y)/fs)

                end
            end
        end

    end
end
%% Start Experiment Instructions

if ~skipStartExpInstructions

    % Display text to start task
    startText = sprintf('%s',["Great job! We will now get started with the task.\n"...
        "\n"...
        "Your job is the same. Find the egg that is ready to hatch.\n"...
        "\n"...
        "Sometimes the hatchling will be difficult to hear but just try your best!"]);

    % Continue Text
    continueText = sprintf('%s',"Press the spacebar to start");

    % Draw Text
    DrawFormattedText(window, startText,'center',screenY*0.15);
    DrawFormattedText(window, continueText,'center',screenY*0.85);

    % Flip the screen
    Screen('Flip',window) % Flip Screen

    % Clear any key presses
    clear KbCheck

    % Wait for space bar press
    while true
        [keyIsDown, ~, keyCode] = KbCheck; % Check for key
        if keyIsDown && keyCode(KbName('space')) % If space is pressed
            break; % Exit loop and proceed
        end
    end
end

%% Present Stimuli

% If condition flag was not provided, loop through all the blocks
if isempty(conditions)
    conditions = 1:6;
end

% Loop through each condition
for i = conditions

    % Reset score
    score(i,:) = zeros(1,size(stim_mat,2)); 

    % Include a few demo trials at the beginning of each block except for
    % first

    if ismember(i,[2,3,4,5,6])

        % Demo instructions
        DemoText = sprintf('%s',["On the next screen you will see 2 eggs in Mama bird's nest.\n"...
            "\n"...
            "Only one egg is ready to hatch, and it will make a chirping sound.\n"...
            "\n"...
            "Listen closely!\n"]);

        continueText = sprintf('%s',"Press the spacebar to continue");

        % Draw text
        DrawFormattedText(window, DemoText,'center',screenY*0.15);
        DrawFormattedText(window, continueText,'center',screenY*0.85);

        % Draw mama bird
        Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

        % Flip the Screen
        Screen('Flip',window)
        WaitSecs(0.5)

        % Clear any key presses
        clear KbCheck

        % Wait for space bar press to continue
        while true
            [keyIsDown, ~, keyCode] = KbCheck; % Check for key press
            if keyIsDown && keyCode(KbName('space')) % If space is pressed
                break; % Exit loop and proceed
            end
        end

        % Choose a random trial
        j = randi(size(stim_mat,2));

        % Define example trial for demo
        ex_trial = stim_mat{i,j,:};
        target_idx = corr_mat(i,j);
        target = ex_trial(target_idx);
        idxs = 1:3;
        noise_idxs = idxs;
        noise_idxs(target_idx) = [];
        noise_idx = noise_idxs(1);

        % Define rectangles to display to eggs
        demoEggRect = eggRect([1,3],:);
        demoBirdRect = birdRect([1,3],:);

        % Randomize eggs
        eggs = eggs(randperm(length(eggs)));

        % Make textures
        cd('\\noisyNest\images')
        for e = 1:numEggs
            [img, ~, alpha] = imread(eggs{e}); % Read the image - make sure background is transparent
            img(:,:,4) = alpha;
            eggImages{e} = img;
            eggTexs(e) = Screen('MakeTexture', window, eggImages{e}); % Create textures from images
        end

        % Draw images (just 2 eggs for simplification and nest)
        Screen('DrawTexture',window,nestTex,[],nestRect);
        for k = [1,2];
            Screen('DrawTexture', window,eggTexs(k),[],demoEggRect(k,:));
        end

        % Draw Text
        text = sprintf('%s',"Listen for the egg that is ready to hatch!");
        DrawFormattedText(window, text,'center',screenY*0.1);

        % Flip to the screen to show the images
        Screen('Flip', window);

        % Animation settings - each egg will shake when clicke
        numShakes = 100; % Number of shaking frames
        shakeMagnitude = 10; % Max pixel displacement for the shake effect
        shakeSpeed = 0.1; % Speed of shaking (higher is faster)

        % Alternate between each egg

        % Randomize which egg is the target or distractor
        demo_egg_order = [1,2];
        demo_egg_order = demo_egg_order(randperm(length(demo_egg_order)));

        distractor_rect_idx = demo_egg_order(1);
        target_rect_idx = demo_egg_order(2);

        % Number of demo trials
        numDemoTrials = 3;
        for n = 1:numDemoTrials

            % Wait some time to display text
            WaitSecs(2)


            % Play the distractor

            % Load audio
            y_noise = stim_mat(i,j,noise_idx);
            y_noise = y_noise{1};
            y_noise = reshape(y_noise,size(y_noise,2),size(y_noise,3));
            y_noise = sum(y_noise,2);

            % Trim audio
            y_noise = y_noise(1:stim_dur*fs);

            % 2 audio channels
            y_noise = [y_noise,y_noise];
            y_noise = y_noise';

            % Load audio into buffer
            PsychPortAudio('FillBuffer',panhandle,y_noise);

            % Start playback
            PsychPortAudio( 'Start',panhandle,1,0,1)

            % Start the animation loop
            start = GetSecs();

            % Animate for the duration of the stimulus
            while GetSecs() - start < stim_dur
                % Randomly generate offsets for shaking
                offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)

                % Draw nest
                Screen('DrawTexture',window,nestTex,[],nestRect);

                % Draw shaking egg
                Screen('DrawTexture', window, eggTexs(distractor_rect_idx), [], [demoEggRect(distractor_rect_idx,1) + offsetX, demoEggRect(distractor_rect_idx,2) + offsetY, demoEggRect(distractor_rect_idx,3) + offsetX, demoEggRect(distractor_rect_idx,4) + offsetY]);

                % Draw the other egg
                Screen('DrawTexture', window, eggTexs(target_rect_idx), [],demoEggRect(target_rect_idx,:));

                % Draw text
                DrawFormattedText(window, text,'center',screenY*0.1);

                % Flip the screen to show the new frame
                Screen('Flip', window);
            end

            % Wait a little bit before presenting target
            WaitSecs(0.5)

            % Play the target

            y_target = stim_mat(i,j,target_idx);
            y_target = y_target{1};
            y_target = reshape(y_target,size(y_target,2),size(y_target,3));

            % Adjust dB of the sound to original SPL_dB
            y_target(:,2) = y_target(:,2) * 1/scaling_factors(i);

            % 2 channels
            y_target = sum(y_target,2);
            y_target = y_target';

            % Trim audio
            y_target = y_target(1:stim_dur*fs);
            y_target = [y_target;y_target];

            % Load audio into buffer
            PsychPortAudio('FillBuffer',panhandle,y_target);

            % Start playback
            PsychPortAudio('Start',panhandle,1,0,1)

            % Start the animation loop
            start = GetSecs();

            % Animate for the duration of the stimulus
            while GetSecs() - start < stim_dur
                % Randomly generate offsets for shaking
                offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)

                % Draw nest
                Screen('DrawTexture',window,nestTex,[],nestRect);

                % Draw shaking egg
                Screen('DrawTexture', window, eggTexs(target_rect_idx), [], [demoEggRect(target_rect_idx,1) + offsetX, demoEggRect(target_rect_idx,2) + offsetY, demoEggRect(target_rect_idx,3) + offsetX, demoEggRect(target_rect_idx,4) + offsetY]);

                % Draw the other egg
                Screen('DrawTexture', window, eggTexs(distractor_rect_idx), [],demoEggRect(distractor_rect_idx,:));

                % Draw text
                DrawFormattedText(window, text,'center',screenY*0.1);

                % Flip the screen to show the new frame
                Screen('Flip', window);
            end

            % Draw images
            Screen('DrawTexture',window,nestTex,[],nestRect);
            Screen('DrawTexture', window,eggTexs(distractor_rect_idx),[],demoEggRect(distractor_rect_idx,:));
            Screen('DrawTexture',window,birdTex,[],demoBirdRect(target_rect_idx,:))

            % Flip the screen
            Screen('Flip',window)

            % Display the bird for 1 sec
            WaitSecs(1)

            if n < numDemoTrials
                % Draw images
                Screen('DrawTexture',window,nestTex,[],nestRect);

                for k = [1,2]
                    Screen('DrawTexture', window,eggTexs(k),[],demoEggRect(k,:));
                end

                % Draw text
                DrawFormattedText(window, text,'center',screenY*0.1);

                % Flip the screen
                Screen('Flip',window)
            end
        end

        % Wait 1 second
        WaitSecs(1)

        % Display Instructions
        instructionsText = sprintf('%s',["Next you will see 3 eggs in Mama bird's nest.\n"...
            "\n"...
            "Only one egg is ready to hatch, and it will make a chirping sound like before.\n"...
            "\n"...
            "You will hear each egg once. Then click on the egg that is ready to hatch.\n"]);

        % Continue Text
        continueText = sprintf('%s',"Press the spacebar to continue");

        % Draw Text
        DrawFormattedText(window, instructionsText,'center',screenY*0.15);
        DrawFormattedText(window, continueText,'center',screenY*0.85);

        % Draw mama bird
        Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

        % Flip the screen
        Screen('Flip',window) % Flip Screen
        WaitSecs(0.5)

        % Clear any key presses
        clear KbCheck

        % Wait for space bar press
        while true
            [keyIsDown, ~, keyCode] = KbCheck; % Check for key
            if keyIsDown && keyCode(KbName('space')) % If space is pressed
                break; % Exit loop and proceed
            end
        end

    end

    % Continue with experiment
    %% QuestPlus Staircase Method
    if(strcmp(staircase_method,"QuestPlus"))

        % Set up the stimulus domain (e.g., 30 dB SPL to 100 dB SPL)
        stimDomain = 30:4:102;
        threshold_values =  30:4:102; %30:100;
        paramDomain = {threshold_values};

        % Define likelihood function
        % modelF = @(stim, threshold) toneInNoise_Weibull(stim, threshold, 0.25, 0.33, 0.05);% (slope fixed at 1, lapse = 0, guess = 0.02)
        modelF = @(stim, threshold) toneInNoise_Weibull(stim, threshold, 1.5, 0.33, 0.05);% (slope fixed at 2, lapse = 0, guess = 0.02)

        % Define other parameters like response domain, stopping rule, etc.
        respDomain = [0, 1];             % Binary response: 0 = "no", 1 = "yes"
        stopRule = 'entropy';              % Stopping rule: stop when entropy is small enough
        stopCriterion = 3;             % Threshold for stopping (usuall 3)
        minNTrials = 19;                 % Minimum number of trials
        maxNTrials = 25;                % Maximum number of trials

        % Guesses for thresholds (prior)
        thresh_guess = [44,65,57,74,64,80];

        % Define the QUEST Plus object
        qp = QuestPlus(modelF, stimDomain, paramDomain, respDomain, stopRule, stopCriterion, minNTrials, maxNTrials);

        % % Define priors for each parameter
        % mu_thresh = thresh_guess(i);
        % sigma_thresh = 5;
        % prior_thresh = exp(-(threshold_values - mu_thresh).^2 / (2 * sigma_thresh^2));
        % prior_thresh = prior_thresh / sum(prior_thresh);
        % prior_thresh = prior_thresh(:);  % [71 x 1]
        
        % Initialize qp object
        % qp.initialise(prior_thresh');  % force column vectors
        qp.initialise();  % force column vectors

        % Initialize dB
        dB_init = dB_mat(i,1);
        dB = dB_init;

        % Run the experiment: Iterate through trials
        for j = 1:qp.maxNTrials

            % Initialize correct response variable
            corr = 0;

            % Load egg images from egg image matrix
            eggs = [eggImgMat{i,j,:}];

            % Make textures
            cd('\\noisyNest\images')
            for e = 1:numEggs
                [img, ~, alpha] = imread(eggs{e}); % Read the image - make sure background is transparent
                img(:,:,4) = alpha;
                eggImages{e} = img;
                eggTexs(e) = Screen('MakeTexture', window, eggImages{e}); % Create textures from images
            end

            % Loop through each stimulus 1x
            numRepeats = 1;
            for r = 1:numRepeats

                for k = 1:size(stim_mat,3)

                    % Load audio
                    y_orig = stim_mat(i,j,k);
                    y_orig = cell2mat(y_orig);

                    % Add noise and target signals (target is just array of zeros
                    % in noise conditions)
                    y = sum(y_orig,3);

                    % Shorten the signal
                    new_stim_dur = 0.5;
                    y = y(1:new_stim_dur*fs);

                    % 2 audio channels
                    y = [y;y];

                    % Load audio into buffer
                    PsychPortAudio('FillBuffer',panhandle,y);

                    % Start playback
                    PsychPortAudio('Start',panhandle,1,0,1)

                    % Animate for the duration of the stimulus

                    % Animation settings - each egg will shake when clicke
                    numShakes = 100; % Number of shaking frames
                    shakeMagnitude = 10; % Max pixel displacement for the shake effect
                    shakeSpeed = 0.1; % Speed of shaking (higher is faster)

                    start = GetSecs();
                    while GetSecs() - start < new_stim_dur
                        % Randomly generate offsets for shaking
                        offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                        offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)

                        % Draw nest
                        Screen('DrawTexture',window,nestTex,[],nestRect);

                        % Draw all the eggs
                        for n = 1:numEggs
                            Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
                        end

                        % Draw shaking egg
                        Screen('DrawTexture', window, eggTexs(k), [], [eggRect(k,1) + offsetX, eggRect(k,2) + offsetY, eggRect(k,3) + offsetX, eggRect(k,4) + offsetY]);

                        % Draw text
                        listenText = 'Listen!';
                        DrawFormattedText(window, listenText,'center',screenY*0.1);

                        % Flip the screen to show the new frame
                        Screen('Flip', window);
                    end

                    % Wait some time before each stimulus presentation
                    WaitSecs(iti)
                end
            end

            % Draw nest and eggs in original position
            Screen('DrawTexture',window,nestTex,[],nestRect);
            for n = 1:numEggs
                Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
            end

            % Draw Text
            questionText = sprintf('%s',"Which egg is about to hatch?");
            DrawFormattedText(window, questionText,'center',screenY*0.1);

            % Flip the screen to show the images
            Screen('Flip', window)

            % Wait until all buttons are released before starting
            [~, ~, buttons] = GetMouse;
            while any(buttons)
                [~, ~, buttons] = GetMouse;
                WaitSecs(0.01);
            end

            % Start timer
            timer = GetSecs();
            numSecs = 10;
            responded = false;

            while GetSecs() - timer < numSecs && ~responded
                [x_click, y_click, buttons] = GetMouse;

                if any(buttons)
                    % Only process the first click and ignore continuous holding
                    % Wait for release before proceeding to next trial
                    for p = 1:length(eggImages)
                        if x_click >= eggRect(p,1) && x_click <= eggRect(p,3) && ...
                                y_click >= eggRect(p,2) && y_click <= eggRect(p,4)

                            responded = true;
                            corr_resp = corr_mat(i,j);
                            corr_rect = eggRect(corr_resp,:);

                            if x_click >= corr_rect(1) && x_click <= corr_rect(3) && ...
                                    y_click >= corr_rect(2) && y_click <= corr_rect(4)
                                corr = 1;
                                score(i,j) = corr;

                                % Feedback: correct
                                Screen('DrawTexture', window, nestTex, [], nestRect);
                                for n = 1:numEggs
                                    if n ~= corr_resp
                                        Screen('DrawTexture', window, eggTexs(n), [], eggRect(n,:));
                                    end
                                end
                                Screen('DrawTexture', window, birdTex, [], birdRect(corr_resp,:));
                                Screen('Flip', window);
                            else
                                % Feedback: incorrect
                                Screen('DrawTexture', window, nestTex, [], nestRect);
                                for n = 1:numEggs
                                    Screen('DrawTexture', window, eggTexs(n), [], eggRect(n,:));
                                end
                                Screen('Flip', window);
                                PsychPortAudio('FillBuffer', panhandle, no_y');
                                PsychPortAudio('Start', panhandle, 1, 0, 1);
                                WaitSecs(1);
                            end

                            WaitSecs(1);  % Hold feedback
                            break;
                        end
                    end

                    % Wait for mouse release before accepting new clicks (prevents multiple triggers)
                    while any(buttons)
                        [~, ~, buttons] = GetMouse;
                        WaitSecs(0.01);
                    end
                end

                WaitSecs(0.01);  % Polling delay
            end


            % % Wait until all mouse buttons are released
            % [~, ~, buttons] = GetMouse;
            % while any(buttons)
            %     [~, ~, buttons] = GetMouse;
            % end
            % % Wait for click
            % valid_click = 0;
            % 
            % % Start timer
            % timer = GetSecs();
            % numSecs = 10; 
            % responded = false;
            % 
            % while GetSecs() - timer < numSecs && ~responded
            %     [~, ~, buttons] = GetMouse(window);  % Just check for any mouse press
            % 
            %     if any(buttons)
            %         % Only call GetClicks if button is down (avoids blocking)
            %         [clicks, x_click, y_click, whichButton, clickSecs] = GetClicks(window, 0);
            % 
            %         % Validate click location
            %         for p = 1:length(eggImages)
            %             if x_click >= eggRect(p,1) && x_click <= eggRect(p,3) && ...
            %                     y_click >= eggRect(p,2) && y_click <= eggRect(p,4)
            % 
            %                 responded = true;
            %                 corr_resp = corr_mat(i,j);
            %                 corr_rect = eggRect(corr_resp,:);
            % 
            %                 if x_click >= corr_rect(1) && x_click <= corr_rect(3) && ...
            %                         y_click >= corr_rect(2) && y_click <= corr_rect(4)
            %                     corr = 1;
            %                     score(i,j) = corr;
            % 
            %                     % Feedback: correct
            %                     Screen('DrawTexture', window, nestTex, [], nestRect);
            %                     for n = 1:numEggs
            %                         if n ~= corr_resp
            %                             Screen('DrawTexture', window, eggTexs(n), [], eggRect(n,:));
            %                         end
            %                     end
            %                     Screen('DrawTexture', window, birdTex, [], birdRect(corr_resp,:));
            %                     Screen('Flip', window);
            %                 else
            %                     % Feedback: incorrect
            %                     Screen('DrawTexture', window, nestTex, [], nestRect);
            %                     for n = 1:numEggs
            %                         Screen('DrawTexture', window, eggTexs(n), [], eggRect(n,:));
            %                     end
            %                     Screen('Flip', window);
            %                     PsychPortAudio('FillBuffer', panhandle, no_y');
            %                     PsychPortAudio('Start', panhandle, 1, 0, 1);
            %                     WaitSecs(1);
            %                 end
            % 
            %                 WaitSecs(1);  % Hold feedback
            %                 break;
            %             end
            %         end
            %     end
            % end

            % Time expired with no response
            if ~responded
                corr = 0;
                score(i,j) = corr;

                % Display timeout feedback
                DrawFormattedText(window, 'Too slow!', 'center', screenY * 0.9);
                Screen('Flip', window);
                WaitSecs(1);
            end
            %     while ~valid_click
            %         [clicks,x_click,y_click,whichButton,clickSecs] = GetClicks(window,[],[]);
            % 
            %         % Correct response and associated rectangle
            %         corr_resp = corr_mat(i,j);
            %         corr_rect = eggRect(corr_resp,:);
            % 
            %         for p = 1:length(eggImages)
            % 
            %             % Check if click was valid (was in one of the rectangles)
            %             if ismember(x_click,eggRect(p,1):eggRect(p,3)) && ismember(y_click,eggRect(p,2):eggRect(p,4))
            %                 valid_click = 1;
            %             end
            %         end
            % 
            %         % Check if click was correct
            %         if valid_click
            %             responded = true;
            % 
            %             % Correct response
            %             if ismember(x_click,corr_rect(1):corr_rect(3)) && ismember(y_click,corr_rect(2):corr_rect(4))
            % 
            %                 % Record response
            %                 corr = 1;
            %                 score(i,j) = corr;
            % 
            %                 % Display correct feedback
            % 
            %                 % Draw nest
            %                 Screen('DrawTexture',window,nestTex,[],nestRect);
            % 
            %                 % Draw all the eggs except correct one
            %                 for n = 1:numEggs
            %                     if n==corr_resp
            %                     else
            %                         Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
            %                     end
            %                 end
            % 
            %                 % Draw bird
            %                 Screen('DrawTexture',window,birdTex,[],birdRect(corr_resp,:))
            % 
            %                 % Flip to the screen
            %                 Screen('Flip', window);
            % 
            %             else
            %                 % Display incorrect feedback
            % 
            %                 % Draw nest
            %                 Screen('DrawTexture',window,nestTex,[],nestRect);
            % 
            %                 % Draw all the eggs
            %                 for n = 1:numEggs
            %                     Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
            %                 end
            % 
            %                 % Flip to the screen
            %                 Screen('Flip', window);
            % 
            %                 % Child saying "no"
            % 
            %                 % Load audio into buffer
            %                 PsychPortAudio('FillBuffer',panhandle,no_y');
            % 
            %                 % Start playback
            %                 PsychPortAudio('Start',panhandle,1,0,1)
            %                 WaitSecs(1)
            % 
            %             end
            % 
            %             % Wait 1 second
            %             WaitSecs(1)
            %         end
            %     end
            % end
            % 
            % % If time expired and no click
            % if ~responded
            %     corr = 0;
            %     score(i,j) = corr; 
            %     Screen('Flip', window);
            %     WaitSecs(1);
            % end

            % At the end of each trial (except the last), update stimulus matrix based on previous response
            if j > 1 && j < size(stim_mat,2)

                % Load the signal of the next target + noise stimulus
                y_next = stim_mat(i,j+1, corr_mat(i,j+1));
                y_next = cell2mat(y_next);
                target_next = y_next(:,:,2);

                % Update the QUEST object
                [dB, idx] =  qp.getTargetStim();
                response = corr;
                qp.update(dB, response);

                % Update dB mat
                dB_mat(i,j+1) = dB;

                % Adjust amplitude of next stimulus
                % dB = 20 * log10 (A / A0) where A = amplitude of signal and A0 =
                % reference amplitude (1 for normalized signal)
                % So we can solve for the scaling factor (A/A0) = 10^(dB / 20)
                % and mutiply this by the original signal to increase/decrease by dB

                scaling_factor = 10^(-(dB_init - dB) / 20);
                target_next_new = target_next * scaling_factor;

                % Update the signal in the stimulus matrix
                y_next(:,:,2) = target_next_new;
                stim_mat(i,j+1,corr_mat(i,j+1)) = {y_next};

                % Keep track of number of trials 
                num_qp_trials(i) = j;

                % Check if the experiment is finished
                if qp.isFinished()
                    break;  % Exit the loop if the stopping criterion is met
                end
            end
        end

        % End of block
    
        % After the block, you can get the estimated threshold
        thresholds(i) = qp.getParamEsts('mean');
        sprintf("Threshold = % dB",thresholds(i))

        %% Test threshold

        if test_threshold

            % Display 2 eggs - one with noise and one with noise + signal at
            % estimated threshold 
    
            % Define example trial for demo
            ex_trial = stim_mat{i,j,:};
            target_idx = corr_mat(i,j);
            target = ex_trial(target_idx);
            idxs = 1:3;
            noise_idxs = idxs;
            noise_idxs(target_idx) = [];
            noise_idx = noise_idxs(1);
    
            % Define rectangles to display to eggs
            demoEggRect = eggRect([1,3],:);
            demoBirdRect = birdRect([1,3],:);
    
            % Randomize eggs
            eggs = eggs(randperm(length(eggs)));
    
            % Make textures
            cd('\\noisyNest\images')
            for e = 1:numEggs
                [img, ~, alpha] = imread(eggs{e}); % Read the image - make sure background is transparent
                img(:,:,4) = alpha;
                eggImages{e} = img;
                eggTexs(e) = Screen('MakeTexture', window, eggImages{e}); % Create textures from images
            end
    
            % Draw images (just 2 eggs for simplification and nest)
            Screen('DrawTexture',window,nestTex,[],nestRect);
            for k = [1,2];
                Screen('DrawTexture', window,eggTexs(k),[],demoEggRect(k,:));
            end
    
            % Draw Text
            text = sprintf('%s',"Listen for the egg that is ready to hatch!");
            DrawFormattedText(window, text,'center',screenY*0.1);
    
            % Flip to the screen to show the images
            Screen('Flip', window);
    
            % Animation settings - each egg will shake when clicke
            numShakes = 100; % Number of shaking frames
            shakeMagnitude = 10; % Max pixel displacement for the shake effect
            shakeSpeed = 0.1; % Speed of shaking (higher is faster)
    
            % Alternate between each egg
    
            % Randomize which egg is the target or distractor
            demo_egg_order = [1,2];
            demo_egg_order = demo_egg_order(randperm(length(demo_egg_order)));
    
            distractor_rect_idx = demo_egg_order(1);
            target_rect_idx = demo_egg_order(2);
    
            % Number of demo trials
            numDemoTrials = 3;
            for n = 1:numDemoTrials
    
                % Wait some time to display text
                WaitSecs(2)
    
                % Play the distractor
    
                % Load audio
                y_noise = stim_mat(i,j,noise_idx);
                y_noise = y_noise{1};
                y_noise = reshape(y_noise,size(y_noise,2),size(y_noise,3));
                y_noise = sum(y_noise,2);
    
                % Trim audio
                y_noise = y_noise(1:stim_dur*fs);
    
                % 2 audio channels
                y_noise = [y_noise,y_noise];
                y_noise = y_noise';
    
                % Load audio into buffer
                PsychPortAudio('FillBuffer',panhandle,y_noise);
    
                % Start playback
                PsychPortAudio( 'Start',panhandle,1,0,1)
    
                % Start the animation loop
                start = GetSecs();
    
                % Animate for the duration of the stimulus
                while GetSecs() - start < stim_dur
                    % Randomly generate offsets for shaking
                    offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                    offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)
    
                    % Draw nest
                    Screen('DrawTexture',window,nestTex,[],nestRect);
    
                    % Draw shaking egg
                    Screen('DrawTexture', window, eggTexs(distractor_rect_idx), [], [demoEggRect(distractor_rect_idx,1) + offsetX, demoEggRect(distractor_rect_idx,2) + offsetY, demoEggRect(distractor_rect_idx,3) + offsetX, demoEggRect(distractor_rect_idx,4) + offsetY]);
    
                    % Draw the other egg
                    Screen('DrawTexture', window, eggTexs(target_rect_idx), [],demoEggRect(target_rect_idx,:));
    
                    % Draw text
                    DrawFormattedText(window, text,'center',screenY*0.1);
    
                    % Flip the screen to show the new frame
                    Screen('Flip', window);
                end
    
                % Wait a little bit before presenting target
                WaitSecs(0.5)
    
                % Play the target
                y_target = stim_mat(i,j,target_idx);
                y_target = y_target{1};
                y_target = reshape(y_target,size(y_target,2),size(y_target,3));
    
                % 2 channels
                y_target = sum(y_target,2);
                y_target = y_target';
    
                % Trim audio
                y_target = y_target(1:stim_dur*fs);
                y_target = [y_target;y_target];
    
                % Load audio into buffer
                PsychPortAudio('FillBuffer',panhandle,y_target);
    
                % Start playback
                PsychPortAudio('Start',panhandle,1,0,1)
    
                % Start the animation loop
                start = GetSecs();
    
                % Animate for the duration of the stimulus
                while GetSecs() - start < stim_dur
                    % Randomly generate offsets for shaking
                    offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                    offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)
    
                    % Draw nest
                    Screen('DrawTexture',window,nestTex,[],nestRect);
    
                    % Draw shaking egg
                    Screen('DrawTexture', window, eggTexs(target_rect_idx), [], [demoEggRect(target_rect_idx,1) + offsetX, demoEggRect(target_rect_idx,2) + offsetY, demoEggRect(target_rect_idx,3) + offsetX, demoEggRect(target_rect_idx,4) + offsetY]);
    
                    % Draw the other egg
                    Screen('DrawTexture', window, eggTexs(distractor_rect_idx), [],demoEggRect(distractor_rect_idx,:));
    
                    % Draw text
                    DrawFormattedText(window, text,'center',screenY*0.1);
    
                    % Flip the screen to show the new frame
                    Screen('Flip', window);
                end
    
                % Draw images
                Screen('DrawTexture',window,nestTex,[],nestRect);
                Screen('DrawTexture', window,eggTexs(distractor_rect_idx),[],demoEggRect(distractor_rect_idx,:));
                Screen('DrawTexture',window,birdTex,[],demoBirdRect(target_rect_idx,:))
    
                % Flip the screen
                Screen('Flip',window)
    
                % Display the bird for 1 sec
                WaitSecs(1)
    
                if n < numDemoTrials
                    % Draw images
                    Screen('DrawTexture',window,nestTex,[],nestRect);
    
                    for k = [1,2]
                        Screen('DrawTexture', window,eggTexs(k),[],demoEggRect(k,:));
                    end
    
                    % Draw text
                    DrawFormattedText(window, text,'center',screenY*0.1);
    
                    % Flip the screen
                    Screen('Flip',window)
                end
            end
        end
        %% Plot and save figure

        % Plot dB of target across trials
        figure;
        plot(dB_mat(i,1:j));
        xlabel("Trials")
        ylabel("Stimulus Level (dB SPL)")
        ylim([15,100])
        title(stimuli_str(i))
        
        % Save figure
        cd(fullfile('\\noisyNest\data',age,sub))
        savefig(sprintf("%s_%s_%s",sub,stimuli_str(i),datetime('now','Format','yyyy_MM_dd_hh_mm_ss')));

        %% End of block text 

        if i < size(stim_mat,1)
            % Draw Text
            endBlockText = sprintf('Great job! You helped Mama bird hatch %i eggs. You may now take a short break.',sum(score(i,:)));
            DrawFormattedText(window,endBlockText,'center',screenY*0.15);
            continueText = sprintf('%s', "Press the spacebar to continue");
            DrawFormattedText(window, continueText,'center',screenY*0.85);

            % Draw mama bird
            Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

            % Flip the screen to show the images
            Screen('Flip', window)
            WaitSecs(0.2)

            % Clear any key presses
            clear KbCheck

            % Wait for space bar press to start
            while true
                [keyIsDown, ~, keyCode] = KbCheck; % Check for key press
                if keyIsDown && keyCode(KbName('space')) % If space is pressed
                    break; % Exit loop and proceed
                end
            end
        else
            % Draw Text
            totalEggsText = sprintf('Great job! You helped Mama bird hatch a total of %i eggs.',sum(score,"all"));
            endExperimentText = sprintf('%s',"You have reached the end of the experiment.");
            DrawFormattedText(window,totalEggsText,'center',screenY*0.15);
            DrawFormattedText(window,endExperimentText,'center',screenY*0.85);

            % Draw mama bird
            Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

            % Flip the screen to show the images
            Screen('Flip', window)

            % Wait a couple of seconds
            WaitSecs(3)
        end

         % Save data 
        cd(fullfile('\\noisyNest\data',age,sub))
        save("data.mat","score","dB_mat","thresholds","num_qp_trials","-append")

        % % If not running entire experiment, don't move onto the next block
        % if ~entireExperiment 
        %     break
        % end


    %% Original Staircasing Method
    else
        % Initialize number of consecutive correct responses
        consec_corr = 0;

        % Initialize dB
        dB_init = dB_mat(i,1);
        dB = dB_init;

        % Loop through each trial
        for j = 1:size(stim_mat,2)
            % Initialize correct response variable
            corr = 0;

            % Load egg images from egg image matrix
            eggs = [eggImgMat{i,j,:}];

            % Make textures
            cd('\\noisyNest\images')
            for e = 1:numEggs
                [img, ~, alpha] = imread(eggs{e}); % Read the image - make sure background is transparent
                img(:,:,4) = alpha;
                eggImages{e} = img;
                eggTexs(e) = Screen('MakeTexture', window, eggImages{e}); % Create textures from images
            end

            % Loop through each stimulus 2x
            numRepeats = 1;
            for r = 1:numRepeats

                for k = 1:size(stim_mat,3)

                    % Load audio
                    y_orig = stim_mat(i,j,k);
                    y_orig = cell2mat(y_orig);

                    % Add noise and target signals (target is just array of zeros
                    % in noise conditions)
                    y = sum(y_orig,3);

                    % Shorten the signal
                    new_stim_dur = 0.5;
                    y = y(1:new_stim_dur*fs);

                    % 2 audio channels
                    y = [y;y];

                    % Load audio into buffer
                    PsychPortAudio('FillBuffer',panhandle,y);

                    % Start playback
                    PsychPortAudio('Start',panhandle,1,0,1)

                    % Animate for the duration of the stimulus

                    % Animation settings - each egg will shake when clicke
                    numShakes = 100; % Number of shaking frames
                    shakeMagnitude = 10; % Max pixel displacement for the shake effect
                    shakeSpeed = 0.1; % Speed of shaking (higher is faster)

                    start = GetSecs();
                    while GetSecs() - start < new_stim_dur
                        % Randomly generate offsets for shaking
                        offsetX = shakeMagnitude * (rand - 0.5) * 2; % Random X shake (-shakeMagnitude to +shakeMagnitude)
                        offsetY = shakeMagnitude * (rand - 0.5) * 2; % Random Y shake (-shakeMagnitude to +shakeMagnitude)

                        % Draw nest
                        Screen('DrawTexture',window,nestTex,[],nestRect);

                        % Draw all the eggs
                        for n = 1:numEggs
                            Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
                        end

                        % Draw shaking egg
                        Screen('DrawTexture', window, eggTexs(k), [], [eggRect(k,1) + offsetX, eggRect(k,2) + offsetY, eggRect(k,3) + offsetX, eggRect(k,4) + offsetY]);

                        % Draw text
                        listenText = 'Listen!';
                        DrawFormattedText(window, listenText,'center',screenY*0.1);

                        % Flip the screen to show the new frame
                        Screen('Flip', window);
                    end

                    % Wait some time before each stimulus presentation
                    WaitSecs(iti)
                end
            end

            % Draw nest and eggs in original position
            Screen('DrawTexture',window,nestTex,[],nestRect);
            for n = 1:numEggs
                Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
            end

            % Draw Text
            questionText = sprintf('%s',"Which egg is about to hatch?");
            DrawFormattedText(window, questionText,'center',screenY*0.1);

            % Flip the screen to show the images
            Screen('Flip', window)

            % Wait for click
            valid_click = 0;

            while ~valid_click
                [clicks,x_click,y_click,whichButton,clickSecs] = GetClicks(window,[],[]);

                % Correct response and associated rectangle
                corr_resp = corr_mat(i,j);
                corr_rect = eggRect(corr_resp,:);

                for p = 1:length(eggImages)

                    % Check if click was valid (was in one of the rectangles)
                    if ismember(x_click,eggRect(p,1):eggRect(p,3)) && ismember(y_click,eggRect(p,2):eggRect(p,4))
                        valid_click = 1;
                    end
                end

                % Check if click was correct
                if valid_click

                    % Correct response
                    if ismember(x_click,corr_rect(1):corr_rect(3)) && ismember(y_click,corr_rect(2):corr_rect(4))

                        % Record response
                        corr = 1;
                        score(i,j) = corr;
                        consec_corr = consec_corr + 1;

                        % Display correct feedback

                        % Draw nest
                        Screen('DrawTexture',window,nestTex,[],nestRect);

                        % Draw all the eggs except correct one
                        for n = 1:numEggs
                            if n==corr_resp
                            else
                                Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
                            end
                        end

                        % Draw bird
                        Screen('DrawTexture',window,birdTex,[],birdRect(corr_resp,:))

                        % Flip to the screen
                        Screen('Flip', window);

                    else
                        % Display incorrect feedback

                        % Draw nest
                        Screen('DrawTexture',window,nestTex,[],nestRect);

                        % Draw all the eggs
                        for n = 1:numEggs
                            Screen('DrawTexture', window,eggTexs(n),[],eggRect(n,:));
                        end

                        % Flip to the screen
                        Screen('Flip', window);

                        % Child saying "no"

                        % Load audio into buffer
                        PsychPortAudio('FillBuffer',panhandle,no_y');

                        % Start playback
                        PsychPortAudio('Start',panhandle,1,0,1)
                        WaitSecs(1)

                    end

                    % Wait 1 second
                    WaitSecs(1)
                end
            end

            % At the end of each trial (except the last), update stimulus matrix based on previous response
            if j > 1 && j < size(stim_mat,2)

                % Load the signal of the next target + noise stimulus
                y_next = stim_mat(i,j+1, corr_mat(i,j+1));
                y_next = cell2mat(y_next);
                target_next = y_next(:,:,2);

                % If past 2 consecutive responses were corect, reduce signal level on
                % the next trial
                if consec_corr == 2

                    % Reduce amplitude by 8 dB (if first reversal) otherwise reduce by
                    % 4 dB
                    if sum(reversals(i,:)) == 0
                        dB = dB - 8;
                    else
                        dB = dB - 4;
                    end

                    % dB = 20 * log10 (A / A0) where A = amplitude of signal and A0 =
                    % reference amplitude (1 for normalized signal)
                    % So we can solve for the scaling factor (A/A0) = 10^(dB / 20)
                    % and mutiply this by the original signal to increase/decrease by dB

                    scaling_factor = 10^(-(dB_init - dB) / 20);
                    target_next_new = target_next * scaling_factor;

                    % Update the signal in the stimulus matrix
                    y_next(:,:,2) = target_next_new;
                    stim_mat(i,j+1,corr_mat(i,j+1)) = {y_next};

                    % Update reversals matrix
                    reversals(i,j) = 1;

                    % Update dB mat
                    dB_mat(i,j+1) = dB;

                    % Reinitialize consecutive correct responses
                    consec_corr = 0;

                    % If response was incorrect
                elseif score(i,j) == 0
                    % Increase amplitude by 8 dB (if first reversal) otherwise reduce by
                    % 4 dB
                    if sum(reversals(i,:))==0
                        dB = dB + 8;
                    else
                        dB = dB + 4;
                    end

                    scaling_factor = 10^(-(dB_init - dB) / 20);
                    target_next_new = target_next * scaling_factor;

                    % Update the signal in the stimulus matrix
                    y_next_new = y_next;
                    y_next_new(:,:,2) = target_next_new;
                    stim_mat(i,j+1,corr_mat(i,j+1)) = {y_next_new};

                    % Update reversals matrix
                    reversals(i,j) = 1;

                    % Update dB mat
                    dB_mat(i,j+1) = dB;
                else
                    % No changes
                    scaling_factor = 10^(-(dB_init - dB) / 20);
                    target_next_new = target_next * scaling_factor;

                    % Update the signal in the stimulus matrix
                    y_next_new = y_next;
                    y_next_new(:,:,2) = target_next_new;
                    stim_mat(i,j+1,corr_mat(i,j+1)) = {y_next_new};

                    % Update reversals matrix
                    reversals(i,j) = 1;

                    % Update dB mat
                    dB_mat(i,j+1) = dB;

                end
            end
        end

        % End of block

        % Plot dB of target across trials
        figure;
        plot(dB_mat(i,:));
        xlabel("Trials")
        ylabel("Stimulus Level (dB SPL)")
        ylim([15,100])
        title(stimuli_str(i))

        % Save figure
        cd(fullfile('\\noisyNest\data',age,sub))
        savefig(sprintf("%s_%s_%s",sub,stimuli_str(i),datetime('now','Format','yyyy_MM_dd_hh_mm_ss')));


        if i < size(stim_mat,1)
            % Draw Text
            endBlockText = sprintf('Great job! You helped Mama bird hatch %i eggs. You may now take a short break.',sum(score(i,:)));
            DrawFormattedText(window,endBlockText,'center',screenY*0.15);
            continueText = sprintf('%s', "Press the spacebar to continue");
            DrawFormattedText(window, continueText,'center',screenY*0.85);

            % Draw mama bird
            Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

            % Flip the screen to show the images
            Screen('Flip', window)

            % Clear any key presses
            clear KbCheck

            % Wait for space bar press to start
            while true
                [keyIsDown, ~, keyCode] = KbCheck; % Check for key press
                if keyIsDown && keyCode(KbName('space')) % If space is pressed
                    break; % Exit loop and proceed
                end
            end
        else
            % Draw Text
            totalEggsText = sprintf('Great job! You helped Mama bird hatch a total of %i eggs.',sum(score,"all"));
            endExperimentText = sprintf('%s',"You have reached the end of the experiment.");
            DrawFormattedText(window,totalEggsText,'center',screenY*0.15);
            DrawFormattedText(window,endExperimentText,'center',screenY*0.85);

            % Draw mama bird
            Screen('DrawTexture',window,mamaBirdTex,[],mamaBirdRect);

            % Flip the screen to show the images
            Screen('Flip', window)

            % Wait a couple of seconds
            WaitSecs(3)
        end

        % Save data 
        cd(fullfile('\\noisyNest\data',age,sub))
        save("data.mat","score","dB_mat","thresholds","num_qp_trials","-append")

    end

end
%% End of experiment 
endExpTime = GetSecs();

% Save data
cd(fullfile('\\noisyNest\data',age,sub))

if strcmp(staircase_method, "QuestPlus")
    % If not all of the conditions have been completed, save the data to
    % the current data matrix
    if sum(ismember(thresholds,0)) > 0
        save("data.mat","score","dB_mat","thresholds","num_qp_trials","-append")
    else
    % Otherwise, save as new data matrix to prevent overwriting
        filename = sprintf('data_%s',datetime('now','Format','yyyy-mm-dd_hh_mm_ss'));
        safesave(filename,score,dB_mat,thresholds,num_qp_trials)
    end

else
    
    % If not all of the conditions have been completed, save the data to
    % the current data matrix
    if sum(ismember(thresholds,0)) > 0
        save("data.mat","score","dB_mat","-append")
    else
    % Otherwise, save as new data matrix to prevent overwriting 
         filename = sprintf('data_%s',datetime('now','Format','yyyy-mm-dd_hh_mm_ss'));
        safesave(filename,score,dB_mat) 
    end
end

% Close PTB
clear;
clc;
sca;
ShowCursor;
ListenChar(0);
