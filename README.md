# Queue Simulation: allowing customers to renege, urgent care with reneging and extension
Group members: Aylene McEntire, Sydney Morrison, and Sarah Kundrat
A queueing simulation in Matlab.

This is an M/M/s queue simulation.
The overall architecture is event driven.

The main class is `ServiceQueue`.
It maintains a list of events, ordered by the time that they occur.
There is one `Arrival` scheduled at any time that represents the arrival of the next customer.
When a customer reaches the front of the waiting queue, they can be moved to a service station.
Once a customer moves into a service slot, a `Departure` event for that customer is scheduled.
There should be one `Departure` event scheduled for each busy service station.
There is one `RecordToLog` scheduled at any time that represents the next time statistics will be added to the log table.

FYI: The use of "queueing" rather than "queuing" is for consistency with the textbook.
Summary of renege feature additions:
In the Renege live script, we added the reneging time to be 15 minutes, or theta =4 in terms of hours. We increased our max time to 50 and log interval to 0.2. We included our M/M/1 queue theory:
% Solving 3.1 and 3.2
P0 = 1/hypergeom(1, mu/theta, lambda/theta);
nMax = 25;
P = zeros([nMax + 1, 1]);
P(1) = P0;

for j = 1:nMax
    P(j + 1) = P(j) * (lambda / (mu + (j - 1) * theta));
end

% Solving 3.2.2
pi_s = (mu * (1 - P0)) / lambda;

fprintf('P0 to P5: %s\n', mat2str(P, 4));
and recalculated our theory calculations accordingly:
n_vals = 0:nMax;
L_theory = sum(n_vals' .* P); 

Lq_theory = sum(max(0, n_vals - s)' .* P);

lambda_eff = lambda * pi_s; 
W_theory = L_theory / lambda_eff;
Wq_theory = Lq_theory / lambda_eff;

theory = [L_theory, Lq_theory, W_theory, Wq_theory]

Then to add our number of customers reneged distribution, we set NumReneged = cellfun(@(q) length(q.Reneged), Qsamples), set the nMax to the max of numReneged. Our theoretical and statisitcal calculations for Run_Service_Queue_Renege are included under the literate script file bracket below. 
Literate Script files:
- Run_Service_Queue.m
  This live script computes the baseline calculations required for this simulation project. It computes the theoretical and simulation of L, L_q, W, and W_q, as well as each respective histogram; the count of customers in system, the count of customers in waiting, the total time customers spend in the system, the time customers spend waiting in the queue, the time customers spend being served, and the count of customers served per shift. Our assumptions include: lambda = 2 (arrival rate); mu = 3(Departure (service) rate); s = 1; NumSamples = 500; MaxTime = 50; and  LogInterval = 1. Simulation versus theore numbers:
Comparing values for P: exactly the same
    Theory: P[0-5]=[0.333, 0.222, 0.148, 0.0987, 0.0658, 0.0438]
    Simulation: P[0-5]=[0.333, 0.222, 0.148, 0.0987, 0.0658, 0.0438]
Comparing values for the mean number is system: 0.118437 difference between thoery and simulation
    Theory:2 
    Simulation: 1.8881563
Comparing values for the mean number waiting in system: 0.107954 difference between thoery and simulation
    Thoery: 1.333
    Simulation: 1.225046
Comparing values for the mean time in system: 0.06362 difference between thoery and simulation
    Theory: 1
    Simulation: 0.93638
Comparing values for the mean waiting time is system: 0.066489
    Theory:0.666 
    Simulation: 0.599511

- Run_Service_Queue_Renege.m
  This live script computes the baseline but with a new M/M/1 queue with reneging system where our reneging time is 15 minutes, or theta = 4 to convert to hours. This time we set our NumSamples to 500 and our LogInterval to 0.2. For our M/M/1 queue simulation; we set our nMax to 25. How do these compare to the simulation numbers:
Comparing values for P: Very similar, a few decimals off
    Theory:P[0-5]=[0.527, 0.351, 0.100, 0.0182, 0.00243, 0.000256}
    Simulation: P[0-5]=[0.5272, 0.3514, 0.1004, 0.1826, 0.002434, 0.002562]
Comparing values for : Exactly the same
    Theory:\pi_s=0.7092
    Simulation: \pi_s=0.7092
Comparing the mean number in system: 0.698416 difference between theory and simulation
    Theory: L=0.618
    Simulation: L=1.316416
Comparing the mean number waiting in system: 0.575456 difference between theory and simulation
    Theory: L_q=0.145
    Simulation: L_q=0.7204560
Comparing the mean time in system: 0.164659 difference between theory and simulation
    Theory: W=0.435
    Simulation:W=0.599659 
Comparing the mean waiting time in system: 0.18208 difference between theory and simulation
    Theory: W_q=0.102
    Simulation: W_q=0.28408
- Run_Service_Queue_Renege_Extension.m
  For the Extension part of this simulation, we decided to simulate s = 2 doctors instead of 1. This time we set s = 2, and LogInterval = 0.05.
