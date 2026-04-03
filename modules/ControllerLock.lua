local Lock = {}

function Lock.tryAcquire(State, owner, reason)
    if State.lockOwner and State.lockOwner ~= owner then
        return false
    end

    State.lockOwner = owner
    State.lockReason = reason or ""
    return true
end

function Lock.release(State, owner)
    if State.lockOwner == owner then
        State.lockOwner = nil
        State.lockReason = nil
    end
end

function Lock.isOwnedByOther(State, owner)
    return State.lockOwner ~= nil and State.lockOwner ~= owner
end

return Lock