clc;
clear;
close all;

%% CONSTANTS
c = 3e8;
k = 1.38e-23;
T = 290;

%% RADAR PARAMETERS
Pt = 1; % 1 W
Gt_dB = 10;
Gr_dB = 10;
Gt = 10^(Gt_dB/10);
Gr = 10^(Gr_dB/10);
sigma = 1;
f0 = 1e9; % 1 GHz
lambda = c/f0;
B = 200e6;
N = 256; % Frequency steps
FFTpoint = N;

%% TARGET DEPTHS (meters)
Ground = 10;
d1 = 30; % Object 1 depth
d2 = 50; % Object 2 depth

%% Radar Range Equation
PrG = (Pt*Gt*Gr*lambda^2*sigma)/((4*pi)^3*Ground^4);
Pr1 = (Pt*Gt*Gr*lambda^2*sigma)/((4*pi)^3*d1^4);
Pr2 = (Pt*Gt*Gr*lambda^2*sigma)/((4*pi)^3*d2^4);

rxGround = zeros(N, FFTpoint);
rx1 = zeros(N, FFTpoint);
rx2 = zeros(N, FFTpoint);
gprfft = zeros(N, FFTpoint);
TargetIndex1 = 70;
TargetIndex2 = 120;

% Frequency vector matching the number of steps N
f = linspace(f0, f0+B, N);

for i1 = 1 : 1 : N
    rxGround(:, i1) = sqrt(PrG) .* exp(-1j*4*pi*f*Ground/c);

    if ((i1 >= TargetIndex1) && (i1 <= TargetIndex1+5))
        rx1(:, i1) = sqrt(Pr1) .* exp(-1j*4*pi*f*d1/c);
    else
        rx1(:, i1) = 0;
    end

    if ((i1 >= TargetIndex2) && (i1 <= TargetIndex2+5))
        rx2(:, i1) = sqrt(Pr2) .* exp(-1j*4*pi*f*d2/c);
    else
        rx2(:, i1) = 0;
    end
end

rxsig = rxGround + rx1 + rx2;

%% Thermal Noise
NF_dB = 5;
NF = 10^(NF_dB/10);
Pn = k*T*B;
noise = sqrt(Pn*NF) * randn(FFTpoint, N);

%% Final GPR Image Processing
gpr = rxsig + noise;
for i1 = 1 : 1 : N
    % CHANGED TO ifft: This corrects the range inversion so ground is at the top
    gprfft(:, i1) = abs(ifft(gpr(:, i1)));
end

%% SVD Clutter Suppression
[u, s, v] = svd(gprfft);
imsvd = abs(u(:, 2:end) * s(2:end, 2:end) * v(:, 2:end)');

%% Display Results
figure(1);
imagesc(10*log10(gprfft));
colormap(jet);
colorbar;
title('Raw Simulated GPR Image (With Dominant Ground Bounce)');
xlabel('Cross Range (Scan Position)');
ylabel('Depth (Range Bins)');
set(gca, 'YDir', 'reverse'); % Keeps shallow depth at the top

figure(2);
imagesc(10*log10(imsvd));
colormap(jet);
colorbar;
title('Enhanced GPR Image (SVD Clutter Suppression Applied)');
xlabel('Cross Range (Scan Position)');
ylabel('Depth (Range Bins)');
set(gca, 'YDir', 'reverse');
