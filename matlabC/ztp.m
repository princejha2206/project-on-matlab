clc;clear;close all;

%% 1. Initialize Symbolic variables 
syms n z a b k 

% Define two arbitrary discrete signals 
x1 = 1^n; %Unit step (simplified representation)
x2 = n;   %Ramp

disp('----------------------------------------');
disp('  VERIFICATION OF Z-TRANSFORM PROPERTIES');
disp('----------------------------------------');

%% Properties 1:LINEARITY
% Theory : Z{a*x1 + b*x2} = a*X1(z) + b*X2(z)

disp("1.Verifying Linearity Property...");

%LHS : Combine in time , then transform 
comb_time = a*x1 +b*x2;
LHS_Lin = simplify(ztrans(comb_time,n,z));

%RHS: Transform separately , then combine 
X1 = ztrans(x1,n,z);
X2 = ztrans(x2,n,z);
RHS_Lin = simplify(a*X1 + b*X2);

%Check
if isequal(LHS_Lin,RHS_Lin)
    disp("[SUCCESS Linearity Verified.");
    disp([" Result: " char(LHS_Lin)]);
else
    disp(" [FAIL] Linearity.");
end

%% PROPERTY 2: TIME SHIFTING (DELAY)
% Theory : Z{x[n-k]} = z^(-k) * X(z)
% We will use a specific delay , e.g., K=2

k_val = 2;

disp("2.Verifying Time Shifting Property (Delay by 2)...");

%Define a signal : Unit step shifted by 2
x_shift = heaviside(n-k_val); %Heaviside is the Unit step in symbolic math

%LHS: Transform the shifted signal 
LHS_Shift = simplify(ztrans(x_shift,n,z));

%RHS: Z^(-K)*Z{Umit Step}
X_step = ztrans(heaviside(n),n,z);
RHS_Shift = simplify((z^(-k_val))*X_step);

%Note: simplify() somtimes struggles with Heaviside discrete vs continuous.
% We visually compare or check difference.

diff = simplify(LHS_Shift - RHS_Shift);

if diff==0
    disp("  [SUCCESS] Time Shifting Verified.");
    disp(["  Result: " char(LHS_Shift)]);
else 
    disp("   [NOTE] Symbolic match complex due to initial conditions.");
    disp("   Let us Compare manually:");
    disp(["   LHS : " char(LHS_Shift)]);
    disp(["   RHS : " char(RHS_Shift)]);
end
disp("  ");

%% PROPERTY 3: SCALING IN Z-DOMAIN (Multiplication by a^n)
% Theory : Z{a^n * x[n]} =X(z/a)

disp("3. Verifying Scaling Property (Multiplication by a^n)...");

% Let x[n] be the Unit Step (1)
% LHS: Transform {a^n*1}
LHS_Scale = simplify(ztrans(a^n * 1 , n, z ));

% RHS: Replace z with (z/a) in X(z) of Unit step 
% X_step(z) = z/(z-1)
RHS_Scale = simplify( subs(X_step,z,z/a));

diff = simplify(LHS_Scale - RHS_Scale);

if isequal(LHS_Scale, RHS_Scale)
    disp('   [SUCCESS] Scaling Property Verified.');
    disp(['   Result: ' char(LHS_Scale)]);
else
    disp('   [FAIL] Scaling Property.');
end
disp(' ')

%% PROPERTY 4 : DIFFERENTIATION IN Z-DOMAIN (Multiplication by n)
% Theory : Z{n*x[n]} = -z*d(X(z)]/dz

disp("4.Verifying Differentiation Property (Mult. by n)...");

% Let x[n] be a constant 1 (Unit Step)
% LHS : Transform{n*1}
LHS_Diff = simplify(ztrans(n*heaviside(n),n,z));

% RHS: -z * derivative of X_step
derivative_X = diff(formula(X_step), z);   % <-- fixed line
RHS_Diff = simplify(-z * derivative_X);

if isequal(LHS_Diff , RHS_Diff)
    disp("  [SUCCESS] Differentiation Property Verified.");
    disp([" Result:" char(LHS_Diff)]);
else
    disp("  [FAIL] Differentiation Property.");
end
disp("----------------------------------------");
