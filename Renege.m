classdef Renege < Event
    properties
        CustomerId 
    end
    
    methods
        function obj = Renege(time, id)
            obj.Time = time;
            obj.CustomerId = id;
        end
        
        function visit(obj, queue)
            queue.handle_renege(obj);
        end
    end
end