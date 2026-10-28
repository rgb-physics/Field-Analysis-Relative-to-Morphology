function queue = farmSurfacePriorityQueue
%FARMSURFACEPRIORITYQUEUE Internal mutable binary min-heap.
% Shared binary min-heap for free-face collapse and sector-burning events.
% Returns Push(id,key), [id,key]=Pop(), and IsEmpty() function handles.
% Each call creates independent state; copying the returned struct aliases the
% SAME captured state. IDs and keys are numeric scalars validated by callers.
% Pop requires a nonempty queue. Equal-key ordering is unspecified. Duplicate
% IDs/keys are allowed; callers implement stale-event checks, not decrease-key.
% Push/Pop take O(log Q) comparisons. Arrays retain peak allocated queue size.
% This helper is internal even though farmSetup makes its path visible.

heapTime = zeros(0, 1);
heapNode = zeros(0, 1);
heapSize = 0;
queue = struct('Push', @push, 'Pop', @pop, 'IsEmpty', @isEmpty);

    function empty = isEmpty()
        empty = heapSize == 0;
    end

    function push(node, time)
        heapSize = heapSize + 1;
        pos = heapSize;
        while pos > 1
            parent = floor(pos / 2);
            if heapTime(parent) <= time
                break
            end
            heapTime(pos, 1) = heapTime(parent);
            heapNode(pos, 1) = heapNode(parent);
            pos = parent;
        end
        heapTime(pos, 1) = time;
        heapNode(pos, 1) = node;
    end

    function [node, time] = pop()
        node = heapNode(1);
        time = heapTime(1);
        lastTime = heapTime(heapSize);
        lastNode = heapNode(heapSize);
        heapSize = heapSize - 1;
        pos = 1;
        while 2 * pos <= heapSize
            child = 2 * pos;
            if child < heapSize && heapTime(child + 1) < heapTime(child)
                child = child + 1;
            end
            if lastTime <= heapTime(child)
                break
            end
            heapTime(pos) = heapTime(child);
            heapNode(pos) = heapNode(child);
            pos = child;
        end
        if heapSize > 0
            heapTime(pos) = lastTime;
            heapNode(pos) = lastNode;
        end
    end
end
