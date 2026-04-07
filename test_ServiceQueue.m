function q = test_ServiceQueue(MaxTime)
    % test_ServiceQueue Basic test of the ServiceQueue class.
    %
    % q = test_ServiceQueue(MaxTime) - Schedule one customer to arrive,
    % then run the queue until its internal clock passes MaxTime.
    arguments
        MaxTime = 8.0;
    end
    q = ServiceQueue(NumServers=2);
    q.schedule_event(Arrival(random(q.InterArrivalDist), Customer(1)));
    run_until(q, MaxTime);
end