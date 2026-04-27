%[text] # Run samples of the ServiceQueue\_Renege simulation: Group Eight
%[text] Collect statistics and plot histograms along the way.
%%
clear all
clear classes %[output:0a76ae9e] %[output:003bb7e9] %[output:6b6b5613] %[output:39485733] %[output:65f1579b] %[output:68efbc19] %[output:7e16549a] %[output:0c04cf74] %[output:49604e18] %[output:3734ec03] %[output:679938a6] %[output:9a0b6dd2] %[output:7dd924b7] %[output:61099715] %[output:03c9c284] %[output:5a4cb466] %[output:87f51987] %[output:32edbe8e]
clc
rehash toolboxcache
%%

%%
PictureFolder = "Pictures";
mkdir(PictureFolder); %[output:583f20c7]
%%
%[text] ## Set up
%[text] `We'll measure time in hours`
%[text] Arrival rate: 2 per hour.
lambda = 2;
%[text] Departure (service) rate: 1 per 20 minutes, so 3 per hour.
mu = 3;
%[text] Number of serving stations.
s = 1;
% NEW:
%s = 2;
%[text] Reneging time is 15 minutes.
theta = 4;
%[text] Run many samples of the queue.
NumSamples = 500;
%[text] Each sample is run up to a maximum time.
MaxTime = 5;
%[text] Make a log entry every so often.
LogInterval = 1;
%%
%[text] ## Numbers from theory for M/M/1+M queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
% Solving 3.1 and 3.2
P0 = 1/hypergeom(1, mu/theta, lambda/theta);
nMax = 5;
P = zeros([nMax + 1, 1]);
P(1) = P0;

for j = 1:nMax
    P(j + 1) = P(j) * (lambda / (mu + (j - 1) * theta));
end

% Solving 3.2.2
pi_s = (mu * (1 - P0)) / lambda;

fprintf('P0 to P5: %s\n', mat2str(P, 4)); %[output:575fb7da]
fprintf('Fraction served (pi_s): %.4f\n', pi_s); %[output:290f43c0]

% NEW:
%nMax = 5;
%P = zeros([nMax + 1, 1]);

%P(1) = 1;

%for j = 1:nMax
    %if j == 1
        %mu_n = mu;                 
    %elseif j == 2
        %mu_n = 2 * mu;             
    %else
        %mu_n = 2 * mu + (j - 2) * theta; 
    %end
    
    %P(j + 1) = P(j) * (lambda / mu_n);
%end

%P = P / sum(P);
%P0 = P(1);

%pi_s = (mu*P(2) + sum(2*mu * P(3:end))) / lambda;

%fprintf('P0 to P5: %s\n', mat2str(P, 4));
%fprintf('Fraction served (pi_s): %.4f\n', pi_s);
%%
%fprintf('P(%d) = %.6f\n', n, P(n+1));
n_vals = 0:nMax;
L_theory = sum(n_vals' .* P); 

Lq_theory = sum(max(0, n_vals - s)' .* P);

%NEW:
%Lq_theory = sum(max(0, n_vals - s)' .* P);

lambda_eff = lambda * pi_s; 
W_theory = L_theory / lambda_eff;
Wq_theory = Lq_theory / lambda_eff;

theory = [L_theory, Lq_theory, W_theory, Wq_theory];
%%
%[text] ## Run simulation samples
%[text] This is the most time consuming calculation in the script, so let's put it in its own section.  That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%[text] Reset the random number generator.  This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.  This is a good idea for testing purposes.  Under other circumstances, you probably want the random numbers to be truly unpredictable and you wouldn't do this.
rng("default");
%[text] We'll store our queue simulation objects in this list.
QSamples = cell([NumSamples, 1]);
%[text] `The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.`
for SampleNum = 1:NumSamples %[output:group:0edf3b31]
    if mod(SampleNum, 10) == 0
        fprintf("%d ", SampleNum); %[output:4deb65d6]
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
end %[output:group:0edf3b31]
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
fprintf("Mean number in system: %f\n", meanNumInSystemSamples); %[output:2bf025e5]

% L_q Simulated
NumInWaiting = vertcat(NumInWaitingSamples{:});
meanNumInWaitingSamples = mean(NumInWaiting);
fprintf("Mean number waiting in system: %f\n", meanNumInWaitingSamples); %[output:4c399bd5]
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
fig = figure(); %[output:19bea5b9]
t = tiledlayout(fig,1,1); %[output:19bea5b9]
ax = nexttile(t); %[output:19bea5b9]
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on"); %[output:19bea5b9]
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:19bea5b9]
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'Theory (Reneging)'); %[output:19bea5b9]
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system"); %[output:19bea5b9]
xlabel(ax, "Count"); %[output:19bea5b9]
ylabel(ax, "Probability"); %[output:19bea5b9]
legend(ax, "simulation", "theory"); %[output:19bea5b9]
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.2$.
%ylim(ax, [0, 0.2]);
%[text] This sets the horizontal axis to go from $-1$ *to* $21$*.  The histogram will use bins* $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [0, nMax]); %[output:19bea5b9]
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.pdf"); %[output:19bea5b9]
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.svg"); %[output:19bea5b9]
%fprintf("Mean number in system: %f\n", meanNumInSystem);

% histogram for L_q
fig = figure(); %[output:1963ef25]
t = tiledlayout(fig,1,1); %[output:1963ef25]
ax = nexttile(t); %[output:1963ef25]
h = histogram(ax, NumInWaiting, Normalization="probability", BinMethod="integers"); %[output:1963ef25]
hold(ax, "on"); %[output:1963ef25]
plot(ax, 0:nMax, P, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r'); %[output:1963ef25]
title(ax, "Number of customers waiting"); %[output:1963ef25]
xlabel(ax, "Count"); %[output:1963ef25]
ylabel(ax, "Probability"); %[output:1963ef25]
pause(2);
exportgraphics(fig, PictureFolder + filesep + "Lq_histogram.pdf"); %[output:1963ef25]
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
fprintf("Mean time in system: %f\n", meanTimeInSystemSamples); %[output:2d9b2862]

% W_q Simulated
WaitingInSystemSamples = vertcat(WaitingInSystemSamples{:});
meanWaitingInSystemSamples = mean(WaitingInSystemSamples);
fprintf("Mean waiting time in system: %f\n", meanWaitingInSystemSamples); %[output:080ea54b]
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
meanTimeInSystem = mean(TimeInSystem);

%fprintf("Mean time in system: %f\n", meanTimeInSystem);
%[text] Make a figure with one set of axes.
fig = figure(); %[output:84872309]
t = tiledlayout(fig,1,1); %[output:84872309]
ax = nexttile(t); %[output:84872309]
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:84872309]
%[text] Add titles and labels and such.
%tvals = linspace(0, max(TimeInSystem), 300);
%fw = (mu - lambda) * exp(-(mu - lambda) * tvals);
%plot(ax, tvals, fw * (5/60), 'r', 'LineWidth', 2);
title(ax, "Time in the system"); %[output:84872309]
xlabel(ax, "Time"); %[output:84872309]
ylabel(ax, "Probability"); %[output:84872309]
%[text] Set ranges on the axes.
%ylim(ax, [0, 0.2]);
xlim(ax, [0, nMax]); %[output:84872309]
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.pdf"); %[output:84872309]
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.svg"); %[output:84872309]

% histogram for W_q
fig = figure(); %[output:3b9db938]
t = tiledlayout(fig,1,1); %[output:3b9db938]
ax = nexttile(t); %[output:3b9db938]
TimeWaiting = WaitingInSystemSamples;
h = histogram(ax, TimeWaiting, Normalization = "probability", BinWidth = 5/60); %[output:3b9db938]
rho = lambda / mu;
tvals = linspace(0, max(TimeWaiting), 300);
%fWq = rho * (mu - lambda) * exp(-(mu - lambda) * tvals);
%plot(ax, tvals, fWq * (5/60), 'r', 'LineWidth', 2);
title(ax, "Waiting time in queue"); %[output:3b9db938]
xlabel(ax, "Time (hours)"); %[output:3b9db938]
ylabel(ax, "Probability"); %[output:3b9db938]
pause(2);
exportgraphics(fig, PictureFolder + filesep + "Wq_histogram.pdf"); %[output:3b9db938]
ServiceTimes = cellfun(@(q) cellfun(@(c) c.DepartureTime - c.BeginServiceTime, q.Served'), QSamples, UniformOutput=false);
ServiceTimes = vertcat(ServiceTimes{:});
CustomersServed = cellfun(@(q) length(q.Served), QSamples);
%histogram for service times
fig = figure(); %[output:24dd4f13]
t = tiledlayout(fig,1,1); %[output:24dd4f13]
ax = nexttile(t); %[output:24dd4f13]
h = histogram(ax, ServiceTimes, Normalization = "probability", BinWidth = 5/60); %[output:24dd4f13]
title(ax, "Service Time Distribution"); %[output:24dd4f13]
xlabel(ax, "Time (hours)"); %[output:24dd4f13]
ylabel(ax, "Probability"); %[output:24dd4f13]
pause(2);
exportgraphics(fig, PictureFolder + filesep + "ServiceTime_histogram.pdf"); %[output:24dd4f13]
%%
%L_q (expected number of customers waiting)
%fig = figure();
%t = tiledlayout(fig,1,1);
%ax = nexttile(t);

%h = histogram(ax, Lq_sim, Normalization="probability", BinMethod="integers");
%title(ax, "expected count waiting");
%xlabel(ax, "Time");
%ylabel(ax, "Probability");
%[text] Set ranges on the axes.
%ylim(ax, [0, 0.2]);
%xlim(ax, [0, 2.0]);
%[text] Wait for MATLAB to catch up.
%pause(2);
%[text] Save the picture.
%exportgraphics(fig, PictureFolder + filesep + "Expected count waiting histogram.pdf");
%exportgraphics(fig, PictureFolder + filesep + "Expected count waiting histogram.svg");
%compute waiting time
%TimeWaitingSamples = cellfun(...
    %@(q) cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served'), ...
    %QSamples,...
    %UniformOutput=false);
%TimeWaiting = vertcat(TimeWaitingSamples{:});
%meanTimeWaiting = mean(TimeWaiting);

%compute Lq
%Lq_theory = lambda * meanTimeWaiting;

%final sim vector
%theory = [L_sim, Lq_sim, W_sim, Wq_sim];

%L_sim_emp  = meanNumInSystem;
%W_sim_emp  = meanTimeInSystem;
%Wq_sim_emp = meanTimeWaiting;
%Lq_sim_emp = lambda * Wq_sim_emp;


xlabel('n (number in system)'); %[output:62f82b61]
ylabel('Probability'); %[output:62f82b61]
legend('Simulation (Histogram)', 'Theory (P_n)'); %[output:6b9f681a] %[output:62f82b61]
title('Empirical vs Theoretical P_n'); %[output:62f82b61]
%%
%[text] ## 4.4
%% total time in system
TimeInSystem = cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served);
figure; %[output:3945ed50]
histogram(TimeInSystem, 'Normalization','probability'); %[output:3945ed50]
title('Total time in system'); %[output:3945ed50]
xlabel('Time in hours'); %[output:3945ed50]
ylabel('probability'); %[output:3945ed50]
%%
%[text] ## waiting time in queue (Wq)
WaitingTime = cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served);
figure; %[output:59a0e43a]
histogram(WaitingTime, 'Normalization','probability'); %[output:59a0e43a]
title('Waiting time in queue'); %[output:59a0e43a]
xlabel('Time in hours'); %[output:59a0e43a]
ylabel('probability'); %[output:59a0e43a]
%%
%[text] ## Service time
ServiceTime = cellfun(@(c) c.DepartureTime - c.BeginServiceTime, q.Served);
figure; %[output:43ce02de]
histogram(ServiceTime, 'Normalization','probability'); %[output:43ce02de]
title('Service Time'); %[output:43ce02de]
xlabel('Time in hours'); %[output:43ce02de]
ylabel('probability'); %[output:43ce02de]
%%
%[text] ## Number of customers served
ServedCounts = cellfun(@(q) length(q.Served), QSamples);
figure; %[output:781c8d78]
histogram(ServedCounts, 'Normalization','probability'); %[output:781c8d78]
title('Number of Customers Served per Run'); %[output:781c8d78]
xlabel('Time in hours'); %[output:781c8d78]
ylabel('probability'); %[output:781c8d78]
%%
%[text] ## Numbers of cusotmers reneged
%%
classes = cellfun(@class, QSamples, 'UniformOutput', false) %[output:63b8511d]
%%
RenegedCounts = cellfun(@(q)...
    length(q.Reneged) / (length(q.Reneged)+ length(q.Served)), QSamples);

% NEW:
%RenegedCounts = cellfun(@(q) length(q.Reneged) / (length(q.Reneged) + length(q.Served)), QSamples);
%meanRenegedFraction = mean(RenegedCounts);
%fprintf('Average fraction of customers lost to reneging: %.4f\n', meanRenegedFraction);

figure; %[output:4cc57ed6]
histogram(RenegedCounts, 'Normalization','probability'); %[output:4cc57ed6]
title('Number of Reneged Customers per Run'); %[output:4cc57ed6]
xlabel('Counts'); %[output:4cc57ed6]
ylabel('Probability'); %[output:4cc57ed6]
figure; %[output:306a9801]
histogram(RenegedCounts, 'Normalization','probability'); %[output:306a9801]
title('Number of Reneged Customers per Run'); %[output:306a9801]
xlabel('Counts'); %[output:306a9801]
ylabel('Probability'); %[output:306a9801]



%sim = [L_sim_emp, Lq_sim_emp, W_sim_emp, Wq_sim_emp];

% Safe percent discrepancy calculation
%pct = nan(size(theory));                % preallocate
%nonzero = theory ~= 0;                  % indices where theory nonzero
%pct(nonzero) = 100 * abs(sim(nonzero) - theory(nonzero)) ./ abs(theory(nonzero));
%pct(~nonzero)  = abs(sim(~nonzero) - theory(~nonzero)); % absolute diff when theory == 0

% Display nicely
%for k = 1:numel(theory)
    %if theory(k) ~= 0
        %fprintf('Stat %d: theory = %.4g, sim = %.4g, discrepancy = %.3f%%n', ...
               % k, theory(k), sim(k), pct(k));
   % else
      %  fprintf('Stat %d: theory = 0, sim = %.4g, abs discrepancy = %.4g\n', ...
              %  k, sim(k), pct(k));
    %end
%end

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
%   data: {"layout":"onright","rightPanelPercent":12.1}
%---
%[output:0a76ae9e]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'Renege' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:003bb7e9]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'Customer' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:6b6b5613]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'RecordToLog' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:39485733]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'onCleanup' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:65f1579b]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'PriorityQueue' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:68efbc19]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'ServiceQueueRenege' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:7e16549a]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'Departure' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:0c04cf74]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'Arrival' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:49604e18]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'prob.ExponentialDistribution' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:3734ec03]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'Renege' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:679938a6]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'Customer' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:9a0b6dd2]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'RecordToLog' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:7dd924b7]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'onCleanup' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:61099715]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'PriorityQueue' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:03c9c284]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'ServiceQueueRenege' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:5a4cb466]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'Departure' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:87f51987]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'Arrival' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:32edbe8e]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Objects of 'prob.ExponentialDistribution' class exist.  Cannot clear this class or any of its superclasses."}}
%---
%[output:583f20c7]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Directory already exists."}}
%---
%[output:575fb7da]
%   data: {"dataType":"text","outputData":{"text":"P0 to P5: [0.5272;0.3514;0.1004;0.01826;0.002434;0.0002562]\n","truncated":false}}
%---
%[output:290f43c0]
%   data: {"dataType":"text","outputData":{"text":"Fraction served (pi_s): 0.7092\n","truncated":false}}
%---
%[output:4deb65d6]
%   data: {"dataType":"text","outputData":{"text":"10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300 310 320 330 340 350 360 370 380 390 400 410 420 430 440 450 460 470 480 490 500 ","truncated":false}}
%---
%[output:2bf025e5]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 1.316416\n","truncated":false}}
%---
%[output:4c399bd5]
%   data: {"dataType":"text","outputData":{"text":"Mean number waiting in system: 0.720460\n","truncated":false}}
%---
%[output:19bea5b9]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAGaxJREFUeF7tnQm4TtX3x7cGaZRSkiG6jTQYIiW5hhTin6lQiqSQSKQy5CZKhkijDCEqGZJGabgqpRIajJmi6MnYrIT\/89ms89vvue\/7nvO+5z33em97PU9P7nv2cPbe37P2WmuvvVaBffv27fvrr7\/UkUceqRKln3\/+WR1xxBGqcOHCMatu375dXXTRRc7zu+66S3Xp0iXRrnT5f\/\/9V\/\/\/sMMOS6p+IpX++OMP3V+8sc2cOVP17NnTafazzz5TJ510Usxu9uzZo3766Sd1wgknJDXfNEwbhx56aNQ+4j1zV2Bsu3fvTuo99u7dq+uy9m76559\/1K+\/\/qqKFCkS8z3jrQPtQgXq1q277++\/\/1Yffvihr3V799131fjx49U333yjWDzoxBNPVJUqVVKA7uyzz3baGTlypFq3bp167bXXnN8uvPBCXaZ69eqqUaNGnn3u2LFDPf7442rRokXq66+\/1uVPOeUUdemll6r27durc88912lj\/fr16v7773f+bteunapVq5bz98aNG1WfPn2cv++44w5VpUoV5+9NmzYp3vmDDz5Q27Ztc36vXLmyatWqlWrcuLH+KLZu3aqGDRum1qxZo7788kunHOPhA7\/vvvscQAOWcePGqTfffNN5fyqULVtWVatWTQObRTSJ+Z0\/f77+6ayzzlLXXnut4iN4++23dZ916tRR9evXV02bNlXMD+\/8ySef6Ge0e91116lbbrlFHXLIIRHtsuhjx45Vc+bMcd4lIyNDMb4bbrhBnXfeeRHl7733XsWcQC1atFBnnHGGmjZtml7PevXqqUGDBulnMDba5dkPP\/zgtMG7UI+5i\/eBSwXaue222\/YDs2zZsvtKlizpCUy+sEceeURPcjwaMmSIat68uS4CeOAQ0QjQ9OvXL25bixcvVrfeemsESNwVnnzySb1I0PLly1XDhg2dIua78CPtNWvWzHn+zDPP6AmOVjfaizHBLAYAr1mzZsx3\/\/jjj9Wpp56qAczHyt+xiI\/s6aefVnywQtSZNWuW\/pPnAMr8UKTcQw89pCZPnqyWLVuWo3lAy8cjBMCYy2hlpczEiRNVjRo1nDrm+jH22bNnO8xI5gLu2KRJE82AYlG5cuXUSy+9pI455pi46\/3bb7858+AbmFOnTtWcwA+98cYbmpM1aNBAL6JwVql79NFHq7Zt26oePXrEbA4uDreLBWyzItyCBQwCTLiQOblMJl+we8JfeOEFVapUqYgFNN+Fsc2bN09v1ybA4s0bOw47lohTfut5rcXcuXMVHBGCE\/G3F73yyisOOOIxFgHmAw88oAC0EEyuWLFiETsJz7p3767YoeJRBDB79+69j4nu2LFjzDoAKzMzM+KrhduwmMgUzz77rHrsscec+pdffrmaMGGC\/vuXX35RFStWdJ5lZWWpG2+80Wt+tLgwcODAiDbZhnkXtna2W6Hhw4frrzZZYCIC1K5d22nPlIPZqtmOhG6\/\/Xbng4onY3777bd66zcXbPTo0fqDhZPykb\/33nvOc7ZNOBrkBiZbOcCCO3Xq1CniY+WDpN2iRYtqbo7IIMT8tW7dWi1YsED\/XwiuePfdd6vSpUsrgAi4hARw\/B0NmJdddpk688wztejG7oQoJNy8atWqmjNCcOiWLVs6Wzs7An35BibKjxdKAAHynFA09PMSn3\/+uVOGBUV2ShaYMqHSIG0z+dCWLVvUxRdf7PRFWRYhWWC6QcRid+7cWV1yySVaZmNh4eBQiRIltNwHxQMmYg+AEXrxxRcj3hmQVahQwXl+zjnnOKByAxMRRGQ0PsoRI0Y49R599FF1zTXX6L+\/+uor\/YEKCdgpTz0h2dHkb+qL\/M5vS5cu1dzbDUyYj1svOP300yPg061bNwVjKl++vJZ5ZcdjGzfl+WiYi+CYfoDp5l4I4bI40sGUKVMiZMYZM2ZoTpksMM0v8YILLnBkrngfUbLA\/P333xV9RCO2ZrgpC4JoYWrE8YAJ90NRhGgDZdFNWCdMDrdq1SqtXJnAdNd194ncJ0rL5s2btVIpJAzE3Q9Kl0mmIsvvsr4mMGONAUXriy++iDp3cFe4Kv95yZc0kDAw+\/fvr55\/\/nmnc+GG5tu88847EeKAfF3JABPuZGrbgMIUFWKBM1lg0t706dNVr1694uFef\/GIMKJFu0GyaMQIdTyms3nz1KSJE9WOnTvVZ4UK6S1z8IIF\/2s7O1v\/+8MBA9TiJUv0vyk3atQoVbR58whgIn+aC49GDFcSMpmEG5giklx99dVxlR73oIWpmMBk+zdlSanDboMiG005kzLsQIh7bq3f3W\/CwHRvHwj3yKUmuRd20qRJii8mGWBiATA5MpzKyxrAu7iByXZqyofvv\/++NqMImVo5v61du1abPF599dWYSpep7Qowu+3cqbrt2BEX1Cozc\/\/zA6CMWTgzU61ZvVr127NHLShUSNUrWFB\/DIAdWrVypco60AbPTWBumzlT3dGli7p41y5dFmBV6dlTPTx4sBqzapX+Dc7XuVw5\/e8Mw7SzpmRJ\/duaUqW0GMMWTf0y69fr39uWLetYMJRYJA6MiR0HpRDuHUvrB5zZ2dmqYMGCMYeeMDDZbkyjOHYzU7CnJ+SZl19+2en0o48+0vJYMsCkEeQUsYkxKDRvIeQzZF4xuF9xxRV6MgFW3bp1nXJwFpO78NUOHjw4BzAR1H\/88Uf9O7Y\/BHsUIuRadgJT0WJhkccKFCiglrdsqc6dOjU+IEN8CpdFBDmyQQOlsrLi9kRZSEAb78PQzwCdR5t7atRQf\/75p\/qxQwf1W6VK2j7Nbrdw4UI9ZzArk9yyrfsdEgYmi2batzAJAEIAA7k1V57zdbDIyQLTLReZQr5bnh0wYIA2ELuVIjRBtEROKNjm+JjMLUc4JmKCKSqYJhPG51bsvhszRh1qfAAhYi9tmn6sSBF1zNChEUqye6d1K4CBgUkDDz74oHruueectuAcmJB27doVYfagwBNPPKFtmFCywHQbw2kL0YAjTnO74D2wAYrc59Yk+XgQO6IJ6AJMt9UBue6mm25Sxx57rObaphhxU5kyqr9hqkob5OTCi8KVV7ZurfZdfrnauXOnNv6bjAAli\/WKRQlzTBri6At7GiaAeAQg+VLY6oIAk7psw+ZxZrR+zZMfniPr9O3b19cyCDA5+8VOaNoVozVQbdcu9cLmzb7a\/i8Xal28uJaPTfLjI5EUMOmEkxCMuCx+NMJ43qZNGweUQYEJYJALOVp0E1yNZ6bxXsrwOx+HeeKE7Nm1a9cI2dhUfpgUxIVomiftchI0ZdMmVXjx4v8y5nyPXcDJOnHig6jlPrt3N8Z6nX\/++frnAn7smO4GACicE2Xj8MMP1xo0JhH+HQaZ\/RUqVEiDBMVKuHK0Pjk3+P777zWnR+aN5\/Vj1kfDRLvnKJX2qVe8eHGVgbnMOCEJY5z5rc3ly5Zp7T6aF5LXWJMCplej+e455hnDSynfjS+sAaHV9++fVOsWmH6mjQm23NLPTOUs433iHbVdC0wf070hI0OVXrvWR0lbJMcMJMk1LTA9sPTD5MmqZJs2FnFBZiAJrmmB6THhUzp0UNePHRtkWWxdC8zUY2BWxYrqmgOOFqlv\/T\/SIgcS4ivgc8iWY3pM1LjSpVX7jRt9TqctFnUGkpAzLTDjYAn76bMlSnh7Dlk8xp8BC8zUIoRDhH41athjyKDTaoEZdAYj68ttyLVxbgCmtsd82pqVMVO7sHJ2a4EZcF4tMANOYJTqnPX68lBPfdf5o0W08STcBK3y47H84npnuWaS30kS8iU9WWB6zLc4EVuumSQwk9jGLTB9zDX3iu688059zdZyTR8TZhZJkltaYPqcZ6KN4IG9feZMazryOWf6pCcJ2VKat1u534k+cCF\/w6RJqnySYRQT6Cr9iya5hVtgBll6HIfxz\/S6Ix6kj3SuGxCUdisPuviA0+PuddAu0q5+CkBpgZmKVc\/OVt80a6Yv\/vsOJpAfOW0ARSfaMlgZMyA4iRhMWD7ond69ddRdCefCb9O3bNFR4X6tVEm9\/vrr+3sTYB4I+6J\/M8OuiKhglo31ngBC2vMCvN8wNVlZatv06Wr16tXeH1uKAWllzICAlOoERCCcDfTdd9\/liDtOxDciv8WKlub5Gl4gNhvwW9ZHOYmi0bt6dbV3zx513OLFOv67vjXasuX+a7YJ+lh6jtUoYDlmIrMVpSxhrAlEGwt4RAAhVB8kYQYDdpkr1b2iGnNPnNA8YZEFZsCZJTZS7969dYDXaJE8zKCwBFYl7Ew6kARzJcQOCRfgkAQzI0iEREdxR9NL5bgsMAPOpoQijJVggYhxBOWCkNm8olEEfJ2UVSe8IXGHiKR38sknR7QrQWnNKMgp6\/hAQxaYAWeUcIsE4Iq1lUtAW3cA1oDd5ml1M84oUUuSibThNQALTK8Z8nhuBouV7BlmlTFjxqiHH35YRyMm80c6kCSngrtHAx2JtkgiEKbcbIEZECksIkkE2PYI1Xj99ddHtChhpslS0aFDh4C95U514fLsAoSDdGeiI8wkAchC3cpbtWrlmbUid6YjfXvZsGGDTh9C4gCCxUo4Z1IaEngM4vdk0iImOytk9TCjKSfSjhkA10zzQhvsEISjxLs\/zI+tgAVmIkuWXmVjhYv0MwqyrpGGTz4qwj3yoUmWDawQ\/DsM+ZI+7VbuZ5XSrAxhu5EDgwATEYWguNGyhWBKImlVmKYvC8w0A52f100FMKUfAtpi5iKRFPkxuQMVJiClXwtMPyudZmVSCcy8GroFZl7NfIj9WmCGOLm26eRnIF8Ak3zlyU\/B\/2p65XBJRR+2DX8zkC+AWf\/WfoGBuWLuZGWB6Q80uVEqXwDzzpdXBAbmq\/fUDwxMSQvoTrOXGwspZ79mLvJE+iXTBcZ1MaBLstG8Ooa0wDyweqkApmSVJRHUPffckwguApcVYJIAFRe2REgyBZveRQJMv+msE+nPT1kLzBQCE65DTh7yWkv6PT+LkIoyqQCmmYgV4zTgJO+R5NtMxXv6bcMCMwFgklNy\/vz5Ojcj7vnckzHzV\/OcsH8sZNGiRXVmXRxrjzrqKJ27nDNnfBupx7kzjgXUWbRokT6nJglWhQoVnCRYcDKy5AJ0M\/c5r0xbOF3A0ThSiwdM3olTFDxtOJYrU6ZMRDpC8iPiwY5b21NPPaUTYzG+lStXqsKFC+dIn43j8NKlS3VCVu4HcaZtfogy7uOOO04\/X7FihR4H84CzLv17kQWmT2AuWbJEp\/IzU+hRFfd8vKMBmXsrN7dDFt1Mzcy2yVlu9+7dI5JokpaPYzQ41bp161SdOnWiuptJNl1JXR0NmGQcxrVLUlMLGHgXvLgrV66sL5n17NkzAic4PTRq1EhVr15dA3\/WrFn6OdGJBw4cqGVxk\/DgGT58uJMLXMbNPSJOWEilbBKgo\/14ZIHpE5jceeHuS58+fTSHgFsALCL2Tpo0SWfVjQVMWYC2bdvq1HnkiZSMrnBXPF3gLiNGjNDAJxckKayDArN169ZqwYIFGty8P5yVdNEATdy9AC9cnRTWAjC4HEqQG5jkSefdMzIytAwNwMkaLGfRXFrjuE+AKeNGGYRT4opGKm4zX3oscIYFTLLpwkhiXSPx4uSJPC8QtlbOzcErr7xSTyh5zcUlDKCiaAAs\/BTjAZMJId0zZHIp0zGX+yejR492XLGCAHP37t06KTzAR\/yQnJXIwXBBiI+K30X5MWVMt\/KDqMHHByEWmHktJVc6XJB\/m8DEu6d27dq6Hrkxa9asqTm4cPrcBiYfPc4b5lgTAVsiZUMHppnql\/sjbOnIau681bGA6b6yALhbtGiht9Jp06Y5Y5X6cFa+6iDApFHACfAQM1DKcGL49NNP9XacKDC5P9O5c+eIrV1eHI7bpEkThwsJMKNdxYAzY1bzshmHxTHzFTDdXE4WBA7CgsApvGRMkdOoi0d1s2bNFHnR8aQWSgSYIlrEkzHXr1+vRo0apebOnZtDNk4UmHK9IpopzEyFDBfmA3CLATJG5Fl2DNzZqlWrFpMBmcCEy4tfJeNGHIIQobZv367q16+vxYrZs2fruUXMYldAxhUuD3MZN26cFm1QQGEW7du310ob953CoNA5prz01q1bVXZ2tt6GUDZEERLbYSyO6TZSpwKYiAUAIBYwUVSqVq2q3xF5ki0U2bB8+fJaA0fGTWQrl6sI5O1GYTMJCwFKm3DIeMb5ZIBpeqMjI2PRgAAeYgGHCjNmzNDz4SaUMpiHW+6VcmHKmqEDk4nH5EGOcTF1sE0yGciYslWHBUz6dUKzHNCOARgUC5hcGuPaAKDkvTjVgQCs1E0EmDK2aAZ3dgOCC4hoktvAFJA1bdrUkWGHDh3qYBRRgxzxjAHLCFYC1gxxCVMcHDcMCh2YDAROgZKDZiokqUrCAqYoJfRnBhqQ0CfxgDls2DBtk3RHmxg\/fnxMGdOUCd3Kj4zV7JN\/7927V3Xs2FGhkffv319vi3kBTLcJSo6HeUdT8cxXMiaKA9sG2yITz41C7o5Mnz5dG45l8VPNMZlUtiFACddE8Vq2bJmWGYVicUzz3jRbHVo02rlZFyA1b95ccw8RDfj4kOPQWt1yIuFUJkyYoLdswAi3oR\/aFNMRZqbcBiamNQBnEusjMixiCPI8lK+AyYAQmpFX0KhNYsBwURZJvlJREJB5WHBkPcKwCHnJmAjl2EshNHM+BjGSi92T3\/kQ4ik\/5mUs2gKAgwYNUigC\/fr10+0DVpQJFAOeQRjYGzdurN\/d3Lrh4MyBKCIyHmQ+uLMoJbHGTXmRMRPRyv3ImD169MixG2NThUTOzHVgVqnzf4G9i7au\/drThMHAOI4DFMcff7w67bTTVOnSpXNMSBg\/YAiHY3OcKTZJP\/1QDxmZY0YEfanLYqPtMgYJ+cLOQB\/FihVzjkWj9YEmTHAt5GyM8QJIP+\/jt4yplZs21GjKT9++fdXNN98cE5iINcifuQ7MkSNHBgYmLw3r51THUt7PgAlMM9pcNGBmZWVpS4Ob8pxj7uNIwVK+mgETmMjyvXr10uOzwMxXy5x+gzGByYkTJ08WmOm3jvnujQEmfgS1atVSQ4YMccYXlGNKLFAadJ\/5p3oS7fXdVM\/oQdCeOIbwKpiixBsrKDDNyHa0zYkVHlNhkAVmGLOax20KMDFXEQKxYcOGObZy3PmwkCSi\/HAggMlKfBdCPZLMK+WHQPN4a+PUmy5RdvMYb767B5j4JeDwkYh5zG8HHAJgLsM0hi9sGJQrHBPjMnY7Tjbk3JmzVo67zCOvMAb4X2wzLLe33JzLXAHmyJEjtQuZeSaLYRf3LQvM1C+3BabPORVgmqcIFpg+Jy+JYhaYPiYNJwoO\/xGYcYjIzMzULl4mMLktuXDhQn2mjasZd1yiRd\/lKJBbiZwnc\/MR54xogUMRGziX56YiKZ1pk5Mp5Fkhjhs5ruMKBW2QCgVnDZF3K1WqlEM+Yyy0R9+c7x+sZIHpY2XE88YsyvmzAJObiO6bgzgH4xhhLv6UKVMc5wlpC8cKPLG5qmECjsT3bocRwAnn5povJJfDcPjgd865u3btqvvl33h0m9eLTY8bbn2GJfT7mFLPIhaYnlO03xkXx1u8h7iPA1CxfwkwaQLOB0Bx1edODRzRDLQvF9AAIvVwqsCAzDVaaM6cOdpBA3MGnj24t+G5hEsdmj93g\/AmMsMzCzCpj62P8vz31ltvabC7w8XIhyGXxnwMPc+KWGD6nPp4MibbOsCVLRROBccDqLiS4TWOPydGYrnqK92KvY6ESLibASoABXekHcm2gGmKS3C43+HOxr1yASZg5xqtBB2Qy27uhFJyFx2OyonKwUwWmD5XJx4w4ZDc4RaSFHfIhGjt8rcEPRBzE+VxH8MZmPs4ONyKMy6OuOK4IO2KzyQA5QqqALNdu3YRIgJcl0tYcG2875EnxacREBP5w5RVfU5BrhazwPQ53fGA6eZA3KXB21wuoZlu\/rG6k+sZiApwv2hcTTKYwX3xJBdgIg7Uq1cvomnhxMiccG85I5arwT6HnWfFLDB9Tn0i5iI3MGVrh2PGuipKXB+cXSV6hnvL5zXlghkZF0ieJMDkrBeZ1yR5Bzlyk3a5QGcqWj6Hn+vFLDB9TnkQYMpVCrgi2rC5lZMNlrTMBOHiCoYoVLh6RYspRIgV4YLxgMmwJKMZIMeRFplz3rx5oRzx+ZxG38UsMH1OlQAThwLJ3R3LwO7mmJzJcoENEw5bKgAUkrAwcjdduCsyJ1d2xcZJVDi4IgqUmIG8gAkgcXDgg6BvrtgSCSMdyALT5yrhbsWFJ7ZGlBUW2C8w6UJkPEDSqVMnfQsRTonRnt8wF5GDBu0bcw732NH22bb5DU6JCemqq67SF78gL2Cal7goj+wK10wHssD0uUosMnIa3BDCwC5OHG4uKDGHRCunPLc\/0NDldqJ0i1kIk5Ip99EX2zjKjkmYe7hyK1xUuG00GVPqiTIlCpPP4eZ5MQvMBJYAzsUxIDEfk40YzLZO9DhuJHK70B2QVV4HIHPciDmJ0yNOewiimihhG4XbxgNvom3mRnkLzNyY5TzqA\/AjDmAN4JTpYLddmtNkgZlHoAmzW64PEJ0NZxFEj2g5yMPsPxVtW2CmYhYPsjbkSJLXQpHiMldYqY\/DGroFZlgza9sNNAMWmIGmz1YOawYsMMOaWdtuoBnIF8Bs1aqVDRETCAYHX2Xc+0w78MH3ht5vVMAC03uS0rEEAc5IxZKulCu3JNN1cux7590MWGDm3dzbnuPMgAWmhcdBOQP\/D\/XmyLbPHxWFAAAAAElFTkSuQmCC","height":0,"width":0}}
%---
%[output:1963ef25]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAFXBJREFUeF7tnXmcj9UXx8+MjPFKGCpLiyWVVnp5KZEm0aZUtFKISiVLSlqoSUqLrVK9UCktlCiUtDNUUrwU7QtZshtMZBB+v\/fte5\/f\/T7z\/X6f7\/bMM\/N73fMP833ucp5zP885555777kZ9erV2y8i8v3330vFihX5r+zdu1fKlSun\/h8P7dy5U5XPysqKp3hYmT179khGRoYccMABCdXdtWuXbNq0SWrUqBGz7pAhQ+TFF1902v7xxx+lQoUKCfWlC9Mn7wi\/ftK+ffukoKBAKleuHFOmTZs2lc2bNytWrrvuOrn\/\/vtjshWvzKI1EgsX8Ixc4pXN9u3b5cADD4xaPkMDc8GCBfLqq69Kfn6+LFmyROrVqyennHKK9OvXTw477LBivAKKJ554QubPny\/Lly9Xz5s0aaLq3HzzzVKtWjWnzpYtW+S2226T\/fvVNyD33XefrFq1SqZPny7vvPOOPPnkk9KuXTvPsd62bZuMGDFC9fn777875U8++WQ577zz5MYbb3RAumjRInnzzTfl66+\/dvijwpVXXqnqDRo0SCpVquTZ588\/\/yzPPvusfPfdd047yKZt27bSuXNnOfTQQ502eA\/6hQDV008\/Hdb+6NGjFT9Q7dq15dFHH3WeM7AzZ86UsWPHyg8\/\/OD8Xr16dbnoooukS5cuakwgZPb555\/L5MmTnXI8A6innnqqdOjQwfk9EZlRaePGjXL33Xc79fv37y98zJ9++qm89957ioezzjpLunXrJocffrjiedq0afLll186GOADqV+\/fjHZ0g4y+Oabb2TdunUKmGCmefPm0r179zAF4wDz+OOPDxOIbpXKL730kmpA01dffSW33nqr87W6OYDh1157TY444gj1CBDm5uY6xW666SY1AJriASbA6NGjh3qhaMSg8OKHHHKIvPXWW4JQo9HChQvDPp5I5V5\/\/XW59957o7aBbGbMmOEApmfPnvL++++r8gBKg1A3gFabO3eu+vOoo46Sjz76yGn79ttvVwMcjehr6tSpcswxxyjgmKA063Ts2FEefvhh9VOiMqPOsmXLpE2bNk6TjLv+2Mx+wAt9oWQiEYA97rjjnEcTJkyQwYMHR30\/+gQH2mo7wIxaQ0R9GZ988omUL19eduzYob4YbUKi1WNg5syZo74KNzDddbyAiQlq1apVTFDqNtFkaCq+7rvuukvxaxL8QAAkJycn6mv\/8ssvcv7558cSi3rWsGFD1ReULDBnzZqlPnRN8HjSSSc5Wkj\/zofHx\/LAAw\/Iyy+\/HJE3rNWAAQMkGZlFAqanAKIUwAIyrvoDufjiiz2bApzjxo1T5cKAyQtjDn799VcZOHBg2KAOHz5cmQg60x3SACodE\/rPP\/8oQJhfsgZcJGAifFR4nTp1BKZPPPHEqIyPHz9eHnroIed569at5ZFHHpGDDz5YmRk08OrVq53naBZcCghzqV+WPpcuXeopIAqgnT\/++GOnLAN+7bXXKi302GOPhbkHfIBHHnlk0sBEs6PhNWl\/Hz8M7aiBz3PcLO2CxPIxk5WZW2MiM1wZTDNji0UyqU+fPnL11Vercbj++uvDPi4t66uuuirMejB2F154oXLHwNy3337r1Js3b55yHR1g4nNh5zUxKAyOJkAJOK+44gpHtcM0al5PevAlTZPfsmVLQYW7gUm9KVOmyLHHHhsXSC699FI1IBB1v\/jiCznooIOcuvg3nTp1cv5GQHxYyQKTCZnJW6NGjZQZzczMVG26ZaM\/wGQ1pvsjuPzyy5XP3bhxY\/nrr78EP1dTixYtHHnHAmayMnMD84YbbnDcGbSwaZ5r1qypxkITCgrLqgngFRUVyQknnOD8hhUC6JoAYteuXZ2\/77zzTrnlllv+B0wa1M41pXbv3q3MlCYAx2QCE2Oax2bNmoWBSzvBGkR8NW5gIrSRI0fGBUomBQ0aNHDK8qW5v1oemnydeeaZyi9OFph\/\/PGHnH322U6f2jx6MZwsMN1WyOwHXw735JJLLik2CY0GzFRk5gbm0KFDlUbUhJXTfr5penmOcps4caJTFneI9kyXCBfv6KOPdsow0zd9ce0COBrzp59+KhaaMJng6\/jggw8E7ZEIwZgbmPqriKcdZomnnXaaU9T8gs3655xzjjNTxyfWk4xkTDlaALOtyT040fguBsxhw\/4tmp+v\/mFyM3n9ejmtqEiq5eRI5y5dRHJz5e+dO6XT2LGOVYjWPhGJ9u3bO4+jATMVmbmB+fjjjwsaXBMfvXab3ErCDUxcQsbBNPFeY67B7gAT82RO8d1qG405adIkNSvUpENKsTrD\/LuB6X7ZWPXdmptwjxlm0XXNQdLaPVmNiXuCy6IJP890a7yA2XfrVum7ZYvXGIQ\/z82VzQUFMq52bVm6ZIkCr6YF2dnO3106d5YcwJmfL8+NG6dAzXO0Upfx41WVVGSWTmD+9ttvsnjx4jBZMoFDcUQjrCMWygEmgehrrrnGKU9IyFTh2sc0NZOeAXuNQCrApG0mOzpWykvNnj07bAFg5cqVKlKgCb7RcskCE1OFtYjUHr9henT7\/E2MlnDYB82by3nz53uJw7\/nWgZ5edJ6yJCkZJZuYBK9MS2eG2fRhBEWx3zllVdUCIUZNsI2Z4PanPXq1Svsd2aTOOnQn3\/+qb4OHHaIyQ+ObqrAJGBL8F\/TPffcoyIBEJqdRQAdP+Q3HUFIFpj4aLgspi+tLQo+ETFHgtyaZj\/wgNQxHHj\/kBd\/y7Nzc+X6lSsTllk6gcnkh5Ug0\/9HsbCwokN1BO779u3r8MlYMgkPCxfp+Nn69evDwiH8jgYl+Em4xB2TQqOxzGcCmZ4ICxAqSBWYa9euFWajJmGuCTXBlxkqInBNXFAvcSbjY9LPmDFjBJdDEzI4\/fTTlWkyY7hd69aVvNmz40dMCZbExD+ZkyNfZmerXuORWTqBSVsQMVfCQqYssbxr1qxR42cSCgZ3Ma4AO0uPJhiZFY8aNSqmiDHzTz31lAqxpApMOmIlKdoqg\/nC7lWqZIFJDJF3MEHvfuFzs7JkjBHKKUHMJdRVp1q1HHC6K7pX9vwAJhaIyaQZsYn0AoCXpVfIASaozsvLK6YpCWWYoRPdIKbtwQcfjDhwBMNZrtIL+ukAJv3i26H2Iy1Log34WNyOdbLApD9cEmaaptnW709\/E9eskfJGHC8htJRw4UjgjCQzfHksoKZYs3J32M89K9cak7aYkOEq6uVS8\/WJ+IAzJrCaMvbrnRWhXwg1EMdjvRlTGWu3CL4oEw8YICjNjKpu3bpq6dIvgl1MAH3icrAeT1zM3DSS7r5ZOGCGuWLFCkGIxBarsQJimKd09+lHe\/Pmzi0xmUXjn51o4At5soKF2WZDixtnxYDph0D+X9rko2BXVfbChXJQ27Zl77X4kPLyygTfFphxDBOAZE8nroKeqTfcvVvO2bFDem\/dKontJI2jQz+LhLYe+tlFOtq2wIxDimzaMLfpVS9XTjbv3atqXrltmzxSUCD+bh2Og8l4i5QRrWmB6TGg5vY3tqb1adxYyrdpI\/MqVpSuNWuq2o9v3CiXb98eLzSCL1cGtKYFpgdMWFh4\/vnnhV3yLCZkstG3VStVa2i1avJ8lSrS7O+\/ZeL69cEDLl4OLDDjlVTpLad3nTvr5ezCDs3GP6tQQbrUrq2Y\/2bFCqm8b5\/zIgS3Sy3Bv7GEG4lPcxkxiPewGtND6nqHFVv+1F5TA5hbMjOlSZ06qoWPV6+W+nv2qP8Dyo61agUxnmnpk1ixuUyYlkYTbMQCM4bAiLnpTa7O7isDmEx\/jg4dEHtjzRppumuXBWaCAIxW3AIzhiDZhMCartKCCxaoRQeZM8fxMfm9fgiYL6xdK61cW9XSNEbpbwYzHmNxIGgzzgtbYMYYdnMplc3DrPooCp0rx3AfGwLmm2vWSJOQxkw\/ktLcIptOPHzMNPeYcHMWmDFERjCdLVuQ3vViAnNTRoacWrduMR8z4VEo6QoWmCUt8fT3p3f1cwKU3UaKQn7mt1lZ0j6UDGLp8uXy78HgUk5oylK6Tc+UnNWYHjhidsruomK79TMy5LGcHBlbtaqcuWOHvLRhQylHZIg9u\/JTNsbJi0uOcejDVC+88IJKvAB916ePdJwxQ3ZkZsrIDRvkUldiBa92A3teBsw4srEa0wMh7mMmHKaqUqWKk96lQ2GhDA8ltgoMbPF2XEa0pQVmnAPKJlfO+biPjrRt2lSGTZ4s\/+bIi07\/iMimzEzJ2b9fKgS1HBjBtyThFmeYvPay8nGy3Y9zOslmyotT1E4xqzETkBg72kngwFEBVoFUAihXXNNsrjAzU0ZUqSKvVK3q\/Ny0qEg6FhaWvOl3mXAdcYiVNqewsFBl12PnuSZ2mXM6gd3rfpIFZjqkCziZqfNviFgD6lKrlnwdWjOvvnevFGVkKJ8UGrFxo7QvqR1JEfxK8jlx7CQaMDl9yvkbnSWDDBqke9H7Ud3JF9IhRrMNC8x0StRYrpxYqZIMYqXov7kwx61bJ6137hSWMMdUrSojQ1nmzPX1dLIR1pYBSkBG8ivyBekcQ9GASaoXzvAo\/seNU+eAMPucHtXpfdxJMtL5DhaY6ZQmbYW0Z9u1a+Wn3bvlpi1b5K6tW51e2H90ca1a8kN2tvTbvFl6Fxamm4N\/24sw0SHkRSogk6IBU5clkx7pHDXhxnBiluSynAHv3bu3L\/xbYPogVjSLThz11qBB0njVqv\/1kpsrT\/TrJ09t2ybHFxXJu2vXppeDGDNvVq\/0mXgyyJFEIhIww\/g3ElpoRjnOzdFsDuW9++676eU\/1JoFpg9i5Sw6yacgEku589nrNIYHZmfLUlLyhZJuqQo687L7N6+\/qZvA+jcZMEhQFgmYcfOfQL7RRMVsgZmoxOIo\/9lnn6mJQzQzia9HhhKIoxuJXowQBwueRWIBszTwb4HpOYSJF9C528mGZyYy1S2ZaXbIpmsmoU28t+RqxAJmaeDfAjO5cY1ZS19MYObpNCuYmfQ4+K8zFfvAStQmYwGzNPBvgekDGnT65mim\/MMPP1Q5ICPdbOEDOxGbjAXM0sC\/BaYPSCBWSLZdKGyDcaiv5557TmXCYxXljTfe8IED7yZjAbM08G+B6T2GCZdgbZmUhYRmIiUq5UIp4oBmns+EO0mxQixglgb+LTBTHOBo1XX2Dsw5F03pYxmcttQBa\/eFDD6xkrApp0LQ\/Ftg+oQGsuaRclun6OZQG5tAdI7IRPLQ+8FiLI1Jf0Hzb4Hpx6iH2iRdInfYmPdeokEJbAd9blsDM9YELEj+LTB9BKZumlTdTCjY98gNcEEE1FN5zSD4t8BMZcRsXd8kYIHpm2htw6lIwAIzFenZur5JwALTN9HahlORgAVmKtKzdX2TgAWmb6K1DaciAQvMVKRn6\/omAQtM30RrG05FAhaYqUgvQl3Oy3BRFYe+OFbBygoXeXHHJRctWYpPAhaY8ckprlJTpkyRAQMGRC3L8iS3GpNixlJsCVhgpgEhpMQePHiwTJ482WmNNXHSZHNZKlvcNKFBSTWjshOXAeIkJddyRzsm4tcrWGCmQbLcaKFByQByYSeg1PcjkiOI37gZGDrjjDPUTWvu05NpYCXtTUyYMEF9dGzbY9NzSZEFZoqSNi+oIhMcgFM5jVxEooAOHTrIkiVL1BN2rpu3zabIhm\/VLTB9E62\/Dffo0UM4Jw5Nnz7dSY0dqdfFixfLZZddph5xy9odd9wRVowLCDgPxClK9m6SzRiws68zKysrrCzHM8gjRL7ORo0ahT3DfeDSLIhjwrVCV7tw9XdBQYFccMEFalI2Y8YMgSf2XnLBFmfh0eYQ\/ZMPlP2jHJ7DNSFPKBnf8JX9JqsxU5Awl58y24bI7QNYvIjtbxxd4MguV2hD\/E0qbbJbRCL6eOaZZ9QVyprQthzdMC+f188Amr554u2333aAC\/BIZsBHMXXq1Ij3vutkWWx1a9GiRTF2SsrXtMD0QlKM5+vWrRMuqILIn9mrV6+kWkOTATCoTZs2yuRzl\/eiRYuUbwoBTiZN+i74VICpmaSf3NxcBdZhw4Y5vHPWPTs7W6X4JqPyzJkzlcZkEgRfaFy\/yQIzBQmbGTWSTcuHyQTcmGUSWQFEc1Kk08nAZl5enmNGUwUm\/bRr1855e0CvPyxm4vqDsz5mCgAJqqo+nkD\/aD3tnyXCD1pJH7MIu7LFaAQ3gbNDaFNSAkKpALNly5YC4EzasGGDNGvWTP1k3tBhgZnIaJaSsuaMPOy6lQT4Gz16tIwaNUqiZe2gqf79+6ubf03\/LhVgRpp40Y++OsbU\/haYCQxmaSlq3jXJig\/ZNbwI08whL2a3mFINukhaTLelwcvfy5Yt89SYtK+1d6TJDwlZu3fvXoxVDczhw4crPxeywPQa0VL6XM90+VcH0KOxShiHsAzEwAMADUzMKFl8IxETq2nTpoVp1Vga0\/R9IwEz0kzeasxSCrBk2WLCoG+zIC7IKchoZK6la3OJC0DqaOKKxAv1apHZhr6a2gS\/BmYk7Wf2Y4GZ7MiW8XrmDb0EusePH6\/MtJsIyXTq1EmFZgi95Ofnq+O8s2bNUnFFCI2pJyC6vmmWzdTSOhU1wfehQ4eGddezZ0919yVkgVnGAZYK+yTMJ7MGxJoy6VUw2ewi4koS4pH4oDrNtBmq4XYIsnQAWCY3+HRMhCCedevWzcneQTsa9AMHDpRJkyYpkGPmiXPi81Jf85IOYOpcmbTlXI2dirDirGvjmHEKKlYxVm6YTJCJ1yRAo68f0b9HCsSbsUrKMXEhZyZA1PXNGCZl0IhoRk2AWqejwS3QH0GqGtPM\/EZfZsgqDaKL2oQFZpqkyyYNNBcAcoORLho2bKhSD7rXtXX3+JeYdA0o\/Tvgxh8999xzi3Gqt6SZD9DU9KPTIJrA1PHQRCY\/vBcTNN4NskuSaQJMSTeD9ly1apXSXmyYYCAbNGgQ1+ZgrgbEZ2XnO2lkqEd9vQwZ6V327NkjZCXGZWCPJ+UjTaBSlQNr50QVatSoIZUrV061Oc\/6VmN6isgWCEICFphBSN326SkBC0xPEdkCQUjAAjMIqds+PSVggekpIlsgCAlYYAYhddunpwQsMD1FZAsEIQELzCCkbvv0lIAFpqeIbIEgJGCBGYTUbZ+eErDA9BSRLRCEBCwwg5C67dNTAhaYniKyBYKQgAVmEFK3fXpKwALTU0S2QBASsMAMQuq2T08JWGB6isgWCEICFphBSN326SkBC0xPEdkCQUjAAjMIqds+PSVggekpIlsgCAlYYAYhddunpwQsMD1FZAsEIQELzCCkbvv0lIAFpqeIbIEgJGCBGYTUbZ+eEvgPUWSBmGe2Z9AAAAAASUVORK5CYII=","height":0,"width":0}}
%---
%[output:2d9b2862]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.599659\n","truncated":false}}
%---
%[output:080ea54b]
%   data: {"dataType":"text","outputData":{"text":"Mean waiting time in system: 0.282408\n","truncated":false}}
%---
%[output:84872309]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAEFxJREFUeF7tnXewFMUTxxsRAcUMlCUqKGZBoSwxIIKKARBLMSOlImYxFoIKiIFkjoAYUBBzLBW1EAkGSlDMmMMfxjKBqURA+dVnyt7f3L69u733Zu921+kqind3uzM93d\/tmenp7m20atWqVVIhrVixQpYuXVpw1yeffCIDBgwIvuvbt6+MGDGi4JqmTZvKOuusI9yvtPrqq0ujRo3KcvD3339L48aNI68r9VvUDb\/++qvhoz5UH97\/+usvYeyV0mOPPSZDhgwJbluwYIG0atUq+Ny7d2\/58MMPzec+ffrIzTffbP5GHsuXL5fmzZvH7rIhMgl38ssvvwh6XWuttWL3H76wUX2AGdUbwDzggAOCn4488kgZP358nUv\/\/PNPOfXUU4PvDznkEOnXr5\/5PGXKFHnllVfM31tvvbXQBsp57rnn5LPPPpN9991XevXqZa5fsmSJ3HDDDTJ\/\/nzz2+abby5HHXWUnHTSSbLaaqvV6ffZZ5+V+++\/X9588035448\/ZMMNN5Rdd93VKJQ241Ap3uFzxowZpplNN93UjPHRRx81vL\/\/\/vtGSd27d5dzzjlHttpqq5Ld\/fjjj3LNNdeYcS1atCi4locdsF100UWy7rrrShiYgwcPlnHjxpl7GGP79u3lwAMPlLPPPluaNGmSiEy0UeSKPt544w3TN8SYu3XrJscdd5zstttu5rv33ntPrrrqqoCXHj16yIknnljA2wMPPCBVB+Zvv\/0mO+20U8DIeeedJ2eddZb5fP7558sTTzxh\/t5oo42MZf3pp5\/qCHTs2LEyffp0o\/AwAVqUqkQbw4YNC9qNQgT9otRyVIr3MWPGyJ133mmaAPRY5C+++CKyydmzZ0u7du2Kdvfll18aEBejl19+WTbeeOMCYNLnsmXLAlDY9+6yyy5GXgpOlzKhnwcffNA8LKUI0B588MGCZe7UqVNw6SabbCIvvvhiwa0Yq9QCsxxISv3+\/PPPG2sBTZs2TS699NKyzbHsCD+54ZviArNcZwj+uuuuK3rZ119\/bSxNFGGF5s2bJxtssEEBMMv1ecstt5jrXcvkm2++kT333LOgex6Ezz\/\/vI5RWbx4sbH4GIFnnnkmuMfWF7NFly5d0g1MpnKmRJ6y008\/Xb777rtgMFjUyZMnS8uWLQVrZQ909OjR0r9\/fzPd77XXXoEV4R6mOgbOkgFrrdMOTy4KL7XerQSYtAd\/W265pcyZM0dOO+20gHeWHS+88EI5LJllTNw1Jo2xLGHsa665ptx4440yceLEoA\/kwW+uZRLmkWkY+a5cudIszezlHEYCEM+cObNAHrZReOqpp8xyJ9UWk3ULaymIhf31118fCBqLg+WB3n77bTn00EOD3y688EI55ZRThCmP9Y0SltP+zJRvK+\/hhx+WnXfeuShgKgEm61nWsErwB59KWJRyVCkwATugh3744YeC\/tVKu5YJ4APwSlhLNsH8j+5effXV4LcOHTqYzRtrdcCrRoH153333Weu40Fk3KkFJlPWu+++GwwqrKQnn3xSGCj07bffSteuXYNrdd167733ysiRI4Pvt912W1lvvfWCz1999ZXwT0ktbTHAVALMd955R1q0aBE0pQJPCpjMBmwEberYsWOgfKZxpnPXMqFP2xtj9w9PbCx5KODFJozHQw89FHyFEVp77bXN\/gPAphaYLOZfe+21gHE18foFu1127lHA1M3MlVdeaabTuMQC\/uSTTy56eVxghh8qGgwrwrXFVODZzGO1dPOov7uWCf0NHz7ceDxKETPVqFGjgqVS2HIzI7Zt29ZskKBcAhPrdMYZZ8ikSZPk6quvDuSFuyXKbaIX4Frp2bNnJoFp+zF1AFHAdC0T7QsXFdaYjYxO0WFB4iY6\/PDDzdesQXfffffgwcGbss0225g9QO6BiVUFoFFWNq4Vta9Ls8WMC0zXMvn4448FhzqEiwxvCLvvhQsXyuOPPx4cAPA7D769prddbMwyLLXUb5tLi3nBBReYXfxHH31U4DxnOrvpppsCBzybn6lTpwbYu+eeewp8bGHw1hqYc+fOlc022yxgq9jJTymL6VomHGrokgtwvf7668EpF5ucHXbYIeDX3uTw5VtvvRUcroRlnWtgMljcTUwvSrhxcFlwvGc7wFmoo\/g11lgjNVM5G7xzzz034AffJtMdBxJsFOoDTNcyCa9Zd9xxR7NOZKpmA2i78XAD8U+J03AOEuwNKL+xAcolMIcOHRr4yXCb7LPPPkXXPQiCJx0fW+fOnUvO8NW2mMUc7VEnP3GncgboUib4Rffff\/\/IEzpbmGxmObJt3bp1gYzxt\/LPJtx6zoCJ9eEsW6nYWTkLY9t1YIPIdqmU25XPmjVLtthiC9Nd2F1kt8nvnCbgA43aOeJPu\/baa6VNmzYlQcmPpXgPr5dsVxf34kRWXx2f4+zKuY7NCusye0OhwDzooIOCY9koYO6xxx7BoUT4tMmVTOAR3V922WV1jhZVoKwt0a3qyxY0a1R+t4nZzBkwy2o1BRewSP\/000+Fs2jOmjmV4Wgv7UR00vfff29iB4hSYtlRLNKq0rG4lAmWmCANXFTKJw88si5Ftr8V43b77bf\/t4BZqdIaej1rKCxTs2bNzJrQU10JhI8nb731VrM0+E9ZzGoBA0DeddddZvmgUzCukP32289sXIhV\/K8T60qikuz4B5ZvxDCwAfXATAAh4Z0qAtcTGNbeOJHjBEcnwFpqmuQUCPecTYQzHn300eYrD0zHqrIX82eeeWYQpPvSSy\/J8ccfb3qzT0Acd5+b5jwwHauSp\/6OO+4Q\/HkEntjR9Ppb2NHsmIVcNOeB6ViNJ5xwgnGbaOid3bwduMCph513hIskC2SH8iXJrwemY+mq7zAqthNntMZ72n7YKCezY7acNRfX\/9rQDj0wGypB6377bNgGnl5C9qImorEjJfoH8sCsqwQPTIfAJKsRlxAUTrXVbvT0g8S1vffeO7jWIRuJNuWn8kTFm0zjdnYjkd2c0NjEyQ1BGFC5NI5kOMxOq95iOtSVfZZuR9hrF5oByOeoqd4hK5lvygPTsQp1qrbTZbULO2mOII+GVKpwzHbqmvPAdKwS4g3JT4rKwdETIVKK7777bsc956s5D0zH+iSHfNCgQaZVe4ND1M0xxxxjzs7t1GPH3eemOQ9Mx6okcpuoc43cJt6T\/GqNog+XsHHcfW6a88BMQJVUWiOF2E4roBumd7I27SpsAJlN0frrr1+vinAJsJ+KJj0wE1QDqRhscv755x9z4mMDkrI3RM7bETY43JnutcJIgqzFapqgk6jCZXoz6bqa2x+rwQou8sCsQFiuLiUinQIAml0YrtQGYO2SN676rbSdqFQIuw2CVOzKbZW2X+p6D0yX0ozZFrk\/WtT2tttuM7lSHFcSva1V4Grt59TaR9RCKuZBILGsPgVp44jJAzOOlBxfo2m3pBZTu1OJKZ\/UV6ZPu26o4+5jNUctocMOO6ygUnGsGx1d5IHpSJBxm7EDOaKmQgqcUpRh++23l6effjpus86v05z2cC64846KNOiBWS1J\/9sPyf042CHKg4ezHZnCKaEYVZirmqxq2Uc2YzxM1HrH28ADw+YsXKzVNW8emK4lWqY9DRYuBjw2RJRdgUjTqFXiml12PGpIlB68\/PLLE5OeB2Zioo1umIq7F198sSmwGlVVmBMiLcXH2Xqt0n6xipR4IULqkksuMUUqcHGxQePIFeKI9YgjjkhEgh6YiYi1eKNagDaqKD53USVNMwUpzhD1Bo5qsEx0FJmdxJeGy7qw1GDJQUpy+BDBFW8emK4kGbMdzZYsNpVrAYBwiZyYzVflMt66wWtroA8++CARl5EHZlVU+f9OUCR1hqCoYGLKo5B3zikQ6Re1II5JCWrGWkf5KYnOZ1OU5DrYA7PKmrcr6V5xxRVy7LHHFnCghbLKld1Okm212lh1\/JnhDRixphwE+Kk8SS3UoG2Ny0TxRB1pCgbpFupwt99AUW0W7TdehNOQsfhUEyF8L8mHx1vMamv93\/qUbHC0cCwbDAI+9NUjaajUocUZEA+FVKkdSsU53ezgVeBvfyRZAwAl2SVvFCN6h8xKJSwomwq76m6SPJRqmyXHhAkT6hRV5R5cSdTDTNKV5S1mrTT\/b78UnWV6pE4n7y2qlUO9mBiw5LitqMpGnUsijpIEpPLhgVljYPruoyXggemRkUoJeGCmUi2eKQ9Mj4FUSsADM5Vq8Ux5YHoMpFICHpipVItnygPTYyCVEvDArIFaKPD6+++\/V9wzFT1I\/V22bJm0aNGiIE+94sZSfoMHZg0UFH5neFwWOEMnUY28oaga73HbycJ1Hpg10BLvhuSV1JUScZqcX3tgVio5f30sCfz888\/CiwLCRMQR6QyUkxk\/fnyd31u1amUierifktP6ooFYnWbsIm8xU6QwLYTAe8mnTp2aIs6qz4oHZvVlXrTHOMAk3YJsRfK6t9tuO9MWNTnJqGzfvr307NlTyCsiL4eIIN7Vzj+S37DSFDIgRRirS92hXr16Fbym22aOgmDz5s0z2ZLklhOTiaXWt20kKToPzCSlW2HbcYBJsYTwGlPfhQ5YAS1AChMWmBfUa3Cy\/Xv4RQWUqpk8ebIpmRhFvGSLFOQkQ\/Q8MCsET5KXNxSYylvfvn2lR48epmACALOJAl784zctlkVxWfLdlaZMmSKjR482H3kQqGFEchpWWCPYSa+IWge7ko8HpitJOmjHBTDDtYZ4DfWMGTMMd5Q+xGoq8fe0adNMORqsLG8EZorv3r27yelhMzZmzJiCNwXbKRfkwLds2dLByOs24YGZiFjr16gLYC5evLjA8W67plh7tmnTJmDOfiMwpWuIUAeoCt6oSiB2ohpWtX\/\/\/vUbbJm7PDATEWv9Gm0oMKPSabUkDRyFK3vYdZKYptu1a2dAqVYUaxlF1JiHBg4cKCNHjqzfYD0wE5FbIo02FJisHSmYYJMCM6ryRxQwme6xnnEoyXWmt5hxNFClaxoKTNKAw5udSoFJ5iZTPETx2FLEO9lZjyZBHphJSLWebaYBmKTlqnOfDRHBImFinUl6L9mSUb\/Xc\/gFt3lgupCiozbSAEzeRKHrRurD47C3CT8oSwYo6rWEjkQhHpiuJOmgnTQAEwc9wOPMngocrFnVJUQlDtxPrE1Zs1I5JKn3YXpgOgCUqybSAEzGgt8TAEIAj6NIylzjisK\/CUVZU1dyoB0PTJfSbGBbWumtVBAH1ozp1I7HVBdP1ObnkUcekaFDh0pUvc2oXbkOgRKJOOuxnDZRs2jIkCHmjD1J8sBMUroZbxsrSW0lStg0adLEBIIwvVejyrEHZsbBk1f2PTDzqtmMj8sDM+MKzCv7Hph51WzGx+WBmXEF5pV9D8y8ajbj4\/LAzLgC88q+B2ZeNZvxcXlgZlyBeWXfAzOvms34uDwwM67AvLLvgZlXzWZ8XB6YGVdgXtn3wMyrZjM+Lg\/MjCswr+x7YOZVsxkflwdmxhWYV\/Y9MPOq2YyPywMz4wrMK\/semHnVbMbH5YGZcQXmlX0PzLxqNuPj8sDMuALzyr4HZl41m\/FxeWBmXIF5Zd8DM6+azfi4\/gfqLOUs4eJ\/tQAAAABJRU5ErkJggg==","height":0,"width":0}}
%---
%[output:3b9db938]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAFTpJREFUeF7tnQeQFUUQhucwJ8xVKiZEQVQUywgYESNiFhUxgQkEjBgJoqCoGBEUA4piRkEMmDBjtlCMGNAyIcYyZ8\/6puytvrmN7y3vbu9NV1lyb2cn\/tvT3dPdUzN9+vTazp07G+iee+4xp5xyiv23ptdff90stdRS9qfRo0ebSy+9NHg8efJks9FGG9V75++\/\/7a\/LbjggvWeyQ9\/\/fVX8IxyNTU19u+PP\/7YSJ\/4e+zYsWaXXXYJyv7zzz\/m33\/\/tX\/zTlwb8hL9oewCCywQ2R\/9gL7pPqV6ySnEXDKnUKtWrcyjjz5ap0TU+OPaYuxRY4h75tbJfND+YostlnlozD1tCS200EKp6vjzzz\/NwgsvnKpszahRo2pPPvlkW\/icc84xN954Y70Xb7\/9drP55pvb3w877DDzzDPP2H8vscQS5rXXXgsm6o033jDjxo0z77zzjvnoo49smeWXX9507NjR7L\/\/\/marrbYK6v7tt9\/MMcccE\/y91157mX322cdcdtll5q233jLTp08Pnm255ZZm9dVXNwcccIDZeOONzaRJk8zUqVOD5zfccIPtw48\/\/mhOPPHE4Pd+\/fqZr7\/+2jz00EMWFL\/88osFyOGHH277404SE8dH8OSTT5pZs2bZerbeemtz+umn2\/boF7TZZpuZ\/v37R07wq6++au666y7z3HPPmc8++yyYq65du5pll13WnHbaaSZq\/BQeP368mTFjhn2vdevWpnv37hbgjOPDDz80O+ywg9l1113tfH3\/\/fd2zmiLZy1btrTzdOSRR5pmzZrV+xCuu+468\/DDDwfjYz422WQT07NnT7PBBhukAs2bb75pLrzwwqDsGWecYdq2bWv\/HjJkiPn888\/tv3fccUez\/vrrmylTpphp06aZL7\/80qy00kpm9913N3369LFzEUU13bt3r73jjjvscxaLSYUAChVCZ511lundu7fhK2OihChzySWX2D9vvfVWM2jQoNiB8bxXr162zE8\/\/VSH0wIoFhsQM4Awuvzyy023bt3MBRdcYD8Aoffee89yNxaJSRYC0C+88EJoXSwEH6IQoD722GNDy\/MBLrrooubbb7+1xXfbbTdz5ZVXRo41aufhhVVXXdU8\/fTTkeOnzEknnRTMPQsJZ5O2daPnnXeemThxonn77bfr9QXQjho1Kvj9iy++MEcffXRoWSk0YcIE+yEm0RNPPGHxIHTbbbeZLbbYIpibd9991\/6bnZTdNozWXXddw267yCKLhD6vadmyZS0cDo4joGMhWHw4jl4IyvHVCwFKwAlg4WRwpCSC67B9RAETbiDc1q2Lr50tPi0wk\/ry2GOPmbXWWssWc+uMezcJmPfdd585\/vjjQ6tgsViQqPG7wEwaQ9xzdgk4IsTu5IoSYe9GiWa6bFpgJvX9\/PPPt9w9jCww7777brstixzHlnv22WebLl262Hf4atkqbrnlFjN48OCgnhdffNGsuOKK5tlnnzWHHnpo8Dvvwn2RPVjw66+\/PngGN2nfvn3swiTJmFmAiZwHd+TjgSuLGEKHxowZY7fEb775JhBVpKOMgXmYM2eOYavSHCsJmFJHnIyZBZhs5QALrs4WqHcU1obdY4UVVjAjRowwDz74YDDXw4cPNz169LC7AP8XgisOHDjQikcAcdiwYcGzgw46yNYTR1mAyVydeeaZdttGTGLOhRALhw4dGg1MtlgAJl\/5cccdZxeRr1u4ICAE4bK9r7feeub++++3lQJM2TIBI1sy8g1yFGKAvENZ5MFtt922IsBkK0fEEHI\/IBEtkH8YsxDzoDmeu7CVBubMmTPN0ksvbbvnKp+ya\/GMbXPvvfcOxoFszPaNssp7Qg888EAgE\/Ibu57I1Pwtu1oUOLMAU9cFltq1axdUC+O75pprooHJRCP7SKGrr77a7LTTTpYLspgQ8geyj3COAQMGmBNOOKFOpWzBbI9MEJxGZA1dqJLARGY89dRTg+ZdTiyyM+MeOXJkUC5sO2NC5SOtJDDZyVAqhVz5FaVMlJa5c+eaTp06BWVFbkck05yUD1YT9WsxDCVL6xIuctICc8MNN6zDlKgHxVEwhNh27bXXRgOT7WDNNdcMuB7bXYsWLczFF18csN5DDjnE3HzzzUElKEw0IpRWRqskMM8991xz8MEHB31EW9TCvQCT7USP7aWXXrJboyY0SVEyKglMrBovv\/xy0BVXftUgcoEJIwGUuu9RXFD\/jmiHzlAuxwybJ63cJgJTd0B\/oY888ojVVMNo9uzZVoaEwjRy5NVNN93U2j8xjwhVEpgiY0nbUcBE2+c\/IXerc7\/0ogATGbdv3771THw777xzLD55R5TCsIJpOSaKshYhqKtkYGoUuwspnXQXRpuZKCMcl3+74G6MwHS3R+GkMl7XGlE0YGr7NIwHeVIOM9JwULdMgwBT5BLpjJat9LYNGMPKYIjHIC+EEsH2Uw7HRKTQQn1arTwtx3z\/\/feNy0XQINHKP\/30U4M8jfE66sOMWlytlbtbclqtvJytHM0bLd61piC6oBFDHCpw4CByLPZaLDBxpzkNAkzhaDLZRx11VJ1TGJcj8rer1aENLr744lZrR17TJLbIuIVxOTW2uG222cbst99+VpvMG5j0T4MoiYuk5ZiYSfRHSv\/ZIhGPKglMzEyIVtrMhMWlTZs2BrFFKz760CRqHhoEmGKblE655gmOvPRxIeXQrDAlpSHsg2j7cQtDPQBRjvOk3qwnP2k5JvWjONAvzRmlXbY\/vXhpgRlmaM968lMOx8QiIToCXBB7bhyxthylLrfccrHlKgLMDh061MqXJIZ03Su3Exh6tTJDWYzXyDEcj2nCLAF3YyH1wrL4v\/76ax2blp5E6sDsBNj1KVAUMNmK5awc472QC0xXa3VlSeyuV1xxhXnqqaesqYv5wACPGIFIIn1Jw1XoA5yKY8M777wz6JMA07Xp6fHHiQAu2PXplTs+d06RlbFUhB3T8lGyrmmcOlxMaC1eWwDClB\/NcGK18tra2to0nC5NGbZgzq0xrmNuaN68eZrXIsvgwTJv3jzz+++\/W5kHE06aiSur0f9f1p4wf\/zxRx2DNA4SbNNpCYCK7Y7+A\/iGJM7NsTN\/99131ukD8YJdoTFRTZ7AbEwDy9IXOIk+UsXWiQOEeOdocxIuX5wYAU5P828GPDCNMS5HZLrhIFgYOC1iC2dj0SYWvGNw6+L4NY0\/6PxbwqZZswfm\/+sad5jgghKFRLZmHCyQhcuxCzZNaJU3Kg\/MhPlDZhavKxw9sGki73KIILZAnGYxBXnKbwY8MBPmEq0a2ysOCZwQaa9weeZ6MeW3PNVbkwdmwtpzKoLHubiQ6eLajY4QE22FwB5cTSQe7HmN2QMzYSbF6QDDsw7b4DUdyqHtiYASh9tqIdd\/NY9xe2DGzCIGd4KpIA08eQU76zrrrGP\/1G6AHpjlQ9MDM2YOOaHCJAS5R7XymriHET6y\/fbbB7VV01ae9zbOJHpgxgATzyLCQCDOmt0TG6IXcYSAwrb68vlG9dbggRmz9vo8OyzcQAexhW311Qur8kfugZkwh7JVE0eOM4omHfyFP2NjO28uHx4NV4MHZsLci6NzmKub+IXiMROWwaThlrX4LXtgJqyhdvHSCg5pUjAJsd3rENriQ6JxjMADM2Ed8DUlTFnCX3HsIMZbslq4qVgax7IWvxcemCnWEN9MQmF1bDavsb1fdNFFkT6igBoFiSwUUTl6UjRfpwgOJdRJbI5k4Mtahy6PczH+rquttlqj8pLywMywqoSDoOTgk8kpUJTTMo7BBNDpWHVi8Nn68X4vh4gxJ99PWi\/6sLboHyEuOKLo1Df4oeLhTuqYhiYPzJxXAN9OnI4lSQEucnAkCS1xIz6zNM9JEzE8xFyVCkyOUUleIckb3P7RH0JL4KANSR6YOc++Tv5A6hniWgAUaXckZWMWmyfiAPk6iWsiolEAVSow6Qduepi2brrpJhsCg6iCowp5jkREiUuzmPOUhVbngZnzLCN3EsjmBu2x\/e+xxx4WWG7sflwX3JyfUrZUYEo4tkSr6rYJziPXJfTBBx\/US\/ya81TFVueBmeNsa6cOSbeoqyfzL1GYOlNeUvNwTKIsJWaQbMC425UCTD4OyeAX1j84uXBN140vqZ95P\/fAzHFGiYPH2A5JSLGuXhbezeCWpQti1C8FmHw4AJv\/k83PtRRIukI3lj1L\/\/Iq64GZ10z+nycUxScKeKJR06Sk587afDnAjGtLc0tCSCQvf9b+5VXeAzOvmTTGpoMh3jwsWwnNcFqEnAnpm0CydCFvYBJbjjIkSRnY6hlHXnbXLGPTZT0wS525kPcka5xk23CLkMfpwAMPLEu5yAuYyK5YEDggEFMWsfJwyoYGJRPkgZkjMCVyMmorlxDhcmS4PIBJxhSOWeWGErLa6StRcpySkqvywCx56uq\/qPNohjkWS\/IxToHkCpuszZcLTO492nPPPW3mNz4gOKa+3Ctrf+ZXeQ\/MHGeW7bFDhw72mM9Ns00zknAK7oQ9sRQqF5iSsAtQPv744\/ZSiMZIHpg5r4oAh4XHA0nCMQi9kCx5HCmiIJVC5QJTkvOTj4lMdmGU5WrDUsaQ5h0PzDSzlKEMWyUKjqQsJJgN5w9J\/Vdu1o5ygEmfOCJNQ6Was9LUnaaMB2aaWcpYhjR\/pI\/RSWDhoGi9UTempW1CgFmKH2jcjW1u+xyrpr2QNG3fs5TzwMwyWxnL4uuIQkSGXu7i8Vnh0k+gB2b6ufIlKzgDHpgVnGzfVPoZ8MBMP1e+ZAVnwAOzgpPtm0o\/Ax6Y6efKl6zgDHhgVnCyfVPpZ8ADM\/1c+ZIVnAEPzApOtm8q\/Qw0GWD+8MMPNtovK3GpFU4XxNQss8wysZd7Zq27EuWJ45k2bZrNDoL7Go4kpE\/kvHuNNdYo7G0aTQaYhDQQpJWVcD8jgQCUdIF81rorUV6ckyXdtL62L+ze9Ur0KY82mgwwOZvGUTcrEa4q+dKLBkx2CbgkHug4\/ZKKxgMzKwLmc3m8ekh9ool4FuGGvXv3DsIadBn8EbnPm62cy0xXXnnl+dzT\/KofNmyYmTBhgunbt6+91hrywMxvfudbTTpZgHsT7XxrtEIV6zvdZ8yYEXxQHpgVWoBymkkDzJ9\/\/jnIPsH1eygREOlT4LjbbbedadGihfX2xsGXQC1isokfpyyubSgfr7zyinUTI+UKnDfqhl3CZNl28Tpacskl7X2VbMeSuTjteLmGm2Sx+HuOGzcueM0FJgohIg6hHiQB4yKtbt26hbbHrjF58mRD0BwRnRBeUZ07d7ZjdolQEcQILkUgulIT88rFXRC7luxEyPT0Eb9Q5uiqq66yicrIXNKlSxdbnrabjIwZtqBpgKkXUsuYcq82Tr\/4Mer71mmrVatWNoALpcN9hnc6IbA6bAExgxQsKCRhRJYOCe1NAieaODdFYE1wk8bq8XCN4KRJk+pVh28oY23dunXwjLnCw54PJ4z4ALiRWKc+FG\/4sHQziFZymwVgF+BKeAlpcvj4Jdsc93ECYImL8sCcO9d06tTJrkUYMGWR+KK504eF46IATWRPa9u2rbUKSA5N8mn269cvKCY5g\/gBCwLX\/H311Vf2GsBZs2bZciw8DsBJpOPT3TANDUzqAYQkMMB0RDvCXeFOJP0Soq\/Sd9LEMCfcc8R4Bdw9e\/Y0cGqhcoApdRDqDBc\/4ogjLOglMM4DMwUwib8GSBDpVdq3bx9wydGjR5uuXbsGi8UWRQiD3mL11X4uh2PxuRaQLB1cNe0mhw0D6fjx483w4cMt6ACbvvlXA9ONO6KuESNGGFJ26xDimTNnmn333dc2Fcb95M5Mnk+dOtVu71C5wORjJ45dHKhlXNTtgZkATJKZovlqEptpWGID8l+OGTPG6GcsAIFpJHslKM0lZFS4GhR2bYtbfuTIkZbbhQFZAxNNHY1dkw6vAJDIyZLlDbA+\/\/zz9Tzt9bY8dOjQ4NbhcoCJKMS4tVe\/B6ZaqSQZkzgd0r5okpsswm6rGDt2rN2SNUcSLoqi06NHj3rAJHU1HBAif2WYoqFfkhDcsFt\/9XgArygU8r7mjuTdJHswfSJYzt2qdZsCQj5KuGq5HJOte\/DgwXXmQsfle46ZwDEHDRpkevXqFQrMsCtWXGDq29PCtmX3tzRyptwI7Grk1KWBee+995p27drVaUIDUzIHC+gGDhxo+vTpE9pNAS8fGQpKEjAJyMPaAEUpP\/3796\/XFjItSqUHZgIww2SuuLt\/XGBydi3aL9tXkuYN2CkXR6JIhYkZSXbMMI4pwHQVNt0HAI71AYAKd4\/bynVmuyzApE3ShXtgzmdgMtGylUfJmJh\/5s2bZ3GACJAUNitbeVgC2FKAKdwwKiRY36mp720XYIbtKmjyHGpk4ZiINOwwONN4YFYAmNoUgyGecF5N4ojBb2E5j1zuiVaNdo2BmvKaSgEmCo3csBGWSVgrTNpCIWm9sfWiuWtC6RKzWlqOycEE6RkxV3lgVgCY+s5JuBPigWijPEPBwtCc9uo\/XZ8L9FKAOWfOnEBJQm7F2C9XxZAlGcDQP4zkgExItHnMUlOmTLEiCOYvrBhkHBFKC0w5zWLX8MCsADBZIM2V4HTIneIVxHMWFw7D8WcSaYXK1bxLASbtSYYPEScwetM\/jieF3Kuv6a82R3HiJalxAJec6qQF5ieffGKPgKEmDUyOATGGQ1FOHKTj69ixoy2jT35ELgxTfkTGC8uDHmYuom7OodkuxdSiwVdKfkqxjbrmLD2eMH\/MMOVH+oeX1ZAhQ+p9FwAOMxYnXy5NnDix3juAmiNGOXjQwGTOOBSIurmDuzsHDBjQtIGZxHka4jnODbNnz7acpXnz5mbttdfO7MBBv+U0CU7Ldp5XFmA+ZhxTuE4FrtemTRuzyiqrxHrCw8Epz7v4BwBkfRqVdZ6bvFaedUKKVB4OjJcQ9waRUpB\/NyVq0lt5U1qosLHItozSwTUpzZo1azJD9sAs+FIis+I+xvl8VCLWIg7RA7OIq1YFffbArIJFLuIQPTCLuGpV0GcPzCpY5CIO0QOziKtWBX32wKyCRS7iED0wi7hqVdBnD8wqWOQiDtEDs4irVgV99sCsgkUu4hA9MIu4alXQZw\/MKljkIg7RA7OIq1YFffbArIJFLuIQPTCLuGpV0GcPzCpY5CIO0QOziKtWBX32wKyCRS7iED0wi7hqVdBnD8wqWOQiDtEDs4irVgV99sCsgkUu4hA9MIu4alXQ5\/8Avk5Vvc4V5fkAAAAASUVORK5CYII=","height":0,"width":0}}
%---
%[output:24dd4f13]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAFcVJREFUeF7tnQewVTUTx4PdUbHhqFgQQbGAYlcQKzo2bGDDClYQsCB2QBAUFbuAWLCBHSkW7B0rimLFgo4NG1Ycu++bX+bbM3tzT73nXLi8l51x5L6Tk5Ns\/tlkN7ubRnV1dXUmJf3999+mUaNGZpFFFkn5Rmmxf\/75x8jnFlpoIbPwwgtH1kNZKMu35s6da5Zaainbxiz03XfflRXfaqutgr+tuOKK5qGHHiors9JKK5ksfZIK\/v3338i+xz0L69Mvv\/xiGjdunKW7QdlddtnFfPzxx\/b36quvbh555JHg2ddff20+\/PBDM2TIEPPFF18Ef99jjz3MNddcE\/wGE0KMVRTv\/\/rrL0Nbl19++dhx32KLLcycOXNMozlz5tStsMIKQeU\/\/vijOfnkkwMA9e\/f33z++edm0qRJ5v777zdnnXWWee6554Lym266qS2v6b777jMTJ04M\/tS3b1+z8cYbmwEDBphPP\/3U\/n299dYzZ599dsl7fPvqq682r7\/+upkxY4Z9tsoqq5h27dqZo48+2qy\/\/vplA\/Dee+\/Zd9544w0DMwHmZpttZt\/p3r17JmDrytu0aWN+++23oA0vvPBC6OBH9en55583N910U\/DO8OHDDXx57LHHzCuvvGL5sdNOO5ljjjnGLLbYYua6664zTz\/9tHn11VcNEwHQnHnmmaGgmzJlirnjjjvM9OnTbRspz0Tac889ze67754apBqYLVq0sG1ziTHZddddLViEGP\/VVlvN\/P777+b4448P\/r7vvvua\/fffP\/jN8xtuuMHcc889JeBu3ry5OeCAA8whhxxill12WVsebE2dOtXcfffd9nejDh061I0bN86sscYa9g+AcPvttw8q58OjR48Ofl9yySXmvPPOCwYNIMAgLdkOOuggy2Chd955xyy55JJmr732Mu+++67989Zbb21uv\/32oAx1HHfccSUMcJk0YsSIEsbfcsstZtCgQZED0bFjR3PllVfab2eltMCM6tNdd91lJ7EQ\/X3ppZfKmnH44YebP\/\/8MxgQXYABfOCBB4L2I53OOOOMkknvVnjqqaeaXr16pepuGmBS0UUXXVSCAaRo165dza+\/\/monmNApp5xievfubX8iHffbbz\/zySefRLZlgw02MHfeeadZeuml7SQUUFpgNm\/evI4Zx2wFZC4w3VoZaBjMjBVCErRt29b+\/Pnnn80mm2wSPDvwwAPNsGHD7O+oQWRgdtxxRyvxkgjJhRR9++23zd57751U3ABOpFFWKhqYWb8v5S+44AJz8MEH25+33nqrFQpJdO6559rVIonSAvOpp56yK5bQiSeeaFgF44CJwEBwCLFVWHnllc1rr71W0iwBM\/2if0IWmPwAcJ06dQoFJoBlaWzWrJkFA8sHYlhIz1KWGRouNHbsWPtuHDDHjBlj9zJC2223nTnnnHPsd1imYYzQpZdeameiK5UvvPBCu5SxZ6KTb775ZvCOLD1JA6WfFw3MjTbayNDGJZZYwvZV94nvshpsvvnmZvz48ebiiy8OmkKf4AFLKnzR2wvq23LLLe0SyADLM0DwzDPPJO610wITXsJzIZZrtiZxwJS9Iu\/QRiQj9NVXX9mJJvtWJO6ECROCuoM9pgCzQ4cOFuGuxASU9957r2nVqlXw8n\/\/\/We23XbbQMLpyrVIRhIjXUXJiZKYLAt6mWMP1qRJE\/s9FBOtiFAW0G644YZBe3bbbTczcuTIEiAeeeSRwe9+\/fqZHj16ZMGlKRqYSG2kN0Rf6YeQXlVQftZZZ52SSXrzzTcb9qxHHHFE8Hcmn\/4NUDQP2Nex146jtMB86623zD777BNUxV7ysssuiwXm2muvXfLpk046yU4sxg3hIasjyzhgFCoDJgCkAS4wpRFuB5FczHIhRDQbWUAqM5f9KXsioShg6tmFZNGKUxhjP\/jgAwMYhZgAejAZXL3HZSVgRchCRQMTjVfa6PJ44MCBRk8kBlAkiuzF0QNQRIVQHpdbbrngN+W19iz7wCKAiWICsIROOOEEc\/rpp8cC013RdDsQaqwE\/AcwNZUBk4ezZs0qA2aUtHHBgQlhzTXXLNn3PfjggyWadBgw2V9qbTsNiNw9TxLgKtlnFg3MJ554wqDMQLNnzzbt27cPmu2CKAyYrgKS1GcUr2OPPbYQiekKIZHWcUs5OkC3bt1ilVl0BVaS1q1bl0vMvn37BnZMlgN3NrPf6dKlS2gHsWm9\/\/779hll1lprLbv3gMLMD2HAxA647rrrBvWjBN14442xDEU6Y24QYg\/DviqKWrZsaZjlWahWgIl0QSkYNWqUwSIixARedNFFI7vEiiJbh6hCaZZyxodVU6wp1IXFAckWB0zKYVfG8jJ58uSS93V7ACeKNyYzKJCYroE9CzC10sJyim1L7I9hMzZqKdcSgoZqmyFmBzRCMbjDTECp953nn3++OfTQQ7PgLrFsrQHz4YcfNj179gzazW89oRM7FFIgDTBdaYkAAEgckEQBE0BiXxZCP2FlnDZtmlX60Fk06ZU1AGbr1q2txET5YfOcBZjukqQ\/xma9adOmJQ2IAiZ2N32ywsaaWQq5e6vBgwebww47rEQ5gVkcAHCqAD355JMleyI01jTmE93YWgPmzJkzS2y4rFZXXXWVBQjESqXNM7fddltgwksjMeGhtlezErL9cE+8UG6xN0NRwESwMEZCKKva3ISV4fLLLw+eY3oUQVO2x8T0wIY1CzCpGc0QEGpyjefyLAqYGNc7d+5cUgdL2A8\/\/FCyBKCgPfvssxaArk2PZ0gAzBFo9ZoqkS61AkyxltAflEl9OgOY4NPLL79cYsh2l8c0wEwjcZkMV1xxRXCYEgVMTFuuRYD9JjrITz\/9ZDAh6pMklG7GD8K0iMZu7Zh69mUFJsb10047raRfzF59NJUETJ6j9aH9xZE++cFkxawMO03RdbhmlTQDQJlaBCamM44xxeoR1hcGmEmrDzmKACYYQcrpfW3cHvP666+3dtskck+qkK5I0Ebjxo2rw1guh+9Zgek2joZgkF1mmWXK2oSRVgzfWhJQEKChoWnjslTA\/pVnLrNxDGDJGjp0aNm3kBqYiLSNLIlJ+rk2Ybn7Xl0uqk\/sozCpCMVp5bJaSVm953b59P3331uA6JM3eQ8lkD0he\/00pPeYYeUx3W2zzTZW+tEmUVCkLBOECSxEf0XJZDyRjChsYROJMeX4EuEi2xHqwXEE81mjLN5FaTqbtwwH\/xhgMV1xSsJ5KoyO8xjiHZxDPvroI2sXQylgf5vVyyhv2+fl+xz90l8ECX3F8qCdceZlW+K+xfk++2POzFGAaOOqq65qMMAvvvjika\/WHDBrhaFh7cBlD4nFhAlbEWq57Qta2zwwU4wYgMSFjSVUliVOXlgKWY6y+Iym+JwvgndRrS3ltTgq7qkL+yPRKjnnZo9Yn7cN82NMPDATuK6PXvGa6tOnj9VM8ViS8+2407H5Maj14ZsemAmjiD8kXthoqJjGtAYpz6LstvUBIPOrDx6YCZw\/6qijrFFfn3jIK9oVjdAOHXuD0bshkT4iLqLfHpgJXJSTiDD\/Rn3C8fjjj1sTCAQotSN1EQNVy3VwOKLd4opoqwdmDBexj4pDsgaevKKdesXjxgOzCFh6rTyWixj6MQkJ2AjXdUmkJK56uOwJNaSlvOhlHB56iRkDTX08K0FwujinGhJykiaUoRhZ0jBq8cCMGWd9FhzmocQpEOfTUNhS3zAgVJ1eemAm8FWWakJH8LDRpKMHtetWdYaqYdXqgZkw3uKO56ZG4TU5EcLzhkhGT8VxwAMzgZc68E0rOARbYRJiudce98UNTcOuyQMzYfyJNSI3k4QYsKckTFk8ySX4v2HDqPjee2Cm4CkOyXhau\/EvLO84wkblRgLUKEiEgsT5HqZogi1StNsdMVt\/\/PGHzVtVax5SHphpUfH\/4CuUHLyz8eqOAiSRnXiS410vhEc8S78E2WX4bFCUJA7EZUUloUhTJ20j3AQnFB13g6c80abE5dQCeWAWPAp4aROgJ5lAcJFDKokfp+ReyvpZTpkIWyBEo1JgcoRKdjmJEXfbRpvIeSSZ\/7K2scjyHphFctMYG+BPtjWIOKWdd97ZAKprr73WKklQWpsnWwFiuImDIfZaAFUpMGkDLno6YI1tCk4qEpIbZn0omEWpqvPATMWm9IUkO4mbt4nln0x5gEvnkYyrOSwMlvKVApOUMUjcsMhRiU6kfmKJtHtf+t4XV9IDszheWskoibN0zlD5BDHZJCkgwI6ErEmExCSZqaQHJzEXrnaVAJOJIQnPwtqGFBep6brwJbWzGs89MAvkKtnWMLZDLL9ujnkZfMmsl\/XTYtCvBJhMGoDN\/0ld7VoJiGciQwb7Tp0pL2sbiyrvgVkUJ40JclhGAU+0aj5JyEZWE00eYMZ1U0tLyRZcIFsqqsoDsyK2hb9E1lwuPCDdIHs5l3R67qikEHHNKRqYpOBBGZLc5yz19KEIm2tetnpg5uWgel\/S5ZBTCE3XJXIqST71ShSMooDJ3hXrgc6Swe0Z5FWvBVDCNw\/MAoEpkZNRS\/mjjz5qbZGV7uOKAOaXX35pj1glST9JuUgZGXZVTYGsyVyVB2ZmlkW\/QE5I0jdDYY7FkmiKUyBCMbJSXmCSlItc6nIfEhJTpwzP2p5qlvfALJC7LJEkoeKoLyyZrKRhTJOGOqxZeYFJVj62G0h0coiGhYoUyI5cVXlg5mJf+csCHgYfDyQyxUGEXshFCTrzW5bP5wWmZLAjC17UDWpkFIm7SjFLe\/OU9cDMw72Qd1kuUXDkRjCC2UjVKHk882TtyANM2sPxaBqqxJSVpt4sZTwws3ArZVmyGpM+Ri4Q5TUkKJpvnvhrAWYlPqDulShxXSHNtZsLM2XXCyvmgVkYK8srwt8RhYickFwZktWgXsWm1XzVHpg1P0QNs4EemA1z3Gu+1x6YNT9EDbOBHpgNc9xrvtcemDU\/RA2zgR6YDXPca77XHpg1P0QNs4EemA1z3Gu+1\/UGmFzIRMRfVmrSpIl1uiCuhovp465azlr3vChPLM+UKVNsdhBc2HAkIX0iZ97NmjVbYG\/TqDfADLtsNQ0wcD8jiQA0fvz4VHcwpql3XpUR52RJN61vRNbXLc+r9hT1nXoDTM6mcdTNStzJKPnSFzRgskogJUmmgOMvqWg8MLMioMrl8eoh\/YkmYlpEGnJftoQ16DL4JHInOks5F5Zyz+GCQoMGDbJ3lPfs2TO4AdkDcwEYPZ0wQN8MuwA0PbGJhEiQbwiaOnVqMKE8MBNZN\/8LpAHm3LlzgyuWuX4PJQLizm8k7g477GBv\/8XjGwdfgrWIyyZ+nLK4tqF8TJs2zbqKcXU1klcchF0uECrLsovXETcFk9aQ5VgyF6fl2uDBg22yWPw9R48eHbzmAhOFkC0OoR4kAeMirU6dOoV+j1VjwoQJhqA5IjohvKK4I50+u0SoCNsILkUgwlITfOXiLohVS1Yi9vS0Ed9QeDRq1ChDojIyl3Ts2NGW59v1Zo8ZNqBpgKkHUu8x5c5wln98Gd07t1u0aGGDuFA63GeE7xIGq0MX2GaQhgWFJIzI0kEKmTSEJs5NEVgT3KSxuj9dunQx3JvuEr6h9JXrs4XgFR72TJwwYgIMHz685NZh8YgPSznD1kpuswDsAlwJLyFNDpNfMs7Jne0SF+WBOXu2ad++vR2LMGDKIDGjSf\/CwHFRgCYyqBFlSPoWyaFJPs1evXoFxSRvEH\/AgsA1f99++62NwZkxY4Ytx8DjBJxEOj7dDdPQwKQeQEgSA0xHfEekK9KJpF9CtFXaTqoYeMI9R\/RXwM2l90hqoTzAlDoIdUaKd+vWzYJeguM8MFMAkxhsgASRYqVt27aBlCStikRG8pwlijAGvcTqq\/1cCcfgcy0gWTq4atpNDhsG0jFjxpghQ4ZY0AE2ffOvBqYbd0RdQ4cONaTs1iHE06dPN507d7afCpN+cmcmzydPnmyXdygvMJnsxLKLA7X0i7o9MBOAiYKB5qtJbKZhiQ3IfzlixAijnzEABKaR7JWgNJfYoyLVoLBrW9zyw4YNs9IuDMgamERForFr0iEWAJJ9smR6A6wvvvhimae9XpYHDhwY3DqcB5hshei39ur3wFQjlbTHJE6HtC+a5CaLsNsqRo4caZdkLZFEiqLodO3atQyYpMNGAkLksAxTNPRLEoYbduuv7g\/gFYVC3tfSkdybZBCmTQTLuUu1\/qaAkEmJVM0rMVm6+\/fvX8ILHZfvJWaCxCQJa\/fu3UOBGZbk1AWmvj0tbFl2\/5Zmnyk3ArsaOXVpYE6aNMm0adOm5BMamJI9WEDXr18\/06NHj9BmCniZZCgoScAkIA9rAxSl\/PTu3bvsW+xpUSo9MBOAGbbnirv7xwUmZ9ei\/bJ8JWnegJ1ycSSKVNg2I8mOGSYxBZiuwqbbAMCxPgBQke5xS7nObJcFmHyTdOEemFUGJoyWpTxqj4n555tvvrE4YAuQFDorS3lYAthKgCnSMCosWN+pqe9tF2CGrSpo8hxqZJGYbGlYYXCm8cCcB8DUphgM8YTzahJHDP4WlvPIlZ5o1WjXGKgpr6kSYKLQyA0bYdmEtcKkLRSS1htbL5q7JpQuMaullZgcTJCeEXOVB+Y8AKa+cxLpxPZAtFGeoWBhaE579Z+uzwV6JcCcNWtWoCSxb8XYL1fFkCUZwNA+jOSATEi0ecxSEydOtFsQzF9YMcg4IpQWmHKaxarhgTkPgMkAaamEpGPfKV5BPGdwkTAcfyaRVqhczbsSYPI9yfIh2wmM3rSP40kh9+pr2qvNUZx4SWocwCWnOmmB+dlnn9kjYKheA5NjQIzhUJQTByn52rVrZ8vokx\/ZF4YpP7LHC8uFHmYuom7OoVkuxdSiwVdJjkqxjbrmLN2fMH\/MMOVH2oeX1YABA8rmBYDDjCUXH+gCY8eOLXsHUHPEKAcPGpjwjEOBqJs7uLuzT58+9RuYSZJnfjzHuWHmzJlWsjRu3Ni0bNkyswMH7ZbTJCQty3lRmYCZzDimkPEYqdeqVSvTtGnTWE94JDjleRf\/AICsT6Oy8rnea+VZGbIglUcC4yXEvUGkFeTf9Ynq9VJenwYqrC+yLKN0cFXK\/L40qkh+e2AWyc35UBd7VtzHOJ+PSsY6H5qV+5MemLlZ6CuoBgc8MKvBVV9nbg54YOZmoa+gGhzwwKwGV32duTnggZmbhb6CanDAA7MaXPV15uaAB2ZuFvoKqsEBD8xqcNXXmZsDHpi5WegrqAYHPDCrwVVfZ24OeGDmZqGvoBoc8MCsBld9nbk54IGZm4W+gmpwwAOzGlz1debmgAdmbhb6CqrBAQ\/ManDV15mbAx6YuVnoK6gGBzwwq8FVX2duDnhg5mahr6AaHPDArAZXfZ25OeCBmZuFvoJqcMADsxpc9XXm5oAHZm4W+gqqwYH\/AY050eqOu\/OPAAAAAElFTkSuQmCC","height":0,"width":0}}
%---
%[output:6b9f681a]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Ignoring extra legend entries."}}
%---
%[output:62f82b61]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAFuBJREFUeF7tnQeUFEUTx\/uMiGJA8QmoiDlgwixiQMxiwkQwACYUs4CiqCjmLII5Z0UBwYhZEVTEgJgVzFkfijnwvV\/rf77eZnZnZnduufO63uNxu9vT01P9n6rq6qrqmtatW880xpihQ4ea7bbbjj\/Nsssua\/+HFl10UfPggw+axRZbzH7+9NNPTfv27aPfl1tuOTN27Fj7eauttjLvv\/++\/XuXXXYxF154of37zjvvNCeccEJ0zcorr2xuuummqE9+OP300831118f3fPFF1+0f1922WVRP3y+8cYbo\/t\/\/\/33Zp111on63Xfffc2pp55qLrroIvPGG2\/Y79dbbz1z0EEH2b9\/+OEHs+WWW5pvv\/3Wfl511VXNmDFj7N\/nnHOOufLKK+3fSyyxhHnuueeifov9sd9++5lnnnlmlmuuuOIKc+6550aXTZkyxcw333zm5ZdfNp07d46+h49HHXWUadOmjfnzzz\/NzTffXPDbKquskjgGNfjtt9+M25650PP4nWy66abmk08+ib5+\/vnnTbNmzeznJ554wvTq1Sv6Db7ssccelh\/du3ePvh88eLDp2rVr9Jk2L730kv08\/\/zzm0mTJpkJEyYYeCTq27ev6d27d\/R5+vTpZu21144+M5d33323\/VwjYF588cVmp512sl+6wOzRo4cZOHBgwbMButdeey367r333jNzzDFHamAycVtvvXVBn8WA2a9fPzN8+PCo7bvvvmvmnHPO6PNnn31mJxVq0qSJWWSRRQp+e\/rppw3X8MLAuJ9++in6vVJg3nvvvea4446L+nv44YfNCiusYCdSk7T77rtHIP3666\/NBhtsEAs2QLrZZptZ4dC8efPUgKwUmC4P6At+brLJJtH9zzzzTLP33nubO+64wwwYMCD6vlOnTgW8HjduXCSUaAQvAPOgQYOia5599lnTokWLgmc75phjzMiRI6PvmKeampr\/A\/OSSy4x3MwHJoDp1q1bURDxw8SJE03Tpk1TAxMJi6R1qRgw3Ulu3bq1eeyxxxInDaAee+yxZvTo0SXbVgpMJPBaa60V3eOUU06xL7crxdEM7kRfcMEFVjuVIl+yJD6wMaZcibnPPvsUgOebb74x66+\/fnRLzb+rUdKMh5cWwPH8Il+o8D3abciQIVEbSe9IYmYB5pFHHlkw6e+8846Za665UgPz1VdftdItDTD32msvI7W+5JJLGiRgEp144onm9ttvL2iGakNtcD0qBqoUmPThvvFIPcbbp08f2z9m0Pjx4y1vXOJ5rrrqqpIvGSbM9ttvn\/So0e\/lAhO1Db9ExYAJPvgn2nDDDUuODS37wAMPFLyEMmncC8844wxz7bXXRl+pTSIwZbfpyr\/\/\/tusueaakUp07bG0NmYWYB5\/\/PHmrrvuigb+5ptvmnnnndd+RjKi6n\/\/\/Xf7eaONNjK77babWW211aL2jBU1pGuYCOyovIDp22Tbbruteeihh2z\/Bx98sOnfv3\/BpCNlIdQVvEPlIyVGjRpVYPcBSsCZlmobmGgfBJJIWrLU+HxTh7UGNr9Lu+66qwEPkIulRGBywYgRIywYId4CSQQ+d+zY0b79UG0A8+qrrzZnnXVW9Cwsog488ED7+amnnjLYwKKTTjrJtGvXLlrE8b1rimDjdejQIXqpWITxPFA5ix+u++OPP0zbtm0LbFeN5\/777y9YkJx\/\/vlm2LBh0XixwZgMiJcMiS4bmAlkItNSbQNz8uTJZuedd46G4790SF1pItYbPDsLLPAhwkRggctCEGJRfdhhh0W\/I1TgERQB01Ud7uJHVwFM1C8GrEvuW1AbwPRVC\/dmVTn33HPPogqZaCSja+MBvsMPP9xMnTrVSk53Nep6FMoFpsAvj4J44\/at75Ckhx56aMQ+xsbKtnHjxoaJx+Mgop27sEoCaG0DE025\/\/77F8w\/fOZlQmvIG8M4XY+Av3jFHEM4fP7555E3R8\/G+oF1RCZgxjHGVze1AUzu60vNuLGwqEAtQKwiX3jhhaS5tG4NXDjYgJUA03cDcWNXsmsgSEVMI0mWYgNkXIC4ZcuWic+gBrUNTO6DqxBTxfVs+ANEA6DCpQkAIHa3KxDiHgoAH3LIIdFPiRIT457VlL\/CPeKII6xKdw17gPrWW2\/Zzl2xjG\/KtbVwNS2wwAIF43ONYBYNWvCokW9C6Hsm8fLLLy9Y+cJA\/INy2dCWdj179rRvJM8kwu8JWCoB5syZM62rx2U+\/s04YOF75V6u3ewyAm0Ar7L4MLneB2YpGxVfLhoEOuCAAwrcQL5vWO4ijRGgnXfeeQUuHv3GnOOZ8Be2P\/74o8HMivOSMC+XXnqp2WKLLQrwUDMTrnrkqnJN3C+\/\/GJ9l40aNTIrrrhiZCekfqVzaMgiZ9q0aVZt4MvEZ9iqVSvrQ\/WJx+Il+fDDDy1AmGh\/dZzDkMrugkUQmwD4DRkXEoZxZpGSZd88hwsxsZiHr776yqCeMV0WXHDBkj3PmDHDXvPRRx9ZwbT88svb542bv9TAzOFZQheBA6k5EICZmlWhYTU5EIBZTW6He6XmQCww2QbEpoTYdN9hhx1SdxgaBg7kwYFYYObRcegjcKASDgRgZuAeK31Wo3gmfJdIhm5C0xQcCMBMwSQAyc4OkTByLrNrw4YCu0p1yQ2V4nHqRZMAzBTT5Id8sQGgYOM999zT7uUTlBEoPw4EYCbwkpA+tuEgAg7Y8WKfnp0dRWcTrU5AcKD8OBCAmcBLtuSuueYas8Yaa9g9YHeXQr8Rm3jbbbflNyuhJxOAmQACImoILiYuVLlDuoRIK\/bZoVdeeaVgS44Yy4ZExVJGyuVBAGYC5zbeeGPzxRdf2CQpN5yOy9yAh0cffTTKlQKUXbp0KXdO6t11BBC7QcR5PEAAZgkussmgaHgXeLrkr7\/+soEkkBuXGoBZOTQDMEvwkEgYXEKQm+LqXqJILPJW3NCthqTK81bj8DcAswQwP\/74YxtnCblpELqEtIqVVlrJfoxT9ZXLjYbbQwBmibnHmb766qvbFkSUE4fqkpv2EafqGy6sKn\/yAMwEHkpVx6XTkt2ndA5ydojGDpQPBwIwE\/ioHPq4VAXtCJEOccMNN+QzI6EXy4EAzAQguHnj7gLn9ddfty4h1D01miibEyg\/DgRgJvCSzEYS25R\/Tm70QgstFKWeukl3+U1L6CkAMwUGSIIjs1Lg1CWodzIGlcDvdwWoWSBR6EuVQFLcrmiTvMPuyHj89ddfzVJLLVXnIqQCMDMghTRUFjkk\/7MLVAyQZECS5+6WFaSyBqq\/EpVPSjM52m6JxwzDt00ZG5mvBKEoQorvqbtE1ZKll146a5e10j4AM2e2kt\/N\/rny4gmRQyopjtMtzJDl1uwyURCAahXlApMtVKq7qXaoPzbGQ9kdJOjspgDMnGeAKCOS+yFqOlFcAFBRE1SFbNP6PDEFnnzySVtwglpAAlS5wFRBWdxalAekvAtmCkEqClDJWswrZ\/ZF3QVg5sxZVSPxi06h\/qmdCbiOPvpoG\/meRH5VDLUvF5gUI0PiqoiFe3+3dKMK8SaNrzZ\/D8DMkbtuUAexm25RV25D1WbKofhVfIsNAYlJKRkVS6FKL6F25QDTLR8ZNzakuKSmH8KXI4tSdxWAmZpVyQ2pXYSzHYqrnqvJR5WyiMpKcuiXA0xeGoDN\/5QZ970EquwbVzcq6zjzaB+AmQcX\/+1DgcPFgKdVNc1VhTnL7SsBZqn7uNKS9BHKhM9uCsDMcQZUQL9YrXh2i3QAQ1xV5aSh5A3M7777zh5coMpzfvXlpPHU5u8BmDlyV6Wdi9WKp2YntTuhchYYeQET2xXvAZsDcmNRjhBJmcdGQB4sDcDMg4v\/9qHMyWKq\/JFHHrG+yHLtuDyA6dcO5UQNisxmrceZI9tiuwrAzJHDHFygOk9xgcWqjJy1vrqGWCkwqUFPHXVymHh5kJhKTc6RDbl0FYCZCxv\/6QQVyckZbPXFnY+04447Wj9mXBnsNMOoFJjUdMfcAJSPP\/54dBpamntXu01Nly5dZqkoXO1B\/JfuR7VcqgRT8ZjFxDzzzGMfj8q7H3zwgf2b74vts5fihfrm+ESq8WYlSn+TDsJ5PTqe0e+DiiLuyXNZ75FX+wDMvDhZD\/pJOpRAj1COKyvvxw+qPG+O1tH+sqQUU7tekn52PU4A5uzifJXvK2BylGFtpNvm\/TgBmHlztI72F4BZRyemoQ8rALOhI6COPn8AZh2dmIY+rAYNTMK+cDIvs8wyDR0Htfr8bCsSX5klBaLBApNsQIpKUU+SYACdNFuqGID2lknsovYPRHQ1Yf+33HKLoQRgWiLXBucxjuu64CBOO+5y2pHfztmbcduexfprsMDUgfdE0LAzobOoyb5zjzt2Gafzxl1gki9D5ItfPS1pAhUdzq5Gp06dkprX69+JCKKKMQW\/KF2ThhokMBVn6J7kWi4wiRGE8YA7y7adgMlB7BQh+K8TJw4ThIF2IUIoieodMCdPnjwTFUjGHGX3yPf4+eefbcFSclPiTkb1mcCh76huN\/uvXGBiP5GExWmuLjA5E5wACFJhKXTVtm1bWxEDIugWqTxy5EhbwH\/zzTcvqP5Ln7Rhr7pFixb22mJ2MCkR7HxwGq5ydrCdmzZtau9HagI84vRYShDSJ5Hr3bp1i0wIxg8QCOZgX5yjV9wjV7DDGU\/jxo1tuBl9oGkoAkt72k6fPt1MmjTJ7rtTZY6xcCiBiEghHOVp67\/XO2C2b99+JozkNAaOBXGJ\/GjOny51VIgy+QDS2LFjo8vLBWacKqcKBqBziZhGwsiYMJWjdn9XwMStt95qBg4cOItAoVgWz6xno3owzzp8+PCCthQpYLdEEUEAhpcYKbX44ovbaB3o7bfftv\/zkpKJ6BN965QLKmC0a9fOHjjAc1AfSUSQMYcOkEnpFiTo2LGjGTp0aAE4qTQHwNPkgtdLYOoAeJKcCM2ikq5ASj5zqSBSAdDPR9b3SF3szzhCCpIEVcrGxMDv3r27bcOko+IJ2cKWRLqMGDHCVpWg1DQlXFh8AVQmknaYF4R5nXzyyVbyEKBw2mmnWXPBLT5AmBqHTJEWgfRbeOGFrZrkjHbIB6aehwUfNTQB+bBhw2zuOBKSl5qXlcAJnhEiuodyMQKm+mDMzZs3t3noAiMSmzOEOANcB1+hFbDZRf369bMvEnNFhY5SVG+B6edBazGTtJjQkSKAhng\/kYBZklv\/\/lgKmCoD6OdCk5eNygWYqNU4G5NiA1OnTrWAcQNiAUvXrl0tYMlWRNUz4XwG3HLDsNKn1DUvbhwwkeR9+vSJHpE+6ZsiBW6pFdIpUNX33HOPlbYuMF3vg1Iz6NBdcSsO04\/jBMhnn312qnTeegtMn5lIC8CQlJwvNQvzOLXXByZvPlHTcUTeC2qvFDBZzAAsQAPwcT8h1XzygSkbjHZ+4peb\/82EIblJeWA1z4vokiY\/Dph+XXZsR\/yLROYgkYkUR8WjxpGEKoctYPopGEhUeOjyg7GMHj3angqBZEXyi5SqQQU6EuH+kxITlYXkEaEiUBVJR2VgN6FKfb9jXjYmNiyJ+EyaCLCTwoCEEkh9YAK2zp07WzvOt0\/pR\/YZUmzixIlWHcY9KxIUqegD07ep6ZOiWxxWhbvLtQ81bh+Y\/tg0Zt8sKgZMpXIUy8p0gepKzDZt2thxUkgBUweNAchZ1EGMizHoRI40Wg8bHVuc+7CIbtasmV0cbrPNNtFCFA1EmRruu+6668Z6E9Bwo0aNMjUsflBVPKSbIZcVmEgW7DpfYubhx+RBAA81dngJZPchcfAGtGzZchZVrhxuX\/pofOTdAB48CUhtgMnCq2fPngXzwAuHlPKBiR3plyXEHGIByIKGogLY5ti1LMAAlw9MP\/cnKzAxQ9BGaSp7uMDEzGDxBSHNBw0aNAv24C1pvWmS1NBOCAGtVfzOXBNE5lUxgSENWTEwpcp9+ycviUk\/uElc0ONCQYriPho8eLCVnL7EdO04v+SJbEoYOGXKFGsT4mZikcXCyCXZ2knAdI9ewX2EW0okGzNvYEqaswBjQyKtKneBqWtYvKEFcFFpQ0SLyySJqXUAYKbILaBDe2AOIkwgbG+8GJhlgA9CyCBURAggXhhMoIqByUPwxsF8FkJ5S0y9Yf5DCDBK+hIwtULF1sOfyVvsL+C0pQfYkfSoD+7jM0sSjO+TgKntVV+t8lLI4Z83MOVkx6XFFmU5wARMLLpctY2GQFPoxS210QGflX\/kL6Cx5dGYAE3zNG3aNNOhQ4dIWsuFxhduQYiKganOfJWZl8QEVPxjwpGSOLmZbAAFadHG6pw9etphP2IXar+edkhEfsNkkXS57777DPYWJHcRapjrv\/zyS6t+RUnAdBdbABE1jcmB3SXChcQCBpMJyVCpKtfLGXeihg\/SYqq8b9++pnfv3gXNcRGqGl3Sfry7kMT251pcYiL8yZhMuPm0HmCBx5rBxwzuO3y1vCwRMP08D7kuklblrERxgUCsfrVTpBVjqSAO1fpxJ0hvq\/bKMarx4zHBqhrBvQAQ0lEqHmCg0lGpkBzsrgtGzOJajHD3bEieA4c9qkb3QYoyNlwycldRkRenfpyNqUWKO8u8TPSD7Uq\/vGT0ia\/VX00n2Zi9evUylAsUKR1Y\/tFyJGbclqZ7TIzvrYm7h1S5fmPhxAYEzxhXoVildGg\/btw468OFwAoaDg2QS2qF1GjafdtSDCz224wZM6ydwvYpD8KKz1cxvL3Yj02aNCl4awEErinAix2VVHMcTwCObaKUhgwZYl+MJH+uxs21uIgYGwsHJXXxgqHG2E7NowyLVuSck079oSQqJjFZAeuQLfXhqtQ0u0rwt3\/\/\/rMsBukPflPFmH\/aZXPrfuqFd++JEMoFmEw4dgP7tkid+kY6mg9VhIQQmJCOqHVs0DQTVM3nVqFVPApxft20qjxuZ88FSRqJqXvx4rHYQROOHz++QMP5JoM8GNKWKoPIHHB9LsBkYCrx7Npt1ZyoSu8ltcgbzt\/QmDFjrGmAbcibXVdIXgV\/t60cVV4pMPFNEhFG4Am+SxGaDZcdah4b0y805u4MYsey\/YoaVxnE3IDJ6qxHjx52AEkrxLoywe44cC\/x1hJQIec4tiiqkrc9TZRVtZ4LO5jFHhsHaY8JLKbKKwWmvBE8e5yte91111mXHuRWuMO0wcbGDACUKoVIcVk8BLkBs1qTEu5THgdqC5iuNwJpx2JZLzFSE+8Imw5xDvUBAwYUbKW6bQIwy5vnendVbQETRrh+T7wV7ESxwCFwRR4OvCDshrmkYBp9p80SPtdMmDAhFNWqdzDLPmBAgGeBFW+rVq2ifKpKVTkjwWPCYsz1+2qECjl0A3z0G14UFswynXCXKfi7pnXr1gGY2ee53l5RmyVilCnAdiSeDbZlcZnheitGxACzEeG7vaquyinHx1sC+duM9Xa2w8DL4oBb6JbFHHvzoqoDkxsrxpF9UqJbAjUsDpBF0KhRI2ub4veMiwCbLcBktUa4FtugfiROw5qihve0+D39ULq4HcPZAsyGNx3hibNyIAAzK8dC+6pwIACzKmwON8nKgQDMrBwL7avCgQDMqrA53CQrBwIws3IstK8KBwIwq8LmcJOsHAjAzMqx0L4qHAjArAqbw02yciAAMyvHQvuqcCAAsypsDjfJyoEAzKwcC+2rwoEAzKqwOdwkKwcCMLNyLLSvCgcCMKvC5nCTrBwIwMzKsdC+KhwIwKwKm8NNsnIgADMrx0L7qnAgALMqbA43ycqBAMysHAvtq8KBAMyqsDncJCsHAjCzciy0rwoHAjCrwuZwk6wc+B8gHK70JY+GUAAAAABJRU5ErkJggg==","height":0,"width":0}}
%---
%[output:3945ed50]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAFkNJREFUeF7tnQeQFcXzxwcVQ4kZCwG1QKJZFBOoIKJlwgRGTIiiIGYBRYIoKGYRATEgIBhBBAPmjFkwoWI4URT1jBh+ZvnVZ37\/3n+\/ud19+9K9d+9NV1Hc3c7OzvR8p6e7p6en3vLly5cbT54DJcaBeh6YJTYivjmWAx6YHgglyQEPzJIcFt8oD0yPgZLkgAdmSQ6Lb5QHpsdASXLAA7Mkh8U3ql5VVVUiP+bGG29sVlxxxZLg2A8\/\/GB+\/PHH\/7kV6tUzzZo1y7ld77zzjvntt99sPQ0aNDCbbrppznXWVgV1ue1RPKrXvHnzRMB8+OGHTevWrbPi9VdffWX+\/fdf++4666xjVltttazqkZeuueYaM3bs2KCOqqqqRPXFtWP\/\/fc37777rq1np512MrfffnuiOkuhUF1ue87AnDt3rmnTpk3G4\/D555+b3XbbLXhv\/PjxZu+99864Hv1CNsBM1466PLh1ue1FA+bixYtNly5dig7MdO3Qg7v77rubW265JafJU5sv1+W2RwKzurp6+YABA8yzzz4blJk1a5Zp0qRJyjsswSuttFLK36qrq80qq6xi1lprrchxSAcI90W27v\/8809bbxRlIzHTtePvv\/82EjawwgorJNKn\/\/nnn8hycc\/C+vXTTz+ZNddcMys8Z9N2eLzyyitn9T39EvXQdvCRTxvEWuVnnHGGuf\/++4PvPffcc6Zp06ahjX788cfNpEmTzNtvv21+\/fVXW2a99dYz2267rTn77LNTlvtrr73WLFy40DzxxBNBXehvGFKHH364adeunf37N998Yyj75ptvBnre6quvbp8fcMAB5qCDDkqZFJkCM0k7hg0bZgAv1LZtWzN48GD78\/PPP29uvfXWoP1XXnmluffee81jjz1mXnnlFbP11lvbFeHEE0+0A33jjTeap59+2rz66quWL3vuuac577zzQkGHenTHHXeYBQsWWF5SfscddzT77bef2WeffRKDJqrtGEXwSmj06NHmkUceMYyhCKLtt9\/e9OvXz3Tq1Cnx9zASb775ZnPPPfcYVCSh5s2bm0MPPdQceeSRgbC66KKLzEcffRSUYSzWXXfd4Hf63bdv3+B3+HnOOef8b688CTCZlZdddlnaJe7yyy83PXr0sB\/q0KGDweAIozFjxphu3brZQTn22GMDkIeV3XfffS2D69evbx9nCswk7YjS0+666y5z\/vnnp0ysl156qUYzjznmGPPHH3+Yu+++u8YzBuyBBx4IjL6\/\/vrLDBo0yNx3332RYGCS9+\/fPxFYotoOAPv06RPUscsuu9iJFkbXX3+9gc\/pCOl48MEHm08++SSy6GabbWbuvPNO69246qqrzLhx44KyMu7yh6eeesr07t07eH7xxRebnj17JgemO0BxHXjwwQetu2WPPfaI7AAzDkkD8x966KGU6pCWIo3lAVYy0jYbYCZpR1Jgphu4qOeXXHKJOeKII+zjqVOnmgsvvDBtVUOGDDEnnHBC2nJJgRlXETxnFUxHI0aMMFOmTAmKbbjhhqZRo0bm9ddfT3n1rLPOMqeddpp577337AoghDACnEIAUa9IL7\/8sll\/\/fWTAROQdO7c2Xz33XdBhTfccIMFHjoGy5f+GFb45MmTbdk43e7nn3+2S6HQYYcdZsV4w4YNDe6pU089NXjGciizP1OJma4dPE8KzK222spceumlZtVVVzUjR440zHhNSIf27dubmTNnGlYPIQYHFxc+WPgjE2+DDTaw9e2www5m3rx5hgGVZwz6M888Y321cZQJMBEIHTt2NJ9++qmVTHpMBRRx32Lpl3doM5IRWrp0qZ14srQzrtgqEOrMxx9\/bH9mAsyfPz9Y\/eCFvKNxk2gpd8WtzAbdARqFziXEDEIhjgMmywEDKHTUUUdZowvDgQ4PHTo0eHbKKaeYgQMH2t+LCUwmYdeuXW07WNJps55Y6HEQfWjVqlXwTJjOUorqIoTk1L+jw+JSE0KP22677fICTHfc3GV2zpw5Zosttoj91iabbJLyHDWQvm2++eYWfKK6sYwDYgieCV\/4Hb0aXdrFBn0\/5JBD7DuJgImxg3QQCnO2T58+PQVIAA7jJZ01TJ1IEQwkBprOYQS5VCrAxHgQwC1ZsiTFaBg+fLg57rjjUsAo0kCc9i6fMLTWXnvt4B3Ka4MCvmvwh6EmqcRkydRGDkbcueeeG1SJhNMrWNi3MFox7MIIHZaVgX8AU8jl08knn2x1bISPGJmUZdzXWGON5MCE4bfddlvwIZGGunGPPvqoATxCouSmA6aroEdN11IBJhMIYwb68ssv7bIo5IJIL1MCTAzIiRMnxkol\/RDD66STTootnxSYrkDB+MLIEkoCTCz9Xr16pagAbuNQT5CSWvpirYseCv\/gIwDFuwFheGGACSWSmOhG2u2A3rPRRhultGfGjBnBUssDFHxmUBww6STuIE2If95j+Tr66KODR3UdmPQJnkyYMMFcccUVQb8wBsTbEIY+dslEdYhCZ20Ckzb88ssvdsuWpV+2ccPAidtMfKXuSsEk0TuA2Cx77bVXZsDEatauC3xRLqAwTrSrRHyhccB0dUUMB\/Hfff\/999aIECoXYDIg+A2FcolBkDpqC5gAEitbiC1qXGSvvfaaNQIRTprEO8Pf8FWjVwphOGv\/Nv5uiaFgoyORxPziiy\/MrrvuGlSKtQgIEdkQIhpRLcRzZgs7KC4wUbjxg0G4E2i8kG4cMxJ3SaGAqdvBN5Ja5dku5SIxFy1alOI8Zwm77rrrLK8gDADtjkGF2mabbaKEpf17bQHzhRdeSFnFLrjgghQfpLuyipEjjcdf6XoxeIY3RhtHOPATAZOXXX8TZj8upN9\/\/z0F+ZTVzloX1C1atLBWHE54lgKtb9FAXBCoCnonijpFYebnbKzyuHbgcy00MJnYAjitW9EfJjLAxV2jHddMfL0cRqGztoCJkep6CNA32ckjDHHatGkpuid+UXAixHifeeaZNbohap9+kBiYNArgiD8qiklIAGaO9r1pI0DewzhiQLp37x4rDeQh+oi4UbIBJvVEtQM9rzaBybLG5oK7iaAZwYAyYLJtG8ek2gImbbjpppus3zUdhe1csWvkSn\/6ye6fG4dhgUklenssaq8cETtq1KjIWEV8cmzNuQ5hLG86o6WBWO1hO0pYbXyHgUEH0zMOS493tUM\/Lh5z2bJl1qfI\/mxcO1AvxE2lpZtr1MUt5fQRd4qQngi6Tp5\/++23VvKz3LnEqoGqERWv4JaParvr8XD1WVYl\/JBCSaxy4mqRjBhwYROL\/X5UNAxXUU90e1317fjjjzfs9buU1dEKAIrkBBBYlAQQI87jrEvA8fXXX9uln3Ls7oiyC3hQqlkO2FlxI5vSzc6o5zBuyy23tMuJbLfFtSPb7+TyHn0nyAFfH\/1u2bJlSpBDLnUX8l32+9GXETYYQEz8xo0bGxzwcZFhru0we\/ZsO0Z5AWYhO5zPumXHIek+cD6\/7euqyQEEGpsFsjKxueDGSchbWUnMUmY6uxJIX9QRcUd4YBZ3xFBb2GrUO1q0iJA47avWrSw7YGJ8vf\/++ykj4YFZXGC6Pkxag8cB11HUsl92wETBl+gXdCAUdQ\/M4gIzm6+XHTA1E5588kkbWe6BmQ00ivuOB6Yx1rHtKf8c0FuQmdZe8cB0faKZMtCXD+dArmfzPTDHjLESUxIc4M4IO9NTKgB0959LoV2y2SHOen7XPM2mjR6YIcD8qPo\/ps2ePbPhZ0HfmTdxUBD9XdAP5Vi5B2YMAwmdYpuVM0Rxxo\/LRCTmj2u0NG26lh4wZw\/axwMzx0lTtNcBJEcI2IcmfpB9e\/ZsOdjGPq0bLOCBmf+h8hIzhKf66IINOFUnDImOItBC\/02MH\/Qj\/nmJmRtQhZ\/e+FF8\/OCDD4JwfSQkwQFEvnPUluARSCdk4HcvMXMDovs2Rg\/Gozd+FGdIKsC5aSKUOAFIkC0OdkKxCA3jmTuTPTDzC8ywyZ7NF8rKKie2j5w8OjmCMEWf537jjTeCXEIemNnAJv4dr2M6\/JEcRWFJAvSxAAJo5eB+XQNm\/mGUnxr1SuSBqXhKrB\/ZICANPCmiM2MQNS9ZIrSyTln0o4abbJWf0cpzLd9WvZXnGvNbneSWgofe+Pk\/3hJRT44cKCoHj0hJkrKSnFXrQ\/kdIl8b++T62EamHCkbHVOnIeGYqRwtFoZwFEBSdSfJB5QpI335\/HKgbIAp53tgT1gSAaKoOeQVtdTnl62+tlw5UDbAhBGyVIclIeWciSRacM8758pE\/37+OVBWwJTMyG6CJtgmO0I6B2P+2elrzBcHygqYOo+nNnBI3kVecJb7q6++2uZ091TaHCgrYJInnhQkciQUnZIbNSTVHSf1yA3kqfQ5UFbAhN2k3iaziHtemeWd7BFxt7IBbIwkMiHHHdov1rASlEL72PuXBKfFaov+LnlCiUUgNaUbvZVt+8oOmMII8rtj5JDShERQcYAkpw4pWXRyWhzwLP+ltOxzZp4UNLQJlaSYBM9ICcT5fZ3HnVQ4JGAjM0suVLbATMoU0puQA13SNxPwweyXvDxuusKk9ea7HDtXREqRxKHYwGR7lxxVkrTV5Rl9D0vumwlPKh6YOpcOKWVIKAoIyHArUilsizMTJmdbFtWCCKkPP\/zQ5hEVIBQbmPCG8EGdkQ4VigAauVkkzDOSCR8qHpiSuUPn34SBqABkTQYMYbd0ZMLkbMuG5aOkrmIDk5zwSG73xg3aRjJXyWBHsrCwjG9J+FHRwNSBHcRvurkbSelNtl9u+uJms9omJCaZm+WOS27MIHyvmMBkwnKzBapOGM906kMdXpgp7yoamPqqaJZL95JOYXKpZPKQTYJiApPJzAThf5L5u94LSaqL3hl17UoSkFY0MCV4OAp4YgXDSI5t5MsVkmRgwsqUAjDj2q6lJUdbOKGaLVU0MOUCJLl3xmWivu5FX46ULbNzfa9UgckNIxhDcmsJSz28zcUXXNHAlJvByAWv72sXAHEFoVxMmosinysg5f1SAyY6MF4NnfaaM1ZIylxASX8rGpg4h7liL2opl9vectWXyhGY3ALC9q\/cdsatG9zixg0g+aCKBqa+sjgsuFhuaGAXiOMYxaZSkZgkYj3wwAPthaZMaiSmvuUsH3yqaGCyFO288852S00ucNdMlWtKktznmI\/BSFdHqQCTi1FRgwAlOUi5XzzfVNHAhJky2DCZKCQ5ksHxC26IhfQVKvkegEzqKxVgyp3lHOSTKxbdfpDtxHW\/ZdLXigcmyxIGjtxBxIE2AkAkFaGbuSMT5ua7bCkAEz6xbZuEcnGxVTwwYfDSpUutEaRvfUOCYmHmctIvyeBlUkaAWcy4UvfSqrj2c0mD3L6bST8r3ip3mUVcIQYRlylxA1uxHeqZDmY5lfcSs5xGs4z64oFZRoNZTl3xwCyn0SyjvnhgltFgllNXPDDLaTTLqC8emGU0mOXUFQ\/MchrNMuqLB2YZDWY5daUkgUkSVq5CyZTIusFxXI7fNmjQIPYseaZ1F6o8gSQcOoMKEQxBvWy7wk82DuBRXaCSBOaECRNsKFWmxL42h8c4yxOWhz3T+mqjvN7iq6qqKsgnhwwZYgN6CU0bP358Qb6R70pLEpgwL5scQ9zhM27cOA9MByUCTAJUJk6cmG8MFaS+kgQmZ0hkedO9JgqI2ElSvowePboGQ1gKyVnE+6RaplypE1KSRLOEifXt27cgzfXALAhb\/79SSU5AfpwpU6YU+GvlU70HZoHHMgkwOQJBwifOoMj5E\/JmcsqxRYsWpmvXrjYRFJHXHA3o0qWL\/ceBNKT0nDlz7HlopC4JEAiE5Ya1MCJpFzl63nrrLXvOul27dlZSy40YSdjBeXbSwEBkuIBIJsBlWSQ6IPSO8zWcPyKBAMQFW\/CiVatWST5hNDDR3WnzvHnzDGFpJHOgvZxV11cZSsWfffaZmTlzpuHE6OLFi02zZs0sP3r27FnDWJs7d65ZtGiRad26tW2fSwgTeNyxY8eARxxp4dAffWFsuAeUg4EluZRHcTsJMMkY7Bo\/MjCAFdACpDCmkfJEAob1c\/cyAbJRoKtFGWhchDV48OBEYXNhxg\/hdwweNHz4cDNixIga7SVelOOySQ5\/Sf8BNKDXcadSMUmy6L8GJ0AbOHBgkGBMN4Lvk3CMpAdCpH\/kxuMoXZYAY\/hLGpnevXvb1yTGtFu3bmbZsmXBadWKAqYwECZ07tzZJjFwjQGYxz+eTZ482b5CAljOSQtNmjTJjBw50v7KROjevbvhVgyksOTl5ELVMD3YRVg6YEr5008\/3Ur8+fPnB2oM57dnzZqVVmoKMKUgkonzTCTCoi9ITojVgjhUSB\/U47vov6wq\/B2esdpASHtJOZgLMKVtAJ47gioOmHLLrjCCq6LJpAaRjhCpIcTPU6dOtYeukLJIE5b4Tp06WSmCMTZq1KgUKSP3WVIHS1TDhg1jgZMOmHybg1962R42bJiZNm2arXfhwoVp\/bUamP369TMcJhOiP+3bt7e\/6pSLRPSj8gDG2bNn22S2Qkg9Eo7BA0BOljwoV2Cyoo0dO9b6WisOmO5AatcUA9G0adNgAOTcOX8gnUyTJk0sUAW8Ydk5cGajZ0JIVa6ZjqN0wBwwYEANa52JxISCwo4du9\/TwAwDsqg\/6LOoIBw1ASQQE02SPuh6UTEk0S2qAZM2V2Bq\/lcUMNu2bVsjBbakiYHpbrYNnbuIZRrFX0tRpGUYkQgA6tWrlxk6dGhOwGQiCEikIn01jF5Koz4kwAzrP++IdOzRo4dN9cLNcmRTjgP+jBkzrP6py+QCTNQFyZVPnRUFTHRHkhhoEmCGZeMIAybLPdIzCSXRM9NJTJZR1yugcyolydwrwAzrP\/2QW4ulvRp0YVnweEeDV9qYDpgimcOMH\/fuyYoCZpi1mCkwRbowOCR0jSOsYPTRXJZylm3X8tbAzERiRlnLAkyRmBqYUUdwccuRCALC9dS4cePYpVxfmeiB2aePZVycgzlTYOK6Eec+BhHBIi6hZxKcwc0SYc91+XQSsxjADFsp3D4SiyDZ3USqisQMk8z6PLoHZgGAOX369EBvxBrFKtWkByDs6kB3gEsRmNXV1dZlA7leDP6G45+VAH+xdqWJR4JsJhhlmrTR6IFZAGDioEcisGePHxGdVVxCDCjWMhIHnZVsHvxf15Zy2iv5ifjZNcBwKxEs4z7Tk0wmJTtiL774onXFCXlgFgCYMFe7awAeW5E4q3HFyDUsYdI0DKClKDFpJ9ughMlJf9CXGzVqZO9OEue6q7PyDnEMQkhO0u1IHWULTMm+FhfEIdteOh5TXDxhyr8o+mE5MON0LZYqljl9+RKMJzsx0iYq2ZQLTnaK+vfvb\/8s8ZgMfIcOHezf8qFjxvWfb7jGj7TRzYGp285OFKuDmzhrwYIFVjpqMMJbsumxUUA6bC0xCW\/El+yOaZ2yymPXxCI8REriXGabrn79+naXhOU92ytEitCFtJ8kLoBADqxzouDxN7Zs2TJWRUEHXbJkiZWsGIBc151phmEPzLRD4wsUgwMemMXguv9mWg54YKZlkS9QDA54YBaD6\/6baTnggZmWRb5AMTjwX3apNGi0ZfN6AAAAAElFTkSuQmCC","height":0,"width":0}}
%---
%[output:59a0e43a]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAF8pJREFUeF7tnQeQFcXzx+dEzFkwgFIEE4qIJUaMJwbMAROIiiAKYiwOUUBEQTArioiiCJ4ZzDmgqBgLxZyRUjGHv4o53L8+87PXfsO+fbu3+969e0xXUdzdzk7o+W5Pd09PT1VdXV2d8eQ5UGYcqPLALLMZ8d2xHPDA9EAoSw54YJbltPhOeWB6DJQlBzwwy3JafKc8MD0GypIDHphlOS2+U1ULFiyoW3bZZXM48fXXX5sFCxb8z2yvqjKtW7dOzKm\/\/vrLvPLKK8F7LVq0MC1btoxVz\/z5881nn30WlO3cubPtR2OiNONv6HH++OOP5t133w26scEGG5jll1++pN2qqq2trevZs2dOo3vttZd56623gr8BsBVXXDFRx3766SezySabBO+ccsop5oQTTgh+\/+KLL8w\/\/\/xjf1955ZXN0ksvHTw777zzzMSJE4Pf33vvPbP44osnar8Uhb\/\/\/nvz66+\/2qaaNm1qmjdvHjRbaPyl6F9923jiiSdMnz59gtdvvvlms+WWW9a3unq9V1VTU1N3\/vnnBy\/ztXTq1Cn4fbPNNjO333574sqjJubTTz8122+\/fVDnlVdeaXbfffdGB8xBgwaZO+64w\/a7Xbt25tFHH\/XATIyU8Beqqqur6x5\/\/PHg6bPPPmsOP\/zw4PdTTz3VDBw4MHFzLjCHDBli+vXrZ+uZN2+eqa6ujg3M999\/3zRp0iRxH4r9QhJg6vEXu19p63clJh+fFlZp64\/zflWbNm3qXn311UCHuPzyy80ll1wSvHvnnXfmLMnyAB0Kilpi\/\/zzz6AeyomeWAiYf\/\/9d7DM806cZZz+UDYugOmb7lMcZrllooBJ2Xzjj2qLsecbQ9Qzt074QftaRYo7RlQs2hJCTYlDf\/zxh1liiSXiFI0sg3pkgXnLLbeYLbbYwhY+8sgjzdNPP21\/xiiaM2dOwKjXX3\/d6n5vv\/22+eijj2yZVVdd1WyzzTbmoIMOMttuu23QIJUfe+yxwe\/77befOeCAA8yll15q3nzzTaOl9FZbbWVatWplDjnkELPpppuaadOmmXvuuSd4d\/LkybYPqBnoqkJIcgy1hx56yC6jP\/\/8s11SjzrqKNsfl0kwDrXhySefNK+99pqtZrvttjNIM9qjX9Dmm2+eow+7XJw9e7ZVb1hdUEuEV3vuuafVl0877TSre4aNn7LXXXedmTVrln1vvfXWMwcffLBVCRjHhx9+aHbeeWfTrVs3yy\/0WHhGWzxr06aN5VPfvn3NYostltM1gDhp0iTz8MMPB+ODH6hjrIIdOnSIBZo33njDaPXu9NNPN+3bt7fvnnnmmQbjFNpll13MRhttZO666y7z4IMPGuyGNdZYw2Cj9O\/f3\/IiLvEhTZgwwdbzzjvv\/A+YQ4cOtcouD2GUEGC6+OKL7a833XSTGTZsWGQ7PD\/66KNtmXw6JiBmAGF02WWXmb333tvkM36YJJgsBKCff\/750LqYiLPPPjt4BqiPO+640PJ8gEsttZT59ttvbfk99tjDXHHFFXnHCoiQlmG01lprmaeeeirv+HkH9YjJhJhIACVt6zrPPfdcU1tbm2OIynNAe+GFFwbF8WKgKmmj1e3flClT7IdYiKKMH3gDcCCMW1bbMMKSZ7VdcsklCzVnPUAIGfgmZIEpE4Ek5KsXApSAE8AiyZBIhQipw\/KRD5hIA5G2bl187eiecYFZqC+PPfaYadu2rS3m1hn1biFg3nvvveakk04KrYLJYkKijD8NzEJjiHrOKoFEhJDO2vjK914+1UyXjwvMQn0fM2aMle6FCNURFVKTBSZfLUvFjTfeaIYPHx48f+GFF6wL5JlnnjFHHHFE8PezzjrLLpXoHkz4tddeGzwTRTlqYgrpmEmAieRCOvLxsMyLGkKHxo8fb5fEb775JlBVpKOMAdVj7ty5hqVKS6xCwJQ6khg\/2l3mApOlHGAh1VkC9YrC3KA+NWvWzIwePdo88MADAa9HjRplevToYVcB\/hdCKtbU1Fj1CCCOHDkyeHbYYYfZeqIoCTDh1RlnnGGXbdQkeC6EWjhixIjItlDFXFcU47LA5E1ACMJlidlwww3NfffdZysFmLJkAkb8keg36FGoAfIOZdEHd9hhh0iJkRUwWcpRMYTcD0hUC\/SW448\/PiiHtNMSz53YUgNT+4ld41NWLTrPsrn\/\/vsH4xBL35U4999\/f6ATUphVT3RqfpdVLR9ikgBT18WKuvHGGwfVdu3a1Vx99dWRwAQ7fKhCfFB8nAEw0T8oIJLjxBNPNCeffHJOpSzBLI8wCEkjuoYuVEpgojMOHjw4aN4FvOjOMGfs2LFBubDlDIaKqlJKYKLfYlQKuforRpkYLZ9\/\/rnp0qVLUFakMPqZlqR8sJqoX6thGFnalnCRExeYHTt2zBFK1IPhKBhCbbvmmmsigel+iKx47BAGwOzVq5e54YYbgkpuvfVW24hQXB2tlMA855xzjN61wlrUyr0Ak+VEj+3FF1+0S6MmvdtVSmDi1XjppZeCrrj6qwaRC0zxMbs7dZFIMMZMnz7d2gxpJWYYn7RxGweYWh2iPwg7vCkBMN1Oslcq\/qswi5ydGvaw2UPFPSJUSmCKjiVt5wMm1j7\/hNylzv3SGwswmdQBAwYs5OLbbbfdIrHJO2IUhhWMKzExlF2jJSkwER5seQph66BXhwLTnRgMHXx3QiJu+f2RRx6xbphyBqa7PIoklT673ojGBkzcYtdff70dDqoB+mSaoJdSAtNVs6ZOnWqN0qoOHTrUuW4glm3AKKT1LxzxOOSFMCJYftIA86KLLspR6uNa5XElJluarhTBgoQBn3zyiUGfxnktVB9guktyXHdRmqVcDAXXm4LqgkUMsanAhoPosfhrkUpRuzmlBObMmTNN7969A97j\/sIGqOrbt2\/OXjkltETkd9eqwxpcZpllrNWOvqZJfJFRE+MuuXSGoI7u3btbazJrYNI\/V5eJWuviAhM3if5I6T9LJCtIKYGJmwnVSruZ8Keuv\/76BrVFCx69aZKPB6UEJluf++6770IbA1Xjxo2r03vjbHnp7UI6j2WFKykO4R\/E51ko7Asgynae1Jt05yeuxKR+DAf6pSWjtMvypycvLjDDHO1Jd37SSEw8EqJGucE3YXPF3LKVusoqq0ROZSmBSUdQE\/UKzd+qZsyYUadj73D0amOGQjiv0WPYHtOEWwLpxkTqiWXyf\/nllxyflmYideB2Aux6FygfMCW6yA3Jc4HpWq2uLonfddy4cYblA+sPJRsHPL5BVBLpSxypwhjoD9uGt912W8AWAabr09Pj19K7EDD17pU7Ppen6Mp4KsK2afkomdc4QR0uMLUVrz0AYcaPFjhxrHJhHH0HeyKsEh2tYAkmaBfnOu6GFVZYIY4QzVsGMf7ll1+a3377zeo8uHDiMC5Vo\/++rCNhfv\/99xyHNAESLNNxCYCK747+A\/iGJPbN8TN\/9913NugD9cI9pdCQ\/cvXNlFN+KLxCCUCZikGQ8YathBR0rMK5+dr1Fuq+DoJgJDoHNedxOqgY1JLMW7fRi4HygaYABIfKPquqAVEqBBaxRZonJhMhoZfDZeDJupGemhCguBh4At1g0okRsCDpeE4UDbAdC1xdC9ZHglyQB+N45srFGXDcuHGMQr7AStupDihYQ03ZYtGy2UBTPRWOfNDsAV+RXRO3FbijyNwFXdMIULCYnyxxxx2gI6\/pdWNC\/XBP0\/PgbIAJpYt\/k+CAtil0RJNnrmRRGFDx5had911raKvAyPSs8nXUGoOlAUw2ZkgejnswJYOZeOYR5S0E8c9wScEocQldEpP2XMgzZHfsgCmbPzj\/NVHJ2CVPk6hfXphbJS4SqQroWLsGROIyg4I\/jWcuO5BL9ciz356Fs0a46xwUZxpcGDi9OZAExQGPFmeee6G4rkDA9ju5oAuwzYdFrt2QwFMJCYOdr5wIsH\/b\/l1zPpdc5NAlAO87j6tm43ESSOJijEOidyS4GuJptdB3EnbbXBgYqhgsED53DQSosURjp122invGPFNYlVDcnQCS549fdl2dXd1RGJKVLsHZlII5ZYXfjZ6iUl0D0cxIInF00PlBCFLMRS21OuyHFFg1wAJzFKuHfUcmWULE2JvVo6WisSUr9sDMx0wES6oVPzfqCWm3lMOC\/nXB8kK6ZiwNJ+jHh1Tzp\/oc\/SNDZjpYFO8t7WEdHlan1YbfCmn07JUc5abgBBN+gAWLqCoPV\/0VQ5v6VOb4qgHsOKg15K3sQFzg10ON6u2\/e\/AV30mPet3vp37ulnppw8CCVkxwJRg47BwM9kRQuJJlHYYY7VkZXeHbUztqGevXIDZmJfyLseeZ5q17Zg1tlLV9+5jN1YmMHWYlTZwSFXCOWiWe32MlTA8lmUs9l133TXQQYl4+uGHH+yOD\/qqRCqxT045\/l9ppZXMyy+\/HExEY5OYHpipvqFkLwM0jgrLEVSCKwCXZJZw06FovVRiOGmR9DKSf4i4SPa8AS+Bz7LvzpKOeiCOeg\/MZHMVVrpiJSaDJT6S46j6fDR\/Z3m\/4IILcuI0te9TA1Mc9URou9FEWPaSJVcbUR6YHpixOMCRDIwc9ER2geIGDmuwknmD93FFsXQTLAtY2UeHtKNe+914hquj3HQ4Ydw3c18ry77RL0gSLcDDRu\/HjIXWGIXq66gXiRmjCV8kAQfYncqXeCxONWXhLorT0UJlsnTUF2rLPy8+ByoGmFk76ovPet9CFAcqBpgMMitHvYdMw3OgooCZhaO+4afE9wAOVBQwkzrqPQTKlwMVBcykjvrynRbfs4oCJtOZxFHvTj\/AZs+dkLg4Se2zgk8xztJn1bc49RSj\/xUHTGFkEkc9mTTIOKeTu3JuiH16AouLRVmdpeckadRtFWSDi8ognHZ8JJ7lEoC4qXXitFexwIwzeMqQHobII8nqS5gcKWsk6YKbIjFuvXHKZXWWPioJK\/0o5s1mxCKQ2It4BA\/MOLMes4zOlkzEEomgYPZVV10V3HEUJ0A5ZnNBsazO0sutD2y75gsLXG211TJVTVB5uMSLZGekORRp7YGZFAUR5eVCJTfLHXvt++yzj2W6e3NwFs1ndZae4yQHHnigvZ\/JTTudRT\/D6nAvApMyHpgZcVyfwAxb7rgqj7SF+mqZjJq2WX6zOEtPxhFCBt0rYrLqZ1g9SExSL6IjQ1wRyPl\/D8yMuK6vpw674ZclnGvwipHZI6uz9HIdCYYaHxp5P\/FM8DEBFH2\/Z0ZsW6ga0ZU9MDPisGT5yAc8sTZpDp0wbsa5Qt3L8ix9oev\/3Ds1C\/WtPs89MOvDtYh3OC1Jgtaw9N68xtEO9ExIX52dthv1DdELa1fy45MslptxucgB9xfGm1za4F72kLb\/7vsemBlzVK5ZkfTUbvVcfHDooYfaP3\/wwQd50xcm7VaWIXoceebYCEkjsL41oYagjpBn1D0ZkLTPUeU9MLPk5r+3c+CczreUyx1Gbp70tN0oVYjejBkz7L3mEFmVi7Wb5YGZFhHO+\/riqbAsIHJbR9LscXG6mUWIHtYxmUpI2xgGOrJhYBRlrSP7pTzODKcow8RuvfXWdil076WkWrmhgWujjznmmBQtLfxqFiF6ItGR+PgzXeOMBBIce\/ZLeaZTV5rKZBlicjkuLDdO6MxxbLdhIGVJSUP0cG1xYxiE+sHxY33Xt5tblNWAFOGoDcX4sDQv\/FKeJTL+rYvJxcCRCwIwIggAkbty4qbYTtq1pCF6Ou33rFmzzJprrmmblB0kfibNIkkfvvrqq8DY4YPC8CmWfkm7HphJZz9mee7FQQrpW9OQoBgOaU76FWo+SYiezqysgQnAx48fn3O7sLSLK2nkyJGZXUuTbzwCTDcxRaHxRz1f5KOLNHO4eYwlkDPopDHMyqFeaIKShOjlq4s6cGlxn2SLFi3s+aes7kkq1P9iPPfALAZXfZ2pOeCBmZqFvoJicMADsxhc9XWm5oAHZmoW+gqKwQEPzGJw1deZmgMemKlZ6CsoBgc8MIvBVV9nag54YKZmoa+gGBwoS2AS4b1gwYLE4yU9NsdxOX673HLLxU76mrihDF9g54bDXVDz5s0zrPm\/qth2hZ9sHITdSFyURlNWWpbAnDBhgk1vnZTY1+bwGAEPYRemJq2vFOWJMpdtz7lz5xalyWHDhtmrTrh6W26OK0pDGVZalsCEeVy\/l5TGjBlj9409MHM5J8AkQGXixIlJ2dog5csSmCT2l+VNc4UoIGInyc0+duzYhRjGUkgkDe+Tatm9ybdBOFygUaQkxyO4g6h\/\/\/5F6aIHZlHY+l+lkpyAa1KmTJlS5NYqp3oPzCLPZRxgciMFpwQ5T92+fXvbI4JyOeXYrl0707VrV0NsI+dhiMSprq62\/ziQhpQmgQDHdpG6nTp1Mt26dbMnD8OI2zVmzpxp70XnTDexkEhqjmLEJc6zk24Fkih5gnsnTZpkEwoQejd\/\/nxDtPqcOXNsuY4dO9prZuQWjkJtaWCiu9NnQuc4g875c\/pLiJzcHKfr+\/jjj8306dPtidF58+aZ1q1bW3707NlzIWON20K4soYEXu7Vi9SJMIHHXbp0CXjEkRYO\/TEW5mby5Mk2EURZLuX5GB0HmFzt5+qYMjGAFdACJJdgGldJS8Cwfu7e+kv6GHS1fAYaWTY4FhwnbC7M+CH8jsmDRowYYWMqXSJelGwY8vFFgVPGD6ABvY47lfd69eplx6\/BCdAGDx4cJBjTbdA+Cce4cU5Izrjn02XJCwV\/hw4davr06WNfk1hOLg\/jVjtACS1SwBQGwoQdd9zRJjFwjQGYxz+eSZIqbmrjDLqQvmKaD4HcQRwKQwrLMVmONYTpwS6ACgFTynMvJhKf6wZFjSFiXY5bxAGmlEEycZ6JQGXGguSEWC2IQ4X0QT3aRf9lVeHv8IzVBkLat2rVyv6cBpjSNwDPHUGLHDDdHD9chkrGMoh0hEgNIX6eOnWqPd6LlEWasMRzvzqSB2Ns9OjROVJGH3VgiWrWrFkUZmxSAtddpCUmbXP+XS\/bJDaora219XJFYaFLukRiUn7AgAFm0KBBQZ8YT+fOne3vOuUiEf2oPIDx7rvvDu53pxxSj0QQ8ACQy3XbaYHJikbKG3ytixww3YnUrikmomXLlsGk6XM2HG0gMhygCnjDsnPoA2KjRo0yPXr0SAXMmpqahax1PiQ+KCjs2LHboAZmGJBF\/UGfRQXhqInkPOJDk6QPul5UDEl0i2rAR5sWmJr\/ixQww46xSpoYmO5m29C5i1imUfy1FEVahhHZ16DevXub4cOHpwImH4KbGEvf4a6X0nwNCTDzHeMV6di9e3fDJoU+j54P+NOmTbP6p\/440gATdUEutaXORQqY6I4kMdAkwAzLxhEGTJZ7pGcciqNnFlrKWUZdr4DOqYSFvfbaa0d2R4AZNn5elJSI0l8NurAseLyjwSt9LARMkcxhxo979+QiBcwwazEpMEW6MDkkdI0irGD00SgqBEyWbdfy1sBMIjHzWcsCTJGYGpj5stzhluO8OiSnNqOAiXHIDciQB2a\/fpYRUQ7mpMDEdSNWMQYRwSIuoWcSnMEpxbDnunw5AjNspXDHSCwC7ipIpKoAM0wyYzDxdw\/MIUNs0tWsgckNEKI3Yo1ilWrSE0CKljBHc7kDk4QJcsVzWKZiHP+sBPiLtStNPBJkM0E31aSNRi8xiwBMHPR8+ezZ40dEZxWXEBOKtYzEQWclmwf\/N7alnP7iUsJNBbkGGG4lgmXcZ1r6y0fJjthzzz1nXXFCHphFACbM1e4agMdWJM5qXDFyDUuYNA0DaDku5fSTbVDC5GQ86Murr766YRtWnOuuzso7xDEIITlJxCB1VCwwJftaVBCHbHvpeExx8YQp\/6Loh+XAjNK1WKpY5pCcmsgVhLRhjz0OsVM0cOBAW1TiMZl4crTLR5DW+IkaP224xo\/0G6Dh+po9e\/ZCQ2EnitWhSZMmOc\/IOod01GCEt2TTQwKTSFZLTMIb8SW7c9qorPI4E13KMkhJnMts0zVt2tTukrC8k6+yUoi4AAI5sM6JgsffuM4660SqKOigZE3mA8MAJF1N0qReHpiVgqAKG4cHZoVNaKUMxwOzUmaywsbhgVlhE1opw\/HArJSZrLBx\/D8FkingD5TvJgAAAABJRU5ErkJggg==","height":0,"width":0}}
%---
%[output:43ce02de]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAFVtJREFUeF7tnQn0VdMXx0\/IsBR\/KVNKGiRDQsakJFYhUxkTEiUyrgZUKooiQ4YyJEoZC5mHzEOGVcgYSSvCSlJkmfmvz1n\/ff\/7nd+99737e\/e9br\/f2WtZ+r1777nn7PO9++y9z9771Pj333\/\/NZ48BzLGgRoemBmbEd8dywEPTA+ETHLAAzOT0+I75YHpMZBJDnhgZnJafKc8MD0GMskBD8xMTovvVOaB+cknn5hPP\/3ULF682CxdutRsscUWplGjRmaPPfaw\/846ffjhh+bXX3+13axVq5Zp0aJFJrr89ddfmz\/\/\/DNRX9Zdd11Tv359U44xZRaYX331lRkzZox58sknI5l3+umnm7PPPttsvPHGiRhczpsPO+ww8\/HHH9tX7r333uaee+4p5+tD38WeSpMmTRL3Y8MNNzQffPCBKceYMgnMH3\/80Rx66KHmu+++y8s8Jnvy5MmmZs2aee9dHTeUYxKTjuuff\/4xTZs2TfqYqfbAvOiii8wDDzyQwziW7gYNGpj333\/ffPHFFznXzjnnHHPBBRckZnQ5HtDAPOCAA8wdd9xRjtfGviNNYJZqTJmTmDBtl112Mb\/88otlbsuWLc3dd99tateuHTD7tddeMyeffHLwN8vSc889FzkZ6Hhrr722QUdKSuhhNWrUMOuss07SR+39f\/31l5FwhLXWWsv2I4q4F0ryrlWrVllJRh+T0Pfff1\/h9r322iv4bdNNNw1Vo+rVq5doTNLg33\/\/HTn2sGuZA+Y333xj9ttvv4BBAwcONGeeeWYFJvbr1y+HcUhSDd5ly5aZ66+\/3syePdt8+eWX9vndd9\/d7Lrrrra9OnXqBG2iOpx\/\/vkBgIYOHWrQcWfOnGkee+wxc91115lHH300MBbWX399c+utt+aAASPtyiuvDNpEFTnuuOPMpZdeahYtWmR\/33777c0ll1ySMxbefeONN5q5c+eaefPm2WsYdfvuu6\/p1atXqLHEu3jmvffes+oOwGRsPHPaaaclArbuzM477xwIBPrwxhtvhGI9akwIjDvvvDN4ZuzYseahhx6yQuPtt9+2AqdDhw4G2wAhcdttt5mXXnrJvPPOO4YP4aCDDjKslhtttFH29sp\/\/\/33nMnYdtttze23324aN26cw6SVK1ean3\/+2f6GtMBaFIIJGEU\/\/PBDKGO33nprM23aNKsaQICwXbt2wb19+vSxwBMaN26ceeSRR8yLL74Y\/PbEE0\/k9JN7+E\/owQcftGCJ0zHfffdd07t378h+0tbNN99sOnfuHLSLPj1ixIjQcfFjx44dbT822GCDyHuiLhQKzKgx3X\/\/\/ebiiy8Omkf\/f\/PNNyu8rkePHoZ5dtU1bmS+H3\/88ewBk87pgcuodthhB7P\/\/vtbN9Fuu+0WaYmjArRv3z52smmTL5SvFWnjAtPlpADuvPPOCy7xZQMqId1npA3Sg6U7ahKZGPSzQgw8JBdt4qY5\/PDD8wIOcCKNklLawEz6frn\/iiuuyCYwZ82alTPpYQMEqCyX3bp1M+g9WrppydWzZ09zxhlnWL3opptuyvlKua9Lly6hwASwLI3bbLONBQNfMhMntOeee5r77rvP\/om+pvWzc88916oG7kem3UWTJk0yI0eODNrjoxs8eLBdSlmmtXS+5pprzFFHHWVVA5Y9IVQHeIAxOHz4cGsYCr366qs5q0ghIEkbmNgH9BHVh7HqMdEfVoPWrVubGTNmmKuuuiroImPKnI4pvZs+fbpdssQIimMseo0sxcccc4yZM2eOvR1w8W8xetDnWF6F2rZta11NrsTkOd7fvHnznNf279\/f6kxC6HjoQ\/zGNSE+LFE9oiTmiSeemLPMoX7UrVs3FOjcC2h33HHH4B2dOnUy48ePzwHiKaecEvw9YMAA07dv30LwGNyTNjCR2khviCWdcQgde+yxZvTo0fZPjJ9mzZrlfKSZBSa9xOJkSXzllVesAh2lMwKkp59+2koIzVzaQEpp0jqP+OVcYB555JHm2muvrTCprjdAGM8Sj5EEISXQR4WigIlKIuNxnwlD02effWYAoxCqiJ5MJldLU1YCvXIUgtC0gfnMM88EfXR5PGzYMKM\/JFYMdqNkzjINTJeZS5Yssdbrs88+azA+NDHQo48+2lp+SWjhwoUVJGaUtEEd2GeffQJA4bIaMmSItfRFsrOkaldWGDBdA68QELEMYqUXSpXRM9MG5vPPP29VIOjbb781bdq0CbrP0q4laOaBiSsEySSEC4G9cZfY2gMUQuiaKM3bbbdd8BtMATRxhEvD\/ZrRd2gvjHjHxIkT7SUMEqQSup\/QW2+9laPzhgETgOt+FuKkRiVBTRFCx8W7EEXs7IS52eJ4kRVg4i7MnMRE1zr++OMD\/iEl0K9ccv2dsvwCZNkZOuSQQ6zBk4+SAJO94iOOOCJo8sADDzRIBigMYFFLuZYQrs\/wp59+stJRHO6MCVBqA+vyyy833bt3zze0RNc9MGPYxaS0atUquAM9EKmEY1YI3RMnr9blsP6QXK7jHcNE2kMVYILF\/4nxgwGRBJj0ATCK014PRax8\/VsUMN1+otPycUH4WHHyC1122WXmpJNOytGfkZZsAGyyySb2thdeeMFodxZbtDjbk5AHZh5usduDVawJZZ8lfcWKFRX2ygEvE4PbKMzXB5DWW2+9CltsAuakwJwwYYK5+uqrK4wCaUpfCgEmzvWuXbvm3MsStnz58iAaiYu0h\/EHAKdMmWLdQkJcQ5qyerDSaMIY1OpCIQDNCjARGJlbymEge9tINgkXy8fUqVOnWp+jEH5AthHjiGX+hhtusE7wpMAkNhQnviYML\/RVl+J2frQ1H9VXvfNDHAGSM2w3RT\/vGmD5+CfXPTAL4BSWK1KT\/e4oNxHWLI5ssfx0s\/gSWQLFBaGvYRGecMIJwV53UmDSlvaX8jfSTO\/xy\/twjIvjW\/ymcg2g4XLSzmW5xgrBNdd4++OPP2xQy6hRoypwUYwxXFGVIe3CitsrjxoT88VqJxRnlctqJfdqnTuzElMzlegewIW7ge07lmT0q4YNGwb6VdQkYDwg3XAJ0Q6WKupA1mI3WSEw2OgnuyTsauGTjYsY4hmCQxYsWGAj41m2t9pqq8RRRpUBcDmeyeRSXo6B+3dkmwMemNmen2rbOw\/Majv12R64B2a256fa9s4Ds9pOfbYH7oFpjGF\/21P6HNBbqElbr\/bAdFMikjLQ3x\/OgWJz6D0wx42zElMKERCKtaJ2U9O8Y7oBEmkAeOagzubee+\/NCeZIo91i23BTT\/hb87Qy7XtgemBWBjexz3hgxrCHXG5SeNlJ0Wm97iOylLNvzX9eYhaHUyQl271+KXf4CCDJASKIQ6LKyecmCoeKHW4xAfm6ASXKugdm8cCUpb2YOk1VbimnEJfOCScYQoJASIAieEDvQbvLjgdmccDkab+UOzzUCVsUPCCNloANUlkl8clNm1jTgIlkdxPsiodSOi2Ie8gD0+Gn5OOQdUjkOrGWQnLN1X3WNGCmA6H0W9F89cB0+HvqqafaaG+3Sga36dRbyQcPW3ayvpS36TPG1G3cMn1kFdHi\/FnTzH9+XhC43DwwHWYSxU7MptQN0pd1sQNdkGBNk5gemEV8QavjUQJnpVKFBp70RVd7oPiTRHmLu0j0NtIWsiaRZAzLFs7LZN\/oF6R56N1F\/5s1IsBxCUFubrdMrJRtoXgqqbZ6KV8dH1NVfieGkM7aTDrWKuMu0nk7Uh1NM4PUCqlFFLbUJ2Wcv7+0HKgywMSZLtXYwlJX2QWiegUUttSXls2+9aQcqDLAZOCyVFN9g\/RcTWQqkt0HheV\/J2Wcv7+0HKhSwJQ87bDSMLIjRJroXXfdVVqu+taL5kCVAqauiKYNHKpzEFjAcq9LsRTNPd9AyThQpYBJHjkFEOTQKnRKDqeSEy2iqmWUjLu+4UpzoEoBEy5QqeLCCy+sUKeI5Z16Q3FF8wE2RhJ1giisUC4qNESvXP1J+p5S9L\/KAVOYSkU3jBzKsFDeOg6QVJijzjmlV4RwwLP8SwW2pJNVyP1JQ\/Si2iRAJa7OE9XjkhbYKqT\/cg+VjKm0F1WJOUlbcm+VBWahzKBGEhWApUw0YXK\/\/fZbEMsphfkLbS\/JfUlD9KLado+ace\/TpRiT9K+Qe9lRo0AsdYo8MAvhWIH36MrEFLGiZCHMvuWWW4I67KXwe1YmRC9sSHJiBoXForwNm222WaqqCSoPR9F8\/vnntuS4SGsPzAJBV8ht6J4cO82hU4MGDQoeQQXgGBWYThFUot\/TpMqE6IW9X+pscgQJ5RfLQe7pH\/JOD8yUuK8DO8KWO0ogUkOT6muc1pUmVSZEL+z9HCWIJ0JyltLsY1RbSExONZMzMjmdgrBCD8yUuE95QxzuEMuSewCpHIQlx66k9FrbTGVC9MLeL0VqMdT40JD+eCb4mABKWM3ONMdBW6Ire2CmxFkJHo4CnlibvA6dMMmpuHFdrGyIXlibuMZ0LXr3HioQU8C2lOSBmTJ3OXKP03AxHOTkCf0KXc\/dPd23mK5UNkQv7J1IKU7tpQIwByYQyIL7C+NNDsUCOPoolmL6HvasB2bKHJWj9qhQTEqGS\/poFyr36hyiYrqSZogekVRkgRKLivWtiUNYUUdIX5bdsGL6HfWsB2bKXJXsyailnBPY8NHh29TH4RXbjXKF6HGSB2eDQxzsVardLA\/MYhHhPM9k4WaBwoKLOSedPHR2gUjHSJPSCNHDOiYAGkkeBjqpipG2juzywQMzTWQYY08ek7Mhw04ak6NQOByeo6XTpDRC9ESiI\/HxZ7rGGXGpRFP5pTzNmStTW\/K1M7lEIWFEQKRfiMNdHwuSVreShujh2nr44Yft69kb5zhqfU66m7LMakDlEdSGUnxYmg9eYqaFCtUOk8vZlXIEH0YEASByyFPcgafFdCdpiJ6uJvL666+bLbfc0r5eH7rKycOcC7R06dLA2MHjgOFTKv2SPnhgFoOEmGc58g4pJIejcisSFMOhmEy\/fN1NEqKnCzZoYAJwTk8LO5scV9KIESNiq93l62Mh1wWYaca7VvvoIs14DrliCaxTp47ZaaedUnOo55vcJCF6UW3RBi4tCj5wEBXGVVz5xXx9Wt3XPTBX9wz494dywAPTAyOTHPDAzOS0+E55YHoMZJIDHpiZnBbfKQ9Mj4FMcsADM5PT4jvlgekxkEkOZBKYRHivWrUqMcOoukE6Lum3tWrVis0lT9x4iR5g54bkLqhevXoleQvbrvCTjQN4tCZQJoE5YcIEWzUjKbGvTfIYAQ9hddiTtleO+4kyl23PhQsXluSVQ4YMsfXRO3XqZMaPH1+Sd6TdaCaBCfPGjh2beKzETrJv7IGZyzoBJgEq+gykxAwu4wOZBOby5cuD5U3zgigg0ggo+TJ69OgKbGIpJJKG5ym1zH1ZJ6Qk6REcitW3b9+SdNcDsyRs\/X+jUpygbdu2ZvLkySV+W9Vp3gOzxHNZCDBJgSBLkHzqFi1a2B4RlEuWY5MmTUzHjh3tSWnkwxCJ06FDB\/sfCWkYIRQQIL8HqduqVSvTuXPnoIS2OzyKdr388ss2S5GcbmIhkdRyIkYh7CCfnXIrkETJE9w7ceJEW1CA0LslS5YYotU5nwjigC140axZs0JeYTQw0d3pM6Fz5KCTf05\/CZHTRxlKw4sXLzYzZswwZIwuWrTINGrUyPKje\/fuFYy1p556ysyfP98W8HIrOtMewgQet2nTJuARKS0k\/TEW5oZzQEkMzORSHsXtQoBJAQNXx5SJAayAFiC5BNOGDx8eBAzr6+5hApSPQVeLMtCoskFacCF56GHGD+F3TB40bNgwG1PpEvGiVMOQjy8OoTJ+AA3oddypPNejRw87fg1OgDZw4MCgwJh+B++n4NjBBx8c\/Cw57lG6LHWhCMgePHiw6dWrl31OYjm7dOliVq5cGWSrVitgCgdhQvv27W0RA9cYgHn8xzUpUkUBWHLQhSZNmmRGjhxp\/+RD6Nq1q00KQwpLmixpDWF6sAugfMCU+zkXE4k\/d+7cQI0hYl3SLQoBptyDZCKfiUBlxoLkhFgtiEOFdKIe70X\/ZVXhd3jGagMh7Rs2bGj\/XQwwpW8AnjOCqh0w3Ro\/FMuiYhlEOUKkhhD\/njJlio1mR8oiTVji27VrZ6UIxtioUaNypIxOdWCJqlu3bhxmbFEC112kJSbvJv9dL9sUNpg6dapt96OPPsrrrxWJyf1nnXWW6d+\/f9AnxtO6dWv7ty65SEQ\/Kg9gnDlzpi1mK4TUo+AYPADkVMlLA5isaJS8wdda7YDpTqR2TTER9evXDyZA59mQ2kBkOEAV8IZV59AJYkhVzqaMo3zAHDBgQAVrnQ9Jqs+FpR2779PADAOyqD\/os6ggpJpIzSM+ND5Al1AxpNAtqgEfbbESU\/O\/WgEzLI1VysTAeLfahq5dxDKN4q+lKNIyjKi+BvXs2dMMHTq0KGDyIbiFsfTRMHopjXqRADMqjVekY7du3QybFDofPQr406dPt\/onJPcUA0zUBamVT5vVCpjojhQx0CTADKvGEQZMlnukZyFUiJ6ZT2KyjMrBWvJOXVMJC7tBgwax3RFgho2fB6UkovRXgy6sCh7PaPBKH\/MBUyRzmPHjnj1ZrYAZZi0mBaZIFyaHgq5xhBWMPlrMUs6y7VreGphJJGaUtSzAFImpgRlV5Q63HPnqkGRtxgFTH5nogdm7t2VcnIM5KTBx3YhzH4OIYBGX0DMJziBLMey6vj+fxFwdwAxbKdwxEouAuwoSqSrADJPMGEz8DnlglgCYnAAheiPWKFapJj0BYUcHuhOcRWBSMEGOeA6rVIzjn5UAf7F2pYlHgmom6J2atNHogVkCYOKg58tnzx4\/IjqruISYUKxlJA46K9U8+P+atpTTX1xKuKkg1wDDrUSwjHtNf2TyUbIjNnv2bOuKE\/LALAEwYa521wA8tiJxVuOKwbcHhUnTMIBmUWLST7ZBCZOT8aAvb7755vbsJHGuuzorzxDHIITkpBCDtFFlgSnV1+KCOGTbS8djiosnTPkXRT+sBmacrsVSxTKH5NRErSCkDXvshRA7Rf369bO3SjwmE0+NdvkIijV+4sbPO1zjR\/oN0HB9zZkzp8JQ2IlidXDr1lN1DumowQhvqaaHBKaQrJaYhDfiS3bndI2yyguZ6HLeg5TEucw2Xc2aNe0uCct7WpWHyzmWqHcRF0AgB9Y5UfD4G5s2bRqroqCDUjWZDwwDkHI1SYt6eWBmYfZ9HypwwAPTgyKTHPDAzOS0+E55YHoMZJIDHpiZnBbfqf8CI9z3bfhZ1NwAAAAASUVORK5CYII=","height":0,"width":0}}
%---
%[output:781c8d78]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAF\/5JREFUeF7tnQm0VtP7x\/eVDH8ZIpIGjRLJlGGVlEpLVIaikiINlAyRaFJUZMgQlURUSlIyJWQoZIgyRqZKIyFT\/kq4\/\/XZv\/9zfvvd95zznnPe+7731t3PWpbue\/bZw7O\/55n23s\/Oy8\/Pz1eOHAeKGQfyHDCL2Yy47mgOOGA6IBRLDjhgFstpcZ1ywHQYKJYccMAsltPiOuWA6TBQLDnggFksp8V1KjEwf\/jhB7Vu3Tq1adMmVaFCBVWnTp1Y3Pznn3\/U6tWr1TfffKPWr1+vqlevrg455BB1wAEHxKrHFd4+OfD555+r5cuXawxs3LhRHXjggapq1arquOOO0\/+ODczNmzerQYMGqWeffdbjyIknnqimT58emUPPP\/+8uu6669Qff\/xR4J399ttPdejQQV111VWqVKlSkevMRsHvvvtO\/fvvv7rqsmXLqt133z0bzZSoOtesWaNuvfVWBQaCqHv37vGBed9996k777wzpc6owNy6dau65pprQjslFTdr1ky3s+eeexbJxK1du1adfPLJXtvjxo1Tp512WpH0ZUdp9Oeff1ZnnHGG4oNPR7El5oUXXqjeeOMNr14AdMwxx6hevXqla0sxuXfccUeBcohuv84eeuih6plnnlE777xz2roLu8CqVatU06ZNHTALkbHXX3+9mjlzZkqNqO7KlSurjz76SJt1Qh4wf\/vtN7Vly5a0Nt6pp57qVRBVUtIYtkSTJk1SOtWlSxfVt29ftffeeytsTsT7wIEDU1Q8Yv\/cc88tRPYo9ddffynGi3oOMheSABNbadddd9XjSULwIKg\/Yc\/82mJ8e+21V5JuqD\/\/\/NPXbMGswaeg3l122SVW3bx75JFHenNbr149NXXq1BSN+OabbyowAeX17Nkz\/5NPPvEk1h577KGOOOIIXcBUXdiUixYtUnPnzvUqR9Kh7sqXL68BFkZXXnllil163nnnqVGjRhV4Zdq0aWrIkCHe740aNVKTJ09WAOWGG27wfu\/atas65ZRTvL+xXbB9hS6\/\/HJtSAvB7AcffFA98cQTCjUtVK1aNQ38jh07eoC6++671bJly9Qrr7zileMjrFKlimrfvr06+uijvd9ffvllNWnSJAUPxWbGTkaLXH311ap27dopY4T5Dz\/8sPcbGuTJJ59U8+fPV4sXL9aTh6TGzmLyH3jgAbVgwQL13nvvKepFMCB5\/EA3b9489dhjj6kPPvhA94XyJ5xwglafLVu2TOnHlClTFH2H6tatq+DnjBkztIbC5Hr99df1MwDFnE+YMEF99tlnXh3U3apVK40TeJiOcHBPOukkr1j\/\/v3VpZdeWuC1Pn36aAGVV61atcDdRahtJhtV6ieGpdYaNWpoxoZRgwYNUtQ1k+43IACE4wNzILz02267TeHFwWAhfmvXrp33N5PRtm1b7+\/7779ftWjRQv+N9Dj77LPVypUrA7t42GGH6YkpU6aMsvtqvnTPPfeo1q1bq7\/\/\/lsb8Q899FDouO1+Pv7442rAgAEpgH\/nnXcK1NG5c2fNA1v1URC+Pffcc55U27Ztm3Ymn3rqqcC+8JEw6ULmfPLRUceSJUv040qVKnnA5L2wehFks2fP1hGVMGIsZuSGMUycOFFHY0z69ddf1e+\/\/x4OTF4YPny46tSpk7rpppu0tLE9aTrGpMLwIAJshx9+uPcYMR42WL96MgHmjTfeqKWuEIxHystEyO9IfSQtdnMQiJG6SDQbYGGTgsSRSYnzXlidN998s45eQEi\/YcOGhQKDh4MHD1YXX3yxLhcmaASYSODLLrvMq1e0qf0hHX\/88fqjTkdIWFPqUh7soHXRbmgZMYO0xETN9uzZU6sOJJkpYukMKlxUh1n56aefrvDS09EXX3yRokqQfPfee2+611KeZwJMBv3TTz\/p+kwmol6YXFHtqNE5c+bocmE2Jh8n9rLUSXkkNIDGfkX9IlmFYPwjjzyi\/7SByUd6yy23qN12202NGDFCvfbaaynjHjt2rKpfv76WSkhfIeEhni71i8DAvKI+xsm88bHJMwC3cOFClZeX5wtMnE3MFJwRMNCvXz9tZghh3hAyI2QIsM2Qz8cff6y1TRhhOoCzMAKojC2vY8eO+XYMEtDcdddd3vswunnz5vrvJMCE2d26dfPqw54x7cgoCM0EmLa64ENkMpHieIISEYCxYpeGAdMej0hacxwAHptRCOmMs2UD0+Qtkuj888\/33jHtcJyfWrVqFQC76TDwEMkpDgR\/Y8MSDRFC6x177LEFgHnBBRfod3faaSevLCASO5QfMZ0wY4466iitbhE4Qg0bNozkEM2aNUuhwfxi2Cb\/8qZNm5ZvMoOHtoTj6xCkJwHmp59+qtq0aeO1e9ZZZxWIhaYDZybAxGHBefAjDHK+UP4zv\/gwYOLsIN2EXnjhhQI2lu3EIfGQRjYwX3zxRQ9wOHCNGzf26h06dKjCzhfiYxLpLhERux2k3j777OO9Q3nT2aPfzLetygGg\/QEj9U3Jb\/IPyYbGPPPMM1XFihXTTV\/KcyQuHxQOFr6JqXmkYN78+fPzRRrKjz\/++KNWBUJ4rCNHjtR\/JgEmBq3pyfLF8uUGEY6F18G8PB1CyQSYfBhIaT8GSDuoQKQXHioUBkwAQ6hDSKShOZ6XXnopxSQSp8kGpukEbtiwQSF5hAREYcDEAcNjjko4Xj169CgAzC+\/\/LJAvBipiBOGmg6j0aNHa+cyKbG0vXTpUgXPsMehvNmzZ+efc845KXVi+GMvCV1xxRXaU04KTN4jBGWKb76Ygw46qMBYWIMnxCEkdp8NTDu++eqrr+oQi5DplfMbXykmC+EQ2wA3wUloBls7DJi2qYPdhl1mEiqLkIgQDgrSubCASV3UOX78eHX77bd77aBqS5cuHYgRQoAIIlNiEvoJ0igSLmI85sKK3QCSj+hMEDF\/zLkQYS\/Wxm1ijnDS8gYMGJCPh2cSBi+GrxBxPVHFSSQm9Uh8Suo0pbDZNm2NGTPG+0nstxUrVnh2Lg+xE\/lPCGlnxkUFmAASpggRVyR08f7772tHA4abJB50GDAx+s3Qi8kfqctWlUwqKq+wgYkZ0bt3b28IfmaFH1jSAZMzih9++KEOi0EIEUwEwnI4VfDN1EC2bWu3ib0tUQSe4XOYcWcpL\/FO7ZWLQcxDHAGMbtMuQRoJupMCEyeDr8Qk2mHtfP\/999fSlK8Fj9IkscH8JCkhClZaUIF8OLaXTBzzrbfeUhj2QjDDdMRs6UeAGoltA9NUV6geAv9CeLvEGzEHIFS7uVrFcyQxjkVhA9P2B7D7+LDFicH5MUNlmCA4L+mAaYf40KDEHYVsR83PATTnkVgy7QoR7cG8MZd9ESIsohBK9ALsNEzIAgaaKhcPz4yRJQUmHbLjiX5fsvmbaULwux34BgioUD81JBKTcAo2rUnYm6zi\/PLLL+rRRx9NATQrODDNBh9qCucDz5SYJPFdcwWHdwghsaxrrhjRLiE1AAMVFjBlRYw6L7nkkpQFDj4EVP27776bEo+FX2KqpAMm9dpxR8aA74HPwBhN2xOhgkMWRpg2tobCjEDoMRcpa+VhKz9E55FKSDShTIDJFwHIzdhY0ED4UACXuXYs9kc6QPPctDH50m1J7FeHvTpiesFSXpwYAI\/EN5npVyeTiVQmdpgtYKJNkDxhIRg+HGxScUKjANNeTQviOx8BkYp0m22QwmiSIBvfrD9wSRKm433aexAzAaY0jI1G3X5eMgxEsuLlyWSaHcaWZKLNScCYR7qaISkTmBjwSEachKA9oKz4oPLNOB4hFABtrgIJMOkTjCZaEbQXlY8Qr9Ych+0UhXnltE2oS8j8UEyJyXMiKcSeMUVsQsphiphhnSjApB4cFuYqaCUMhxN7O+qGEex7eIBdHhQlwYHL27ZtWz47fwgXoIZq1qyp12IBSLYJe\/brr79W3377rd5wQBzt4IMP1nZjGGGY8w5SC7VlSvSw91gPxiaDyTBo33331bvvaTeoTQLb33\/\/veYN3m65cuUKfKwAFMmJg0YZ1o0xFcK842zxFjULT4mJ4rAwn4wzE4Lf2NzwjhAS8V74Bk6S7qRiLvBj8A\/AAfxnLuEbCxGx92NmMkD3ruNAVA44YEbllCuXUw44YOaU3a6xqBxwwIzKKVcupxxwwMwpu11jUTnggBmVU\/9fjqC1o2gcMPc8RHvjv6UcMGNyjC1jfkchYlazwxePc1DRjxkOmDEhIntX4yR4kCZkb6O5+cRPAoukIb7a8JJbVbnq9dSiCdepH1ekbj8zg+lRpZNfH2KyQO\/nZAxBbdIG40rCI+mLA2bMWckEmH5NpZPAJjB5v\/apndRPKz5Ry+c\/mlKdbD6JOZysFHfALES2srrBsh4bWcKyfwiQ7G13cbpi7xRHIpqAO\/TU\/+yGAnwmMMvVqKdqN++kvnh5mveMckjT4gJMJCVbGp0qj4MIn7IAkl1CrDPLOjrHE9iix\/q5vTFBJGaYKkvXJYBpgo9\/m4A789Z5uoqnr2sZCkyzXHEBJv0uDK1S4lW5fTSBNXvZXMBGFjZSmJswCoPptu1oS8IkwORDMbedRbU5031ESZ47VZ6Ea8Y7bFyRbCOcn2aHEhsv2G0uh8DshAVRJabp1ODF23+HqegkwDRZkYmZkSFL9euF8fGWaInJkRISGHC2mz2i5pY3eWbbSlFtTD+nJqrtmASYJtBrHvA\/nsdM\/3MpPZ2NWQif9kUXXaSPkJrHk6Va87w2Z19kv2FUaUC5rzf+r7YRCfPgoGQKuKgqn\/ZwqCBAmknYJgmbnSpPwjXjHTmqYZ55ksfmkQzzzLUNTDsOKdLJD5hIzP2qH6FBmlSVS\/\/w2KMC3YybyvuZSFKAF\/a+A2YGwDQPW\/kd9jczX3BORzJ0iIoWRyPdKpBILjs4bv5ulwl6xu9mPWHlYI3dZhi70p3XMd9lzGHl5XkmkrrE2pjmqU2knt8ueIk3ktFNUh6KNMjgmygRr6I5\/CR11MGXWGCa6Vg44itHb4VxbP2X3JZ+qj4qg125ZBwoscAkmE52EMgvSYCZJsdP1Sdjt3srKgdKLDBhkKhq89y3MI6c4JKPR86aR2WqK5c5B0o0MCX9tl+eT1kRMnNbZs5uV0NUDpRoYJp5Lk0Hh+xwbERA3XOlC2kTHeWWAyUamCSMIoudZMYlMQDnpCWfPFnw\/K5\/ye0UlczWSjQwmXJSU5Maxr6pC\/VO5o7t+TY0kh8Qj8004UFRfBolHpjCdDJM4OSQToYkXIUFSDaDhOXqISNwuhsfkgBDog5kVGFcflRUfYsyHgfMKFzKoIy9Kdiuis0jZnq+DJpKeVXyhYYBs6j6FmWMDphRuJSwjOT0JMeP3FphV8U9RulyNUVtnnSMJKll256kQgwCZq77FnUMUs4BMy7HYpSXNH5Jro+J0YxXFLuYq5ZNCgJmrvsWdzwOmHE5FqM8+d7x+nO1cZcVLNl9T2Y2Ui8GATPXfYvBNl3UATMux2KUlzTaxETxjpFmRAG4ioTYqHm3YoxqIxWVyxKCgFmUfYsyAAfMKFxKWCbdPYwkiuUqxGxQOmAWZd+ijNcBMwqXEpZBKpKnnJ1LJL1n0whJ8sl2zG3GUDauvabedMAsyr5FYacDZhQuJSwjNh9HgfG+TZLr8DgqbAf3EzaX8lo6YBZl36KMzwEzCpeyUMa8MIsQT2GFjKSr6YAZNqRs9y0KOx0wo3ApQRnW4dlszMlLP9DJaUKq9rsuL0GTkSVmUfctytgcMKNwKUEZuUsSr5iYoZ3Rgz2g7FwqClVe1H2Lwk4HzChcSlDGvMnNPh6M6ibLB+vZculogiZCXwlT5UXdtyhjdcCMwqWEZSRpAq9zWSuXP23cuNFzdliqxPEpbPsyildelH2Lwk4HzChcSlgGW27s2LG+d34TruGirbDMcgmb1a+JxAy6Wbco+xZlXA6YUbiUYRm21HEpFBctcSkUu3qyBci4XS2ufXPAjDuTrnxOOOCAmRM2u0bicsABMy7HXPmccMABMydsdo3E5YADZlyOufI54YADZk7Y7BqJywEHzLgcc+VzwgEHzJyw2TUSlwPbFTBJtrp58+a4Y9TZNbZu3aq2bNmiypQpU2hnxmN3JMYLrMyQ1Rjyy90Zo6rAoqyZw08SIsCj4kTbFTDHjx+vs2PEJW6eGDNmjFq7dq1vvvW49eWiPDvcJfHpihUrstLk4MGDdX52bu4YN25cVtpIWul2BUyYlySXEHf1sGbtgJkKEwEmO+wnTJiQFENZeW+7AuamTZs89WZyo0OHDvrYKqldRo0aVYBRqEJ28fA+KZgpV9wJKcnxBy6\/6tWrV1a664CZFbb+t1I56N+oUSM1efLkLLe241TvgJnluYwCTG6e4IQiZ7nr1Kmje0R+TDIH16hRQzVv3lynVmG7GLuAmjZtqv+rVKmSltIkCCAFC1KXXEMtW7b0UmXbwyOJ1cKFC\/UJSc6Tsw8TSS03X0Rhx1dffaUWLFigi\/bo0UP\/n43FXJjF\/Zfdu3dX69atU+xG5x4iiIu04EWtWrWiNKFMYGK70+dFixbp8++cfae\/bM8zryyUilevXq1mz56tyCW6atUqVbVqVc2PTp06FXDW5s2bp0jAQPIw+mcTwgQeN2zY0OPRdqXKg7gdBZhkBrZtTJkYwApoAZIf04YNG6ZWrlxZ4Jl9aQCZ4rDVghw0LrwaOHBggWMWfuPyc342bNigJw8aOnSo3s9pE0c5Zs6c6X18YQiV8QNoQM9NHjZ17txZMX4TnACtf\/\/+3qWw5ju0P3r0aNWiRQvvZznDHmTLNmvWTPN30KBBqlu3bvo9B8zp0z0Gtm7dWjVp0kQfDrOdAZjHfzyTBFkkep0xY4b3\/qRJk9SIESP033wIbdu21QfSkMJyRJcjFX52sA2IdMCU8tx\/icRfunSpZ8awW37OnDlppaYAUwqiNVq1aqWzhTAWyYOEtqhbt64uxrEQcjFBtIv9i1bhd3iGtoGQ9lWqVNH\/dsAMsTHDJCbMs\/MLcSX03LlzNWO7dOmipYYQ\/54yZYrOC4SURZqg4hs3bqylCM7YyJEjU6SMeZRh8eLFqly5cqHASQdM2iaFoam2SapAviJo2bJlaeO1JjB79+6t+vXr5\/WJ8dSvX1\/\/jQSUixLIqYnJAxiffvppVbZsWe8dpF6bNm00DwA5qRAdMJcvV2HOTzpg2hNphqaYiIoVK3oTYN7Oy52T7EoHqAJe7FZ7h7p5AAypKlf\/BaEzHTCvvfbaAt46HxIfFOR3d5HdlglMPyALz7BnMUHWr1\/v5VviQ+MDtAkTY+rUqfpnTAM+WicxE0pMvyO0qGgmA+JYhHkzL05Q+\/bt9TPUNIa\/KUWRln5E5jeoa9euasiQIRlJTD4EOymXeQWMqUqDGhJgBh0hFunYrl07xSKFeRY+CPizZs3S9qf5cThgJgQmtuPEiRNT5k+A6ZctzQ+YqHukZxSKYmemk5ioUblAS9rEQ0aVQnjYlStXDu2OANNv\/LwotxNLf03QETUoVapUgfpN8Eof0wFTJLNzfnr21AwNi+PFBaZIF+rt27dvKCDwgrFHwygdMFHbEvbyA2YciRnkLQswRWKawAzKHkJYjrPyEKGnChUqhKpy82pEB8wsAJPQjQT3cYjYLGITdiabM7A\/\/Z6b5YsjMP00hT1GkjsQroJEqorE9JPMOEz8DjlgZgGY3D4hdiPeKF6pSeYE+F0RaE9wcQQmyRrkOmi\/LMkE\/tEExIvNUJpEJEjHiG1qkuk0OmBmAZgE6PnyWbMnjojNKiEhJhRvGYmDzcp93vx\/e1Pl9JeQEmEqyHbACCuxWcZ+Zn5k8lGyIvb222\/rUJyQA2YWgAlzzXANwGMpkmA1oRhie5CfNPUDaHGUmPSTZVC2ycl4sJfLly+v7xKS4Lpts\/IOoTwhJCeJFqSOHRaYrFZwyVNYHFOWvcwEVxLi8TP+xdD3S7ESZmuhqlBzkqRfmE6eIqQNa+xRiJWiPn366KKyH5OJb9Cggf6tMJyfsPHThu38SL8BGqGvJUuWFBgKK1FoB9tjJ+Md0tEEI7wdPny4lsBcvb3DScwoE53LMkhJgsss05UuXVqvkqDezVhoLvuTjbbYF8BGDrxzdsGzPFmzZs1QEwUbdM2aNVqy4gCSKicoodgOsVaeDca7OouWAw6YRct\/13oABxwwHTSKJQccMIvltLhOOWA6DBRLDvwf4eoJ+3Xm5X4AAAAASUVORK5CYII=","height":0,"width":0}}
%---
%[output:63b8511d]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"500×1 cell array","name":"classes","rows":500,"type":"cell","value":[["'ServiceQueueRenege'"],["'ServiceQueueRenege'"],["'ServiceQueueRenege'"],["'ServiceQueueRenege'"],["'ServiceQueueRenege'"],["'ServiceQueueRenege'"],["'ServiceQueueRenege'"],["'ServiceQueueRenege'"],["'ServiceQueueRenege'"],["'ServiceQueueRenege'"]]}}
%---
%[output:4cc57ed6]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAF75JREFUeF7tnQnUVlMXx0+G8AkhLYpVkooolgxRFE0vMs+EMiVkaEJokCFTlMyiyFg0CpEyT4VMZYiMlWTKPPSt39G+337Oe+\/z3OF5X8\/nPXutd9Fz7xnuPv+zz9777LNPtRUrVqwwnjwHSowD1TwwS2xEfHcsBzwwPRBKkgMemCU5LL5THpgeAyXJAQ\/MkhwW3ykPTI+BkuSAB2ZJDovvVA4w\/\/jjD7N48WLz2WefmZ9++sk0adLEbLLJJnm59NFHH+V9vtpqq5l1113X\/lWrVs1zPCMHli9fbr777jtbyyqrrFJwfMKa+\/PPP80nn3xiPvzwQ\/PFF1+YBg0amEaNGpnatWtn7F3xigfABGBnnHGGeeedd4LazznnHHP66adHtgaQ+aA4tOGGG5qjjz7anHbaaWb11VePU8S\/E8KBq666ytxwww3Bk\/fee88w+ePSI488Yvr162d+\/PHHckUYoyOOOMKcddZZZtVVV41bZYW8FwDzqKOOMi+++GJOI8UEplS8ww47mDFjxpi11lqrQj7o317pFVdcYW666abEwPz1119Nr169DMAsRHvttZe55pprzDrrrFPo1Qp7boGJaN9yyy1zGuncubPZZ599TIcOHYoiMXUlZ599tpXOnpJzIC0wkbJIW5c23nhjs2jRonK\/o8ZNmjQpkTRO\/jXRJSwwly1bZlq0aBG8VUhSyovuUt6uXTtz3XXXBfXwfOHChea+++4z99xzT\/D7pptuap5++unIXqFHrb322ql00t9++81Ur149No9+\/vlnu2wlKfP777\/bAUujM3\/\/\/fdW345Lf\/31l+FPlus0wESfbNOmTU6Txx57rEFArLfeegbBhCQ9\/\/zzc5b4oUOHmkMPPTRuV2O9x7eAN3iQj+fVhg0btgL9cvLkyUHFzZs3N40bNza77babQXJGkQvMvffe21x\/\/fXlXidOZKeddjJff\/118Oztt9\/OWc7fffddM2LECPP666\/bGQwwWfZ33XVX061bt5yZ+9Zbb5lhw4YFdV1++eXmscceM0888UQA+B133NH06NHD7LHHHuX6s3TpUnPttdeaF154wYjxRlvbb7+96d69u9lggw3KlQHwSJ2ZM2eauXPn2uetW7c25557rpUsfA9Eu+5qMG3aNHPvvfea1157zQ48utzOO+9sV6SysrJQ9k6dOtU88MADZs6cObYMbR133HHm1VdfTbyUn3nmmTnje9hhhxl45tLYsWPNhRdeGPxMm6NHj7b\/PumkkwzqANSyZUtz6qmn5hQ\/+eSTzS+\/\/GJ\/Y5U95phjgueAke+5+eabc2wY+LDvvvsaJsnmm29u3weHzz33nKnWsmXLFWGinJe6du2a01H3Q+ICk3KAdt68ebYKQMfgisTh4wcNGhQ5AUQSi14KAGGEUKtWrcyzzz4bWp6JQttCL7\/8sjXA9CTRBZHmDNBmm20W\/IyUA7CuDi7fsuaaawb16cmJZMXQmDBhQuS3ha1OgOaWW24JLcNg6r7HMX6Y3HqMn3zyyQAIuhFWDwwfASBWOhIawnIXOuigg8qpBfq5ixu+MR8PwMP48eOtIc1EZ0JWKysrW\/Hpp5+Ws9J4+fjjj7cKcxTFBebs2bNzloQDDjjAKtcQ0m+\/\/faLbEMeAE4ZLBeY+QrzHW+++aZ9BcnDkhYFSqmHwUcyUhZiSWO2xyENTIy8gQMHFix2wQUX2FUBmjVrlhUIcakQMAFb06ZNg+qaNWuWFyRR7aYFJqsFgkAInm677bblJjkrKiof\/IJvVsfEL8YyJsRDxGshcoEpS5SUQ2J88MEHwXIpv9MwUg46\/PDDzSuvvBI0ddlll9klDh8b\/XjjjTeCZ88884ypW7euXbK1xOSF2267zaoe6LS4pTT4XnrpJbPRRhtZ\/VfrwACAJYrvQLIyU4V4DzWGZR+maaJf9H\/BggXmvPPOy2lLgPnNN9+Y3XffPZjwGBl8G3WxVKHficsGKQ0goQMPPDBQFfg3wgEXDm1hjYsaIf0pBMz58+fnqAvwFpUpKaUFZu\/evc1DDz0UNCcqHHYE0lF7Cfi2GjVq2HeLCsxCH8tsGT58uGnbtq191Z3NnTp1yvHRAUT0KqE+ffpY3cYFpmvlX3311WbkyJFBOXTAbbbZxkptpDdEX\/h\/UcABEnqmkOhX7oxHX+NPiOUdV5uQABPVQk9ud7K7\/sgHH3zQTjqWXaGtt97aTJkyJfj3l19+afU37YMsBMynnnrKnHDCCUEdhdSzqDFMC0wECOMldMghh9gJv91225kffvjBMHGEECwyHpUKTDoAuNDX0C9hKmAUQuJqtxXWopamfBCSzAXmHXfckWPkMEOZqUIPP\/ywwaBjCdGDussuu+SMg9YhRQVAfdCGgtSlC+p6BZiuIYH7pWbNmkExdtf4ExoyZIjZaqutzMEHHxz8Bp\/69u2b00fXkCkETFdV0mpUFAjDfk8LTHeV0nUz8eDX\/vvvbyelpqICE\/1Fz062NZkRd955Z06jspS7s7kQo0TPdIH56KOP5uxAoWijcGtgwljAmYRYPgcMGGDuuuuuoBjGU61atXKqwbKUHTMBZhK9lMpQCVjutTRG6rtWu7saFAKmq6axKiCdowi1RgjhITtAaYGJVOzSpUs5FcRtn+9CjQnaLqaOGeUucp27Yom6RhH6F\/pWFDVs2NBK2zTAxADQ26e4J7ReHdYmy60743F7INk04SISnVZ4cOONN5orr7wyeA1pn28rlpUDUODiEgrT9dki1npZIWBSl7tSoGbUqVOn3Cd\/9dVX1o0lxERmhYA0MF2pi9eCpVnIVRfEXTRu3DiDehZF06dPN1tssYV9XFSJGQVMVw+TjruMuPjii63hUojSABMmt2\/f3hpVUFRf3bZdtaB\/\/\/45qwL+VwwKIakXKa5B5kr1sG9066K\/2hsAcJlMSXRM2nHBfOSRR5pLLrmkXBfw7WIDCGndXU8+\/v\/+++8P3sP3jAvJBSb+a56JFGYyoM7gz8UABKjaSNUTsVKA6TIco0DcKHo2Iy0nTpxo1l9\/ffuNM2bMyFnaYBRulbTAdAcI0MlM\/\/zzz61xxNIDYfwg6d9\/\/33TsWPHnEHkd6xy3Gw9e\/YMwK4B71rDAJZBJyIIQhqL85p\/oy6gX8MPTRhfbHZAuFPYndEUR2IyGQG5JpzsuALxVgB0dubwGmhi00J0fj2peUc8JHheTjzxxBxJKILHNW7Zg7\/11luDJlyBpSdCpQDTNXK0g9b19WF0wATCsdDnNInUSQvMMJ8pzFpjjTXKBTcwSLiyINflUU7UqB+0JD7llFMMy5MQEw9A477S4YLolvhNsUhdqUVZJBQ7T9p1JnXGASbvsoGhJ0K+b+AZEw5nu5A4vuXfjBPqEe4fN1JJL+Va\/5aJi8qG7oujX7u\/mBxikFYKMN0lG2sMyYhijf7B9lXYropmnhbzaYFJffjw9HZm2AC50g03DVJe1ABdhgHSA6OByXfvueeeoSFmeoCZnKLvoq8xmNpizweiuMDEbwgPtU8xql4mKz5THfoWdyOEOjUwWba1pyGqTSbsqFGjgq3nTMB0o5Ki9DbAh46nB\/D2228P\/JlIA5ayML0HaYIBgtQQKgRM9lu1deu6eCg\/ePDg0MHHbYMO5gZosCyxFOMIZ2uVfmExY0nSlkhA1zDAQc9EYK\/cJSQH1qjrKkGaYCDitdDE5MAfq11IcYEp9WA44WkI2\/1ikiFZ+aawAJXnn3\/erh56exNjhW1L+iQT1zV+MLZoMyqoHFUANUsHt5TU0QoG\/+OPP7a7RewAYEWjMKeJ4im0VKGQE3WDSwg9CYu\/fv36sYKYdQQT+8raSofJrh5IXwAb34VeyjfRXliwiO73kiVL7JYte\/EAMklUUqHvB1z0h50y\/MdY3fXq1bNqTSFiJYB3TE7+4gQVYwgxtuje6PGML6cj8I4Q4eRSSQGzEEP+iecYbnoHB6MIw0WMGNedhCTWkTX\/RJ\/\/DW16YBYYRVci8jpLHsswEsBdnmRf\/t8Ajn\/yGzwwY3D\/8ccft479fARYcSMhUT1l54AHZnYe+hoqgAMemBXAVF9ldg54YCbkITqkp3gc0Pvu8Ur87y0PzIQcCzvmnLCKKvE6Ozj6AGLSj\/bATMgxCQqG6UhPnPEuucHEhZqQqHrZFIiqt0n7Y0zjdn8HuSxdMNc8d3M\/64cVom\/UkUVS0Tb9yVIP5anHA7PQyBfxuQBTQAQwdztlaNACYEkKTAprFYHtWQYXIG7Y4O+gjvnTx5paWzTLC8woNSMLUNOwTk\/eNOUp4yXmSs6xM8H2Ibss+TJQyFIO+FiuAOb+Q6cF\/J\/Yr6wcMMMAo8ESFeUN4Gs1aGbrBvCFgKljJqVDWZfUpMASaZ+13SoPTADJ0Qz2s2Uvn2MQRDhxPtzNCxS2lOcDZr6jBXrQAaBIXlmm4wBTxwSIlJXlfv4TY03NHz7IWVL1YTwN3mJKVb+UJ53OIe+7RyD0uW1iFgl\/03v1aYA5dvJTOcs9UlUv018veNMs\/XBuKmCKRBW9U+uhYcCsDKnqgZkRmDpOlLPPxCBy\/EGfziRyhpN92sBAB5RooUJLOYMUBkwtDQFQWmC60joOMF1J3LD2fzIZKnoYxHjiN2\/8pATopZdeas+jc4iOOEUJzKA6eebqSqJj\/r8Ac970u8txxwMzJWAqqxjJBEjuRXS2m0BBnwvn3IqEnBVrKa8siYkkbtz+f+eoMKIqEpiMnV\/KMyJYcvpwnFUnO6BanQCBwGLRzeIA0+2WNmx4ho5ZmcDU7iy3bYCKseUSK0Jag8gDMwMw9UEpDTypUkfncyJQIuhlKZezKeibrgES1i33nbAyhd7Rz8XYKVSG9+K8U4iVbnKIfO\/DE+8uKsTRiOf65GBUDKVISX0MRKRBymarTDGkrXZlJf3wKuvH5IiD5M7kLAtHBDRx3EKOzYYt9UkZ7d9PxoEqC0yc6XKGOywZgc7yFrbUJ2OzfzspB6osMGGULNVucleecYZbcumQX1NyZSZlsH8\/HQeqNDAlc1rYsWPZESLHpZsULB2rfakkHKjSwNTZ5rSBw5FZdnRY7sl8zFlxT5XLgSoNTM6WkwZFsqdx8pEzzpLWJSzXeOUOT9VtrUoDk2EneQFZL9yLmVjeSSMYdVEWoMZAIgFYnCQBWSAWNyQvSRscO+aWCZJmJblZLUkbWd6t8sAU5pEdAiOHdDbsAkUBktxCpHXRyVxxvrP0F3vJTxqSFxcIOkKe3EJhmTDi1lVR73lgJuAsyQ\/IyiHptwmRQ+pIHKebFTdB1aGvJg3Ji9MeqWrIzCy5izww43CtxN8hjIurTyBys5MVja1LMqPJ9TDF8nmmCcmLwz43R6gHZhyulfg7cokWeS+5WEqI5Z+7isjDXqx7MtOE5BViH3v+5HonQ5tkZvPALMS1En+ugzp0JmLptiRcda9ASftZaULy8rXFaUqWcDYKuM9I0nN7YKYdoRIpRyJVnO0Q6a\/d1HuSs1PfxJal62lC8qLaQzcmeSoSnSAUYgQkxbcHZpZRKoGyEjgcBTwMIkmNnTSZqvt5aUPyotgkaoEkldW3THhglgC4snRBEvOTaJTc4S7pVNDss2e5hD5tSF7Y98n5JaKnCFYhEt8DMwsSSqysXKsSddc6Fxlw5yNEpl59fijppxQrJI\/MvxhsuIZ0sLMHZtIRKeH3RfJELeWSQxPfpr5mMM0nFSskT+6rpE86yzE6Jy4uCA8DSR7YftVXYafpdzHLeAd7TG7qu4rCAou5v4Yz6O7lTDGrL\/daMULyRLeM0wd9lUmc9yv6HQ\/MmBxmb7xly5Z2WQy7wU3us8FPyFXTWakYIXlMJtJxu8S3yLEHJhN6Z4sWLexlVKVCHpgJRkK2CFnOiUCS4xgcvRCHO4YRBlJWShqShztL7n3kKu18N1xoq99b5VlHqgTKY0xg4MiFAOQ3IvhDLs9ys3Zk6XLSkDydPYR7GrmqJIo8MLOMTImW5SpBJJK+JQ0Jyv0+WU4Fhn1ukpA8naChEDD1TRxZXVsVNUx+KU\/JWa7xQ4fjEikuh6rImMa4IXkpP6Uki3lgluSw+E55YHoMlCQHPDBLclh8pzwwPQZKkgMemCU5LL5THpgeAyXJAQ\/MkhwW3ykPTI+BkuSAB2aRhoUzQQsXLjTz5s2zRy8INatXr549+FWnTp0itVJ1qvHALMJYjxs3zvTt2zeyJrYwSUVTiokFivD5FVKFB2YGthIMMWjQIHvqUIh986ZNm5rly5fbw19CSFDS0JRSaFm+T9fxpwSI1K1bNwOnkhf1wEzOs6AEt10IKAl14wQioJQLq8h6wW+SxrBVq1b2Fjb3hGWGLlRYUX2GadasWZUe3e6BmXJodaYMssQBuLB8RyRD4NjC3Ll\/3wyhz96kbLpSinlgVgqbi98I9wJxlhyaOHFikDY7rCWCcTnXDXEDW69evXJeI8kVZ4YAA5FEHKsA7MR+Vq9ePeddjnBwJqht27amefPmOc9QH7hQC+IoscRkjhkzxixbtsyUlZVZo2zSpEmGPhFfyuVbnJdHmgtxzGLOnDn2Ui6oS5cuNqsdoX01atSwv9FXrlzh4B39adSokV0tuNUjKiFZklHwEjMJt1a+SxY2rG2I\/EWApRChsxH8y7He+vXr29f5N2m2hw8fHlqcNkaOHGkHXYgzRRzvGDhwoE3wpQmgyd08RLMLcAEeEe5MivHjx5tFixaVa08nBJP33Zfkdg853xTWafrM6sFp0izkgZmCewwsmTIgcmuSqCoNIckAGET6FpZ8JNLs2bOtbgox0BhN3HEJZQGm9JF2yMYBWMkBKiRBw1OnTrUuL5kwffr0MbVq1TKca+JocadOnWwRIvhJosAzUjjKDcZIWIzCLOSBmYJ7OutG2tSDLNmAm2WQs98AURtFknKG7g0YMMBGzRcDmLTTuXPn4KsBvUysu+++O5hwUTrmqFGjzJAhQ2x5N\/pd3GZ4JlAVsgRPe2CmAOaMGTOsvgUh9bR+Fre6yZMnB0cxwq5zoR7UBM4XIU1Je5gVmK1btzajR4\/O6eKSJUvsLWaQvr0jDjD1hKE87jPKQagRrn4clze854GZhFsr39UWedhVLHGqHDFihF36ojJ7UEfv3r2tAaLT0mRZysMML9qRM+xa+kcBU\/s3KUvfMKoAN30rVtpvD8w4KHLe0acM2fHp3r17wVpYmjnIhnXLUiqgC5NiUpmAl3+TRrCQxKR+kd5hxg9JZ7t161aurwJMMnegf0L53EV8C+fnJSuxrpBvY5cr6xFmD8yCkAp\/QSzXOPcA4cbBLQPJTRgCzHyXgWJYTZgwIUeq5pOYWvcNA2aYJZ9UYgo3OGlJRhL+Zs6cmXNqtBi7XB6YKYGpU0bjF+SkZBTpvXRZLlEBSI\/NIJKQS3aLdB2SI1ODX4AZJv10OxUFTG7q4J7NmjVr5vgr8VSQDwmdG3KNrKRs9sBMyrGV7+tUgSj6WKss0y7hksHpzH+xVtne48jvtGnTrF8RCssbpJdlnT5b0m3jfCc3kaYePXrYVINQRQGTawyxxtlgYEtWE1KUVDN4GnjGO2nJAzMt54yxEoLsGxDpYkghw5JNFBGp\/vBHooOKLqalCIOIHxDAoo9hLYtTmmddu3YNMnxQj4C+f\/\/+dscFkLPM4+dE56W89KUYwMSP2bFjR\/tteATwDECDBw+2e\/9IelLjyGYBz\/QOF\/1Bf05LHphpObdy5wZjgiwYmgCNXLEiv4c54rWvkvcwXMirCRClvOuSQSIiGYUAtaSsASwyCbJKTOJLSYct\/WDSTJkyxXz77bemTZs2QftMLr6XOFT+ICYnwS3eXZQBXFmLEqSB5AJALhipu0mTJjY9obuvLe2iX7KkuxYug40+2qFDh3JdxBF+0UUX5fwOGGhHkv5rYIo\/NInxQ+VIPb2DI1uSJPzq2bNn6PciWWkna3C0l5hZkbmyPPvebNchvQiYQJI1bNgwVnAwOYrQWVk+2S2hHOVlGzKsixggBFCgMhDjyfthBlTWzyN0b\/HixdbYqV27dlAd6gYRU\/SbHStUDSL2uQKwGOSBWQwu+jqKzgEPzKKz1FdYDA54YBaDi76OonPAA7PoLPUVFoMDHpjF4KKvo+gc+C+0swoIGys5JQAAAABJRU5ErkJggg==","height":0,"width":0}}
%---
%[output:306a9801]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKYAAABkCAYAAAAMqEvIAAAAAXNSR0IArs4c6QAAF75JREFUeF7tnQnUVlMXx0+G8AkhLYpVkooolgxRFE0vMs+EMiVkaEJokCFTlMyiyFg0CpEyT4VMZYiMlWTKPPSt39G+337Oe+\/z3OF5X8\/nPXutd9Fz7xnuPv+zz9777LNPtRUrVqwwnjwHSowD1TwwS2xEfHcsBzwwPRBKkgMemCU5LL5THpgeAyXJAQ\/MkhwW3ykPTI+BkuSAB2ZJDovvVA4w\/\/jjD7N48WLz2WefmZ9++sk0adLEbLLJJnm59NFHH+V9vtpqq5l1113X\/lWrVs1zPCMHli9fbr777jtbyyqrrFJwfMKa+\/PPP80nn3xiPvzwQ\/PFF1+YBg0amEaNGpnatWtn7F3xigfABGBnnHGGeeedd4LazznnHHP66adHtgaQ+aA4tOGGG5qjjz7anHbaaWb11VePU8S\/E8KBq666ytxwww3Bk\/fee88w+ePSI488Yvr162d+\/PHHckUYoyOOOMKcddZZZtVVV41bZYW8FwDzqKOOMi+++GJOI8UEplS8ww47mDFjxpi11lqrQj7o317pFVdcYW666abEwPz1119Nr169DMAsRHvttZe55pprzDrrrFPo1Qp7boGJaN9yyy1zGuncubPZZ599TIcOHYoiMXUlZ599tpXOnpJzIC0wkbJIW5c23nhjs2jRonK\/o8ZNmjQpkTRO\/jXRJSwwly1bZlq0aBG8VUhSyovuUt6uXTtz3XXXBfXwfOHChea+++4z99xzT\/D7pptuap5++unIXqFHrb322ql00t9++81Ur149No9+\/vlnu2wlKfP777\/bAUujM3\/\/\/fdW345Lf\/31l+FPlus0wESfbNOmTU6Txx57rEFArLfeegbBhCQ9\/\/zzc5b4oUOHmkMPPTRuV2O9x7eAN3iQj+fVhg0btgL9cvLkyUHFzZs3N40bNza77babQXJGkQvMvffe21x\/\/fXlXidOZKeddjJff\/118Oztt9\/OWc7fffddM2LECPP666\/bGQwwWfZ33XVX061bt5yZ+9Zbb5lhw4YFdV1++eXmscceM0888UQA+B133NH06NHD7LHHHuX6s3TpUnPttdeaF154wYjxRlvbb7+96d69u9lggw3KlQHwSJ2ZM2eauXPn2uetW7c25557rpUsfA9Eu+5qMG3aNHPvvfea1157zQ48utzOO+9sV6SysrJQ9k6dOtU88MADZs6cObYMbR133HHm1VdfTbyUn3nmmTnje9hhhxl45tLYsWPNhRdeGPxMm6NHj7b\/PumkkwzqANSyZUtz6qmn5hQ\/+eSTzS+\/\/GJ\/Y5U95phjgueAke+5+eabc2wY+LDvvvsaJsnmm29u3weHzz33nKnWsmXLFWGinJe6du2a01H3Q+ICk3KAdt68ebYKQMfgisTh4wcNGhQ5AUQSi14KAGGEUKtWrcyzzz4bWp6JQttCL7\/8sjXA9CTRBZHmDNBmm20W\/IyUA7CuDi7fsuaaawb16cmJZMXQmDBhQuS3ha1OgOaWW24JLcNg6r7HMX6Y3HqMn3zyyQAIuhFWDwwfASBWOhIawnIXOuigg8qpBfq5ixu+MR8PwMP48eOtIc1EZ0JWKysrW\/Hpp5+Ws9J4+fjjj7cKcxTFBebs2bNzloQDDjjAKtcQ0m+\/\/faLbEMeAE4ZLBeY+QrzHW+++aZ9BcnDkhYFSqmHwUcyUhZiSWO2xyENTIy8gQMHFix2wQUX2FUBmjVrlhUIcakQMAFb06ZNg+qaNWuWFyRR7aYFJqsFgkAInm677bblJjkrKiof\/IJvVsfEL8YyJsRDxGshcoEpS5SUQ2J88MEHwXIpv9MwUg46\/PDDzSuvvBI0ddlll9klDh8b\/XjjjTeCZ88884ypW7euXbK1xOSF2267zaoe6LS4pTT4XnrpJbPRRhtZ\/VfrwACAJYrvQLIyU4V4DzWGZR+maaJf9H\/BggXmvPPOy2lLgPnNN9+Y3XffPZjwGBl8G3WxVKHficsGKQ0goQMPPDBQFfg3wgEXDm1hjYsaIf0pBMz58+fnqAvwFpUpKaUFZu\/evc1DDz0UNCcqHHYE0lF7Cfi2GjVq2HeLCsxCH8tsGT58uGnbtq191Z3NnTp1yvHRAUT0KqE+ffpY3cYFpmvlX3311WbkyJFBOXTAbbbZxkptpDdEX\/h\/UcABEnqmkOhX7oxHX+NPiOUdV5uQABPVQk9ud7K7\/sgHH3zQTjqWXaGtt97aTJkyJfj3l19+afU37YMsBMynnnrKnHDCCUEdhdSzqDFMC0wECOMldMghh9gJv91225kffvjBMHGEECwyHpUKTDoAuNDX0C9hKmAUQuJqtxXWopamfBCSzAXmHXfckWPkMEOZqUIPP\/ywwaBjCdGDussuu+SMg9YhRQVAfdCGgtSlC+p6BZiuIYH7pWbNmkExdtf4ExoyZIjZaqutzMEHHxz8Bp\/69u2b00fXkCkETFdV0mpUFAjDfk8LTHeV0nUz8eDX\/vvvbyelpqICE\/1Fz062NZkRd955Z06jspS7s7kQo0TPdIH56KOP5uxAoWijcGtgwljAmYRYPgcMGGDuuuuuoBjGU61atXKqwbKUHTMBZhK9lMpQCVjutTRG6rtWu7saFAKmq6axKiCdowi1RgjhITtAaYGJVOzSpUs5FcRtn+9CjQnaLqaOGeUucp27Yom6RhH6F\/pWFDVs2NBK2zTAxADQ26e4J7ReHdYmy60743F7INk04SISnVZ4cOONN5orr7wyeA1pn28rlpUDUODiEgrT9dki1npZIWBSl7tSoGbUqVOn3Cd\/9dVX1o0lxERmhYA0MF2pi9eCpVnIVRfEXTRu3DiDehZF06dPN1tssYV9XFSJGQVMVw+TjruMuPjii63hUojSABMmt2\/f3hpVUFRf3bZdtaB\/\/\/45qwL+VwwKIakXKa5B5kr1sG9066K\/2hsAcJlMSXRM2nHBfOSRR5pLLrmkXBfw7WIDCGndXU8+\/v\/+++8P3sP3jAvJBSb+a56JFGYyoM7gz8UABKjaSNUTsVKA6TIco0DcKHo2Iy0nTpxo1l9\/ffuNM2bMyFnaYBRulbTAdAcI0MlM\/\/zzz61xxNIDYfwg6d9\/\/33TsWPHnEHkd6xy3Gw9e\/YMwK4B71rDAJZBJyIIQhqL85p\/oy6gX8MPTRhfbHZAuFPYndEUR2IyGQG5JpzsuALxVgB0dubwGmhi00J0fj2peUc8JHheTjzxxBxJKILHNW7Zg7\/11luDJlyBpSdCpQDTNXK0g9b19WF0wATCsdDnNInUSQvMMJ8pzFpjjTXKBTcwSLiyINflUU7UqB+0JD7llFMMy5MQEw9A477S4YLolvhNsUhdqUVZJBQ7T9p1JnXGASbvsoGhJ0K+b+AZEw5nu5A4vuXfjBPqEe4fN1JJL+Va\/5aJi8qG7oujX7u\/mBxikFYKMN0lG2sMyYhijf7B9lXYropmnhbzaYFJffjw9HZm2AC50g03DVJe1ABdhgHSA6OByXfvueeeoSFmeoCZnKLvoq8xmNpizweiuMDEbwgPtU8xql4mKz5THfoWdyOEOjUwWba1pyGqTSbsqFGjgq3nTMB0o5Ki9DbAh46nB\/D2228P\/JlIA5ayML0HaYIBgtQQKgRM9lu1deu6eCg\/ePDg0MHHbYMO5gZosCyxFOMIZ2uVfmExY0nSlkhA1zDAQc9EYK\/cJSQH1qjrKkGaYCDitdDE5MAfq11IcYEp9WA44WkI2\/1ikiFZ+aawAJXnn3\/erh56exNjhW1L+iQT1zV+MLZoMyqoHFUANUsHt5TU0QoG\/+OPP7a7RewAYEWjMKeJ4im0VKGQE3WDSwg9CYu\/fv36sYKYdQQT+8raSofJrh5IXwAb34VeyjfRXliwiO73kiVL7JYte\/EAMklUUqHvB1z0h50y\/MdY3fXq1bNqTSFiJYB3TE7+4gQVYwgxtuje6PGML6cj8I4Q4eRSSQGzEEP+iecYbnoHB6MIw0WMGNedhCTWkTX\/RJ\/\/DW16YBYYRVci8jpLHsswEsBdnmRf\/t8Ajn\/yGzwwY3D\/8ccft479fARYcSMhUT1l54AHZnYe+hoqgAMemBXAVF9ldg54YCbkITqkp3gc0Pvu8Ur87y0PzIQcCzvmnLCKKvE6Ozj6AGLSj\/bATMgxCQqG6UhPnPEuucHEhZqQqHrZFIiqt0n7Y0zjdn8HuSxdMNc8d3M\/64cVom\/UkUVS0Tb9yVIP5anHA7PQyBfxuQBTQAQwdztlaNACYEkKTAprFYHtWQYXIG7Y4O+gjvnTx5paWzTLC8woNSMLUNOwTk\/eNOUp4yXmSs6xM8H2Ibss+TJQyFIO+FiuAOb+Q6cF\/J\/Yr6wcMMMAo8ESFeUN4Gs1aGbrBvCFgKljJqVDWZfUpMASaZ+13SoPTADJ0Qz2s2Uvn2MQRDhxPtzNCxS2lOcDZr6jBXrQAaBIXlmm4wBTxwSIlJXlfv4TY03NHz7IWVL1YTwN3mJKVb+UJ53OIe+7RyD0uW1iFgl\/03v1aYA5dvJTOcs9UlUv018veNMs\/XBuKmCKRBW9U+uhYcCsDKnqgZkRmDpOlLPPxCBy\/EGfziRyhpN92sBAB5RooUJLOYMUBkwtDQFQWmC60joOMF1J3LD2fzIZKnoYxHjiN2\/8pATopZdeas+jc4iOOEUJzKA6eebqSqJj\/r8Ac970u8txxwMzJWAqqxjJBEjuRXS2m0BBnwvn3IqEnBVrKa8siYkkbtz+f+eoMKIqEpiMnV\/KMyJYcvpwnFUnO6BanQCBwGLRzeIA0+2WNmx4ho5ZmcDU7iy3bYCKseUSK0Jag8gDMwMw9UEpDTypUkfncyJQIuhlKZezKeibrgES1i33nbAyhd7Rz8XYKVSG9+K8U4iVbnKIfO\/DE+8uKsTRiOf65GBUDKVISX0MRKRBymarTDGkrXZlJf3wKuvH5IiD5M7kLAtHBDRx3EKOzYYt9UkZ7d9PxoEqC0yc6XKGOywZgc7yFrbUJ2OzfzspB6osMGGULNVucleecYZbcumQX1NyZSZlsH8\/HQeqNDAlc1rYsWPZESLHpZsULB2rfakkHKjSwNTZ5rSBw5FZdnRY7sl8zFlxT5XLgSoNTM6WkwZFsqdx8pEzzpLWJSzXeOUOT9VtrUoDk2EneQFZL9yLmVjeSSMYdVEWoMZAIgFYnCQBWSAWNyQvSRscO+aWCZJmJblZLUkbWd6t8sAU5pEdAiOHdDbsAkUBktxCpHXRyVxxvrP0F3vJTxqSFxcIOkKe3EJhmTDi1lVR73lgJuAsyQ\/IyiHptwmRQ+pIHKebFTdB1aGvJg3Ji9MeqWrIzCy5izww43CtxN8hjIurTyBys5MVja1LMqPJ9TDF8nmmCcmLwz43R6gHZhyulfg7cokWeS+5WEqI5Z+7isjDXqx7MtOE5BViH3v+5HonQ5tkZvPALMS1En+ugzp0JmLptiRcda9ASftZaULy8rXFaUqWcDYKuM9I0nN7YKYdoRIpRyJVnO0Q6a\/d1HuSs1PfxJal62lC8qLaQzcmeSoSnSAUYgQkxbcHZpZRKoGyEjgcBTwMIkmNnTSZqvt5aUPyotgkaoEkldW3THhglgC4snRBEvOTaJTc4S7pVNDss2e5hD5tSF7Y98n5JaKnCFYhEt8DMwsSSqysXKsSddc6Fxlw5yNEpl59fijppxQrJI\/MvxhsuIZ0sLMHZtIRKeH3RfJELeWSQxPfpr5mMM0nFSskT+6rpE86yzE6Jy4uCA8DSR7YftVXYafpdzHLeAd7TG7qu4rCAou5v4Yz6O7lTDGrL\/daMULyRLeM0wd9lUmc9yv6HQ\/MmBxmb7xly5Z2WQy7wU3us8FPyFXTWakYIXlMJtJxu8S3yLEHJhN6Z4sWLexlVKVCHpgJRkK2CFnOiUCS4xgcvRCHO4YRBlJWShqShztL7n3kKu18N1xoq99b5VlHqgTKY0xg4MiFAOQ3IvhDLs9ys3Zk6XLSkDydPYR7GrmqJIo8MLOMTImW5SpBJJK+JQ0Jyv0+WU4Fhn1ukpA8naChEDD1TRxZXVsVNUx+KU\/JWa7xQ4fjEikuh6rImMa4IXkpP6Uki3lgluSw+E55YHoMlCQHPDBLclh8pzwwPQZKkgMemCU5LL5THpgeAyXJAQ\/MkhwW3ykPTI+BkuSAB2aRhoUzQQsXLjTz5s2zRy8INatXr549+FWnTp0itVJ1qvHALMJYjxs3zvTt2zeyJrYwSUVTiokFivD5FVKFB2YGthIMMWjQIHvqUIh986ZNm5rly5fbw19CSFDS0JRSaFm+T9fxpwSI1K1bNwOnkhf1wEzOs6AEt10IKAl14wQioJQLq8h6wW+SxrBVq1b2Fjb3hGWGLlRYUX2GadasWZUe3e6BmXJodaYMssQBuLB8RyRD4NjC3Ll\/3wyhz96kbLpSinlgVgqbi98I9wJxlhyaOHFikDY7rCWCcTnXDXEDW69evXJeI8kVZ4YAA5FEHKsA7MR+Vq9ePeddjnBwJqht27amefPmOc9QH7hQC+IoscRkjhkzxixbtsyUlZVZo2zSpEmGPhFfyuVbnJdHmgtxzGLOnDn2Ui6oS5cuNqsdoX01atSwv9FXrlzh4B39adSokV0tuNUjKiFZklHwEjMJt1a+SxY2rG2I\/EWApRChsxH8y7He+vXr29f5N2m2hw8fHlqcNkaOHGkHXYgzRRzvGDhwoE3wpQmgyd08RLMLcAEeEe5MivHjx5tFixaVa08nBJP33Zfkdg853xTWafrM6sFp0izkgZmCewwsmTIgcmuSqCoNIckAGET6FpZ8JNLs2bOtbgox0BhN3HEJZQGm9JF2yMYBWMkBKiRBw1OnTrUuL5kwffr0MbVq1TKca+JocadOnWwRIvhJosAzUjjKDcZIWIzCLOSBmYJ7OutG2tSDLNmAm2WQs98AURtFknKG7g0YMMBGzRcDmLTTuXPn4KsBvUysu+++O5hwUTrmqFGjzJAhQ2x5N\/pd3GZ4JlAVsgRPe2CmAOaMGTOsvgUh9bR+Fre6yZMnB0cxwq5zoR7UBM4XIU1Je5gVmK1btzajR4\/O6eKSJUvsLWaQvr0jDjD1hKE87jPKQagRrn4clze854GZhFsr39UWedhVLHGqHDFihF36ojJ7UEfv3r2tAaLT0mRZysMML9qRM+xa+kcBU\/s3KUvfMKoAN30rVtpvD8w4KHLe0acM2fHp3r17wVpYmjnIhnXLUiqgC5NiUpmAl3+TRrCQxKR+kd5hxg9JZ7t161aurwJMMnegf0L53EV8C+fnJSuxrpBvY5cr6xFmD8yCkAp\/QSzXOPcA4cbBLQPJTRgCzHyXgWJYTZgwIUeq5pOYWvcNA2aYJZ9UYgo3OGlJRhL+Zs6cmXNqtBi7XB6YKYGpU0bjF+SkZBTpvXRZLlEBSI\/NIJKQS3aLdB2SI1ODX4AZJv10OxUFTG7q4J7NmjVr5vgr8VSQDwmdG3KNrKRs9sBMyrGV7+tUgSj6WKss0y7hksHpzH+xVtne48jvtGnTrF8RCssbpJdlnT5b0m3jfCc3kaYePXrYVINQRQGTawyxxtlgYEtWE1KUVDN4GnjGO2nJAzMt54yxEoLsGxDpYkghw5JNFBGp\/vBHooOKLqalCIOIHxDAoo9hLYtTmmddu3YNMnxQj4C+f\/\/+dscFkLPM4+dE56W89KUYwMSP2bFjR\/tteATwDECDBw+2e\/9IelLjyGYBz\/QOF\/1Bf05LHphpObdy5wZjgiwYmgCNXLEiv4c54rWvkvcwXMirCRClvOuSQSIiGYUAtaSsASwyCbJKTOJLSYct\/WDSTJkyxXz77bemTZs2QftMLr6XOFT+ICYnwS3eXZQBXFmLEqSB5AJALhipu0mTJjY9obuvLe2iX7KkuxYug40+2qFDh3JdxBF+0UUX5fwOGGhHkv5rYIo\/NInxQ+VIPb2DI1uSJPzq2bNn6PciWWkna3C0l5hZkbmyPPvebNchvQiYQJI1bNgwVnAwOYrQWVk+2S2hHOVlGzKsixggBFCgMhDjyfthBlTWzyN0b\/HixdbYqV27dlAd6gYRU\/SbHStUDSL2uQKwGOSBWQwu+jqKzgEPzKKz1FdYDA54YBaDi76OonPAA7PoLPUVFoMDHpjF4KKvo+gc+C+0swoIGys5JQAAAABJRU5ErkJggg==","height":0,"width":0}}
%---
