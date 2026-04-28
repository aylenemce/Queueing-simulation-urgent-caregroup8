%[text] # Run samples of the ServiceQueue\_Renege\_Extension simulation: Group Eight
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
MaxTime = 50;
%[text] Make a log entry every so often.
LogInterval = 0.05;
%%
%[text] ## Numbers from theory for M/M/1+M queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
nMax = 25;
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

pi_s = 0;
for n = 1:nMax
    if n <= s
        pi_s = pi_s + (n*mu)*P(n+1);
    else
        pi_s = pi_s + (s*mu)*P(n+1);
    end
end

pi_s = pi_s / lambda;

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
%[text] The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.
for SampleNum = 1:NumSamples
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
%[text] Print out mean number of customers in the system.
meanNumInSystem = mean(NumInSystem);
%fprintf("Mean number in system: %f\n", meanNumInSystem);
%[text] Make a figure with one set of axes.
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on");
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, 'Normalization',"probability",'BinEdges', -0.5:1:(nMax+0.5));
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'Theory (Reneging)');
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system");
xlabel(ax, "Count");
ylabel(ax, "Probability");
legend(ax, "simulation", "theory");
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.2$.
%ylim(ax, [0, 0.2]);
%[text] This sets the horizontal axis to go from $-1$ *to* $21$*.  The histogram will use bins* $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [0, nMax]);
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.pdf");
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.svg");
%fprintf("Mean number in system: %f\n", meanNumInSystem);


%%
% ===== NUMBER WAITING (Lq) =====

H = zeros(nMax,1);

% P(Lq = 0) → system has <= s customers
H(1) = sum(P(1:s+1));

% P(Lq = k), k >= 1
for k = 1:nMax-1
    idx = k + s + 1;

    if idx <= length(P)
        H(k+1) = P(idx);
    else
        H(k+1) = 0;
    end
end

fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
hold(ax, "on");

% Histogram
h = histogram(ax, NumInWaiting, ...
    'Normalization','probability', ...
    'BinEdges', -0.5:1:(nMax+0.5));

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

%fprintf("Mean time in system: %f\n", meanTimeInSystem);
%[text] Make a figure with one set of axes.
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60);
%[text] Add titles and labels and such.
%tvals = linspace(0, max(TimeInSystem), 300);
%fw = (mu - lambda) * exp(-(mu - lambda) * tvals);
%plot(ax, tvals, fw * (5/60), 'r', 'LineWidth', 2);
title(ax, "Time in the system");
xlabel(ax, "Time");
ylabel(ax, "Probability");
%[text] Set ranges on the axes.
%ylim(ax, [0, 0.2]);
xlim(ax, [0, nMax]);
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.pdf");
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.svg");

% histogram for W_q
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
TimeWaiting = WaitingInSystemSamples;
h = histogram(ax, TimeWaiting, Normalization = "probability", BinWidth = 5/60);
rho = lambda / mu;
tvals = linspace(0, max(TimeWaiting), 300);
%fWq = rho * (mu - lambda) * exp(-(mu - lambda) * tvals);
%plot(ax, tvals, fWq * (5/60), 'r', 'LineWidth', 2);
title(ax, "Waiting time in queue");
xlabel(ax, "Time (hours)");
ylabel(ax, "Probability");
pause(2);
exportgraphics(fig, PictureFolder + filesep + "Wq_histogram.pdf");
ServiceTimes = cellfun(@(q) cellfun(@(c) c.DepartureTime - c.BeginServiceTime, q.Served'), QSamples, UniformOutput=false);
ServiceTimes = vertcat(ServiceTimes{:});
CustomersServed = cellfun(@(q) length(q.Served), QSamples);
%histogram for service times
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
h = histogram(ax, ServiceTimes, Normalization = "probability", BinWidth = 5/60);
title(ax, "Service Time Distribution");
xlabel(ax, "Time (hours)");
ylabel(ax, "Probability");
pause(2);
exportgraphics(fig, PictureFolder + filesep + "ServiceTime_histogram.pdf");

xlabel('n (number in system)');
ylabel('Probability');
legend('Simulation (Histogram)', 'Theory (P_n)');
title('Empirical vs Theoretical P_n');
%%
%[text] ## Numbers of customers reneged
%%

%%
%[text] ## Numbers of customers reneged
%%
classes = cellfun(@class, QSamples, 'UniformOutput', false)
%%
RenegedCounts = cellfun(@(q) length(q.Reneged) / (length(q.Reneged) + length(q.Served)), QSamples);
meanRenegedFraction = mean(RenegedCounts);
fprintf('Average fraction of customers lost to reneging: %.4f\n', meanRenegedFraction);





NumReneged = cellfun(@(q) length(q.Reneged), QSamples);

fig = figure();
ax = axes(fig);

histogram(ax, NumReneged, ...
    Normalization="probability", ...
    BinMethod="integers");

hold(ax, "on");

nMax = max(NumReneged);
n = 0:nMax;

counts = histcounts(NumReneged, ...
    'BinMethod','integers', ...
    'Normalization','probability');

plot(ax, n, counts(1:length(n)), 'o', ...
    MarkerEdgeColor='k', ...
    MarkerFaceColor='r');

xlabel('n (number reneged)');
ylabel('Probability');
legend('Simulation', 'Overlay');
title('P_n empirical vs theoretical results');


%%



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

%%
%[text] ## Theoretical Calculations
%[text] $\\lambda = 2$
%[text] $\\mu = 3$
%[text] $s = 2$
%[text] $\\theta=4$
%[text] $\\alpha= \\frac{\\lambda}{\\mu}=\\frac{2}{3}$
%[text] $P\_0=\[1+\\alpha+\\frac{\\alpha^2}{2!}(1+\\frac{\\lambda}{2\\mu+\\theta+}...)\]^{-1}$ 
%[text] $2\\mu = 6$
%[text] $2\\mu+\\theta=10$
%[text] $2\\mu+2\\theta=14$
%[text] $\\frac{\\lambda}{10}=0.2$, $\\frac{\\lambda}{14}=0.142857$
%[text] $L=\\sum\_{n=0}^{\\infty}nP\_n$
%[text] $L=1(0.3438)+2(0.1146)+3(0.02292)+4(0.00327)+5(0.000363)=0.6557$
%[text] $L\_q=\\sum\_{n=3}^{\\infty}(n-2)P\_n$
%[text] $L\_q=1(0.02292)+2(0.00327)+3(0.000363)=0.0305$
%[text] $P\_{abandon}=\\sum\_{n=2}^{\\infty}P\_n\*\\frac{\\theta}{2\\mu+\\theta(n-2)$
%[text] $P\_{abandon}=0.02292(0.4)+0.00327(0.2857)+0.000363(0.2222)=0.01018$
%[text] $\\lambda\_{eff}=\\lambda(1-P\_{abandon})=2(0.98982)=1.9796$
%[text] $W=\\frac{L}{\\lambda\_{eff}}=\\frac{0.6567}{1.9796}=0.332$
%[text] $W\_q=\\frac{L\_q}{\\lambda\_{eff}}=\\frac{0.0305}{1.9796}=0.0154$
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":12.1}
%---
