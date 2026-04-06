%% This script generates target and noise auditory stimuli for frequency discrimination task 

%% Generate target stimuli (150,2000,4000 Hz)

% First set some parameters 
fs=44100; 
stim_dur=2; 
t=0:1/fs:stim_dur-1/fs;

% 150 Hz
f=150;
target_150 = sin(2*pi*f*t);

% 2000 Hz
f=2000;
target_2000 = sin(2*pi*f*t);

% 4000 Hz
f=4000;
target_4000 = sin(2*pi*f*t);

figure;
fs = 44100; 
pspectrum(target_4000,fs); % pspectrum


%% Generate 150 Hz flat spectrum noise

% Set some filter parameters
fs = 44100;  % Sampling frequency (Hz)
T = stim_dur;       % Signal duration (seconds)
N = fs * T;  % Number of samples
f_center = 150;  % Center frequency (Hz)
f_low = 10; % Lower cutoff frequency
f_high = 2500; % Upper cutoff frequency
f_low_stopband_atten = 1; 
f_high_stopband_atten = f_low_stopband_atten;

% Generate white noise 
noise = randn(1, N);
p = pspectrum(noise,fs);
% plot(pow2db(p))
% xlabel("Frequency (Hz)")
% ylabel("Power (dB)")
% title("White Noise Power Spectrum")

% Adjust the power of the noise signal so that it is around 60 dB (like in
% paper)
% power_adj = mean(pow2db(p)) - 75; 
% noise = wgn(1,N,abs(power_adj));
% p = pspectrum(noise,fs);
% figure;
% plot(pow2db(p))
% xlabel("Frequency (Hz)")
% ylabel("Power (dB)")
% title("White Noise Power Spectrum (Adjusted)")


% Design bandpass filter of bandwidth 4000 Hz centered on signal frequency
% FIR was chosen bc IIR filters can induce phase distortion (diff frequency
% components are delayed by diff amounts which can distort the output of
% the signal) 

bpFilt = designfilt('bandpassfir', 'FilterOrder', 500, ...
                    'CutoffFrequency1', f_low, 'CutoffFrequency2', f_high, ...
                    'SampleRate', fs);
% % Plot the filter 
% freqz(bpFilt,N,fs);

% Apply the filter to the noise
filtered_noise = filtfilt(bpFilt, noise);

% Compute and plot power spectrum
[Pxx,f] = pwelch(filtered_noise,[],[],[],fs); % Estimate PSD using Welch's method;
figure;
plot(f,pow2db(Pxx))
xlabel("Frequency (kHz)")
ylabel("Power (dB)")
title("150 Hz Flat Power Spectrum")

% Play sound
flat_noise_150 = filtered_noise; 
% sound(flat_noise_150,fs)

%% Generate 2000 Hz flat spectrum noise

fs = 44100;  % Sampling frequency (Hz)
T = stim_dur;       % Signal duration (seconds)
N = fs * T;  % Number of samples
f_center = 2000;  % Center frequency (Hz)
BW = 4000;        % Bandwidth (Hz)
f_low = f_center - BW/2 + 1;  % Lower cutoff frequency
f_high = f_center + BW/2; % Upper cutoff frequency
f_low_stopband_atten = 0.1; 
f_high_stopband_atten = f_low_stopband_atten;


% Design bandpass filter of bandwidth 4000 Hz centered on signal frequency
bpFilt = designfilt('bandpassfir', 'FilterOrder', 500, ...
                    'CutoffFrequency1', f_low, 'CutoffFrequency2', f_high, ...
                    'SampleRate', fs);

% Apply the filter to the noise
filtered_noise = filtfilt(bpFilt, noise);

% Compute and plot power spectrum
[Pxx,f] = pwelch(filtered_noise,[],[],[],fs); % Estimate PSD using Welch's method;
figure;
plot(f,pow2db(Pxx))
xlabel("Frequency (kHz)")
ylabel("Power (dB)")
title('2000 Hz Flat Spectrum');


% Play sound
flat_noise_2000 = filtered_noise; 
% sound(flat_noise_2000,fs)

%% Generate 4000 Hz flat spectrum noise

fs = 44100;  % Sampling frequency (Hz)
T = stim_dur;       % Signal duration (seconds)
N = fs * T;  % Number of samples
f_center = 4000;  % Center frequency (Hz)
BW = 4000;        % Bandwidth (Hz)
f_low = f_center - BW/2;  % Lower cutoff frequency
f_high = f_center + BW/2; % Upper cutoff frequency

bpFilt = designfilt('bandpassfir', 'FilterOrder', 500, ...
                    'CutoffFrequency1', f_low, 'CutoffFrequency2', f_high, ...
                    'SampleRate', fs);
% % Plot the filter 
% freqz(bpFilt,N,fs);

% Apply the filter to the noise
filtered_noise = filtfilt(bpFilt, noise);

% Compute and plot power spectrum
[Pxx,f] = pwelch(filtered_noise,[],[],[],fs); % Estimate PSD using Welch's method;
figure;
plot(f,pow2db(Pxx))
xlabel("Frequency (kHz)")
ylabel("Power (dB)")
title("4000 Hz Flat Power Spectrum")

% Play sound
flat_noise_4000 = filtered_noise;
% sound(flat_noise_4000,fs)

%% Generate 150 Hz notched spectrum noise

% Center frequency (Hz)
fs = 44100;  % Sampling frequency (Hz)
T = stim_dur;       % Signal duration (seconds)
N = fs * T;  % Number of samples
f_center = 150;  % Center frequency (Hz)
bands = [10,50;250,2250]; % Each row defines [f_low, f_high]
f_low_stopband_atten = 0.1; 
f_high_stopband_atten = f_low_stopband_atten;


% Initialize Filtered Signal
filtered_noise = zeros(size(noise));

for i = 1:size(bands, 1)
    f_low = bands(i, 1);
    f_high = bands(i, 2);
  
 
    % Design Bandpass FIR Filter using designfilt
    bpFilt = designfilt('bandpassfir', ...
                        'FilterOrder', 500, ...
                        'CutoffFrequency1', f_low, ...
                        'CutoffFrequency2', f_high, ...
                        'StopbandAttenuation1',f_low_stopband_atten,  'StopbandAttenuation2',f_high_stopband_atten, ...
                        'SampleRate', fs);

        
    % Apply Filter and Accumulate Signals
    filtered_noise = filtered_noise + filtfilt(bpFilt, noise);
end

% Compute and plot power spectrum
[Pxx,f] = pwelch(filtered_noise,[],[],[],fs); % Estimate PSD using Welch's method;
figure;
plot(f,pow2db(Pxx))
xlabel("Frequency (kHz)")
ylabel("Power (dB)")
title("150 Hz Notched Power Spectrum")

% Play sound
notched_noise_150 = filtered_noise;
% sound(notched_noise_150,fs)

%% Generate 2000 Hz notched spectrum noise

% Center frequency (Hz)
fs = 44100;  % Sampling frequency (Hz)
T = stim_dur;       % Signal duration (seconds)
N = fs * T;  % Number of samples
f_center = 2000;  % Center frequency (Hz)
notch_width = 800; 
bw = 2000; 
bands = [1e-10,f_center-notch_width/2;f_center+notch_width/2,f_center+notch_width/2+bw]; % Each row defines [f_low, f_high]

% Initialize Filtered Signal
filtered_noise = zeros(size(noise));

for i = 1:size(bands, 1)
    f_low = bands(i, 1);
    f_high = bands(i, 2);
    
    % Design Bandpass FIR Filter using designfilt
    bpFilt = designfilt('bandpassfir', ...
                           'FilterOrder', 500, ...
                           'CutoffFrequency1', f_low, ...
                           'CutoffFrequency2', f_high, ...
                           'SampleRate', fs);
    
    % Apply Filter and Accumulate Signals
    filtered_noise = filtered_noise + filtfilt(bpFilt, noise);
end

% Compute and plot power spectrum
[Pxx,f] = pwelch(filtered_noise,[],[],[],fs); % Estimate PSD using Welch's method;
figure;
plot(f,pow2db(Pxx))
xlabel("Frequency (kHz)")
ylabel("Power (dB)")
title("2000 Hz Notched Power Spectrum")

% Play sound
notched_noise_2000 = filtered_noise;
% sound(notched_noise_2000,fs)
%% Generate 4000 Hz notched spectrum noise

% Center frequency (Hz)
fs = 44100;  % Sampling frequency (Hz)
T = stim_dur;       % Signal duration (seconds)
N = fs * T;  % Number of samples
f_center = 4000;  % Center frequency (Hz)
notch_width = 1600; 
bw = 2000; 
bands = [f_center-notch_width/2-bw,f_center-notch_width/2;f_center+notch_width/2,f_center+notch_width/2+bw]; % Each row defines [f_low, f_high]

% Initialize Filtered Signal
filtered_noise = zeros(size(noise));

for i = 1:size(bands, 1)
    f_low = bands(i, 1);
    f_high = bands(i, 2);
    
    % Design Bandpass FIR Filter using designfilt
    bpFilt = designfilt('bandpassfir', ...
                           'FilterOrder', 500, ...
                           'CutoffFrequency1', f_low, ...
                           'CutoffFrequency2', f_high, ...
                           'SampleRate', fs);
    
    % Apply Filter and Accumulate Signals
    filtered_noise = filtered_noise + filtfilt(bpFilt, noise);
end

% Compute and plot power spectrum
[Pxx,f] = pwelch(filtered_noise,[],[],[],fs); % Estimate PSD using Welch's method;
figure;
plot(f,pow2db(Pxx))
xlabel("Frequency (kHz)")
ylabel("Power (dB)")
title('4000 Hz Notched Spectrum');

% Play sound
notched_noise_4000 = filtered_noise;
% sound(notched_noise_4000,fs)

%% Generate stimulus matrix 
% 25 trials x 6 conditions (150 Hz, 2000 Hz, 4000 Hz x flat spectrum,
% notched noise) x 3 choices
% Each trial is a 3 alternative forced choice: 1) noise 2) noise 3) signal
% + noise (presented in random order)
% Frequency and type of noise is the same for a given trial 

% Create stimuli list (each target stimulus is repeated 2x so that its
% indices correspond to each noise stimulus
noise_stim = [notched_noise_150; flat_noise_150;notched_noise_2000; flat_noise_2000; notched_noise_4000;flat_noise_4000; ];
target_stim = [target_150; target_150; target_2000; target_2000; target_4000; target_4000]; 

% Create conditions order
conditions = 1:size(noise_stim,1);
condition_order = conditions; 
% condition_order = conditions(randperm(length(conditions)));

% Create stimuli list of strings
stimuli_str = ["150 Hz Notched Spectrum", "150 Hz Flat Spectrum",...
                "2000 Hz Notched Spectrum", "2000 Hz Flat Spectrum",...
                "4000 Hz Notched Spectrum", "4000 Hz Flat Spectrum"];
stimuli_str = stimuli_str(condition_order); 

% Initialize stimulus matrix 
stim_mat = cell(6,25,3);

% Initialize correct response matrix
corr_mat = zeros(6,25);

% Initialize matrix of target dB
dB_mat = zeros(6,25);

% Initialize array of starting dB for each condition 
SPL_dB_init = [65,80,70,85,75,98]; 

% Initialize array to contain scaling factor for each condition 
scaling_factors = zeros(1,length(conditions)); 

% Loop through each condition
for i = 1:size(stim_mat,1)
    noise = noise_stim(condition_order(i),:);
    target = target_stim(condition_order(i),:);

    % Reference pressure (20 µPa)
    P_ref = 20e-6;  % 20 µPa in Pascals
    
    % Compute the RMS (Root Mean Square) of the signal
    rms_signal = rms(target);
    
    % Compute the SPL (Sound Pressure Level) in dB with respect to 20 µPa
    SPL_dB_orig = 20 * log10(rms_signal / P_ref);

    % Adjust starting dB of target to 60

    % dB = 20 * log10 (A / A0) where A = amplitude of signal and A0 =
    % reference amplitude (1 for normalized signal)
    % So we can solve for the scaling factor (A/A0) = 10^(dB / 20)
    % and mutiply this by the original signal to increase/decrease by dB
    SPL_dB_new = SPL_dB_orig;
    SPL_dB_new = SPL_dB_init(i);  
    dB_reduction = SPL_dB_orig - SPL_dB_new;
    scaling_factor = 10^(-dB_reduction / 20);
    scaling_factors(i) = scaling_factor; 
    target = target* scaling_factor;

    % Update dB_mat
    dB_mat(i,:) = SPL_dB_new;
            
    % Loop through each trial
    for j = 1:size(stim_mat,2)

        % Determine order of 3AFC presentation (choice 1 = noise, choice 2
        % = noise, choice 3 = noise + target) 
        choices = [1,2,3]; 
        choice_order = choices(randperm(length(choices)));

        % Populate stimulus array with noise and target stimuli (size =
        % 2,length(signal)) where first row corresponds to noise and second
        % row corresponds to target (array of zeros in the 2 noise
        % conditions) 

        stim = zeros(length(choices),length(noise),2); 
        stim(1,:,1) = noise;
        % stim(1,:,2) = noise;
        stim(2,:,1) = noise; 
        % stim(2,:,2) = noise; 
        stim(3,:,1) = noise; 
        stim(3,:,2) = target; 

        % Randomize stimulus order - noise, noise, target + noise
        stim_rand = [stim(choice_order(1),:,:);stim(choice_order(2),:,:);stim(choice_order(3),:,:)];

        % Find index of correct response (choice 3)
        corr_mat(i,j) = find(choice_order==3); 

        % Populate stim_matrix with randomized 3 alternative forced choice
        % stimuli 
        for k = 1:size(stim_mat,3)
            stim_mat(i,j,k) = {stim_rand(k,:,:)};
            y = stim_rand(k,:,:);
            y = reshape(y,size(y,2),2); 
        end

    end
end
% close all

%% Generate list of egg images
cd('Z:\data\auditory_behavior\freq_discrimination\images')
allFiles = dir(); 
allFileNames = extractfield(allFiles,"name");
eggFileNames = allFileNames(contains(allFileNames,"egg_"));
eggImgMat = cell(size(stim_mat));

for i = 1:size(eggImgMat,1)
    for j = 1:size(eggImgMat,2)
        % Randomize list of images 
        eggFileNames = eggFileNames(randperm(numel(eggFileNames)));

        % Choose first 3 images from list 
        eggImgMat{i,j,k} = eggFileNames(1:3); 

        % if j > 1 && j < 3
        %     if any(contains([eggImgMat{i,j-1}],eggImgMat{i,j}))
        %         eggImgMat{i,j} = eggFileNames(randi(length(eggFileNames)));
        %     end
        % end
        % 
        % % Ensure that an egg can not be a target in 2 consecutive trials
        % % (should not be one of the last 3 images in the array) 
        % if j > 3
        %     % Keep track of the last 3 images 
        %     history = [eggImgMat{i,j-3:j-1}];
        % 
        %     % Exclude these images from the list that is drawn from    
        %     eggFileNames_new = eggFileNames(~contains(eggFileNames,history)); 
        %     eggImgMat{i,j} = eggFileNames_new(randi(length(eggFileNames_new)));
        % end
    end
end

%% Save stimulus matrix 
% cd('Z:\data\auditory_behavior\freq_discrimination\code')
% save("stim_mat.mat","stim_mat","corr_mat","condition_order","stim_dur","fs","dB_mat","SPL_dB_orig","SPL_dB_new","scaling_factors","stimuli_str","eggImgMat")
