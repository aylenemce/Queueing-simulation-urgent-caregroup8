%[text] # Run samples of the ServiceQueue\_Renege simulation: Group Eight
%[text] Collect statistics and plot histograms along the way.
%%
clear all
clear classes
clc
rehash toolboxcache
%%
PictureFolder = "Pictures";
mkdir(PictureFolder);
%%
%[text] ## Set up
%[text] `We'll measure time in hours`
%[text] Arrival rate: 2 per hour.
lambda = 2;
%[text] Departure (service) rate: 1 per 20 minutes, so 3 per hour.
mu = 3;
%[text] Number of serving stations.
s = 2;
%[text] Reneging time is 15 minutes.
theta = 4;
%[text] Run many samples of the queue.
NumSamples = 500;
%[text] Each sample is run up to a maximum time.
MaxTime = 5;
%[text] Make a log entry every so often.
LogInterval = 0.2;
%%
%[text] ## Numbers from theory for M/M/2+M queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
nMax = 10;
P = zeros([nMax + 1, 1]);

P(1) = 1;

for j = 1:nMax

    if j <= s
        mu_n = j * mu;              % increasing service capacity
    else
        mu_n = s * mu + (j - s) * theta;  % reneging dominates
    end

    P(j + 1) = P(j) * (lambda / mu_n);
end

P = P / sum(P);
P0 = P(1);

pi_s = (mu*P(2) + sum(2*mu * P(3:end))) / lambda;

fprintf('P0 to P5: %s\n', mat2str(P, 4));
fprintf('Fraction served (pi_s): %.4f\n', pi_s);
%%
%fprintf('P(%d) = %.6f\n', n, P(n+1));
n_vals = 0:nMax;
L_theory = sum(n_vals' .* P); 

Lq_theory = sum(max(0, n_vals - s)' .* P);

lambda_eff = lambda * pi_s; 
W_theory = L_theory / lambda_eff;
Wq_theory = Lq_theory / lambda_eff;

theory = [L_theory, Lq_theory, W_theory, Wq_theory]
%%
%[text] ## Run simulation samples
%[text] This is the most time consuming calculation in the script, so let's put it in its own section.  That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%[text] Reset the random number generator.  This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.  This is a good idea for testing purposes.  Under other circumstances, you probably want the random numbers to be truly unpredictable and you wouldn't do this.
rng("default");
%[text] We'll store our queue simulation objects in this list.
QSamples = cell([NumSamples, 1]);
%[text] `The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.`
for SampleNum = 1:NumSamples
    if mod(SampleNum, 10) == 0
        fprintf("%d ", SampleNum);
    end
    if mod(SampleNum, 100) == 0
        fprintf("\n");
    end
    q = ServiceQueueRenege( ...
        ArrivalRate=lambda, ...
        DepartureRate=mu, ...
        NumServers=s, ...
        LogInterval=LogInterval,...
        RenegeRate = theta);

    q.schedule_event(Arrival(random(q.InterArrivalDist), Customer(1)));
    run_until(q, MaxTime);
    QSamples{SampleNum} = q;
end
%%
%[text] ## Collect measurements of how many customers are in the system
%[text] Count how many customers are in the system at each log entry for each sample run.  There are two ways to do this.  You only have to do one of them.
%[text] ### Option one: Use a for loop: Solving for L
NumInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end

% Solving for L_q
NumInWaitingSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInWaitingSamples{SampleNum} = q.Log.NumWaiting;
end

% L Simulated
NumInSystem = vertcat(NumInSystemSamples{:});
meanNumInSystemSamples = mean(NumInSystem);
fprintf("Mean number in system: %f\n", meanNumInSystemSamples);

NumInServiceSamples = cell([NumSamples, 1]);

for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    NumInServiceSamples{SampleNum} = q.Log.NumInService;
end

NumInService = vertcat(NumInServiceSamples{:});

% L_q Simulated
NumInWaiting = vertcat(NumInWaitingSamples{:});
meanNumInWaitingSamples = mean(NumInWaiting);
fprintf("Mean number waiting in system: %f\n", meanNumInWaitingSamples);
%[text] ### Option two: Map a function over the cell array of ServiceQueue objects.
%[text] The `@(q) ...` expression is shorthand for a function that takes a ServiceQueue as input, names it `q`, and computes the sum of two columns from its log.  The `cellfun` function applies that function to each item in `QSamples`. The option `UniformOutput=false` tells `cellfun` to produce a cell array rather than a numerical array.
%NumInSystemSamples = cellfun( ...
    %@(q) q.Log.NumWaiting + q.Log.NumInService, ...
    %QSamples, ...
    %UniformOutput=false);
%[text] ## Join numbers from all sample runs.
%[text] `vertcat` is short for "vertical concatenate", meaning it joins a bunch of arrays vertically, which in this case results in one tall column.
NumInSystem = vertcat(NumInSystemSamples{:});
%[text] MATLAB-ism: When you pull multiple items from a cell array, the result is a "comma-separated list" rather than some kind of array.  Thus, the above means
%[text] `NumInSystem = vertcat(NumInSystemSamples{1}, NumInSystemSamples{2}, ...)`
%[text] which concatenates all the columns of numbers in NumInSystemSamples into one long column.
%[text] This is roughly equivalent to "splatting" in Python, which looks like `f(*args)`.
%%
%[text] ## Pictures and stats for number of customers in system
%[text] 
% ===== NUMBER IN SYSTEM (Pn) =====

fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
hold(ax, "on");

% Histogram (simulation)
h = histogram(ax, NumInSystem, ...
    'Normalization','probability', ...
    'BinEdges', -0.5:1:(nMax+0.5));

% Force same range as theory
xlim(ax, [0 nMax]);

% Overlay theory
plot(ax, 0:nMax, P, 'ro', ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', 'r');

title(ax, "Number of customers in system");
xlabel(ax, "n");
ylabel(ax, "Probability");
legend(ax, "Simulation", "Theory");

pause(2);
exportgraphics(fig, PictureFolder + filesep + "Number_in_system.pdf");
%%
% ===== NUMBER WAITING (Lq) =====

% Theoretical distribution for waiting
H = [P(1)+P(2); P(3:end)];

fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
hold(ax, "on");

% Histogram
h = histogram(ax, NumInWaiting, ...
    'Normalization','probability', ...
    'BinEdges', -0.5:1:(nMax-1+0.5));

xlim(ax, [0 nMax-1]);

% Overlay theory
plot(ax, 0:nMax-1, H, 'ro', ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', 'r');

title(ax, "Number waiting in queue");
xlabel(ax, "n");
ylabel(ax, "Probability");
legend(ax, "Simulation", "Theory");

pause(2);
exportgraphics(fig, PictureFolder + filesep + "Lq_histogram.pdf");
%%

%%

%[text] 
%%
%[text] ## Collect measurements of how long customers spend in the system
%[text] This is a rather different calculation because instead of looking at log entries for each sample `ServiceQueue`, we'll look at the list of served  customers in each sample ServiceQueue.
%[text] ### Option one: Use a for loop: Solving for W
TimeInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % The next command has many parts.
    %
    % q.Served is a row vector of all customers served in this particular
    % sample.
    % The ' on q.Served' transposes it to a column.
    %
    % The @(c) ... expression below says given a customer c, compute its
    % departure time minus its arrival time, which is how long c spent in
    % the system.
    %
    % cellfun(@(c) ..., q.Served') means to compute the time each customer
    % in q.Served spent in the system, and build a column vector of the
    % results.
    %
    % The column vector is stored in TimeInSystemSamples{SampleNum}.
    TimeInSystemSamples{SampleNum} = ...
        cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served');
end

% Solving for W_q
WaitingInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % The next command has many parts.
    %
    % q.Served is a row vector of all customers served in this particular
    % sample.
    % The ' on q.Served' transposes it to a column.
    %
    % The @(c) ... expression below says given a customer c, compute its
    % departure time minus its arrival time, which is how long c spent in
    % the system.
    %
    % cellfun(@(c) ..., q.Served') means to compute the time each customer
    % in q.Served spent in the system, and build a column vector of the
    % results.
    %
    % The column vector is stored in TimeInSystemSamples{SampleNum}.
    WaitingInSystemSamples{SampleNum} = ...
        cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served');
    
end

% W Simulated
TimeInSystemSamples = vertcat(TimeInSystemSamples{:});
TimeInSystem = TimeInSystemSamples;
meanTimeInSystemSamples = mean(TimeInSystemSamples);
fprintf("Mean time in system: %f\n", meanTimeInSystemSamples);

% W_q Simulated
WaitingInSystemSamples = vertcat(WaitingInSystemSamples{:});
meanWaitingInSystemSamples = mean(WaitingInSystemSamples);
fprintf("Mean waiting time in system: %f\n", meanWaitingInSystemSamples);
%[text] ### Option two: Use `cellfun` twice.
%[text] The outer call to `cellfun` means do something to each `ServiceQueue` object in `QSamples`.  The "something" it does is to look at each customer in the `ServiceQueue` object's list q.Served and compute the time it spent in the system.
%TimeInSystemSamples = cellfun( ...
    %@(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    %QSamples, ...
    %UniformOutput=false);
%[text] ### Join them all into one big column.
%TimeInSystem = vertcat(TimeInSystemSamples{:});
%%
%[text] ## Pictures and stats for time customers spend in the system
%[text] `Print out mean time spent in the system.`
% ===== TIME IN SYSTEM (W) =====

fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);

histogram(ax, TimeInSystem, ...
    'Normalization','probability', ...
    'BinWidth', 1/12);   % 1 minute bins

title(ax, "Time in system");
xlabel(ax, "Time (hours)");
ylabel(ax, "Probability");

xlim(ax, [0 max(TimeInSystem)]);

pause(2);
exportgraphics(fig, PictureFolder + filesep + "Time_in_system.pdf");

% ===== WAITING TIME (Wq) =====

fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);

histogram(ax, WaitingInSystemSamples, ...
    'Normalization','probability', ...
    'BinWidth', 1/12);

title(ax, "Waiting time in queue");
xlabel(ax, "Time (hours)");
ylabel(ax, "Probability");

xlim(ax, [0 max(WaitingInSystemSamples)]);

pause(2);
exportgraphics(fig, PictureFolder + filesep + "Wq_histogram.pdf");
%%
% ===== SERVICE TIME =====

ServiceTimes = cellfun(@(q) ...
    cellfun(@(c) c.DepartureTime - c.BeginServiceTime, q.Served'), ...
    QSamples, 'UniformOutput', false);

ServiceTimes = vertcat(ServiceTimes{:});

fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);

histogram(ax, ServiceTimes, ...
    'Normalization','probability', ...
    'BinWidth', 1/12);

title(ax, "Service time distribution");
xlabel(ax, "Time (hours)");
ylabel(ax, "Probability");

xlim(ax, [0 max(ServiceTimes)]);

pause(2);
exportgraphics(fig, PictureFolder + filesep + "Service_time.pdf");

%%
%[text] ## Numbers of customers reneged
%%
% ===== RENEGING FRACTION =====

RenegedFraction = cellfun(@(q) ...
    length(q.Reneged) / (length(q.Reneged) + length(q.Served)), ...
    QSamples);

fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);

histogram(ax, RenegedFraction, ...
    'Normalization','probability', ...
    'BinWidth', 0.02);

title(ax, "Fraction of customers who reneged");
xlabel(ax, "Fraction");
ylabel(ax, "Probability");

pause(2);
exportgraphics(fig, PictureFolder + filesep + "Reneging_fraction.pdf");
%%
Utilization = NumInService / s;
meanUtil = mean(Utilization);
fprintf("Mean utilization per server: %f\n", meanUtil);
%%
%[text] ## Part 4 question 5
%[text] Average Value Estimates: 
%[text] $lambda$ = $2$
%[text] $mu$ = $3$ 
%[text] $theta$= $4$
%[text] $maxtime = 8$
%[text] $hypergeom(\[1\],\[c\],z)=\\sum\_{k=0}^{\\infty}\\frac{(1)\_kz^k}{(c)\_kz!}=\\frac{x^k}{c\_k}\n$
%[text] $c\_k = c(c+1)(c+2)...(c+k-1)$
%[text] $c=\\frac{mu}{theta} = \\frac{3}{4}$
%[text] $z=\\frac{lambda}{theta}=\\frac{2}{4}=\\frac{1}{2}$
%[text] $hypergeom(\[1\].\[0.75\],\[0.5)=1+\\frac{0.5}{0.75}+\\frac{0.5^2}{0.75\*1.75}+\\frac{0.5^3}{0.75\*2.75}+...&dollar&; =1.8969$
%[text] $P\_(n+1)=P\_n\*\\frac{lambda}{mu+(n\*theta)}$
%[text] $P\_0=\\frac{1}{1.8969}=0.527$
%[text] $P\_1=P\_0\*\\frac{lambda}{mu}=0.527\*\\frac{2}{3}=0.351$
%[text] $P\_2=P\_1\*\\frac{lambda}{mu+theta}=0.351\*\\frac{2}{3+4}=0.100$
%[text] $P\_3=P\_2\*\\frac{lambda}{mu+(2\*theta)}=0.100\*\\frac{2}{3+2(4)}=0.0182$
%[text] $P\_4=P\_3\*\\frac{lambda}{mu+(3\*theta)}=0.0182\*\\frac{2}{3+3(4)}=0.00243$
%[text] $P\_5=P\_4\*\\frac{lambda}{mu+(4\*theta)}=0.00243\*\\frac{2}{3+4(4)}=0.000256$
%[text] $\\pi\_s=\\frac{mu(1-P\_0)}{lambda}=\\frac{3(1-0.527)}{2}=\\frac{1.419}{2}=0.7092$
%[text] $L=\\sum\_{n=0}^{\\infty}n\*P\_0$
%[text] for $n=1$: $1\*P\_1 = 0.351$
%[text] for $n=2$: $2\*P\_2 = 2(0.100)=0.200$
%[text] for $n=3$: $3\*P\_3 = 3(0.0182) = 0.0546$
%[text] for $n=4$: $4\*P\_4=4(0.00243)=0.00972$
%[text] for $n=5$: $4\*P\_5 = 5(0.00026)=0.00130$
%[text] $L = 0.618$
%[text] $L\_q = \\sum\_{n=0}^{\\infty}max(0,n-1)P\_n$
%[text] for $n=2$: $(2-1)P\_2=1(0.1)=0.1$
%[text] for $n=3$: $(3-1)P\_3=2(0.0182)=0.0364$
%[text] for $n=4$: $(4-1)P\_4=3(0.00243)=0.00729$
%[text] for $n=5$: $(5-1)P\_5=4(0.0026)=0.00104$
%[text] $L\_q=0.145$
%[text] $lambda\_e=lambda\*\\pi\_s=2(0.7092)=1.419$
%[text] $W=\\frac{L}{lambda\_e}=\\frac{0.618}{1.419}=0.435$
%[text] $W\_q=\\frac{L\_q}{lambda\_e}=\\frac{0.145}{1.419}=0.102$
%[text] ## Part 4 question 6
%[text] How do these compare to the simulation numbers:
%[text] Comparing values for P: Very similar, a few decimals off
%[text]     Theory: $P\[0-5\]=\[0.527, 0.351, 0.100, 0.0182, 0.00243, 0.000256}$
%[text]     Simulation: $P\[0-5\]=\[0.5272, 0.3514, 0.1004, 0.1826, 0.002434, 0.002562\]$
%[text] Comparing values for $\\pi\_s$: Exactly the same
%[text]     Theory: $\\pi\_s=0.7092$
%[text]     Simulation: $\\pi\_s=0.7092$
%[text] Comparing the mean number in system: 0.698416 difference between theory and simulation
%[text]     Theory: $L=0.618$
%[text]     Simulation: $L=1.316416$
%[text] Comparing the mean number waiting in system: 0.575456 difference between theory and simulation
%[text]     Theory: $L\_q=0.145$
%[text]     Simulation: $L\_q=0.7204560$
%[text] Comparing the mean time in system: 0.164659 difference between theory and simulation
%[text]     Theory: $W=0.435$
%[text]     Simulation: $W=0.599659$
%[text] Comparing the mean waiting time in system: 0.18208 difference between theory and simulation
%[text]     Theory: $W\_q=0.102$
%[text]     Simulation: $W\_q=0.28408$
%[text] ## Part 4 question 7
%[text] In theory, the reneging statistics make the system look better than the statistics without reneging. The mean number in system and mean number waiting in system are smaller in the reneging system because the system doesn't build up as long of a queue, so the number says low. The mean time in system and mean time waiting in system are also lower because the patients waiting will also be waiting for less time in the reneging system. However, this is all in theory because fewer customers are served in the reneging system. 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":12.1}
%---
